import CoreGraphics
import XCTest
@testable import WorkshopWallCore

final class WallpaperTests: XCTestCase {
    private var tmp: URL!

    override func setUpWithError() throws {
        tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmp)
    }

    private func makeProject(_ name: String, json: String, files: [String] = []) throws -> URL {
        let dir = tmp.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try json.write(to: dir.appendingPathComponent("project.json"), atomically: true, encoding: .utf8)
        for f in files { try Data().write(to: dir.appendingPathComponent(f)) }
        return dir
    }

    func testVideoProject() throws {
        let dir = try makeProject("123456789", json: #"{"title":"Neon","type":"video","file":"clip.mp4","preview":"preview.jpg"}"#,
                                  files: ["clip.mp4", "preview.jpg"])
        let wp = try XCTUnwrap(Wallpaper.load(folder: dir))
        XCTAssertEqual(wp.title, "Neon")
        XCTAssertEqual(wp.kind, .video)
        XCTAssertTrue(wp.isPlayable)
        XCTAssertEqual(wp.preview?.lastPathComponent, "preview.jpg")
        XCTAssertEqual(wp.workshopID, "123456789")
    }

    func testTypeIsCaseInsensitive() throws {
        let dir = try makeProject("w", json: #"{"title":"VU","type":"Web","file":"index.html"}"#, files: ["index.html"])
        XCTAssertEqual(Wallpaper.load(folder: dir)?.kind, .web)
    }

    func testSceneIsNotPlayable() throws {
        let dir = try makeProject("s", json: #"{"title":"XDR","type":"scene","file":"scene.json"}"#, files: ["scene.pkg"])
        let wp = try XCTUnwrap(Wallpaper.load(folder: dir))
        XCTAssertEqual(wp.kind, .scene)
        XCTAssertFalse(wp.isPlayable)
    }

    func testWebmVideoIsUnsupported() throws {
        let dir = try makeProject("v", json: #"{"title":"W","type":"video","file":"a.webm"}"#, files: ["a.webm"])
        XCTAssertEqual(Wallpaper.load(folder: dir)?.kind, .unsupported)
    }

    func testMissingFileIsNotPlayable() throws {
        let dir = try makeProject("m", json: #"{"title":"Gone","type":"video","file":"gone.mp4"}"#)
        let wp = try XCTUnwrap(Wallpaper.load(folder: dir))
        XCTAssertNil(wp.file)
        XCTAssertFalse(wp.isPlayable)
    }

    func testWebProperties() throws {
        let json = #"{"title":"P","type":"web","file":"index.html","general":{"properties":{"speed":{"type":"slider","value":3}}}}"#
        let dir = try makeProject("p", json: json, files: ["index.html"])
        XCTAssertEqual(Wallpaper.load(folder: dir)?.webPropertiesJSON, #"{"speed":{"value":3}}"#)
    }

    func testLooseVideoFolder() throws {
        let dir = tmp.appendingPathComponent("Loose")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data().write(to: dir.appendingPathComponent("movie.MOV"))
        let wp = try XCTUnwrap(Wallpaper.load(folder: dir))
        XCTAssertEqual(wp.kind, .video)
        XCTAssertEqual(wp.title, "Loose")
    }

    func testDiscoverWorkshopFolder() throws {
        let ws = tmp.appendingPathComponent("431960")
        for id in ["111111", "222222"] {
            let d = ws.appendingPathComponent(id)
            try FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
            try "{}".write(to: d.appendingPathComponent("project.json"), atomically: true, encoding: .utf8)
        }
        XCTAssertEqual(Wallpaper.discoverProjects(in: ws).map(\.lastPathComponent), ["111111", "222222"])
    }

    func testSafeFolderName() {
        XCTAssertEqual(Wallpaper.safeFolderName("a/b:c"), "a-b-c")
        XCTAssertEqual(Wallpaper.safeFolderName("..hidden"), "hidden")
    }
}

final class WorkshopTests: XCTestCase {
    func testItemIDs() {
        let text = """
        https://steamcommunity.com/sharedfiles/filedetails/?id=1980701630&searchtext=xdr
        2843921567
        https://steamcommunity.com/sharedfiles/filedetails/?id=1980701630
        """
        XCTAssertEqual(Workshop.itemIDs(in: text), ["1980701630", "2843921567"])
        XCTAssertEqual(Workshop.itemIDs(in: "no ids here 12345"), [])
    }

    func testSanitizedUsername() {
        XCTAssertEqual(Workshop.sanitizedUsername("kerem.b_1; rm -rf /"), "kerem.b_1rm-rf")
    }

    func testParseSuccessAndFailure() {
        let out = """
        Downloading item 111 ...
        Success. Downloaded item 111 to "/tmp/steamapps/workshop/content/431960/111" (1024 bytes)
        Downloading item 222 ...
        ERROR! Download item 222 failed (Failure).
        """
        let r = Workshop.parseDownloadOutput(out)
        XCTAssertEqual(r.downloaded.map(\.id), ["111"])
        XCTAssertEqual(r.downloaded.first?.folder.lastPathComponent, "111")
        XCTAssertEqual(r.failed.map(\.id), ["222"])
        XCTAssertEqual(r.failed.first?.reason, "Failure")
        XCTAssertFalse(r.needsLogin)
    }

    func testParseNeedsLogin() {
        XCTAssertTrue(Workshop.parseDownloadOutput("Logging in user 'x' to Steam Public...\nCached credentials not found.").needsLogin)
    }
}

final class CoverageTests: XCTestCase {
    let screen = CGRect(x: 0, y: 0, width: 1470, height: 956)

    func testFullScreenWindowCovers() {
        XCTAssertTrue(Coverage.isCovered(screen: screen, by: [screen]))
    }

    func testMaximizedWindowCovers() {
        XCTAssertTrue(Coverage.isCovered(screen: screen, by: [CGRect(x: 0, y: 33, width: 1470, height: 860)]))
    }

    func testSmallWindowDoesNotCover() {
        XCTAssertFalse(Coverage.isCovered(screen: screen, by: [CGRect(x: 100, y: 100, width: 800, height: 600)]))
    }

    func testWindowOnOtherDisplayDoesNotCover() {
        XCTAssertFalse(Coverage.isCovered(screen: screen, by: [CGRect(x: 1470, y: 0, width: 1920, height: 1080)]))
    }

    func testTwoHalvesCover() {
        let left = CGRect(x: 0, y: 0, width: 735, height: 956)
        let right = CGRect(x: 735, y: 0, width: 735, height: 956)
        XCTAssertTrue(Coverage.isCovered(screen: screen, by: [left, right]))
    }
}
