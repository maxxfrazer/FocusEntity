//
//  FocusEntity+Classic.swift
//  FocusEntity
//
//  Created by Max Cobb on 8/28/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

#if canImport(ARKit) && !targetEnvironment(simulator)
import RealityKit

/// An extension of FocusEntity holding the methods for the "classic" style.
internal extension FocusEntity {

  // MARK: - Configuration Properties

  /// Original size of the focus square in meters. Not currently customizable
  static let size: Float = 0.17

  /// Thickness of the focus square lines in meters. Not currently customizable
  static let thickness: Float = 0.018

  /// Scale factor for the focus square when it is closed, w.r.t. the original size.
  static let scaleForClosedSquare: Float = 0.97

  /// Side length of the focus square segments when it is open (w.r.t. to a 1x1 square).
//  static let sideLengthForOpenSegments: CGFloat = 0.2

  /// Duration of the open/close animation. Not currently used.
  static let animationDuration = 0.7

  /// Color of the focus square fill. Not currently used.
//  static var fillColor = #colorLiteral(red: 1, green: 0.9254901961, blue: 0.4117647059, alpha: 1)

  /// Indicates whether the segments of the focus square are disconnected.
//  private var isOpen = true

  /// List of the segments in the focus square.

  // MARK: - Initialization

  func setupClassic(_ classicStyle: ClassicStyle) {
//    opacity = 0.0
    /*
    The focus square consists of eight segments as follows, which can be individually animated.

        s0  s1
        _   _
    s2 |     | s3

    s4 |     | s5
        -   -
        s6  s7
    */

    let segCorners: [(Corner, Alignment)] = [
      (.topLeft, .horizontal), (.topRight, .horizontal),
      (.topLeft, .vertical), (.topRight, .vertical),
      (.bottomLeft, .vertical), (.bottomRight, .vertical),
      (.bottomLeft, .horizontal), (.bottomRight, .horizontal)
    ]
    self.segments = segCorners.enumerated().map { (index, cornerAlign) -> Segment in
      Segment(
        name: "s\(index)",
        corner: cornerAlign.0,
        alignment: cornerAlign.1,
        color: classicStyle.color
      )
    }

    let sl: Float = 0.5  // segment length
    let c: Float = FocusEntity.thickness / 2 // correction to align lines perfectly
    segments[0].position += [-(sl / 2 - c), 0, -(sl - c)]
    segments[1].position += [sl / 2 - c, 0, -(sl - c)]
    segments[2].position += [-sl, 0, -sl / 2]
    segments[3].position += [sl, 0, -sl / 2]
    segments[4].position += [-sl, 0, sl / 2]
    segments[5].position += [sl, 0, sl / 2]
    segments[6].position += [-(sl / 2 - c), 0, sl - c]
    segments[7].position += [sl / 2 - c, 0, sl - c]

    for segment in segments {
      self.positioningEntity.addChild(segment)
      segment.open()
    }

//    self.positioningEntity.addChild(fillPlane)
    self.positioningEntity.scale = SIMD3<Float>(repeating: FocusEntity.size * FocusEntity.scaleForClosedSquare)

    // Always render focus square on top of other content.
//    self.displayNodeHierarchyOnTop(true)
  }

  // MARK: Animations

  func offPlaneAniation() {
    // Open animation
    guard !isOpen else {
      return
    }
    isOpen = true

    for segment in segments {
      segment.open()
    }
    positioningEntity.scale = .init(repeating: FocusEntity.size)
  }

  func onPlaneAnimation(newPlane: Bool = false) {
    guard isOpen else {
      return
    }
    self.isOpen = false

    // Close animation
    for segment in self.segments {
      segment.close()
    }

    if newPlane {
      // New plane animation not implemented
    }
  }

}
#endif
