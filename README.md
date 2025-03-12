<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# Cameraly

[![pub package](https://img.shields.io/pub/v/cameraly.svg)](https://pub.dev/packages/cameraly)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A powerful and flexible camera package for Flutter that simplifies camera integration while providing advanced features and customization options. Cameraly builds on top of the official Flutter camera plugin to provide a more developer-friendly API, additional features, and better error handling.

## Features

- 📸 **Easy camera integration**
  - Simple API for camera preview and capture
  - Photo and video modes with quality settings
  - Automatic permission handling
  - Built-in error handling

- 🧭 **Accurate Orientation Detection**
  - Platform-specific method channel for precise device rotation
  - Correctly handles landscape left vs landscape right orientation
  - Ensures photos and videos are captured with proper orientation
  - Works reliably on both Android and iOS

- 🎨 **Flexible Overlay System**
  - Beautiful default camera UI
  - Customizable control positions
  - Support for custom overlays
  - Theme customization

- 📱 **Responsive Design**
  - Adapts to different screen orientations
  - Handles device rotations
  - Supports various aspect ratios
  - Platform-specific optimizations

- 🎮 **Advanced Controls**
  - Tap-to-focus with visual indicator
  - Pinch-to-zoom gesture support
  - Flash mode control (auto, on, off, torch)
  - Exposure adjustment

- 🎬 **Video Features**
  - Duration limits
  - Quality settings
  - Pause/resume support
  - Recording indicator

- 📦 **Media Management**
  - Built-in media stack display
  - Custom storage locations
  - Gallery integration
  - Thumbnail generation

## Platform Support

| Android | iOS |
|:-------:|:---:|
|    ✅    |  ✅  |

## Technical Implementation Details

### Orientation Detection

Cameraly uses a platform-specific method channel approach to accurately detect device orientation:

- On Android, the native `WindowManager.getDefaultDisplay().getRotation()` API is used to get the exact device rotation
- Rotation values are mapped to Flutter's `DeviceOrientation` enum values
- This provides reliable detection of landscape left vs. landscape right orientation
- Fallback mechanisms are in place to ensure compatibility with all devices

This approach is more reliable than using MediaQuery orientation or screen padding to infer orientation, particularly for:
- Devices with symmetrical designs
- Devices with unusual notch placements
- Newer Android devices (e.g., Pixel 8)

## Getting Started

### Prerequisites

Ensure you have:
- Flutter SDK (3.16.0 or higher)
- Dart SDK (3.6.1 or higher)
- For iOS: Xcode 13.0+, iOS 11.0+
- For Android: minSdkVersion 21+

### Installation

Add Cameraly to your `pubspec.yaml`:

```yaml
dependencies:
  cameraly: ^0.1.0
```

Then run:

```bash
flutter pub get
```

### Platform Configuration

#### Android

Add camera permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

#### iOS

Add camera usage descriptions to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos and record videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record videos</string>
```

## Basic Usage

### New Simplified API (Recommended)

Cameraly now provides a significantly simplified API through `CameraPreviewer` - a single widget that manages the entire camera experience for you:

```dart
class CameraScreen extends StatelessWidget {  // StatelessWidget is all you need!
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraPreviewer(
        settings: CameraPreviewSettings(
          // Camera settings
          cameraMode: CameraMode.photoOnly,
          resolution: ResolutionPreset.high,
          
          // UI customization
          showFlashButton: true,
          showSwitchCameraButton: true,
          showMediaStack: true,
          
          // Add a custom "done" button
          customRightButton: FloatingActionButton(
            onPressed: () => Navigator.pop(context),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            child: const Icon(Icons.check),
          ),
          
          // Callbacks
          onCapture: (file) {
            print('Photo captured: ${file.path}');
          },
          onComplete: (mediaList) {
            // Return all captured photos when done
            Navigator.pop(context, mediaList);
          },
        ),
      ),
    );
  }
}
```

The `CameraPreviewer` handles everything for you:
- ✅ Controller creation and initialization
- ✅ Lifecycle management (no need for dispose)
- ✅ State management (no StatefulWidget required)
- ✅ Loading and error states
- ✅ UI overlay and controls
- ✅ Camera switching
- ✅ Media management

### Legacy Approach (Manual Controller Management)

The following examples show the traditional approach with manual controller management, which is still supported but no longer recommended:

```dart
class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameralyController? _controller;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await CameralyController.getAvailableCameras();
    final controller = CameralyController(
      description: cameras.first,
      settings: const CaptureSettings(
        cameraMode: CameraMode.photoOnly,
      ),
    );
    
    await controller.initialize();
    
    // Only update state if widget is still mounted
    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Use CameralyControllerProvider to share controller with descendants
    return Scaffold(
      body: CameralyControllerProvider(
        controller: _controller!,
        child: CameralyPreview(
          controller: _controller!,
          // No need to pass controller to overlay - it gets it from the provider
          overlay: DefaultCameralyOverlay(
            showFlashButton: true,
            showSwitchCameraButton: true,
            onCapture: (file) {
              print('Picture saved to: ${file.path}');
            },
          ),
          // Optional custom loading widget
          loadingBuilder: (context, value) => Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Initializing camera...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### Simplified Controller Sharing

Cameraly provides a convenient way to share the controller between widgets using `CameralyControllerProvider`. This eliminates the need to pass the controller to both `CameralyPreview` and `DefaultCameralyOverlay`:

```dart
// Old approach - controller passed to both widgets
CameralyPreview(
  controller: controller,  
  overlay: DefaultCameralyOverlay(
    controller: controller,  // Duplicate reference
    // other parameters
  ),
)

// New approach - controller is shared automatically
CameralyControllerProvider(
  controller: controller,
  child: CameralyPreview(
    controller: controller,
    overlay: DefaultCameralyOverlay(
      // No need to pass controller here
      // other parameters
    ),
  ),
)
```

The `CameralyControllerProvider` is an `InheritedWidget` that makes the controller available to its descendants. This is particularly useful for custom overlay implementations that need access to the controller.

### Handling Async Initialization

Cameraly provides a clean pattern for handling the asynchronous camera initialization process:

1. Declare your controller as nullable: `CameralyController? _controller;`
2. Initialize it asynchronously in `_initCamera()` method
3. Set the controller in state after successful initialization
4. Use CameralyPreview's `uninitializedBuilder` to show a UI while the controller is being created

This pattern solves the common issue of accessing an uninitialized controller in the build method, which often happens because initialization is asynchronous and the build method may be called before initialization completes.

```dart
// Simplified async initialization pattern
CameralyController? _controller;

@override
void initState() {
  super.initState();
  _initializeAsync();
}

Future<void> _initializeAsync() async {
  final cameras = await CameralyController.getAvailableCameras();
  final controller = CameralyController(...);
  await controller.initialize();
  
  if (mounted) {
    setState(() {
      _controller = controller;
    });
  }
}

@override
Widget build(BuildContext context) {
  return CameralyPreview(
    controller: _controller!,
    overlay: _controller != null ? DefaultCameralyOverlay(...) : null,
    uninitializedBuilder: (context) => YourLoadingWidget(),
  );
}
```

CameralyPreview handles both cases:
- When `_controller` is null (controller not yet created): shows `uninitializedBuilder`
- When `_controller` exists but not initialized: shows `loadingBuilder`
- When `_controller` is fully initialized: shows the camera preview

### Video Recording with Duration Limit

```dart
CameralyPreview(
  controller: _controller,
  overlay: DefaultCameralyOverlay(
    controller: _controller,
    maxVideoDuration: const Duration(seconds: 15),
    onMaxDurationReached: (file) {
      print('Video saved to: ${file.path}');
    },
  ),
)
```

### Custom Overlay

```dart
CameralyPreview(
  controller: _controller,
  overlay: DefaultCameralyOverlay(
    controller: _controller,
    theme: const CameralyOverlayTheme(
      primaryColor: Colors.blue,
      secondaryColor: Colors.white,
      backgroundColor: Colors.black87,
      opacity: 0.8,
    ),
    customLeftButton: YourCustomWidget(),
    customRightButton: YourCustomWidget(),
    topLeftWidget: YourCustomWidget(),
    centerLeftWidget: YourCustomWidget(),
    bottomOverlayWidget: YourCustomWidget(),
  ),
)
```

## Advanced Features

### Media Management

```dart
final mediaManager = CameralyMediaManager(
  maxItems: 30,
  onMediaAdded: (file) async {
    // Handle new media file
  },
);

CameralyPreview(
  controller: _controller,
  overlay: DefaultCameralyOverlay(
    controller: _controller,
    onPictureTaken: (file) => mediaManager.addMedia(file),
  ),
)
```

### Custom Storage Location

```dart
final appDir = await getApplicationDocumentsDirectory();
final savePath = path.join(appDir.path, 'camera');
await Directory(savePath).create(recursive: true);

// Use the path in your media manager
final mediaManager = CameralyMediaManager(
  maxItems: 30,
  onMediaAdded: (file) async {
    final fileName = path.basename(file.path);
    final newPath = path.join(savePath, fileName);
    await File(file.path).copy(newPath);
  },
);
```

## Examples

The package includes several example implementations:

1. Basic camera usage
2. Photo-only mode with custom UI
3. Video recording with duration limits
4. Custom overlay implementation
5. Persistent storage example
6. Display customization demo

Check the [example](example) folder for complete implementations.

## Documentation

- [Quick Start Guide](QUICK_START.md)
- [API Documentation](https://pub.dev/documentation/cameraly/latest/)
- [Project Structure](PROJECT_STRUCTURE.md)
- [Development Tasks](TASKS.md)

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on top of the official [camera](https://pub.dev/packages/camera) plugin
- Inspired by the needs of real-world camera applications
- Special thanks to all contributors

## Support

If you find a bug or want a feature, please file an [issue](https://github.com/InspectlyMads/cameraly/issues).

## Zoom Controls

Cameraly provides built-in zoom functionality with intuitive pinch-to-zoom gestures. The zoom is handled internally by the `CameralyController` and includes:

- Automatic sensitivity adjustment for smoother zooming
- Visual zoom level indicator
- Zoom slider for precise control
- Zoom button for quick access

The zoom functionality is automatically enabled when using the default overlay with `showZoomControls: true`.

```dart
// Example of using the built-in zoom functionality
CameralyPreview(
  controller: _controller,
  overlay: DefaultCameralyOverlay(
    controller: _controller,
    showZoomControls: true, // Enable zoom controls in the UI
  ),
  // The onScale callback is optional as zoom is handled internally
  onScale: (scale) {
    // Optional: Use this callback to update UI elements or perform additional actions
    setState(() {
      _currentZoom = _controller.value.zoomLevel;
    });
  },
)
```

You can also programmatically control the zoom level:

```dart
// Set zoom level directly
await _controller.setZoomLevel(2.0);

// Get current zoom level
final currentZoom = _controller.value.zoomLevel;

// Get min/max zoom levels
final minZoom = await _controller.getMinZoomLevel();
final maxZoom = await _controller.getMaxZoomLevel();
```

## Orientation Detection

Cameraly includes a reliable native orientation detection system that ensures your camera captures photos and videos with the correct orientation on all devices.

### OrientationChannel

The `OrientationChannel` class provides device rotation information using platform-specific native implementations:

```dart
// Get current device orientation
final deviceOrientation = await OrientationChannel.getPlatformOrientation();

// Check if device is in landscape left orientation
final isLandscapeLeft = await OrientationChannel.isLandscapeLeft();

// For debugging, get the raw rotation value (0, 1, 2, or 3)
final rawRotation = await OrientationChannel.getRawRotationValue();
```

The orientation detection works by using a dedicated method channel to communicate directly with native platform code:

- **Android**: Uses `WindowManager.getDefaultDisplay().getRotation()` to get the exact device rotation value
- **iOS**: Uses `UIDevice.current.orientation` with fallback to `UIApplication.shared.statusBarOrientation`

This approach is far more reliable than using Flutter's MediaQuery or view padding, especially for distinguishing between landscape left and landscape right orientations. The `CameralyController` automatically uses this system to ensure photos and videos are captured with the correct orientation.

## Initialization

Initialize the camera with a single, flexible method:

```dart
// Initialize for both photo and video (default)
final controller = await CameralyController.initializeCamera(
  settings: CaptureSettings(
    cameraMode: CameraMode.both,
    resolution: ResolutionPreset.high,
    enableAudio: true,
  )
);

// Initialize for photos only
final photoController = await CameralyController.initializeCamera(
  settings: CaptureSettings(
    cameraMode: CameraMode.photoOnly,
    resolution: ResolutionPreset.high,
    flashMode: FlashMode.auto,
  )
);

// Initialize for videos only
final videoController = await CameralyController.initializeCamera(
  settings: CaptureSettings(
    cameraMode: CameraMode.videoOnly,
    resolution: ResolutionPreset.high,
    enableAudio: true,
  )
);
```

> **Note:** The specialized methods `initializeForPhotos()` and `initializeForVideos()` are deprecated and will be removed in a future version. Please use `initializeCamera()` with the appropriate `CameraMode` instead.

### Smart Camera Preview

CameralyPreview intelligently handles all camera states internally:

- Shows a loading indicator when the camera is initializing
- Displays permission request UI when camera access is denied
- Automatically renders the camera feed once ready
- Shows error messages when problems occur

This means you don't need to manually check `controller.value.isInitialized` in your code - just place the CameralyPreview in your widget tree and it handles everything.