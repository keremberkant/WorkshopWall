import AppKit
import Carbon.HIToolbox

/// System-wide shortcuts via Carbon `RegisterEventHotKey` (no Accessibility permission needed).
@MainActor
final class HotKeys {
    struct Binding {
        let keyCode: Int
        let modifiers: Int
        let action: @MainActor () -> Void
    }

    private static var actions: [UInt32: @MainActor () -> Void] = [:]
    private var refs: [EventHotKeyRef] = []
    private var handler: EventHandlerRef?

    init(_ bindings: [Binding]) {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var id = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                           nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
            guard status == noErr else { return status }
            let key = id.id
            DispatchQueue.main.async { MainActor.assumeIsolated { HotKeys.actions[key]?() } }
            return noErr
        }, 1, &spec, nil, &handler)

        let signature = OSType(0x4344_5752) // "CDWR"
        for (index, binding) in bindings.enumerated() {
            let id = UInt32(index + 1)
            Self.actions[id] = binding.action
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(UInt32(binding.keyCode), UInt32(binding.modifiers),
                                             EventHotKeyID(signature: signature, id: id),
                                             GetApplicationEventTarget(), 0, &ref)
            if status == noErr, let ref { refs.append(ref) }
        }
    }

    static let controlOptionCommand = controlKey | optionKey | cmdKey
}
