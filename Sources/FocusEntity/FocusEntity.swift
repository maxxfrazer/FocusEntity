//
//  FocusEntity.swift
//  FocusEntity
//
//  Created by Max Cobb on 8/26/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

import RealityKit
import ARKit
import Combine

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

@objc public protocol FocusEntityDelegate: AnyObject {
  /// Called when the FocusEntity is now in world space
  @objc optional func toTrackingState()

  /// Called when the FocusEntity is tracking the camera
  @objc optional func toInitializingState()
}

/**
An `Entity` which is used to provide uses with visual cues about the status of ARKit world tracking.
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

  public func setAutoUpdate(to autoUpdate: Bool) {
    if autoUpdate == self.isAutoUpdating {
      return
    }
    if autoUpdate {
      self.updateCancellable = self.myScene.subscribe(
        to: SceneEvents.Update.self, self.updateFocusEntity
      )
    } else {
      self.updateCancellable?.cancel()
    }
    self.isAutoUpdating = autoUpdate
  }
  public var delegate: FocusEntityDelegate?

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
          recentFocusEntityPositions.removeAll()
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

  public internal(set) var onPlane: Bool = false

  /// Indicates if the square is currently being animated.
  public internal(set) var isAnimating = false

  /// Indicates if the square is currently changing its alignment.
  internal var isChangingAlignment = false

  /// The focus square's current alignment.
  internal var currentAlignment: ARPlaneAnchor.Alignment?

  /// The current plane anchor if the focus square is on a plane.
  public internal(set) var currentPlaneAnchor: ARPlaneAnchor?

  /// The focus square's most recent positions.
  internal var recentFocusEntityPositions: [SIMD3<Float>] = []

  /// The focus square's most recent alignments.
  internal var recentFocusEntityAlignments: [ARPlaneAnchor.Alignment] = []

  /// Previously visited plane anchors.
  internal var anchorsOfVisitedPlanes: Set<ARAnchor> = []

  /// The primary node that controls the position of other `FocusEntity` nodes.
  internal let positioningEntity = Entity()

  internal var fillPlane: ModelEntity?

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
      guard let classicStyle = self.focusEntity.classicStyle else {
        return
      }
      self.setupClassic(classicStyle)
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

  private func stateChangedSetup(newPlane: Bool = false) {
    guard !isAnimating else { return }
    self.stateChanged(newPlane: newPlane)
  }

  public func updateFocusEntity(event: SceneEvents.Update? = nil) {
    // Perform hit testing only when ARKit tracking is in a good state.
    guard let camera = self.arView.session.currentFrame?.camera,
      case .normal = camera.trackingState,
      let result = self.smartRaycast()
    else {
      self.state = .initializing
      return
    }

    self.state = .tracking(raycastResult: result, camera: camera)
  }
}
