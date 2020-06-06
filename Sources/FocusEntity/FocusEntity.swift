//
//  FocusEntity.swift
//
//
//  Created by Max Cobb on 8/26/19.
//

import RealityKit
import ARKit
import Combine

private extension UIView {
  /// Center of the view
  var screenCenter: CGPoint {
    let bounds = self.bounds
    return CGPoint(x: bounds.midX, y: bounds.midY)
  }
}

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

public protocol HasFocusEntity: Entity {}

public extension HasFocusEntity {
  var focusEntity: FocusEntityComponent {
    get { self.components[FocusEntityComponent.self] ?? .classic }
    set { self.components[FocusEntityComponent.self] = newValue }
  }
  var isOpen: Bool {
    get { self.focusEntity.isOpen }
    set { self.focusEntity.isOpen = newValue }
  }
  internal var segments: [FocusEntity.Segment] {
    get { self.focusEntity.segments }
    set { self.focusEntity.segments = newValue }
  }
}

@objc public protocol FEDelegate: AnyObject {
  /// Called when the FocusEntity is now in world space
  @objc optional func toTrackingState()

  /// Called when the FocusEntity is tracking the camera
  @objc optional func toInitializingState()
}

/**
An `Entity` which is used to provide uses with visual cues about the status of ARKit world tracking.
- Tag: FocusSquare
*/
open class FocusEntity: Entity, HasAnchoring, HasFocusEntity {

  public enum FEError: Error {
    case noScene
  }

  private var myScene: Scene {
    self.arView.scene
  }

  public var arView: ARView

  private var updateCancellable: Cancellable?
  public private(set) var isAutoUpdating: Bool = false

  @discardableResult
  public func setAutoUpdate(to autoUpdate: Bool) -> FocusEntity.FEError? {
    if autoUpdate {
      self.updateCancellable = self.myScene.subscribe(to: SceneEvents.Update.self, { _ in
        self.updateFocusEntity()
      })
    } else {
      self.updateCancellable?.cancel()
    }
    self.isAutoUpdating = autoUpdate
    return nil
  }
  public var delegate: FEDelegate?

  // MARK: - Types
  public enum State: Equatable {
    case initializing
    case tracking(raycastResult: ARRaycastResult, camera: ARCamera?)
  }

  // MARK: - Properties

  /// The most recent position of the focus square based on the current state.
  var lastPosition: SIMD3<Float>? {
    switch state {
    case .initializing: return nil
    case .tracking(let raycastResult, _): return raycastResult.worldTransform.translation
    }
  }

  fileprivate func entityOffPlane(_ raycastResult: ARRaycastResult, _ camera: ARCamera?) {
    self.onPlane = false
    displayOffPlane(for: raycastResult, camera: camera)
  }

