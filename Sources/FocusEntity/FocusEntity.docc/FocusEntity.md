# ``FocusEntity``

Visualise the camera focus in Augmented Reality.

## Overview

FocusEntity lets you see exactly where the centre of the view will sit in the AR space. To add FocusEntity to your scene:

```swift
let focusSquare = FocusEntity(on: <#ARView#>, focus: .classic)
```

## Topics

### FocusEntity

- ``FocusEntity/FocusEntity``
- ``FocusEntityComponent``
- ``HasFocusEntity``

### Events

Use the ``FocusEntityDelegate`` to catch events such as changing the plane anchor or otherwise a change of state.

- ``FocusEntityDelegate``
