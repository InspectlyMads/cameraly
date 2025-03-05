# Cameraly - Context Guide

This document serves as a quick reference guide to understand the Cameraly project structure, architecture, and development status. It's designed to provide rapid context during development sessions.

## Project Overview

Cameraly is a Flutter package that enhances the official Flutter camera plugin with a more developer-friendly API, additional features, and better error handling. It aims to simplify camera integration while providing advanced features and customization options.

## Key Components

### Core Classes

1. **CameralyController** (`lib/src/cameraly_controller.dart`)
   - Main class for camera operations
   - Manages camera state using ValueNotifier
   - Handles initialization, photo/video capture, and camera settings

2. **CameralyPreview** (`lib/src/cameraly_preview.dart`)
   - UI widget that displays the camera feed
   - Handles user interactions (tap-to-focus, pinch-to-zoom)
   - Manages the overlay system

3. **CameralyValue** (`lib/src/cameraly_value.dart`)
   - State container for camera information
   - Tracks initialization status, recording status, and settings

### Overlay System

1. **CameralyOverlayType** (`lib/src/overlays/cameraly_overlay_type.dart`)
   - Enum defining overlay types (none, default, custom)

2. **DefaultCameralyOverlay** (`lib/src/overlays/default_cameraly_overlay.dart`)
   - Ready-to-use overlay with standard camera controls
   - Includes capture button, flash toggle, camera switch, etc.

3. **CameralyOverlayTheme** (`lib/src/overlays/cameraly_overlay_theme.dart`)
   - Theme class for styling camera overlays

### Settings and Types

1. **CaptureSettings** (`lib/src/types/capture_settings.dart`)
   - Base class for camera capture settings

2. **PhotoSettings** (`lib/src/types/photo_settings.dart`)
   - Settings specific to photo capture

3. **VideoSettings** (`lib/src/types/video_settings.dart`)
   - Settings specific to video recording

4. **CameraDevice** (`lib/src/types/camera_device.dart`)
   - Information about available camera devices

### Utilities

1. **CameralyUtils** (`lib/src/utils/cameraly_utils.dart`)
   - Helper functions for camera operations

2. **PermissionHandler** (`lib/src/utils/permission_handler.dart`)
   - Utilities for requesting and checking permissions

## Architecture

Cameraly follows a clean architecture approach with clear separation of concerns:

1. **UI Layer**: CameralyPreview and overlay components
2. **Controller Layer**: CameralyController manages camera operations
3. **State Management**: CameralyValue using ValueNotifier for reactive updates
4. **Settings Layer**: Hierarchical settings classes for configuration
5. **Utility Layer**: Helper functions and permission handling

## State Management

Cameraly uses Flutter's built-in ValueNotifier for state management, which provides a simple and efficient way to handle reactive updates:

1. **CameralyController extends ValueNotifier<CameralyValue>**
   - The controller itself is a ValueNotifier, exposing the current camera state
   - UI components can listen to state changes using ValueListenableBuilder

2. **CameralyValue is immutable**
   - All state updates create a new CameralyValue instance
   - Uses copyWith pattern for efficient state updates

3. **State Update Flow**
   - User action or system event occurs
   - Controller method is called
   - Controller updates internal state
   - Controller calls `value = value.copyWith(...)` to update the ValueNotifier
   - UI rebuilds in response to the value change

4. **Example Usage**
   ```dart
   ValueListenableBuilder<CameralyValue>(
     valueListenable: controller,
     builder: (context, value, child) {
       return value.isInitialized
         ? CameraPreview(controller.cameraController!)
         : const CircularProgressIndicator();
     },
   )
   ```

## Development Status

- **Current Stage**: Pre-publishing Preparation (93% complete)
- **Last Completed Task**: Implemented overlay system
- **Next Tasks**: 
  - Implement tests
  - Update package configuration
  - Finalize documentation

## Key Features

- 📸 Easy camera integration
- 🔄 Seamless camera switching
- 📱 Responsive UI for different orientations
- 🔍 Zoom controls with gestures
- 🔦 Flash mode control
- 🎯 Tap-to-focus with visual indicator
- 📊 Exposure control
- 🎚️ Resolution settings
- 🎬 Video recording
- 🔒 Permission handling
- 🛠️ Extensive customization options
- 🎨 Flexible overlay system

## Usage Patterns

```dart
// 1. Initialize controller
final controller = CameralyController(description: cameras.first);
await controller.initialize();

// 2. Display preview with default overlay
CameralyPreview(
  controller: controller,
  onTap: (position) {
    controller.setFocusAndExposurePoint(position);
  },
)

// 3. Capture media
final photo = await controller.takePicture();
// OR
await controller.startVideoRecording();
final video = await controller.stopVideoRecording();

// 4. Control camera
await controller.switchCamera();
await controller.toggleFlash();
await controller.setZoomLevel(2.0);

// 5. Custom overlay
CameralyPreview(
  controller: controller,
  overlayType: CameralyOverlayType.custom,
  customOverlay: YourCustomOverlay(controller: controller),
)
```

## Common Patterns and Idioms

### Error Handling

```dart
try {
  await controller.initialize();
} catch (e) {
  if (e is CameraException) {
    // Handle camera-specific errors
    if (e.code == 'cameraPermission') {
      // Handle permission denied
    }
  } else {
    // Handle general errors
  }
}
```

### Lifecycle Management

```dart
@override
void initState() {
  super.initState();
  _initCamera();
}

@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

### Permission Flow

```dart
final permissionResult = await controller.requestCameraPermission();
if (permissionResult == PermissionStatus.granted) {
  await controller.initialize();
} else {
  // Show permission denied UI
}
```

## Example App

The package includes a comprehensive example app in the `example/` directory that demonstrates all features:

- `example/lib/main.dart`: Entry point with navigation
- `example/lib/cameraly_example.dart`: Basic usage example
- `example/lib/overlay_example.dart`: Overlay system demonstration

## Testing Strategy

The package follows a comprehensive testing approach:

1. **Unit Tests**: Test individual components in isolation
2. **Widget Tests**: Test UI components and interactions
3. **Integration Tests**: Test components working together
4. **Example App Tests**: Verify functionality in real-world scenarios

## Platform Support

- ✅ Android
- ✅ iOS

## Development Roadmap

### Current Version (v0.1.0)
- Core camera functionality
- Basic UI components
- Permission handling

### Next Release (v0.2.0)
- Face detection
- QR/Barcode scanning
- Image filters

### Future Releases
- Custom overlays
- Advanced camera controls
- ML integration 