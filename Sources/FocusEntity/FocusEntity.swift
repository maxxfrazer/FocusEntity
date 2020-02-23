//
//  FocusEntity.swift
//
//
//  Created by Max Cobb on 8/26/19.
//

import RealityKit
import ARKit
import SmartHitTest

private extension UIView {
  /// Center of the view
  var screenCenter: CGPoint {
    let bounds = self.bounds
    return CGPoint(x: bounds.midX, y: bounds.midY)
  }
}

@objc public protocol FEDelegate: AnyObject {
  @objc optional func toTrackingState()
  @objc optional func toInitializingState()
}

extension ARView: ARSmartHitTest {}

/**
An `Entity` which is used to provide uses with visual cues about the status of ARKit world tracking.
- Tag: FocusSquare
*/
open class FocusEntity: Entity {

  weak public var viewDelegate: ARSmartHitTest? {
    didSet {
      guard let view = self.viewDelegate as? (ARView & ARSmartHitTest) else {
        print("FocusEntity viewDelegate must conform to ARSmartHitTest for now")
        return
      }
      view.scene.addAnchor(povEntity)
      view.scene.addAnchor(rootEntity)
    }
  }

  public var delegate: FEDelegate?

  private var povEntity = AnchorEntity()
  private var rootEntity = AnchorEntity()

  // MARK: - Types
  public enum State: Equatable {
    case initializing
    case tracking(hitTestResult: ARHitTestResult, camera: ARCamera?)
  }

  var screenCenter: CGPoint?

  // MARK: - Properties

  /// The most recent position of the focus square based on the current state.
  var lastPosition: SIMD3<Float>? {
    switch state {
    case .initializing: return nil
    case .tracking(let hitTestResult, _): return hitTestResult.worldTransform.translation
    }
  }

  fileprivate func entityOffPlane(_ hitTestResult: ARHitTestResult, _ camera: ARCamera?) {
    self.onPlane = false
    displayOffPlane(for: hitTestResult, camera: camera)
  }

  public var state: State = .initializing {
    didSet {
      guard state != oldValue else { return }

      switch state {
      case .initializing:
        if oldValue != .initializing {
          self.delegate?.toInitializingState?()
          displayAsBillboard()
        }
      case let .tracking(hitTestResult, camera):
        let stateChanged = oldValue == .initializing
        if stateChanged {
          self.delegate?.toTrackingState?()
          self.rootEntity.addChild(self)
        }
        if let planeAnchor = hitTestResult.anchor as? ARPlaneAnchor {
          entityOnPlane(for: hitTestResult, planeAnchor: planeAnchor, camera: camera)
          currentPlaneAnchor = planeAnchor
        } else {
          entityOffPlane(hitTestResult, camera)
          currentPlaneAnchor = nil
        }
      }
    }
  }

  public var onPlane: Bool = false

  /// Indicates if the square is currently being animated.
  public var isAnimating = false

  /// Indicates if the square is currently changing its alignment.
  private var isChangingAlignment = false

  /// The focus square's current alignment.
  private var currentAlignment: ARPlaneAnchor.Alignment?

  /// The current plane anchor if the focus square is on a plane.
  private(set) var currentPlaneAnchor: ARPlaneAnchor?

  /// The focus square's most recent positions.
  private var recentFocusEntityPositions: [SIMD3<Float>] = []

  /// The focus square's most recent alignments.
  private(set) var recentFocusEntityAlignments: [ARPlaneAnchor.Alignment] = []

  /// Previously visited plane anchors.
  private var anchorsOfVisitedPlanes: Set<ARAnchor> = []

  /// The primary node that controls the position of other `FocusEntity` nodes.
  public let positioningEntity = Entity()

  public var scaleEntityBasedOnDistance = true {
    didSet {
      if self.scaleEntityBasedOnDistance == false {
        self.scale = .one
      }
    }
  }

  // MARK: - Initialization

  public required init() {
    super.init()
    self.name = "FocusEntity"
    self.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])

    // Always render focus square on top of other content.
