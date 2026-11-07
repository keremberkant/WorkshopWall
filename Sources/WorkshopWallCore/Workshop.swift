import Foundation

/// Helpers for Steam Workshop links and SteamCMD output. Free of UI and process handling so they can be tested.
public enum Workshop {
    /// Wallpaper Engine's Steam app ID.
    public static let appID = "431960"

    /// Extracts Workshop item IDs from pasted text (links like
    /// `https://steamcommunity.com/sharedfiles/filedetails/?id=123` or bare IDs), keeping order, without duplicates.
    public static func itemIDs(in text: String) -> [String] {
        var ids: [String] = []
        let patterns = [#"[?&]id=(\d{6,12})"#, #"(?<![\d=])(\d{8,12})(?!\d)"#]
        let range = NSRange(text.startIndex..., in: text)
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            for match in regex.matches(in: text, range: range) {
                guard let r = Range(match.range(at: 1), in: text) else { continue }
                let id = String(text[r])
                if !ids.contains(id) { ids.append(id) }
            }
        }
        return ids
    }

    /// Only letters, digits, `_`, `.` and `-` are allowed in a Steam login name we pass to a shell.
    public static func sanitizedUsername(_ name: String) -> String {
        name.filter { $0.isASCII && ($0.isLetter || $0.isNumber || "_.-".contains($0)) }
    }

    public struct DownloadReport: Equatable, Sendable {
        public var downloaded: [(id: String, folder: URL)] = []
        public var failed: [(id: String, reason: String)] = []
        public var needsLogin = false

        public static func == (a: Self, b: Self) -> Bool {
            a.downloaded.map(\.id) == b.downloaded.map(\.id)
                && a.downloaded.map(\.folder) == b.downloaded.map(\.folder)
                && a.failed.map(\.id) == b.failed.map(\.id)
                && a.failed.map(\.reason) == b.failed.map(\.reason)
                && a.needsLogin == b.needsLogin
        }
    }

    /// Parses the console output of `steamcmd +workshop_download_item …`.
    public static func parseDownloadOutput(_ output: String) -> DownloadReport {
        var report = DownloadReport()
        let range = NSRange(output.startIndex..., in: output)

        if let ok = try? NSRegularExpression(pattern: #"Success\. Downloaded item (\d+) to "([^"]+)""#) {
            for m in ok.matches(in: output, range: range) {
                if let r1 = Range(m.range(at: 1), in: output), let r2 = Range(m.range(at: 2), in: output) {
                    report.downloaded.append((String(output[r1]), URL(fileURLWithPath: String(output[r2]))))
                }
            }
        }
        if let bad = try? NSRegularExpression(pattern: #"ERROR! Download item (\d+) failed \(([^)]+)\)"#) {
            for m in bad.matches(in: output, range: range) {
                if let r1 = Range(m.range(at: 1), in: output), let r2 = Range(m.range(at: 2), in: output) {
                    report.failed.append((String(output[r1]), String(output[r2])))
                }
            }
        }
        let lower = output.lowercased()
        let loginMarkers = ["cached credentials not found", "login failure", "invalid password",
                            "password:", "two-factor code", "steam guard code"]
        report.needsLogin = report.downloaded.isEmpty && loginMarkers.contains { lower.contains($0) }
        return report
    }
}
