//
//  FocusARView.swift
//  FocusEntity-Example
//
//  Created by Max Cobb on 8/26/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

import RealityKit
import SmartHitTest
//import FocusEntity
import ARKit
import UIKit

class FocusARView: ARView, ARSmartHitTest, ARSessionDelegate {
  let focusSquare = FESquare()
  required init(frame frameRect: CGRect) {
    super.init(frame: frameRect)
    focusSquare.viewDelegate = self
//    self.scene.addAnchor(focusSquare)
    let config = ARWorldTrackingConfiguration()
    config.planeDetection = [.horizontal, .vertical]
    session.delegate = self
    session.run(config, options: [])
  }

  @objc required dynamic init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    self.focusSquare.updateFocusNode()
  }
}