//    self.displayNodeHierarchyOnTop(true)

    self.addChild(self.positioningEntity)

    // Start the focus square as a billboard.
    self.displayAsBillboard()
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  // MARK: - Appearance

  /// Hides the focus square.
  func hide() {
//    guard action(forKey: "hide") == nil else { return }

//    displayNodeHierarchyOnTop(false)
//    runAction(.fadeOut(duration: 0.5), forKey: "hide")
  }

  /// Unhides the focus square.
  func unhide() {
//    guard action(forKey: "unhide") == nil else { return }

//    displayNodeHierarchyOnTop(true)
//    runAction(.fadeIn(duration: 0.5), forKey: "unhide")
  }

  /// Displays the focus square parallel to the camera plane.
  private func displayAsBillboard() {
    self.povEntity.addChild(self)
    self.onPlane = false
    self.transform = .identity
    self.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
    position = [0, 0, -0.8]

    unhide()
    stateChangedSetup()
  }

  /// Called when a surface has been detected.
  private func displayOffPlane(for hitTestResult: ARHitTestResult, camera: ARCamera?) {
    self.stateChangedSetup()
    let position = hitTestResult.worldTransform.translation
    recentFocusEntityPositions.append(position)
    updateTransform(for: position, hitTestResult: hitTestResult, camera: camera)
  }

  /// Called when a plane has been detected.
  private func entityOnPlane(for hitTestResult: ARHitTestResult, planeAnchor: ARPlaneAnchor, camera: ARCamera?) {
    self.onPlane = true
    self.stateChangedSetup(newPlane: !anchorsOfVisitedPlanes.contains(planeAnchor))
    anchorsOfVisitedPlanes.insert(planeAnchor)
    let position = hitTestResult.worldTransform.translation
    recentFocusEntityPositions.append(position)
    updateTransform(for: position, hitTestResult: hitTestResult, camera: camera)
  }

  // MARK: Helper Methods

  /// Update the transform of the focus square to be aligned with the camera.
  private func updateTransform(for position: SIMD3<Float>, hitTestResult: ARHitTestResult, camera: ARCamera?) {
    // Average using several most recent positions.
    recentFocusEntityPositions = Array(recentFocusEntityPositions.suffix(10))

    // Move to average of recent positions to avoid jitter.
    let average = recentFocusEntityPositions.reduce(
      SIMD3<Float>(repeating: 0), { $0 + $1 }
    ) / Float(recentFocusEntityPositions.count)
    self.position = average
    if self.scaleEntityBasedOnDistance {
      self.scale = SIMD3<Float>(repeating: scaleBasedOnDistance(camera: camera))
    }

    // Correct y rotation of camera square.
    guard let camera = camera else { return }
    let tilt = abs(camera.eulerAngles.x)
    let threshold1: Float = .pi / 2 * 0.65
    let threshold2: Float = .pi / 2 * 0.75
    let yaw = atan2f(camera.transform.columns.0.x, camera.transform.columns.1.x)
    var angle: Float = 0

    switch tilt {
    case 0..<threshold1:
      angle = camera.eulerAngles.y

    case threshold1..<threshold2:
      let relativeInRange = abs((tilt - threshold1) / (threshold2 - threshold1))
      let normalizedY = normalize(camera.eulerAngles.y, forMinimalRotationTo: yaw)
      angle = normalizedY * (1 - relativeInRange) + yaw * relativeInRange

    default:
      angle = yaw
    }

    if state != .initializing {
      updateAlignment(for: hitTestResult, yRotationAngle: angle)
    }
  }

  private func updateAlignment(for hitTestResult: ARHitTestResult, yRotationAngle angle: Float) {
    // Abort if an animation is currently in progress.
    if isChangingAlignment {
      return
    }

    var shouldAnimateAlignmentChange = false
    let tempNode = SCNNode()
    tempNode.simdRotation = SIMD4<Float>(0, 1, 0, angle)

    // Determine current alignment
    var alignment: ARPlaneAnchor.Alignment?
    if let planeAnchor = hitTestResult.anchor as? ARPlaneAnchor {
      alignment = planeAnchor.alignment
    } else if hitTestResult.type == .estimatedHorizontalPlane {
      alignment = .horizontal
    } else if hitTestResult.type == .estimatedVerticalPlane {
      alignment = .vertical
    }

    // add to list of recent alignments
    if alignment != nil {
      self.recentFocusEntityAlignments.append(alignment!)
    }

    // Average using several most recent alignments.
    self.recentFocusEntityAlignments = Array(self.recentFocusEntityAlignments.suffix(20))

    let horizontalHistory = recentFocusEntityAlignments.filter({ $0 == .horizontal }).count
    let verticalHistory = recentFocusEntityAlignments.filter({ $0 == .vertical }).count

    // Alignment is same as most of the history - change it
    if alignment == .horizontal && horizontalHistory > 15 ||
      alignment == .vertical && verticalHistory > 10 ||
      hitTestResult.anchor is ARPlaneAnchor {
      if alignment != self.currentAlignment {
        shouldAnimateAlignmentChange = true
        self.currentAlignment = alignment
        self.recentFocusEntityAlignments.removeAll()
      }
    } else {
      // Alignment is different than most of the history - ignore it
      alignment = self.currentAlignment
      return
    }

    if alignment == .vertical {
      tempNode.simdOrientation = hitTestResult.worldTransform.orientation
      shouldAnimateAlignmentChange = true
    }

    // Change the focus square's alignment
    if shouldAnimateAlignmentChange {
      performAlignmentAnimation(to: tempNode.simdOrientation)
    } else {
      orientation = tempNode.simdOrientation
    }
  }

  private func normalize(_ angle: Float, forMinimalRotationTo ref: Float) -> Float {
    // Normalize angle in steps of 90 degrees such that the rotation to the other angle is minimal
    var normalized = angle
    while abs(normalized - ref) > .pi / 4 {
      if angle > ref {
        normalized -= .pi / 2
      } else {
        normalized += .pi / 2
      }
    }
    return normalized
  }

  /**
  Reduce visual size change with distance by scaling up when close and down when far away.

  These adjustments result in a scale of 1.0x for a distance of 0.7 m or less
  (estimated distance when looking at a table), and a scale of 1.2x
  for a distance 1.5 m distance (estimated distance when looking at the floor).
  */
  private func scaleBasedOnDistance(camera: ARCamera?) -> Float {
    guard let camera = camera else { return 1.0 }

    let distanceFromCamera = simd_length(self.convert(position: .zero, to: nil) - camera.transform.translation)
    if distanceFromCamera < 0.7 {
      return distanceFromCamera / 0.7
    } else {
      return 0.25 * distanceFromCamera + 0.825
    }
  }

  // MARK: Animations

  /// Called whenever the state of the focus entity changes
  ///
  /// - Parameter newPlane: If the entity is directly on a plane, is it a new plane to track
  public func stateChanged(newPlane: Bool = false) {
  }

  private func stateChangedSetup(newPlane: Bool = false) {
    guard !isAnimating else { return }
    self.stateChanged(newPlane: newPlane)
  }

  /// - TODO: Animate this orientation change
  private func performAlignmentAnimation(to newOrientation: simd_quatf) {
    orientation = newOrientation
  }

  /// - TODO: RealityKit to allow for setting render order
  /// Sets the rendering order of the `positioningEntity` to show on top or under other scene content.
