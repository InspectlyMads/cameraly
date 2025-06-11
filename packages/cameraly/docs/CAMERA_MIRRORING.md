# Camera Preview Mirroring

## Overview

The cameraly package implements platform-specific camera preview mirroring to provide a consistent and intuitive user experience across Android and iOS devices.

## Behavior

### Android
- **Front Camera**: Preview is mirrored (horizontally flipped) to match user expectations
- **Back Camera**: Preview is not mirrored
- **Rationale**: Android's camera API does not automatically mirror the front camera preview, so we apply a transform

### iOS
- **Front Camera**: Preview is automatically mirrored by the system
- **Back Camera**: Preview is not mirrored
- **Rationale**: iOS handles front camera mirroring natively, so no additional transformation is needed

## Implementation

The mirroring is implemented in the `_buildCameraPreview` method of the `CameraScreen` widget:

```dart
// Mirror the preview for front camera on Android only
if (defaultTargetPlatform == TargetPlatform.android && 
    cameraState.lensDirection == CameraLensDirection.front) {
  preview = Transform(
    alignment: Alignment.center,
    transform: Matrix4.identity()..scale(-1.0, 1.0),
    child: preview,
  );
}
```

## Technical Details

- Uses Flutter's `Transform` widget with a horizontal scale of -1.0
- Only applied when:
  - Platform is Android
  - Camera lens direction is front
- The transform is applied to the entire preview widget, maintaining aspect ratio and layout

## Captured Media

**Important**: This mirroring only affects the preview display. The actual captured photos and videos are saved in their original orientation without mirroring. This ensures that:
- Selfies are saved correctly (not mirrored)
- Text and logos appear correctly in saved media
- The saved media matches what other apps would capture

## User Experience

This implementation provides:
- Familiar "mirror" experience when taking selfies
- Consistent behavior with native camera apps
- No impact on captured media quality or orientation