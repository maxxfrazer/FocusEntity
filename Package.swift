// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "FocusEntity",
  platforms: [.iOS("13.0")],
  products: [
    .library(name: "FocusEntity", targets: ["FocusEntity"])
  ],
  dependencies: [
//  .package(path: "../ARKit-SmartHitTest")
    .package(
      url: "https://github.com/maxxfrazer/ARKit-SmartHitTest",
      .upToNextMajor(from: "2.0.0")
    )
  ],
  targets: [
    .target(name: "FocusEntity", dependencies: ["SmartHitTest"])
  ],
  swiftLanguageVersions: [.v5]
)
