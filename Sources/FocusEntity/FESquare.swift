//
//  FESquare.swift
//
//
//  Created by Max Cobb on 8/28/19.
//

import ARKit
import RealityKit

/// This example class is taken almost entirely from Apple's own examples.
/// I have simply moved some things around to keep only what's necessary
///
/// An `Entity` which is used to provide uses with visual cues about the status of ARKit world tracking.
/// - Tag: FocusSquare
public class FESquare: FocusEntity {

  // MARK: - Types
  public enum State: Equatable {
      case initializing
      case tracking(raycastResult: ARRaycastResult, camera: ARCamera?)
  }

  // MARK: - Configuration Properties

  /// Original size of the focus square in meters.
  static let size: Float = 0.17

  /// Thickness of the focus square lines in meters.
  static let thickness: Float = 0.018

  /// Scale factor for the focus square when it is closed, w.r.t. the original size.
  static let scaleForClosedSquare: Float = 0.97

  /// Side length of the focus square segments when it is open (w.r.t. to a 1x1 square).
  static let sideLengthForOpenSegments: CGFloat = 0.2

  /// Duration of the open/close animation
  static let animationDuration = 0.7

  static var primaryColor = #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)

  /// Color of the focus square fill.
  static var fillColor = #colorLiteral(red: 1, green: 0.9254901961, blue: 0.4117647059, alpha: 1)

  /// Indicates whether the segments of the focus square are disconnected.
  private var isOpen = true

  /// List of the segments in the focus square.
  private var segments: [FESquare.Segment] = []

  // MARK: - Initialization

  public required init() {
    super.init()
//    opacity = 0.0

    /*
    The focus square consists of eight segments as follows, which can be individually animated.

        s1  s2
        _   _
    s3 |     | s4

    s5 |     | s6
        -   -
        s7  s8
    */
    let s1 = Segment(name: "s1", corner: .topLeft, alignment: .horizontal)
    let s2 = Segment(name: "s2", corner: .topRight, alignment: .horizontal)
    let s3 = Segment(name: "s3", corner: .topLeft, alignment: .vertical)
    let s4 = Segment(name: "s4", corner: .topRight, alignment: .vertical)
    let s5 = Segment(name: "s5", corner: .bottomLeft, alignment: .vertical)
    let s6 = Segment(name: "s6", corner: .bottomRight, alignment: .vertical)
    let s7 = Segment(name: "s7", corner: .bottomLeft, alignment: .horizontal)
    let s8 = Segment(name: "s8", corner: .bottomRight, alignment: .horizontal)
    segments = [s1, s2, s3, s4, s5, s6, s7, s8]

    let sl: Float = 0.5  // segment length
    let c: Float = FESquare.thickness / 2 // correction to align lines perfectly
    s1.position += [-(sl / 2 - c), 0, -(sl - c)]
    s2.position += [sl / 2 - c, 0, -(sl - c)]
    s3.position += [-sl, 0, -sl / 2]
    s4.position += [sl, 0, -sl / 2]
    s5.position += [-sl, 0, sl / 2]
    s6.position += [sl, 0, sl / 2]
    s7.position += [-(sl / 2 - c), 0, sl - c]
    s8.position += [sl / 2 - c, 0, sl - c]

    for segment in segments {
      self.positioningEntity.addChild(segment)
      segment.open()
    }
    self.positioningEntity.addChild(fillPlane)
    self.positioningEntity.scale = SIMD3<Float>(repeating: FESquare.size * FESquare.scaleForClosedSquare)

    // Always render focus square on top of other content.
//    self.displayNodeHierarchyOnTop(true)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  // MARK: Animations

  override public func stateChanged(newPlane: Bool) {
    super.stateChanged()
    if self.onPlane {
      self.onPlaneAnimation(newPlane: newPlane)
    } else {
      self.offPlaneAniation()
    }
  }

  public func offPlaneAniation() {
    // Open animation
    guard !isOpen else {
      return
    }
//    self.isAnimating = true
    isOpen = true

    for segment in segments {
      segment.open()
    }
//    self.isAnimating = false
    positioningEntity.scale = SIMD3<Float>(repeating: FESquare.size)
  }

  public func onPlaneAnimation(newPlane: Bool = false) {
    guard isOpen else {
      return
    }
//    self.isAnimating = true
    self.isOpen = false

    // Close animation
    for segment in self.segments {
      segment.close()
    }
//    self.isAnimating = false

    if newPlane {
//      let waitAction = SCNAction.wait(duration: FocusSquare.animationDuration * 0.75)
//      let fadeInAction = SCNAction.fadeOpacity(to: 0.25, duration: FocusSquare.animationDuration * 0.125)
//      let fadeOutAction = SCNAction.fadeOpacity(to: 0.0, duration: FocusEntitySquare.animationDuration * 0.125)
//      fillPlane.runAction(SCNAction.sequence([waitAction, fadeInAction, fadeOutAction]))
//
//      let flashSquareAction = flashAnimation(duration: FocusEntitySquare.animationDuration * 0.25)
//      for segment in segments {
//        segment.runAction(.sequence([waitAction, flashSquareAction]))
//      }
    }
  }

  // MARK: Convenience Methods

  private func scaleAnimation(for keyPath: String) -> CAKeyframeAnimation {
    let scaleAnimation = CAKeyframeAnimation(keyPath: keyPath)

    let easeOut = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
    let easeInOut = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
    let linear = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)

    let size = FESquare.size
    let ts = FESquare.size * FESquare.scaleForClosedSquare
    let values = [size, size * 1.15, size * 1.15, ts * 0.97, ts]
    let keyTimes: [NSNumber] = [0.00, 0.25, 0.50, 0.75, 1.00]
    let timingFunctions = [easeOut, linear, easeOut, easeInOut]

    scaleAnimation.values = values
    scaleAnimation.keyTimes = keyTimes
    scaleAnimation.timingFunctions = timingFunctions
    scaleAnimation.duration = FESquare.animationDuration

    return scaleAnimation
  }

