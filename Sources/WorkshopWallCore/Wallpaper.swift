import Foundation

/// A wallpaper on disk: either a Wallpaper Engine project folder (with `project.json`)
/// or a plain folder that contains a video, image or `index.html`.
public struct Wallpaper: Identifiable, Hashable, Sendable {
    public enum Kind: String, Sendable, CaseIterable {
        case video, web, image, scene, unsupported
    }

    public let folder: URL
    public let title: String
    public let kind: Kind
    /// The file to play. `nil` when the project points to a missing file.
    public let file: URL?
    public let preview: URL?
    /// Steam Workshop item ID, when known.
    public let workshopID: String?
    /// Default user properties for web wallpapers (`general.properties` in project.json),
    /// as a JSON string in the shape Wallpaper Engine passes to `applyUserProperties`.
    public let webPropertiesJSON: String

    public var id: String { folder.standardizedFileURL.path }

    /// Whether macOS can play this wallpaper.
    public var isPlayable: Bool {
        file != nil && (kind == .video || kind == .web || kind == .image)
    }

    public init(folder: URL, title: String, kind: Kind, file: URL?, preview: URL?,
                workshopID: String? = nil, webPropertiesJSON: String = "{}") {
        self.folder = folder
        self.title = title
        self.kind = kind
        self.file = file
        self.preview = preview
        self.workshopID = workshopID
        self.webPropertiesJSON = webPropertiesJSON
    }

    public static func == (a: Wallpaper, b: Wallpaper) -> Bool { a.id == b.id }
    public func hash(into h: inout Hasher) { h.combine(id) }

    /// Formats AVFoundation can decode natively (hardware accelerated on Apple silicon).
    public static let videoExtensions: Set<String> = ["mp4", "mov", "m4v"]
    public static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "gif", "heic", "webp", "bmp", "tiff"]
    public static let webExtensions: Set<String> = ["html", "htm"]

    public static func kind(forExtension ext: String) -> Kind {
        let ext = ext.lowercased()
        if videoExtensions.contains(ext) { return .video }
        if imageExtensions.contains(ext) { return .image }
        if webExtensions.contains(ext) { return .web }
        return .unsupported
    }

    // MARK: Loading

    /// Reads a folder as a wallpaper. Returns `nil` if the folder contains nothing usable.
    public static func load(folder: URL, fileManager fm: FileManager = .default) -> Wallpaper? {
        let projectURL = folder.appendingPathComponent("project.json")
        if let data = try? Data(contentsOf: projectURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return fromProject(json, folder: folder, fileManager: fm)
        }
        return fromLooseFiles(folder: folder, fileManager: fm)
    }

    static func fromProject(_ json: [String: Any], folder: URL, fileManager fm: FileManager) -> Wallpaper {
        let title = (json["title"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? folder.lastPathComponent

        var file = (json["file"] as? String).map { folder.appendingPathComponent($0) }
        if let f = file, !fm.fileExists(atPath: f.path) { file = nil }

        let preview = (json["preview"] as? String)
            .map { folder.appendingPathComponent($0) }
            .flatMap { fm.fileExists(atPath: $0.path) ? $0 : nil }

        var kind: Kind
        switch (json["type"] as? String ?? "").lowercased() {
        case "video": kind = .video
        case "web": kind = .web
        case "scene": kind = .scene
        case "image": kind = .image
        default: kind = file.map { Self.kind(forExtension: $0.pathExtension) } ?? .unsupported
        }
        // e.g. WebM videos: AVFoundation cannot play them.
        if kind == .video, let f = file, !videoExtensions.contains(f.pathExtension.lowercased()) {
            kind = .unsupported
        }

        let workshopID: String? = {
            if let id = json["workshopid"] as? String, !id.isEmpty { return id }
            if let id = json["workshopid"] as? Int { return String(id) }
            let name = folder.lastPathComponent
            return name.count >= 6 && name.allSatisfy(\.isNumber) ? name : nil
        }()

        return Wallpaper(folder: folder, title: title, kind: kind, file: file, preview: preview,
                         workshopID: workshopID, webPropertiesJSON: webProperties(from: json))
    }

    static func fromLooseFiles(folder: URL, fileManager fm: FileManager) -> Wallpaper? {
        let items = ((try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [])
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        let title = folder.lastPathComponent
        if let html = items.first(where: { $0.lastPathComponent.lowercased() == "index.html" }) {
            return Wallpaper(folder: folder, title: title, kind: .web, file: html, preview: nil)
        }
        if let video = items.first(where: { videoExtensions.contains($0.pathExtension.lowercased()) }) {
            return Wallpaper(folder: folder, title: title, kind: .video, file: video, preview: nil)
        }
        if let image = items.first(where: { imageExtensions.contains($0.pathExtension.lowercased()) }) {
            return Wallpaper(folder: folder, title: title, kind: .image, file: image, preview: image)
        }
        return nil
    }

    /// Converts `general.properties` to `{ key: { value: … } }`.
    static func webProperties(from json: [String: Any]) -> String {
        guard let general = json["general"] as? [String: Any],
              let properties = general["properties"] as? [String: Any] else { return "{}" }
        var result: [String: Any] = [:]
        for (key, value) in properties {
            if let dict = value as? [String: Any], let v = dict["value"] { result[key] = ["value": v] }
        }
        guard JSONSerialization.isValidJSONObject(result),
              let data = try? JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]),
              let string = String(data: data, encoding: .utf8) else { return "{}" }
        return string
    }

    // MARK: Discovery

    /// Finds wallpaper projects inside a folder the user picked: a single project, Wallpaper Engine's
    /// `workshop/content/431960` folder, or its `projects/myprojects` folder (searched two levels deep).
    public static func discoverProjects(in url: URL, fileManager fm: FileManager = .default) -> [URL] {
        let hasProject = { (u: URL) in fm.fileExists(atPath: u.appendingPathComponent("project.json").path) }
        if hasProject(url) { return [url] }
        var found: [URL] = []
        let level1 = (try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
        for sub in level1 {
            if hasProject(sub) { found.append(sub); continue }
            let level2 = (try? fm.contentsOfDirectory(at: sub, includingPropertiesForKeys: nil)) ?? []
            found += level2.filter(hasProject)
        }
        return found.isEmpty ? [url] : found.sorted { $0.path < $1.path }
    }

    /// A folder name that is safe on every file system.
    public static func safeFolderName(_ name: String) -> String {
        let cleaned = name
            .components(separatedBy: CharacterSet(charactersIn: "/:\\\0"))
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
        return String(cleaned.prefix(120))
    }
}
