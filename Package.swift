// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WorkshopWall",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "WorkshopWall", targets: ["WorkshopWall"]),
    ],
    targets: [
        // Pure, UI-free logic: wallpaper parsing, Workshop link parsing, SteamCMD output parsing.
        .target(name: "WorkshopWallCore"),
        // The macOS app (SwiftUI + AppKit).
        .executableTarget(name: "WorkshopWall", dependencies: ["WorkshopWallCore"]),
        .testTarget(name: "WorkshopWallCoreTests", dependencies: ["WorkshopWallCore"]),
    ]
)
