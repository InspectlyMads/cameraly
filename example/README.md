# Cameraly Example App

This is a complete example application demonstrating the features and capabilities of the Cameraly package. The app provides a full-featured camera implementation with photo capture, video recording, and various camera controls.

## Features Demonstrated

- 📸 **Photo capture** with flash control (auto, on, off)
- 🎬 **Video recording** with start/stop functionality
- 🔄 **Camera switching** between front and back cameras
- 🔍 **Zoom control** with pinch-to-zoom gesture
- 🎯 **Tap-to-focus** with visual focus indicator
- 📱 **Responsive UI** that adapts to different screen orientations
- 🔒 **Permission handling** with proper request flow
- 🔄 **Lifecycle management** for proper camera resource handling

## Code Structure

The example app is organized as follows:

### Main Components

1. **MyApp**: The root application widget that sets up the MaterialApp and theme.

2. **LandingPage**: The initial screen that requests camera permissions and provides a welcome UI.

3. **CameraScreen**: The main camera interface that handles camera initialization, preview, and capture operations.

4. **CameraApp**: An alternative entry point that can be used when camera permissions are already granted.

### Key Implementation Details

#### Permission Handling

The app demonstrates proper permission handling using the `permission_handler` package:

```dart
Future<void> _requestCameraAccess(BuildContext context) async {
  final status = await Permission.camera.request();
  if (status.isGranted) {
    final cameras = await availableCameras();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => CameraScreen(cameras: cameras))
      );
    }
  } else {
    // Show permission denied message
  }
}
```

#### Camera Initialization

The app properly initializes the camera with appropriate error handling:

```dart
Future<void> _initializeCamera() async {
  _controller = CameraController(
    widget.cameras[_isFrontCamera ? 1 : 0], 
    ResolutionPreset.max, 
    enableAudio: true
  );

  try {
    await _controller.initialize();
    // Additional setup...
  } catch (e) {
    // Error handling...
  }
}
```

#### Camera Initialization

The app demonstrates the simplified camera initialization with appropriate error handling:

```dart
Future<void> _initCamera() async {
  try {
    // Simplified camera initialization with the convenience method
    final controller = await CameralyController.initializeCamera();
    
    if (controller == null) {
      // Handle initialization failure
      return;
    }
    
    _controller = controller;
    setState(() {
      _isInitialized = true;
    });
    
    // Additional setup...
  } catch (e) {
    // Error handling...
  }
}
```

For more control, you can specify camera index and settings:

```dart
// Initialize with the front camera
final controller = await CameralyController.initializeCamera(
  cameraIndex: 1, // Front camera
  settings: CaptureSettings(
    resolution: ResolutionPreset.high,
    enableAudio: true,
    flashMode: FlashMode.auto,
  ),
);
```

#### Responsive Layout

The app handles both portrait and landscape orientations with a responsive layout:

```dart
final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
// Different layout logic based on orientation
```

#### Tap-to-Focus Implementation

The app implements tap-to-focus with visual feedback:

```dart
Future<void> _handleTapToFocus(Offset normalizedPoint) async {
  if (!_controller.value.isInitialized) return;

  try {
    await _controller.setFocusPoint(normalizedPoint);
    await _controller.setExposurePoint(normalizedPoint);
    // Visual feedback...
  } catch (e) {
    // Error handling...
  }
}
```

#### Flash Mode Control

The app demonstrates cycling through flash modes:

```dart
Future<void> _cycleFlashMode() async {
  if (!_controller.value.isInitialized || _isVideoMode || _isFrontCamera) return;

  final modes = [FlashMode.auto, FlashMode.always, FlashMode.off];
  final nextIndex = (modes.indexOf(_flashMode) + 1) % modes.length;
  final newMode = modes[nextIndex];

  try {
    await _controller.setFlashMode(newMode);
    setState(() {
      _flashMode = newMode;
    });
  } catch (e) {
    // Error handling...
  }
}
```

## Running the Example

To run this example:

1. Ensure you have Flutter installed and set up
2. Clone the repository
3. Navigate to the `example` directory
4. Run `flutter pub get` to install dependencies
5. Connect a device or start an emulator
6. Run `flutter run` to start the app

## Learning from the Example

This example demonstrates best practices for camera implementation in Flutter:

- Proper permission handling
- Lifecycle management with WidgetsBindingObserver
- Error handling for camera operations
- Responsive UI for different orientations
- Handling platform-specific camera behaviors
- Providing visual feedback for user interactions

You can use this example as a reference for implementing camera functionality in your own Flutter applications.

# Cameraly Custom Widget Slots

This example demonstrates how to use the custom widget slots in the Cameraly package to add your own UI elements to the camera overlay.

## Available Widget Slots

The `DefaultCameralyOverlay` provides three customizable widget slots:

1. **topLeftWidget**: Positioned in the top-left corner of the screen
2. **centerLeftWidget**: Positioned in the center-left area of the screen
3. **bottomOverlayWidget**: Positioned above the capture button and mode toggle

## Examples

### 1. Placeholder Demo

The `placeholder_demo.dart` file shows how to enable the placeholder widgets to visualize where each custom widget slot will appear. This is useful during development to understand the positioning of each slot.

```dart
DefaultCameralyOverlay(
  controller: cameralyController,
  showPlaceholders: true, // Set to true to see colored placeholders
)
```

### 2. Custom Widgets Demo

The `custom_widgets_demo.dart` file demonstrates how to add your own custom widgets to each slot:

```dart
DefaultCameralyOverlay(
  controller: cameralyController,
  topLeftWidget: _buildExposureControl(),
  centerLeftWidget: _buildGridToggle(),
  bottomOverlayWidget: _buildCameraInfo(),
)
```

## Running the Examples

1. Make sure you have Flutter installed and set up
2. Navigate to the example directory
3. Run the placeholder demo:
   ```
   flutter run -t lib/placeholder_demo.dart
   ```
4. Run the custom widgets demo:
   ```
   flutter run -t lib/custom_widgets_demo.dart
   ```

## Screenshots

### Placeholder Demo
![Placeholder Demo](screenshots/placeholder_demo.png)

### Custom Widgets Demo
![Custom Widgets Demo](screenshots/custom_widgets_demo.png)

## Implementation Notes

- The placeholders are only visible when `showPlaceholders` is set to `true`
- In production, set `showPlaceholders` to `false` to hide the placeholders when no custom widgets are provided
- The widget slots adapt to different screen orientations (portrait and landscape)
- You can provide any Flutter widget to these slots, including buttons, sliders, text, or complex custom UI components
