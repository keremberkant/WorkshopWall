import AppKit
import CanliDuvarCore

/// Downloads Wallpaper Engine Workshop items with Valve's official SteamCMD tool.
///
/// The Steam password never passes through this app: the user signs in once in Terminal,
/// directly in SteamCMD, which then keeps its own session for later downloads.
/// SteamCMD and everything it downloads live next to the wallpaper library (e.g. on an external drive).
@MainActor
final class WorkshopDownloader: ObservableObject {
    static let workshopURL = URL(string: "https://steamcommunity.com/app/431960/workshop/")!
    static let steamcmdURL = URL(string: "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz")!

    @Published var log = ""
    @Published private(set) var isRunning = false
    @Published var status: String?
    @Published private(set) var needsLogin = false
    @Published var username: String = UserDefaults.standard.string(forKey: AppSettings.Keys.steamUser) ?? "" {
        didSet { UserDefaults.standard.set(username, forKey: AppSettings.Keys.steamUser) }
    }

    private unowned let library: WallpaperLibrary

    init(library: WallpaperLibrary) { self.library = library }

    var root: URL {
        if let saved = UserDefaults.standard.string(forKey: AppSettings.Keys.steamcmdRoot) {
            return URL(fileURLWithPath: saved, isDirectory: true)
        }
        return library.root.deletingLastPathComponent().appendingPathComponent("SteamCMD", isDirectory: true)
    }

    private var script: URL { root.appendingPathComponent("steamcmd.sh") }
    private var home: URL { root.appendingPathComponent("home", isDirectory: true) }
    private var downloads: URL { root.appendingPathComponent("downloads", isDirectory: true) }

    var isInstalled: Bool { FileManager.default.isExecutableFile(atPath: script.path) }
    private var login: String { Workshop.sanitizedUsername(username) }

    // MARK: Install

    func install() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }
        status = String(localized: "Downloading SteamCMD…")
        do {
            try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
            let (temp, _) = try await URLSession.shared.download(from: Self.steamcmdURL)
            let archive = root.appendingPathComponent("steamcmd_osx.tar.gz")
            try? FileManager.default.removeItem(at: archive)
            try FileManager.default.moveItem(at: temp, to: archive)
            _ = try await run("/usr/bin/tar", ["-xzf", archive.path, "-C", root.path])
            try? FileManager.default.removeItem(at: archive)
            status = String(localized: "Preparing SteamCMD for the first time (this can take a few minutes)…")
            _ = try await run("/bin/bash", [script.path, "+quit"])
            status = isInstalled ? String(localized: "SteamCMD is ready.") : String(localized: "SteamCMD could not be installed.")
        } catch {
            status = String(localized: "Install failed: \(error.localizedDescription)")
        }
    }

    // MARK: Sign in (in Terminal)

    func openLoginTerminal() {
        guard !login.isEmpty else { status = String(localized: "Enter your Steam user name first."); return }
        let command = root.appendingPathComponent("steam-login.command")
        let intro = String(localized: "Canlı Duvar – Steam sign-in (only needed once). Your password and Steam Guard code go directly to Steam.")
        let done = String(localized: "Done. You can close this window and return to Canlı Duvar.")
        let body = """
        #!/bin/zsh
        cd \(shellQuote(root.path))
        clear
        echo \(shellQuote(intro))
        echo
        HOME=\(shellQuote(home.path)) ./steamcmd.sh +login \(shellQuote(login)) +quit
        echo
        echo \(shellQuote(done))
        """
        do {
            try body.write(to: command, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: command.path)
            NSWorkspace.shared.open(command)
            needsLogin = false
            status = String(localized: "Terminal opened: enter your password and Steam Guard code there, then press Download.")
        } catch {
            status = String(localized: "Could not open the sign-in window: \(error.localizedDescription)")
        }
    }

    private func shellQuote(_ s: String) -> String { "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'" }

    // MARK: Download

    func download(_ text: String) async {
        guard !isRunning else { return }
        let ids = Workshop.itemIDs(in: text)
        guard !ids.isEmpty else { status = String(localized: "No Workshop link or ID found."); return }
        guard !login.isEmpty else { status = String(localized: "Enter your Steam user name first."); return }
        guard isInstalled else { status = String(localized: "Install SteamCMD first."); return }

        isRunning = true
        defer { isRunning = false }
        log = ""
        status = String(localized: "Downloading items: \(ids.count)…")
        try? FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)

        var args = [script.path, "+force_install_dir", downloads.path, "+login", login]
        for id in ids { args += ["+workshop_download_item", Workshop.appID, id, "validate"] }
        args.append("+quit")

        let output: String
        do { output = try await run("/bin/bash", args) } catch {
            status = String(localized: "Could not run SteamCMD: \(error.localizedDescription)")
            return
        }

        let report = Workshop.parseDownloadOutput(output)
        if report.needsLogin {
            needsLogin = true
            status = String(localized: "Steam sign-in required: use “Sign In to Steam…” once.")
            return
        }

        var added: [String] = [], unsupported: [String] = []
        var playableFolders: [URL] = []
        for item in report.downloaded {
            let wallpaper = Wallpaper.load(folder: item.folder)
            if let wallpaper, wallpaper.isPlayable {
                playableFolders.append(item.folder)
                added.append(wallpaper.title)
            } else {
                unsupported.append(wallpaper?.title ?? item.id)
                try? FileManager.default.removeItem(at: item.folder)
            }
        }
        if !playableFolders.isEmpty { await library.importItems(playableFolders, move: true) }

        var lines: [String] = []
        if !added.isEmpty {
            let names = added.joined(separator: ", ")
            lines.append(String(localized: "Added: \(names)"))
        }
        if !unsupported.isEmpty {
            let names = unsupported.joined(separator: ", ")
            lines.append(String(localized: "Scene wallpapers can’t play on macOS and were removed: \(names)"))
        }
        if !report.failed.isEmpty {
            let failed = report.failed.map { "\($0.id) (\($0.reason))" }.joined(separator: ", ")
            lines.append(String(localized: "Failed: \(failed). Check that the item belongs to Wallpaper Engine and that your account owns Wallpaper Engine."))
        }
        status = lines.isEmpty ? String(localized: "SteamCMD reported nothing; see the log.") : lines.joined(separator: "\n")
    }

    // MARK: Process

    private func run(_ executable: String, _ arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = root
        var environment = ProcessInfo.processInfo.environment
        environment["HOME"] = home.path // keep all SteamCMD data next to the library
        process.environment = environment
        process.standardInput = FileHandle.nullDevice
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        let collector = OutputCollector()
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            let text = String(decoding: data, as: UTF8.self)
            collector.append(text)
            Task { @MainActor in
                guard let self else { return }
                self.log += text
                if self.log.count > 60_000 { self.log = String(self.log.suffix(40_000)) }
            }
        }
        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { _ in
                pipe.fileHandleForReading.readabilityHandler = nil
                collector.append(String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self))
                continuation.resume(returning: collector.text)
            }
            do { try process.run() } catch { continuation.resume(throwing: error) }
        }
    }
}

private final class OutputCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = ""
    func append(_ s: String) { lock.lock(); buffer += s; lock.unlock() }
    var text: String { lock.lock(); defer { lock.unlock() }; return buffer }
}
