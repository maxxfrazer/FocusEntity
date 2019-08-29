//
//  FEPlane.swift
//  
//
//  Created by Max Cobb on 8/26/19.
//

import ARKit
import RealityKit
import QuartzCore

/// A simple example subclass of FocusNode which shows whether the plane is
/// tracking on a known surface or estimating.
public class FEPlane: FocusEntity {

  /// Original size of the focus square in meters.
  let size: Float

  /// Color of the focus square fill when estimating position.
  static let offColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 0.5)
  /// Color of the focus square fill when at known position.
  static let onColor = #colorLiteral(red: 0, green: 1, blue: 0, alpha: 0.5)

  /// Set up the focus square with just the size as a parameter
  ///
  /// - Parameter size: Size in m of the square. Default is 0.17
  public required init(size: Float = 0.17) {
    self.size = size
    super.init()
//    opacity = 0.0
    self.positioningNode.addChild(fillPlane)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  public required init() {
    self.size = 0.17
    super.init()
    self.positioningNode.addChild(fillPlane)
  }

  // MARK: Animations

  /// Called when either `onPlane`, `state` or both have changed.
  ///
  /// - Parameter newPlane: If the cube is tracking a new surface for the first time
  override public func stateChanged(newPlane: Bool) {
    if self.onPlane {
//      positioningNode.removeAction(forKey: "pulse")
      self.fillPlane.model?.materials[0] = SimpleMaterial(
        color: FEPlane.onColor, isMetallic: false
      )
    } else {
      // Open animation
      self.fillPlane.model?.materials[0] = SimpleMaterial(
        color: FEPlane.offColor, isMetallic: false
      )
    }
    isAnimating = false
  }

  // MARK: Convenience Methods

  private lazy var fillPlane: ModelEntity = {
    let thickness = 0.018
    let correctionFactor = thickness / 2 // correction to align lines perfectly
    let length = Float(1.0 - thickness * 2 + correctionFactor)

    let node = ModelEntity(
      mesh: MeshResource.generatePlane(width: length, depth: length),
      materials: [
        SimpleMaterial(color: FEPlane.offColor, isMetallic: false)
      ]
    )
    node.scale = SIMD3<Float>(repeating: self.size)
    node.name = "fillPlane"
//    node.opacity = 0.5

//    let material = plane.firstMaterial!
//    material.diffuse.contents = FocusEntityPlane.offColor
//    material.isDoubleSided = true
//    material.ambient.contents = UIColor.black
//    material.lightingModel = .constant
//    material.emission.contents = FocusEntityPlane.offColor

    return node
  }()
}
