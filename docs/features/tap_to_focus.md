# Tap to Focus Feature

## Overview
The camera app now supports tap-to-focus functionality, allowing users to tap on the camera preview to set the focus and exposure point.

## Implementation Details

### User Experience
1. **Tap to Focus**: Tap anywhere on the camera preview to focus on that point
2. **Visual Feedback**: A white circle animation appears at the tap location (Pixel-style)
3. **Auto-dismiss**: The focus indicator automatically fades out after 1.2 seconds
4. **Haptic Feedback**: Light haptic feedback when tapping

### Technical Implementation

#### Gesture Detection
The tap to focus is implemented using `onTapDown` in the main `GestureDetector` that also handles pinch-to-zoom:

```dart
onTapDown: (details) {
  // Only process tap if not pinching and enough time has passed since last scale
  if (!_isPinching && (_lastScaleUpdateTime == null || 
      DateTime.now().difference(_lastScaleUpdateTime!).inMilliseconds > 300)) {
    _handleTapToFocus(details.localPosition, cameraState);
  }
},
```

#### Preventing Conflicts with Pinch Zoom
To ensure tap-to-focus doesn't interfere with pinch-to-zoom:
1. **Pinching State**: We track `_isPinching` to disable tap during zoom
2. **Time Delay**: 300ms delay after pinch gesture before allowing taps
3. **Scale Detection**: Pinch is only detected when scale differs by > 0.05 from 1.0

#### Focus Indicator Animation
The `FocusIndicator` widget provides Pixel-style visual feedback:
- White circle with subtle shadow for visibility on any background
- Scale animation: Starts at 1.4x and scales down to 0.9x
- Inner circle pulse animation with semi-transparent fill
- Center dot indicator
- Opacity animation: Fades out in the last 30% of the animation
- Total duration: 1.2 seconds

#### Camera Integration
The focus point is set using the camera controller's built-in methods:
```dart
await controller.setExposurePoint(point);
await controller.setFocusPoint(point);
```

### Coordinate Conversion
Tap coordinates are converted from screen space to camera space (0.0 to 1.0):
```dart
final offset = Offset(
  localPosition.dx / size.width,
  localPosition.dy / size.height,
);
```

## Usage Notes
- Works in both portrait and landscape orientations
- Focus point is automatically reset when switching cameras
- The camera may take a moment to adjust focus after tapping
- Some devices may not support manual focus control

## Testing
Run the focus tap tests:
```bash
flutter test test/unit/widgets/focus_tap_test.dart
```