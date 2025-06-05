# Grid Button Option

## Overview
The grid button in the camera interface is now optional and hidden by default. You can enable it by passing a parameter when creating the CameraScreen widget.

## Usage

### Default (Grid Button Hidden)
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CameraScreen(
      initialMode: CameraMode.photo,
    ),
  ),
);
```

### With Grid Button Enabled
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CameraScreen(
      initialMode: CameraMode.photo,
      showGridButton: true,
    ),
  ),
);
```

## Implementation Details

The `CameraScreen` widget now accepts an optional `showGridButton` parameter:
- **Type**: `bool`
- **Default**: `false` (hidden)
- **Location**: Top-right controls in portrait mode

When enabled, users can:
- Toggle between grid on/off
- See rule of thirds overlay on the camera preview
- Visual feedback through icon change (grid_on/grid_off)

## Benefits
- Cleaner default interface
- Flexibility for different use cases
- Maintains grid functionality when needed
- Easy to enable/disable per screen instance