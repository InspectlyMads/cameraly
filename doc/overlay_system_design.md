# Cameraly Overlay System Design

This document outlines the design for the Cameraly overlay system, which allows both default and custom overlays to be used with the `CameralyPreview` widget.

## Overview

The overlay system provides three modes:
1. **No Overlay**: Just the camera preview
2. **Default Overlay**: A configurable, pre-built camera UI
3. **Custom Overlay**: User-provided widgets for complete customization

## Component Architecture

### Core Components

#### 1. CameralyOverlayType

```dart
enum CameralyOverlayType {
  /// No overlay - just the camera preview
  none,
  
  /// Use the default overlay provided by the package
  defaultOverlay,
  
  /// Use a custom overlay provided by the developer
  custom,
}
```

#### 2. OverlayPosition

```dart
enum OverlayPosition {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}
```

#### 3. CameralyOverlayTheme

```dart
class CameralyOverlayTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final double opacity;
  final TextStyle labelStyle;
  final double iconSize;
  final double buttonSize;
  final BorderRadius borderRadius;
  
  // Constructor with default values
  const CameralyOverlayTheme({
    this.primaryColor = Colors.white,
    this.secondaryColor = Colors.blue,
    this.backgroundColor = Colors.black54,
    this.opacity = 0.7,
    this.labelStyle = const TextStyle(color: Colors.white),
    this.iconSize = 24.0,
    this.buttonSize = 56.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(28.0)),
  });
  
  // Copy with method for modifications
  CameralyOverlayTheme copyWith({...});
}
```

### Default Overlay Components

#### 1. DefaultCameralyOverlay

```dart
class DefaultCameralyOverlay extends StatelessWidget {
  final CameralyController controller;
  final CameralyOverlayTheme theme;
  
  // Control visibility
  final bool showCaptureButton;
  final bool showFlashToggle;
  final bool showCameraSwitchButton;
  final bool showZoomControls;
  final bool showGalleryThumbnail;
  
  // Control positioning
  final OverlayPosition captureButtonPosition;
  final OverlayPosition flashTogglePosition;
  final OverlayPosition cameraSwitchPosition;
  final OverlayPosition zoomControlsPosition;
  final OverlayPosition galleryThumbnailPosition;
  
  // Constructor with default values
  const DefaultCameralyOverlay({
    required this.controller,
    this.theme = const CameralyOverlayTheme(),
    this.showCaptureButton = true,
    this.showFlashToggle = true,
    this.showCameraSwitchButton = true,
    this.showZoomControls = true,
    this.showGalleryThumbnail = false,
    this.captureButtonPosition = OverlayPosition.bottomCenter,
    this.flashTogglePosition = OverlayPosition.topRight,
    this.cameraSwitchPosition = OverlayPosition.topLeft,
    this.zoomControlsPosition = OverlayPosition.centerRight,
    this.galleryThumbnailPosition = OverlayPosition.bottomLeft,
  });
  
  @override
  Widget build(BuildContext context) {
    // Implementation
  }
}
```

#### 2. Individual Control Widgets

- `CaptureModeButton`: Toggle between photo and video modes
- `CaptureButton`: Take photo or start/stop recording
- `FlashModeToggle`: Cycle through flash modes
- `CameraSwitchButton`: Switch between front and back cameras
- `ZoomControls`: Slider or buttons for zoom control
- `FocusIndicator`: Visual indicator for tap-to-focus
- `RecordingTimer`: Timer display during video recording
- `GalleryThumbnail`: Thumbnail of the last captured media

### Integration with CameralyPreview

```dart
class CameralyPreview extends StatelessWidget {
  final CameralyController controller;
  final CameralyOverlayType overlayType;
  final DefaultCameralyOverlay? defaultOverlay;
  final Widget? customOverlay;
  final Function(Offset)? onTap;
  final Function(double)? onScale;
  
  const CameralyPreview({
    required this.controller,
    this.overlayType = CameralyOverlayType.defaultOverlay,
    this.defaultOverlay,
    this.customOverlay,
    this.onTap,
    this.onScale,
  });
  
  @override
  Widget build(BuildContext context) {
    // Implementation
  }
}
```

## Usage Examples

### Basic Usage with Default Overlay

```dart
CameralyPreview(
  controller: controller,
  overlayType: CameralyOverlayType.defaultOverlay,
)
```

### Customized Default Overlay

```dart
CameralyPreview(
  controller: controller,
  overlayType: CameralyOverlayType.defaultOverlay,
  defaultOverlay: DefaultCameralyOverlay(
    theme: CameralyOverlayTheme(
      primaryColor: Colors.amber,
      secondaryColor: Colors.deepOrange,
      buttonSize: 64.0,
    ),
    showFlashToggle: false,
    captureButtonPosition: OverlayPosition.bottomCenter,
    cameraSwitchPosition: OverlayPosition.topRight,
  ),
)
```

### Custom Overlay

```dart
CameralyPreview(
  controller: controller,
  overlayType: CameralyOverlayType.custom,
  customOverlay: Builder(
    builder: (context) {
      return Stack(
        children: [
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => controller.takePicture(),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                ),
              ),
            ),
          ),
          // Other custom UI elements
        ],
      );
    },
  ),
)
```

## Implementation Strategy

1. **Phase 1**: Define the core interfaces and enums
2. **Phase 2**: Implement the default overlay with basic controls
3. **Phase 3**: Modify CameralyPreview to support overlay types
4. **Phase 4**: Add advanced controls and customization options
5. **Phase 5**: Document and provide examples

## File Structure

```
lib/
  src/
    overlays/
      cameraly_overlay_type.dart
      overlay_position.dart
      cameraly_overlay_theme.dart
      default_cameraly_overlay.dart
      widgets/
        capture_button.dart
        flash_toggle.dart
        camera_switch_button.dart
        focus_indicator.dart
        zoom_controls.dart
        recording_timer.dart
        gallery_thumbnail.dart
```

## Considerations

1. **Performance**: Ensure overlays don't impact camera preview performance
2. **Responsiveness**: Overlays should adapt to different screen sizes and orientations
3. **Accessibility**: Controls should be accessible and support semantics
4. **Theming**: Support both light and dark themes
5. **Extensibility**: Allow for easy addition of new controls in the future 