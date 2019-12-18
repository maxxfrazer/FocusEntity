//
//  ContentView.swift
//  FocusEntity-Example
//
//  Created by Max Cobb on 8/26/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

import SwiftUI
import RealityKit

struct ContentView: View {
  var body: some View {
    ARViewContainer().edgesIgnoringSafeArea(.all)
  }
}

struct ARViewContainer: UIViewRepresentable {

  func makeUIView(context: Context) -> FocusARView {
    FocusARView(frame: .zero)
  }

  func updateUIView(_ uiView: FocusARView, context: Context) {}

}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
#endif
