//
//  FocusEntity.swift
//  FocusEntity
//
//  Created by Max Cobb on 8/26/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

#if canImport(ARKit)
import RealityKit

public struct FocusEntityComponent: Component {
  public enum Style {
    case classic(color: Material.Color)
    case colored(
      onColor: Material.Color, offColor: Material.Color,
      otherColor: Material.Color, mesh: MeshResource
    )

    internal struct Classic {
      var color: Material.Color
    }
    internal struct Colored {
      var onColor: Material.Color
      var offColor: Material.Color
      var otherColor: Material.Color
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
    case .colored(let onColor, let offColor, let otherColor, let mesh):
      return Style.Colored(onColor: onColor, offColor: offColor, otherColor: otherColor, mesh: mesh)
    default:
      return nil
    }
  }
  public static let classic = FocusEntityComponent(style: .classic(color: #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)))
  public static let plane = FocusEntityComponent(style: .colored(onColor: .green, offColor: .red, otherColor: Material.Color.orange.withAlphaComponent(0.2), mesh: FocusEntityComponent.defaultPlane))
  internal var isOpen = true
  internal var segments: [FocusEntity.Segment] = []

  static var defaultPlane: MeshResource {
    let thickness = 0.018
    let correctionFactor = thickness / 2 // correction to align lines perfectly
    let length = Float(1.0 - thickness * 2 + correctionFactor)

    return MeshResource.generatePlane(width: length, depth: length)
  }
  public init(style: Style) {
    self.style = style
  }
}
#endif
