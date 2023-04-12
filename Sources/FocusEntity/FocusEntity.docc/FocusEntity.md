# ``FocusEntity``

Visualise the camera focus in Augmented Reality.

## Overview

FocusEntity lets you see exactly where the centre of the view will sit in the AR space. To add FocusEntity to your scene:

```swift
let focusSquare = FocusEntity(on: <#ARView#>, focus: .classic)
```

To make a whole SwiftUI View with a FocusEntity:

```swift
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
```

## Topics

### FocusEntity

- ``FocusEntity/FocusEntity``
- ``FocusEntityComponent``
- ``HasFocusEntity``

### Events

Use the ``FocusEntityDelegate`` to catch events such as changing the plane anchor or otherwise a change of state.

- ``FocusEntityDelegate``
