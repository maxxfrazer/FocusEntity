//
//  FocusARView.swift
//  FocusEntity-Example
//
//  Created by Max Cobb on 8/26/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

import RealityKit
import FocusEntity
import Combine
import ARKit

class FocusARView: ARView {
  enum FocusStyleChoices {
    case classic
    case material
    case color
  }

  /// Style to be displayed in the example
  let focusStyle: FocusStyleChoices = .classic
  var focusEntity: FocusEntity?
  required init(frame frameRect: CGRect) {
    super.init(frame: frameRect)
    self.setupConfig()

    switch self.focusStyle {
    case .color:
      self.focusEntity = FocusEntity(on: self, focus: .plane)
    case .material:
      do {
        var onColor: MaterialColorParameter
        var offColor: MaterialColorParameter

        if #available(iOS 15.0, *),
           let circleImg = UIImage(systemName: "circle")?.cgImage,
           let plusImg = UIImage(systemName: "plus.circle")?.cgImage,
           let imgCircle = try? TextureResource.generate(
            from: circleImg, withName: "circle", options: .init(semantic: .raw)),
           let imgPlus = try? TextureResource.generate(
            from: plusImg, withName: "plus.circle", options: .init(semantic: .raw)
           ) {
          onColor = .texture(imgPlus)
          offColor = .texture(imgCircle)
        } else {
          onColor = try .texture(.load(named: "Add"))
          offColor = try .texture(.load(named: "Open"))
        }
        self.focusEntity = FocusEntity(
          on: self,
          style: .colored(
            onColor: onColor, offColor: offColor,
            nonTrackingColor: offColor
          )
        )
      } catch {
        self.focusEntity = FocusEntity(on: self, focus: .classic)
        print("Unable to load plane textures")
        print(error.localizedDescription)
      }
    default:
      self.focusEntity = FocusEntity(on: self, focus: .classic)
    }
  }

  func setupConfig() {
    let config = ARWorldTrackingConfiguration()
    config.planeDetection = [.horizontal, .vertical]
    session.run(config, options: [])
  }

  @objc required dynamic init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
