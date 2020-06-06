//
//  FEPlane.swift
//  
//
//  Created by Max Cobb on 8/26/19.
//

import ARKit
import RealityKit
import QuartzCore

/// A simple example subclass of FocusEntity which shows whether the plane is
/// tracking on a known surface or estimating.
public extension FocusEntity {

  internal func coloredStateChanged() {
    guard let coloredStyle = self.focusEntity.coloredStyle else {
      return
    }
    var endColor: Material.Color = .clear
    if self.state == .initializing {
      endColor = coloredStyle.otherColor
    } else {
      endColor = self.onPlane ? coloredStyle.onColor : coloredStyle.offColor
    }
    self.fillPlane?.model?.materials[0] = SimpleMaterial(
      color: endColor, isMetallic: false
    )
  }
}
