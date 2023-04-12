// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FocusEntity",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(name: "FocusEntity", targets: ["FocusEntity"])
    ],
    dependencies: [],
    targets: [
        .target(name: "FocusEntity", dependencies: [])
    ],
    swiftLanguageVersions: [.v5]
)
