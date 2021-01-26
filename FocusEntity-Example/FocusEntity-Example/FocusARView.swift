//
//  FocusARView.swift
//  FocusEntity-Example
//
//  Created by Max Cobb on 8/26/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

import RealityKit
//import FocusEntity
import Combine
import ARKit
import UIKit

class FocusARView: ARView {
  var focusEntity: FocusEntity?
  required init(frame frameRect: CGRect) {
    super.init(frame: frameRect)
    self.setupConfig()
    //self.focusEntity = FocusEntity(on: self, focus: .classic)
    //self.focusEntity = FocusEntity(on: self, focus: .plane)
    do{
        let onColor : MaterialColorParameter = try .texture(.load(named: "Add"))
        let offColor : MaterialColorParameter = try .texture(.load(named: "Open"))
        self.focusEntity = FocusEntity(on: self, style: .colored(onColor: onColor, offColor: offColor, nonTrackingColor: offColor))
    } catch {
        self.focusEntity = FocusEntity(on: self, focus: .classic)
        print("Unable to load plane textures")
        print(error.localizedDescription)
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

extension FocusARView: FocusEntityDelegate {
  func toTrackingState() {
    print("tracking")
  }
  func toInitializingState() {
    print("initializing")
  }
}
