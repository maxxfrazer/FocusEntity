//
//  BasicARView.swift
//  FocusEntity-Example
//
//  Created by Max Cobb on 12/04/2023.
//  Copyright © 2023 Max Cobb. All rights reserved.
//

import SwiftUI
import RealityKit
import FocusEntity
import ARKit

struct BasicARView: UIViewRepresentable {
    typealias UIViewType = ARView
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let arConfig = ARWorldTrackingConfiguration()
        arConfig.planeDetection = [.horizontal, .vertical]
        arView.session.run(arConfig)
        _ = FocusEntity(on: arView, style: .classic())
        return arView
    }
    func updateUIView(_ uiView: ARView, context: Context) {}
}

struct BasicARView_Previews: PreviewProvider {
    static var previews: some View {
        BasicARView()
    }
}
