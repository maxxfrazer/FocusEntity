// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "FocusEntity",
  platforms: [.iOS("13.0")],
  products: [
    .library(name: "FocusEntity", targets: ["FocusEntity"])
  ],
  dependencies: [],
  targets: [
    .target(name: "FocusEntity", dependencies: [])
  ],
  swiftLanguageVersions: [.v5]
)
