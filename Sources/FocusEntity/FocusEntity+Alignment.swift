//
//  FocusEntity.swift
//  FocusEntity
//
//  Created by Max Cobb on 8/26/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

#if canImport(ARKit)
import RealityKit
import ARKit
import Combine

extension FocusEntity {

  // MARK: Helper Methods
    
  /// Update the position of the focus square.
  internal func updatePosition(){
        // Average using several most recent positions.
        recentFocusEntityPositions = Array(recentFocusEntityPositions.suffix(10))

        // Move to average of recent positions to avoid jitter.
        let average = recentFocusEntityPositions.reduce(
          SIMD3<Float>(repeating: 0), { $0 + $1 }
        ) / Float(recentFocusEntityPositions.count)
        self.position = average
    }

  /// Update the transform of the focus square to be aligned with the camera.
  internal func updateTransform(for position: SIMD3<Float>, raycastResult: ARRaycastResult, camera: ARCamera?) {
    
    self.updatePosition()
    
    //Produces odd scaling when focus entity is moving towards the user along a horizontal plane;
    //looks like the focus entity is sinking downwards.
//    if self.scaleEntityBasedOnDistance {
//      self.scale = SIMD3<Float>(repeating: scaleBasedOnDistance(camera: camera))
//    }

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

  internal func updateAlignment(for raycastResult: ARRaycastResult, yRotationAngle angle: Float) {

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

    let alignCount = self.recentFocusEntityAlignments.count
    let horizontalHistory = recentFocusEntityAlignments.filter({ $0 == .horizontal }).count
    let verticalHistory = recentFocusEntityAlignments.filter({ $0 == .vertical }).count

    // Alignment is same as most of the history - change it
    if alignment == .horizontal && horizontalHistory > alignCount * 3/4 ||
      alignment == .vertical && verticalHistory > alignCount / 2 ||
      raycastResult.anchor is ARPlaneAnchor {
      if alignment != self.currentAlignment {
        isChangingAlignment = true
        self.currentAlignment = alignment
        self.recentFocusEntityAlignments.removeAll()
      }
    } else {
      // Alignment is different than most of the history - ignore it
      return
    }
    
    
    let yRotation = simd_quatf(angle: angle, axis: [0,1,0])
    let targetAlignment = raycastResult.worldTransform.orientation * yRotation
    // Change the focus entity's alignment
    if isChangingAlignment {
        //Uses interpolation.
        //Needs to be called on every frame that the animation is desired, Not just the first frame.
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
      allowing: .estimatedPlane, alignment: .any
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

    ///Uses interpolation between orientations to create a smooth `easeOut` orientation adjustment animation.
      internal func performAlignmentAnimation(to newOrientation: simd_quatf) {
        //interpolate between current and target orientations
        orientation = simd_slerp(orientation, newOrientation, 0.15)
        let forward : simd_float3 = [0,0,-1]
        let point1 = orientation.act(forward)
        let point2 = newOrientation.act(forward)
        let distanceBetweenVectors = simd_distance(point1, point2)
        //Stop interpolating when the rotations are close enough to each other.
        if distanceBetweenVectors < 0.03 {
            //Stop calling this function for horiztonal and vertical surfaces.
            isChangingAlignment = false
        }
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
