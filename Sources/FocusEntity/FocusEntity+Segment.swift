//
//  FocusEntity+Segment.swift
//  FocusEntity
//
//  Created by Max Cobb on 8/28/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

import RealityKit

internal extension FocusEntity {
    /*
     The focus square consists of eight segments as follows, which can be individually animated.

     s0  s1
     _   _
     s2 |     | s3

     s4 |     | s5
     -   -
     s6  s7
     */
    enum Corner {
        case topLeft // s0, s2
        case topRight // s1, s3
        case bottomRight // s5, s7
        case bottomLeft // s4, s6
    }

    enum Alignment {
        case horizontal // s0, s1, s6, s7
        case vertical // s2, s3, s4, s5
    }

    enum Direction {
        case up, down, left, right

        var reversed: Direction {
            switch self {
            case .up:   return .down
            case .down: return .up
            case .left:  return .right
            case .right: return .left
            }
        }
    }

    class Segment: Entity, HasModel {

        // MARK: - Configuration & Initialization

        /// Thickness of the focus square lines in m.
        static let thickness: Float = 0.018

        /// Length of the focus square lines in m.
        static let length: Float = 0.5  // segment length

        /// Side length of the focus square segments when it is open (w.r.t. to a 1x1 square).
        static let openLength: Float = 0.2

        let corner: Corner
        let alignment: Alignment
        let plane: ModelComponent

        init(name: String, corner: Corner, alignment: Alignment, color: Material.Color) {
            self.corner = corner
            self.alignment = alignment

            switch alignment {
            case .vertical:
                plane = ModelComponent(
                    mesh: .generatePlane(width: 1, depth: 1),
                    materials: [UnlitMaterial(color: color)]
                )
            case .horizontal:
                plane = ModelComponent(
                    mesh: .generatePlane(width: 1, depth: 1),
                    materials: [UnlitMaterial(color: color)]
                )
            }
            super.init()

            switch alignment {
            case .vertical:
                self.scale = [Segment.thickness, 1, Segment.length]
            case .horizontal:
                self.scale = [Segment.length, 1, Segment.thickness]
            }
            //      self.orientation = .init(angle: .pi / 2, axis: [1, 0, 0])
            self.name = name

            //      let material = plane.firstMaterial!
            //      material.diffuse.contents = FocusSquare.primaryColor
            //      material.isDoubleSided = true
            //      material.ambient.contents = UIColor.black
            //      material.lightingModel = .constant
            //      material.emission.contents = FocusSquare.primaryColor
            model = plane
        }

        required init() {
            fatalError("init() has not been implemented")
        }

        // MARK: - Animating Open/Closed

        var openDirection: Direction {
            switch (corner, alignment) {
            case (.topLeft, .horizontal): return .left
            case (.topLeft, .vertical): return .up
            case (.topRight, .horizontal): return .right
            case (.topRight, .vertical): return .up
            case (.bottomLeft, .horizontal): return .left
            case (.bottomLeft, .vertical): return .down
            case (.bottomRight, .horizontal): return .right
            case (.bottomRight, .vertical): return .down
            }
        }

        func open() {
            if alignment == .horizontal {
                self.scale[0] = Segment.openLength
            } else {
                self.scale[2] = Segment.openLength
            }

            let offset = Segment.length / 2 - Segment.openLength / 2
            updatePosition(withOffset: Float(offset), for: openDirection)
        }

        func close() {
            let oldLength: Float
            if alignment == .horizontal {
                oldLength = self.scale[0]
                self.scale[0] = Segment.length
            } else {
                oldLength = self.scale[2]
                self.scale[2] = Segment.length
            }

            let offset = Segment.length / 2 - oldLength / 2
            updatePosition(withOffset: offset, for: openDirection.reversed)
        }

        private func updatePosition(withOffset offset: Float, for direction: Direction) {
            switch direction {
            case .left:     position.x -= offset
            case .right:    position.x += offset
            case .up:       position.z -= offset
            case .down:     position.z += offset
            }
        }

    }
}
