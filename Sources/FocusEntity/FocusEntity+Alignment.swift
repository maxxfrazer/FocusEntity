//
//  FocusEntity.swift
//  FocusEntity
//
//  Created by Max Cobb on 8/26/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

#if canImport(ARKit) && !targetEnvironment(simulator)
import RealityKit
import ARKit
import Combine

extension FocusEntity {

    // MARK: Helper Methods

    /// Update the position of the focus square.
    internal func updatePosition() {
        // Average using several most recent positions.
        recentFocusEntityPositions = Array(recentFocusEntityPositions.suffix(10))

        // Move to average of recent positions to avoid jitter.
        let average = recentFocusEntityPositions.reduce(
            SIMD3<Float>.zero, { $0 + $1 }
        ) / Float(recentFocusEntityPositions.count)
        self.position = average
    }

    /// Update the transform of the focus square to be aligned with the camera.
    internal func updateTransform(raycastResult: ARRaycastResult) {
        self.updatePosition()

        if state != .initializing {
            updateAlignment(for: raycastResult)
        }
    }

    internal func updateAlignment(for raycastResult: ARRaycastResult) {

        var targetAlignment = raycastResult.worldTransform.orientation

        // Determine current alignment
        var alignment: ARPlaneAnchor.Alignment?
        if let planeAnchor = raycastResult.anchor as? ARPlaneAnchor {
            alignment = planeAnchor.alignment
            // Catching case when looking at ceiling
            if targetAlignment.act([0, 1, 0]).y < -0.9 {
                targetAlignment *= simd_quatf(angle: .pi, axis: [0, 1, 0])
            }
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

        let alignCount = self.recentFocusEntityAlignments.count
        let horizontalHistory = recentFocusEntityAlignments.filter({ $0 == .horizontal }).count
        let verticalHistory = recentFocusEntityAlignments.filter({ $0 == .vertical }).count

        // Alignment is same as most of the history - change it
        if alignment == .horizontal && horizontalHistory > alignCount * 3/4 ||
            alignment == .vertical && verticalHistory > alignCount / 2 ||
            raycastResult.anchor is ARPlaneAnchor {
            if alignment != self.currentAlignment ||
                (alignment == .vertical && self.shouldContinueAlignAnim(to: targetAlignment)
                ) {
                isChangingAlignment = true
                self.currentAlignment = alignment
            }
        } else {
            // Alignment is different than most of the history - ignore it
            return
        }

        // Change the focus entity's alignment
        if isChangingAlignment {
            // Uses interpolation.
            // Needs to be called on every frame that the animation is desired, Not just the first frame.
            performAlignmentAnimation(to: targetAlignment)
        } else {
            orientation = targetAlignment
        }
    }

    internal func normalize(_ angle: Float, forMinimalRotationTo ref: Float) -> Float {
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

    internal func getCamVector() -> (position: SIMD3<Float>, direciton: SIMD3<Float>)? {
        guard let camTransform = self.arView?.cameraTransform else {
            return nil
        }
        let camDirection = camTransform.matrix.columns.2
        return (camTransform.translation, -[camDirection.x, camDirection.y, camDirection.z])
    }

    /// - Parameters:
    /// - Returns: ARRaycastResult if an existing plane geometry or an estimated plane are found, otherwise nil.
    internal func smartRaycast() -> ARRaycastResult? {
        // Perform the hit test.
        guard let (camPos, camDir) = self.getCamVector() else {
            return nil
        }
        let rcQuery = ARRaycastQuery(
            origin: camPos, direction: camDir,
            allowing: self.allowedRaycast, alignment: .any
        )
        let results = self.arView?.session.raycast(rcQuery) ?? []

        // 1. Check for a result on an existing plane using geometry.
        if let existingPlaneUsingGeometryResult = results.first(
            where: { $0.target == .existingPlaneGeometry }
        ) {
            return existingPlaneUsingGeometryResult
        }

        // 2. As a fallback, check for a result on estimated planes.
        return results.first(where: { $0.target == .estimatedPlane })
    }

    /// Uses interpolation between orientations to create a smooth `easeOut` orientation adjustment animation.
    internal func performAlignmentAnimation(to newOrientation: simd_quatf) {
        // Interpolate between current and target orientations.
        orientation = simd_slerp(orientation, newOrientation, 0.15)
        // This length creates a normalized vector (of length 1) with all 3 components being equal.
        self.isChangingAlignment = self.shouldContinueAlignAnim(to: newOrientation)
    }

    func shouldContinueAlignAnim(to newOrientation: simd_quatf) -> Bool {
        let testVector = simd_float3(repeating: 1 / sqrtf(3))
        let point1 = orientation.act(testVector)
        let point2 = newOrientation.act(testVector)
        let vectorsDot = simd_dot(point1, point2)
        // Stop interpolating when the rotations are close enough to each other.
        return vectorsDot < 0.999
    }

    /**
     Reduce visual size change with distance by scaling up when close and down when far away.
     
     These adjustments result in a scale of 1.0x for a distance of 0.7 m or less
     (estimated distance when looking at a table), and a scale of 1.2x
     for a distance 1.5 m distance (estimated distance when looking at the floor).
     */
    internal func scaleBasedOnDistance(camera: ARCamera?) -> Float {
        guard let camera = camera else { return 1.0 }

        let distanceFromCamera = simd_length(self.convert(position: .zero, to: nil) - camera.transform.translation)
        if distanceFromCamera < 0.7 {
            return distanceFromCamera / 0.7
        } else {
            return 0.25 * distanceFromCamera + 0.825
        }
    }
}
#endif
