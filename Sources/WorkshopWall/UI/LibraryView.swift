import WorkshopWallCore
import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var library: WallpaperLibrary
    @EnvironmentObject private var desktop: DesktopController
    @State private var dropTargeted = false
    @State private var showWorkshop = false
    @State private var search = ""
    @State private var filter: Filter = .playable

    enum Filter: Hashable { case playable, all }

    private let columns = [GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 16)]

    private var shown: [Wallpaper] {
        library.wallpapers
            .filter { filter == .all || $0.isPlayable }
            .filter { search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack(spacing: 0) {
            NowPlayingBar()
            Divider()
            content
        }
        .toolbar { toolbar }
        .searchable(text: $search, placement: .toolbar, prompt: Text("Search wallpapers"))
        .overlay {
            if dropTargeted {
                RoundedRectangle(cornerRadius: 12).stroke(Color.accentColor, lineWidth: 3).padding(6)
            }
        }
        .sheet(isPresented: $showWorkshop) { WorkshopSheet() }
        .onDrop(of: [.fileURL], isTargeted: $dropTargeted, perform: handleDrop)
        .onReceive(NotificationCenter.default.publisher(for: .showWorkshop)) { _ in showWorkshop = true }
        .navigationTitle("WorkshopWall")
    }

    @ViewBuilder private var content: some View {
        if !library.isAvailable {
            ContentUnavailableView {
                Label("Library folder not found", systemImage: "externaldrive.badge.exclamationmark")
            } description: {
                Text("Connect the drive that holds your wallpapers, or choose another folder in Settings.")
            }
        } else if library.wallpapers.isEmpty {
            ContentUnavailableView {
                Label("No wallpapers yet", systemImage: "photo.on.rectangle.angled")
            } description: {
                Text("Drag Wallpaper Engine project folders, the Workshop folder (431960), or MP4 / MOV / GIF / image / HTML files here — or download from the Steam Workshop.")
            } actions: {
                HStack {
                    Button("Add Files…") { importPanel() }
                    Button("Download from Workshop…") { showWorkshop = true }
                }
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(shown) { wallpaper in
                        WallpaperCard(wallpaper: wallpaper, isCurrent: desktop.current == wallpaper)
                            .onTapGesture { desktop.apply(wallpaper) }
                            .contextMenu { contextMenu(for: wallpaper) }
                    }
                }
                .padding(16)
            }
            .overlay(alignment: .bottom) { statusBar }
        }
    }

    @ViewBuilder private var statusBar: some View {
        if library.isImporting || library.lastMessage != nil {
            HStack(spacing: 8) {
                if library.isImporting { ProgressView().controlSize(.small); Text("Importing…") }
                else if let message = library.lastMessage { Text(message) }
            }
            .font(.callout)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .padding(12)
            .task(id: library.lastMessage) {
                try? await Task.sleep(for: .seconds(5))
                library.lastMessage = nil
            }
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Picker("Show", selection: $filter) {
                Text("Playable").tag(Filter.playable)
                Text("All").tag(Filter.all)
            }
            .pickerStyle(.segmented)
        }
        ToolbarItemGroup(placement: .primaryAction) {
            Button { showWorkshop = true } label: { Label("Download from Workshop…", systemImage: "arrow.down.circle") }
                .help("Download wallpapers from the Steam Workshop")
            Button { importPanel() } label: { Label("Add Files…", systemImage: "plus") }
                .help("Add wallpaper files or folders")
            Button { NSWorkspace.shared.open(library.root) } label: { Label("Show in Finder", systemImage: "folder") }
                .help("Show the library folder in Finder")
        }
    }

    @ViewBuilder private func contextMenu(for wallpaper: Wallpaper) -> some View {
        Button("Apply") { desktop.apply(wallpaper) }.disabled(!wallpaper.isPlayable)
        Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([wallpaper.folder]) }
        if let id = wallpaper.workshopID,
           let url = URL(string: "https://steamcommunity.com/sharedfiles/filedetails/?id=\(id)") {
            Button("Open Workshop Page") { NSWorkspace.shared.open(url) }
        }
        Divider()
        Button("Move to Trash", role: .destructive) {
            if desktop.current == wallpaper { desktop.stop() }
            library.remove(wallpaper)
        }
    }

    private func importPanel() {
        let panel = NSOpenPanel()
        panel.title = String(localized: "Add wallpapers")
        panel.message = String(localized: "Choose Wallpaper Engine project folders, the Workshop folder, or video / image / HTML files.")
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK {
            let urls = panel.urls
            Task { await library.importItems(urls) }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        Task {
            var urls: [URL] = []
            for provider in providers {
                if let item = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier),
                   let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    urls.append(url)
                }
            }
            await library.importItems(urls)
        }
        return true
    }
}

extension Notification.Name {
    static let showWorkshop = Notification.Name("WorkshopWall.showWorkshop")
}

/// Current wallpaper with previous / next / pause controls.
struct NowPlayingBar: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var desktop: DesktopController

    var body: some View {
        HStack(spacing: 12) {
            Button { AppModel.shared.step(-1) } label: { Image(systemName: "backward.fill") }
                .help("Previous wallpaper (⌘← · anywhere: ⌃⌥⌘←)")
            Button { desktop.userPaused.toggle() } label: {
                Image(systemName: desktop.userPaused ? "play.fill" : "pause.fill").frame(width: 16)
            }
            .help(desktop.userPaused ? "Resume" : "Pause")
            .disabled(desktop.current == nil)
            Button { AppModel.shared.step(1) } label: { Image(systemName: "forward.fill") }
                .help("Next wallpaper (⌘→ · anywhere: ⌃⌥⌘→)")
            Button { AppModel.shared.applyRandom() } label: { Image(systemName: "shuffle") }
                .help("Random wallpaper")

            VStack(alignment: .leading, spacing: 1) {
                Text(desktop.current?.title ?? String(localized: "No wallpaper selected"))
                    .font(.headline).lineLimit(1)
                Text(desktop.statusText).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.leading, 4)
            Spacer()
            Toggle(isOn: Binding(get: { !settings.muted }, set: { settings.muted = !$0 })) {
                Label("Sound", systemImage: settings.muted ? "speaker.slash" : "speaker.wave.2")
            }
            .toggleStyle(.button)
            .help("Wallpaper sound")
        }
        .buttonStyle(.borderless)
        .controlSize(.large)
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}
