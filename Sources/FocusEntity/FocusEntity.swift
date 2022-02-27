//
//  FocusEntity.swift
//  FocusEntity
//
//  Created by Max Cobb on 8/26/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

import RealityKit
#if canImport(RealityFoundation)
import RealityFoundation
#endif

#if os(macOS) || targetEnvironment(simulator)
#warning("FocusEntity: This package is only fully available with physical iOS devices")
#endif

#if canImport(ARKit) && !targetEnvironment(simulator)
import ARKit
import Combine

public protocol HasFocusEntity: Entity {}

public extension HasFocusEntity {
    var focus: FocusEntityComponent {
        get { self.components[FocusEntityComponent.self] ?? .classic }
        set { self.components[FocusEntityComponent.self] = newValue }
    }
    var isOpen: Bool {
        get { self.focus.isOpen }
        set { self.focus.isOpen = newValue }
    }
    internal var segments: [FocusEntity.Segment] {
        get { self.focus.segments }
        set { self.focus.segments = newValue }
    }
    var allowedRaycast: ARRaycastQuery.Target {
        get { self.focus.allowedRaycast }
        set { self.focus.allowedRaycast = newValue }
    }
}

@objc public protocol FocusEntityDelegate {
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

    private var myScene: Scene? {
        self.arView?.scene
    }

    internal weak var arView: ARView?

    /// For moving the FocusEntity to a whole new ARView
    /// - Parameter view: The destination `ARView`
    public func moveTo(view: ARView) {
        let wasUpdating = self.isAutoUpdating
        self.setAutoUpdate(to: false)
        self.arView = view
        view.scene.addAnchor(self)
        if wasUpdating {
            self.setAutoUpdate(to: true)
        }
    }

    /// Destroy this FocusEntity and its references to any ARViews
    /// Without calling this, your ARView could stay in memory.
    public func destroy() {
        self.setAutoUpdate(to: false)
        self.delegate = nil
        self.arView = nil
        for child in children {
            child.removeFromParent()
        }
        self.removeFromParent()
    }

    private var updateCancellable: Cancellable?
    public private(set) var isAutoUpdating: Bool = false

    public func setAutoUpdate(to autoUpdate: Bool) {
        guard autoUpdate != self.isAutoUpdating,
              !(autoUpdate && self.arView == nil) else {
                  return
              }
        self.updateCancellable?.cancel()
        if autoUpdate {
            self.updateCancellable = self.myScene?.subscribe(
                to: SceneEvents.Update.self, self.updateFocusEntity
            )
        }
        self.isAutoUpdating = autoUpdate
    }
    public weak var delegate: FocusEntityDelegate?

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
        displayOffPlane(for: raycastResult)
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
                if stateChanged && self.anchor != nil {
                    self.anchoring = AnchoringComponent(.world(transform: Transform.identity.matrix))
                }
                if let planeAnchor = raycastResult.anchor as? ARPlaneAnchor {
                    entityOnPlane(for: raycastResult, planeAnchor: planeAnchor)
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
    public internal(set) var isChangingAlignment = false

    /// A camera anchor used for placing the focus entity in front of the camera.
    internal var cameraAnchor: AnchorEntity!

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
        self.init(on: arView, focus: FocusEntityComponent(style: style))
    }
    public required init(on arView: ARView, focus: FocusEntityComponent) {
        self.arView = arView
        super.init()
        self.focus = focus
        self.name = "FocusEntity"
        self.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])

        self.addChild(self.positioningEntity)

        cameraAnchor = AnchorEntity(.camera)
        arView.scene.addAnchor(cameraAnchor)

        // Start the focus square as a billboard.
        displayAsBillboard()
        self.delegate?.toInitializingState?()
        arView.scene.addAnchor(self)
        self.setAutoUpdate(to: true)
        switch self.focus.style {
        case .colored(_, _, _, let mesh):
            let fillPlane = ModelEntity(mesh: mesh)
            self.positioningEntity.addChild(fillPlane)
            self.fillPlane = fillPlane
            self.coloredStateChanged()
        case .classic:
            guard let classicStyle = self.focus.classicStyle else {
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
        self.onPlane = false
        self.currentAlignment = .none
        stateChangedSetup()
    }

    /// Places the focus entity in front of the camera instead of on a plane.
    private func putInFrontOfCamera() {

        // Works better than arView.ray()
        let newPosition = cameraAnchor.convert(position: [0, 0, -1], to: nil)
        recentFocusEntityPositions.append(newPosition)
        updatePosition()
        // --//
        // Make focus entity face the camera with a smooth animation.
        var newRotation = arView?.cameraTransform.rotation ?? simd_quatf()
        newRotation *= simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        performAlignmentAnimation(to: newRotation)
    }

    /// Called when a surface has been detected.
    private func displayOffPlane(for raycastResult: ARRaycastResult) {
        self.stateChangedSetup()
        let position = raycastResult.worldTransform.translation
        if self.currentAlignment != .none {
            // It is ready to move over to a new surface.
            recentFocusEntityPositions.append(position)
            performAlignmentAnimation(to: raycastResult.worldTransform.orientation)
        } else {
            putInFrontOfCamera()
        }
        updateTransform(raycastResult: raycastResult)
    }

    /// Called when a plane has been detected.
    private func entityOnPlane(
        for raycastResult: ARRaycastResult, planeAnchor: ARPlaneAnchor
    ) {
        self.onPlane = true
        self.stateChangedSetup(newPlane: !anchorsOfVisitedPlanes.contains(planeAnchor))
        anchorsOfVisitedPlanes.insert(planeAnchor)
        let position = raycastResult.worldTransform.translation
        if self.currentAlignment != .none {
            // It is ready to move over to a new surface.
            recentFocusEntityPositions.append(position)
        } else {
            putInFrontOfCamera()
        }
        updateTransform(raycastResult: raycastResult)
    }

    /// Called whenever the state of the focus entity changes
    ///
    /// - Parameter newPlane: If the entity is directly on a plane, is it a new plane to track
    public func stateChanged(newPlane: Bool = false) {
        switch self.focus.style {
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
        guard let camera = self.arView?.session.currentFrame?.camera,
              case .normal = camera.trackingState,
              let result = self.smartRaycast()
        else {
            // We should place the focus entity in front of the camera instead of on a plane.
            putInFrontOfCamera()
            self.state = .initializing
            return
        }

        self.state = .tracking(raycastResult: result, camera: camera)
    }
}
#else
/**
 FocusEntity is only enabled for environments which can import ARKit.
 */
open class FocusEntity {
    public convenience init(on arView: ARView, style: FocusEntityComponent.Style) {
        self.init(on: arView, focus: FocusEntityComponent(style: style))
    }
    public convenience init(on arView: ARView, focus: FocusEntityComponent) {
        self.init()
    }
    internal init() {
        print("This is only supported on a physical iOS device.")
    }
}
#endif
