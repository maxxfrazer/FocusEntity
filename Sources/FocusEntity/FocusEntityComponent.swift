//
//  FocusEntity.swift
//  FocusEntity
//
//  Created by Max Cobb on 8/26/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

#if canImport(ARKit)
import RealityKit
import UIKit

public struct FocusEntityComponent: Component {
  public enum Style {
    case classic(color: Material.Color)
    case colored(
      onColor: MaterialColorParameter, offColor: MaterialColorParameter,
      nonTrackingColor: MaterialColorParameter,
      mesh: MeshResource = MeshResource.generatePlane(width: 0.1, depth: 0.1)
    )

    internal struct Classic {
      var color: Material.Color
    }

    /// When using colored style, first material of a mesh will be replaced with the chosen color
    internal struct Colored {
      /// Color when tracking the surface of a known plane
      var onColor: MaterialColorParameter
      /// Color when tracking an estimated plane
      var offColor: MaterialColorParameter
      /// Color when no surface tracking is achieved
      var nonTrackingColor: MaterialColorParameter
      var mesh: MeshResource
    }
  }
    
    
  let style: Style
  var classicStyle: Style.Classic? {
    switch self.style {
    case .classic(let color):
      return Style.Classic(color: color)
    default:
      return nil
    }
  }

  var coloredStyle: Style.Colored? {
    switch self.style {
    case .colored(let onColor, let offColor, let nonTrackingColor, let mesh):
      return Style.Colored(onColor: onColor, offColor: offColor, nonTrackingColor: nonTrackingColor, mesh: mesh)
    default:
      return nil
    }
  }

    ///Convenient presets
  public static let classic = FocusEntityComponent(style: .classic(color: #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)))
  public static let plane = FocusEntityComponent(
    style: .colored(
        onColor: MaterialColorParameter.color(.green),
      offColor: MaterialColorParameter.color(.orange),
        nonTrackingColor: MaterialColorParameter.color(UIColor.red.withAlphaComponent(0.2)),
        mesh: MeshResource.generatePlane(width: 0.1, depth: 0.1)
    )
  )
  internal var isOpen = true
  internal var segments: [FocusEntity.Segment] = []

//  static var defaultPlane: MeshResource {
//    let thickness = 0.018
//    let correctionFactor = thickness / 2 // correction to align lines perfectly
//    let length = Float(1.0 - thickness * 2 + correctionFactor)
//
//    return MeshResource.generatePlane(width: length, depth: length)
//  }
    
  public init(style: Style) {
    self.style = style
  }
}
#endif
