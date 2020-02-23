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
  let focusSquare = FESquare()
  required init(frame frameRect: CGRect) {
    super.init(frame: frameRect)
    focusSquare.viewDelegate = self
    focusSquare.delegate = self
    self.setupConfig()
  }

  func setupConfig() {
    let config = ARWorldTrackingConfiguration()
    config.planeDetection = [.horizontal, .vertical]
    session.delegate = self
    session.run(config, options: [])
  }

  @objc required dynamic init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension FocusARView: FEDelegate {
  func toTrackingState() {
    print("tracking")
  }
  func toInitializingState() {
    print("initializing")
  }
}

// Extension added to update FocusEntity on every frame update
extension FocusARView: ARSessionDelegate {
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    self.focusSquare.updateFocusEntity()
  }
}
