# FocusEntity

This package is based on the package [ARKit-FocusNode](https://github.com/maxxfrazer/ARKit-FocusNode), but adapted to work in Apple's framework RealityKit.


<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS-lightgrey"/>
  <img src="https://img.shields.io/github/v/release/maxxfrazer/FocusEntity?color=orange&label=SwiftPM&logo=swift"/>
  <img src="https://img.shields.io/badge/Swift-5.2-orange?logo=swift"/>
  <img src="https://github.com/maxxfrazer/FocusEntity/workflows/swiftlint/badge.svg"/>
  <img src="https://github.com/maxxfrazer/FocusEntity/workflows/build/badge.svg"/>
  <img src="https://img.shields.io/github/license/maxxfrazer/FocusEntity"/>
</p>

![FocusEntity Example 1](media/FocusEntity-Example1.gif)

[The Example](./Example-RealityKit) looks identical to the above GIF, which uses the FocusEntity classic style.


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

See the [Example](./FocusEntity-Example) for a full working example as can be seen in the GIF above

- After installing, import `FocusEntity` to your .swift file
- Create an instance of FocusEntity:
<br>```let focusSquare = FocusEntity(on: self.arView, style: .classic)```
<br><br>(Optional)<br>
- Set `focusSquare.delegate` to an object which conforms to `FocusEntityDelegate` if you wish to get callbacks for when the FocusEntity changes state.
- Optionally, you may select to use one of 3 visual styles: classic, color, and material.
- If you choose material, you may use the preset textures or provide your own customized textures.
- If you want to provide your own textures, add them to the Assets.xcassets catalog, then type the name of the asset in the appropriate place in this code:
<br>```let onColor: MaterialColorParameter = try .texture(.load(named: "<#customAsset1#>"))```
<br>```let offColor: MaterialColorParameter = try .texture(.load(named: "<#customAsset2#>"))```


If something's not making sense in the Example, [send me a tweet](https://twitter.com/maxxfrazer) or Fork & open a Pull Request on this repository to make something more clear.

I'm hoping to make the animations look a little smoother over time, but any and all contributions are welcome and encouraged.

---

The original code to create this repository has been adapted from one of Apple's examples from 2018, [license also included](LICENSE.origin). I have merely adapted the code to be used and distributed from within a Swift Package, and now further adapted to work with [RealityKit](https://developer.apple.com/documentation/realitykit).