  private lazy var fillPlane: ModelEntity = {
    let correctionFactor = FESquare.thickness / 2 // correction to align lines perfectly
    let length = CGFloat(1.0 - FESquare.thickness * 2 + correctionFactor)

//    let plane = SCNPlane(width: length, height: length)
    let fillEntity = ModelEntity(
      mesh: MeshResource.generatePlane(width: Float(length), depth: Float(length)),
      materials: [UnlitMaterial(color: FESquare.fillColor.withAlphaComponent(0.0))]
    )
    fillEntity.name = "fillPlane"

//    let material = plane.firstMaterial!
//    material.diffuse.contents = FocusEntitySquare.fillColor
//    material.isDoubleSided = true
//    material.ambient.contents = UIColor.black
//    material.lightingModel = .constant
//    material.emission.contents = FocusEntitySquare.fillColor

    return fillEntity
  }()
}

// MARK: - Animations and Actions

private func pulseAction() -> SCNAction {
  let pulseOutAction = SCNAction.fadeOpacity(to: 0.4, duration: 0.5)
  let pulseInAction = SCNAction.fadeOpacity(to: 1.0, duration: 0.5)
  pulseOutAction.timingMode = .easeInEaseOut
  pulseInAction.timingMode = .easeInEaseOut

  return SCNAction.repeatForever(SCNAction.sequence([pulseOutAction, pulseInAction]))
}

private func flashAnimation(duration: TimeInterval) -> SCNAction {
  let action = SCNAction.customAction(duration: duration) { (node, elapsedTime) -> Void in
    // animate color from HSB 48/100/100 to 48/30/100 and back
    let elapsedTimePercentage = elapsedTime / CGFloat(duration)
    let saturation = 2.8 * (elapsedTimePercentage - 0.5) * (elapsedTimePercentage - 0.5) + 0.3
    if let material = node.geometry?.firstMaterial {
      material.diffuse.contents = UIColor(
        hue: 0.1333, saturation: saturation, brightness: 1.0, alpha: 1.0
      )
    }
  }
  return action
}