//  func displayNodeHierarchyOnTop(_ isOnTop: Bool) {
//    // Recursivley traverses the node's children to update the rendering order depending on the `isOnTop` parameter.
//    func updateRenderOrder(for node: Entity) {
//      node.render = isOnTop ? 2 : 0
//
//      for material in node.geometry?.materials ?? [] {
//        material.readsFromDepthBuffer = !isOnTop
//      }
//
//      for child in node.childNodes {
//        updateRenderOrder(for: child)
//      }
//    }

//    updateRenderOrder(for: self.positioningNode)
//  }

  @available(*, deprecated, renamed: "updateFocusEntity")
  public func updateFocusNode() {
    self.updateFocusEntity()
  }

  public func updateFocusEntity() {
    guard let view = self.viewDelegate as? (ARView & ARSmartHitTest) else {
      print("FocusEntity viewDelegate must conform to ARSmartHitTest and be an ARView for now")
      return
    }
    // Perform hit testing only when ARKit tracking is in a good state.
    guard let camera = view.session.currentFrame?.camera,
      case .normal = camera.trackingState
    else {
      self.state = .initializing
      povEntity.transform = view.cameraTransform
      return
    }
    var result: ARHitTestResult?
    if !Thread.isMainThread {
      if let center = self.screenCenter {
        result = view.smartHitTest(center)
      } else {
        DispatchQueue.main.async {
          self.screenCenter = view.screenCenter
          self.updateFocusEntity()
        }
        return
      }
    } else {
      result = view.smartHitTest(view.screenCenter)
    }

    if let result = result {
      self.state = .tracking(hitTestResult: result, camera: camera)
    } else {
      povEntity.transform = view.cameraTransform
      self.state = .initializing
    }
  }
}
