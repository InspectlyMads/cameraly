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

### Photo Only Camera

```dart
class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameralyController _controller;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await CameralyController.getAvailableCameras();
    _controller = CameralyController(
      description: cameras.first,
      settings: const CaptureSettings(
        cameraMode: CameraMode.photoOnly,
      ),
    );
    await _controller.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameralyPreview(
        controller: _controller,
        overlay: DefaultCameralyOverlay(
          controller: _controller,
          onPictureTaken: (file) {
            print('Picture saved to: ${file.path}');
          },
        ),
      ),
    );
  }
}
```

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