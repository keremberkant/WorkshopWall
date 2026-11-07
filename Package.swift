// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CanliDuvar",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "CanliDuvar", targets: ["CanliDuvar"]),
    ],
    targets: [
        // Pure, UI-free logic: wallpaper parsing, Workshop link parsing, SteamCMD output parsing.
        .target(name: "CanliDuvarCore"),
        // The macOS app (SwiftUI + AppKit).
        .executableTarget(name: "CanliDuvar", dependencies: ["CanliDuvarCore"]),
        .testTarget(name: "CanliDuvarCoreTests", dependencies: ["CanliDuvarCore"]),
    ]
)
