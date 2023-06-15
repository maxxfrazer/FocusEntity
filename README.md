# FocusEntity

This package is based on [ARKit-FocusNode](https://github.com/maxxfrazer/ARKit-FocusNode), but adapted to work in Apple's framework RealityKit.

<p align="center">
  <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmaxxfrazer%2FFocusEntity%2Fbadge%3Ftype%3Dswift-versions"/>
  <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmaxxfrazer%2FFocusEntity%2Fbadge%3Ftype%3Dplatforms"/></br>
  <img src="https://github.com/maxxfrazer/FocusEntity/workflows/swiftlint/badge.svg"/>
  <img src="https://github.com/maxxfrazer/FocusEntity/workflows/build/badge.svg"/>
  <img src="https://img.shields.io/github/license/maxxfrazer/FocusEntity"/>
</p>

<p align="center">
  <img src="media/focusentity-dali.gif"/>
</p>

[The Example](./FocusEntity-Example) looks identical to the above GIF, which uses the FocusEntity classic style.

See the [documentation](https://maxxfrazer.github.io/FocusEntity/documentation/focusentity/) for more.

## Minimum Requirements
  - Swift 5.2
  - iOS 13.0 (RealityKit)
  - Xcode 11

If you're unfamiliar with using RealityKit, I would also recommend reading my articles on [Getting Started with RealityKit](https://medium.com/@maxxfrazer/getting-started-with-realitykit-3b401d6f6f).

## Installation

### Swift Package Manager

Add the URL of this repository to your Xcode 11+ Project.

Go to File > Swift Packages > Add Package Dependency, and paste in this link:
`https://github.com/maxxfrazer/FocusEntity`

---
## Usage

See the [Example project](./FocusEntity-Example) for a full working example as can be seen in the GIF above

1. Install `FocusEntity` with Swift Package Manager

```
https://github.com/maxxfrazer/FocusEntity.git
```

2. Create an instance of FocusEntity, referencing your ARView:

```swift
let focusSquare = FocusEntity(on: self.arView, focus: .classic)
```

And that's it! The FocusEntity should already be tracking around your AR scene. There are options to turn the entity off or change its properties.
Check out [the documentation](https://maxxfrazer.github.io/FocusEntity/documentation/focusentity/) or [example project](FocusEntity-Example) to learn more.

---

Feel free to [send me a tweet](https://twitter.com/maxxfrazer) if you have any problems using FocusEntity, or open an Issue or PR!


> The original code to create this repository has been adapted from one of Apple's examples from 2018, [license also included](LICENSE.origin). I have adapted the code to be used and distributed from within a Swift Package, and now further adapted to work with [RealityKit](https://developer.apple.com/documentation/realitykit).
