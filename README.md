# FocusEntity

This package is based on the package [ARKit-FocusNode](https://github.com/maxxfrazer/ARKit-FocusNode), but adapted to work in Apple's Augmented Reality framework, RealityKit.

[![Lint Status](https://github.com/maxxfrazer/FocusEntity/workflows/swiftlint/badge.svg)](https://github.com/maxxfrazer/FocusEntity/actions)
[![Build Status](https://github.com/maxxfrazer/FocusEntity/workflows/build/badge.svg)](https://github.com/maxxfrazer/FocusEntity/actions)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-v0.1-orange.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat)](https://swift.org/)

![FocusEntity Example 1](media/FocusEntity-Example1.gif)

[The Example](./Example-RealityKit) looks identical to the above GIF, which uses the FESquare class (Focus Entity Square).


## ⚠️ iOS 13.2 bug ⚠️

There is a crashing bug when using this library with iOS 13.2 and importing via Swift Package Manager

The Swift bug has been reported here:
https://bugs.swift.org/browse/SR-11564

And there is a temporary solution, which involves setting the "Dead Code Stripping" property in your build's target to "No"

Target > Build Settings > Linking > Dead Code Stripping

## Minimum Requirements
  - Swift 5.0
  - iOS 13.0 (RealityKit)
  - Xcode 11

If you're unfamiliar with using RealityKit, I would also recommend reading my articles on [Getting Started with RealityKit](https://medium.com/@maxxfrazer/getting-started-with-realitykit-3b401d6f6f).

## Installation

### Swift Package Manager

Add the URL of this repository to your Xcode 11+ Project.

`https://github.com/maxxfrazer/FocusEntity.git`

---
## Usage

See the [Example](./FocusEntity-Example) for a full working example as can be seen in the GIF above

- After installing, import `FocusEntity` to your .swift file
- Create an instance of `let focusSquare = FESquare()`, or another `FocusEntity` class.
- Set `focusSquare.viewDelegate` to the `ARView` it is to be rendered within.
- Set the FocusEntity to auto-update: `focusSquare.setAutoUpdate(to: true)`


If something's not making sense in the Example, [send me a tweet](https://twitter.com/maxxfrazer) or Fork & open a Pull Request on this repository to make something more clear.

I'm hoping to make the animations look a little smoother over time, but any and all contributions are welcome and encouraged.

Please follow the guide for creating GitHub Issues, otherwise I may simply close them.

---

The original code to create this repository has been adapted from one of Apple's examples from 2018, [license also included](LICENSE.origin). I have merely adapted the code to be used and distributed from within a Swift Package, and now further adapted to work with [RealityKit](https://developer.apple.com/documentation/realitykit).
