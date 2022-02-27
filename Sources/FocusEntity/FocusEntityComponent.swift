//
//  FocusEntity.swift
//  FocusEntity
//
//  Created by Max Cobb on 8/26/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

import RealityKit
#if !os(macOS)
import ARKit
#endif

internal struct ClassicStyle {
    var color: Material.Color
}

/// When using colored style, first material of a mesh will be replaced with the chosen color
internal struct ColoredStyle {
    /// Color when tracking the surface of a known plane
    var onColor: MaterialColorParameter
    /// Color when tracking an estimated plane
    var offColor: MaterialColorParameter
    /// Color when no surface tracking is achieved
    var nonTrackingColor: MaterialColorParameter
    var mesh: MeshResource
}

public struct FocusEntityComponent: Component {
    public enum Style {
        case classic(color: Material.Color)
        case colored(
            onColor: MaterialColorParameter,
            offColor: MaterialColorParameter,
            nonTrackingColor: MaterialColorParameter,
            mesh: MeshResource = MeshResource.generatePlane(width: 0.1, depth: 0.1)
        )
    }

    let style: Style
    var classicStyle: ClassicStyle? {
        switch self.style {
        case .classic(let color):
            return ClassicStyle(color: color)
        default:
            return nil
        }
    }

    var coloredStyle: ColoredStyle? {
        switch self.style {
        case .colored(let onColor, let offColor, let nonTrackingColor, let mesh):
            return ColoredStyle(
                onColor: onColor, offColor: offColor,
                nonTrackingColor: nonTrackingColor, mesh: mesh
            )
        default:
            return nil
        }
    }

    /// Convenient presets
    public static let classic = FocusEntityComponent(style: .classic(color: #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)))
    public static let plane = FocusEntityComponent(
        style: .colored(
            onColor: .color(.green),
            offColor: .color(.orange),
            nonTrackingColor: .color(Material.Color.red.withAlphaComponent(0.2)),
            mesh: FocusEntityComponent.defaultPlane
        )
    )
    internal var isOpen = true
    internal var segments: [FocusEntity.Segment] = []
    #if !os(macOS)
    public var allowedRaycast: ARRaycastQuery.Target = .estimatedPlane
    #endif

    static var defaultPlane = MeshResource.generatePlane(
        width: 0.1, depth: 0.1
    )

    public init(style: Style) {
        self.style = style
        // If the device has LiDAR, then default behaviour is to only allow
        // existing detected planes
        #if !os(macOS)
        if #available(iOS 13.4, *),
           ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            self.allowedRaycast = .existingPlaneGeometry
        }
        #endif
    }
}