  public var state: State = .initializing {
    didSet {
      guard state != oldValue else { return }

      switch state {
      case .initializing:
        if oldValue != .initializing {
          displayAsBillboard()
          self.delegate?.toInitializingState?()
        }
      case let .tracking(raycastResult, camera):
        let stateChanged = oldValue == .initializing
        if stateChanged {
          self.anchoring = AnchoringComponent(.world(transform: Transform.identity.matrix))
        }
        if let planeAnchor = raycastResult.anchor as? ARPlaneAnchor {
          entityOnPlane(for: raycastResult, planeAnchor: planeAnchor, camera: camera)
          currentPlaneAnchor = planeAnchor
        } else {
          entityOffPlane(raycastResult, camera)
          currentPlaneAnchor = nil
        }
        if stateChanged {
          self.delegate?.toTrackingState?()
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

  public convenience init(on arView: ARView, style: FocusEntityComponent.Style) {
    self.init(on: arView, style: FocusEntityComponent(style: style))
  }
  public required init(on arView: ARView, style: FocusEntityComponent) {
    self.arView = arView
    super.init()
    self.name = "FocusEntity"
    self.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])

    self.addChild(self.positioningEntity)

    // Start the focus square as a billboard.
    displayAsBillboard()
    self.delegate?.toInitializingState?()
    arView.scene.addAnchor(self)
    self.setAutoUpdate(to: true)
    switch self.focusEntity.style {
    case .colored(_, _, _, let mesh):
      let fillPlane = ModelEntity(mesh: mesh)
      self.positioningEntity.addChild(fillPlane)
      self.fillPlane = fillPlane
    case .classic:
      self.setupClassic()
    }
  }

  required public init() {
    fatalError("init() has not been implemented")
  }
  
  // MARK: - Appearance

  /// Hides the focus square.
  func hide() {
    self.isEnabled = false
//    runAction(.fadeOut(duration: 0.5), forKey: "hide")
  }

  /// Displays the focus square parallel to the camera plane.
  private func displayAsBillboard() {
    self.anchoring = AnchoringComponent(.camera)
    self.onPlane = false

    self.transform = .init(
      scale: .one, rotation: simd_quatf(angle: .pi / 2, axis: [1, 0, 0]),
      translation: [0, 0, -0.8]
    )
    stateChangedSetup()
  }

  /// Called when a surface has been detected.
  private func displayOffPlane(for raycastResult: ARRaycastResult, camera: ARCamera?) {
    self.stateChangedSetup()
    let position = raycastResult.worldTransform.translation
    recentFocusEntityPositions.append(position)
    updateTransform(for: position, raycastResult: raycastResult, camera: camera)
  }

  /// Called when a plane has been detected.
  private func entityOnPlane(for raycastResult: ARRaycastResult, planeAnchor: ARPlaneAnchor, camera: ARCamera?) {
    self.onPlane = true
    self.stateChangedSetup(newPlane: !anchorsOfVisitedPlanes.contains(planeAnchor))
    anchorsOfVisitedPlanes.insert(planeAnchor)
    let position = raycastResult.worldTransform.translation
    recentFocusEntityPositions.append(position)
    updateTransform(for: position, raycastResult: raycastResult, camera: camera)
  }

  // MARK: Helper Methods

  /// Update the transform of the focus square to be aligned with the camera.
  private func updateTransform(for position: SIMD3<Float>, raycastResult: ARRaycastResult, camera: ARCamera?) {
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
      updateAlignment(for: raycastResult, yRotationAngle: angle)
    }
  }

  private func updateAlignment(for raycastResult: ARRaycastResult, yRotationAngle angle: Float) {
    // Abort if an animation is currently in progress.
    if isChangingAlignment {
      return
    }

    var shouldAnimateAlignmentChange = false
    let tempNode = SCNNode()
    tempNode.simdRotation = SIMD4<Float>(0, 1, 0, angle)

    // Determine current alignment
    var alignment: ARPlaneAnchor.Alignment?
    if let planeAnchor = raycastResult.anchor as? ARPlaneAnchor {
      alignment = planeAnchor.alignment
    } else if raycastResult.targetAlignment == .horizontal {
      alignment = .horizontal
    } else if raycastResult.targetAlignment == .vertical {
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
      raycastResult.anchor is ARPlaneAnchor {
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
      tempNode.simdOrientation = raycastResult.worldTransform.orientation
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
    switch self.focusEntity.style {
    case .colored:
      self.coloredStateChanged()
    case .classic:
      if self.onPlane {
        self.onPlaneAnimation(newPlane: newPlane)
      } else {
        self.offPlaneAniation()
      }
    }
  }

  internal var fillPlane: ModelEntity?

  private func stateChangedSetup(newPlane: Bool = false) {
    guard !isAnimating else { return }
    self.stateChanged(newPlane: newPlane)
  }

  private func performAlignmentAnimation(to newOrientation: simd_quatf) {
    orientation = newOrientation
  }

  @available(*, deprecated, renamed: "updateFocusEntity")
  public func updateFocusNode() {
    self.updateFocusEntity()
  }

  private func raycastQuery() -> ARRaycastQuery {
    let camTransform = self.arView.cameraTransform
    let camDirection = camTransform.matrix.columns.2
    return ARRaycastQuery(
      origin: simd_float3(camTransform.translation),
      direction: -[camDirection.x, camDirection.y, camDirection.z],
      allowing: .estimatedPlane,
      alignment: .any
    )
  }

  public func updateFocusEntity() {
    // Perform hit testing only when ARKit tracking is in a good state.
    guard let camera = self.arView.session.currentFrame?.camera,
      case .normal = camera.trackingState,
      let result = self.arView.session.raycast(self.raycastQuery()).first
    else {
      self.state = .initializing
      return
    }

    self.state = .tracking(raycastResult: result, camera: camera)
  }
}
