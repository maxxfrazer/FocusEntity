//
//  FocusEntity+Colored.swift
//  FocusEntity
//
//  Created by Max Cobb on 8/26/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

#if canImport(ARKit)
import RealityKit

/// An extension of FocusEntity holding the methods for the "colored" style.
public extension FocusEntity {

  internal func coloredStateChanged() {
    guard let coloredStyle = self.focus.coloredStyle else {
      return
    }
    var endColor: MaterialColorParameter
    if self.state == .initializing {
      endColor = coloredStyle.nonTrackingColor
    } else {
      endColor = self.onPlane ? coloredStyle.onColor : coloredStyle.offColor
    }
    if self.fillPlane?.model?.materials.count == 0 {
        self.fillPlane?.model?.materials = [SimpleMaterial()]
    }
    // Necessary for transparency.
    var modelMaterial = UnlitMaterial(color: .clear)
    if #available(iOS 15.0, *) {
      switch endColor {
      case .color(let color):
        modelMaterial.color = .init(tint: color, texture: nil)
      case .texture(let tex):
        modelMaterial.color = .init(tint: .white, texture: .init(tex))
      @unknown default:
        #if DEBUG
          print("FOCUSENTITY: Could not work with color parameter")
        #endif
      }
      modelMaterial.blending = .transparent(opacity: 1.0)
    } else {
      // Necessary for transparency.
      modelMaterial.baseColor = endColor
      modelMaterial.tintColor = Material.Color.white.withAlphaComponent(0.995)
    }
    self.fillPlane?.model?.materials[0] = modelMaterial
  }
}
#endif
