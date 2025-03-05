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

A powerful and flexible camera package for Flutter that simplifies camera integration while providing advanced features and customization options.

Cameraly builds on top of the official Flutter camera plugin to provide a more developer-friendly API, additional features, and better error handling.

## Features

- 📸 **Easy camera integration** - Simple API for camera preview, photo capture, and video recording
- 🔄 **Seamless switching** between front and back cameras
- 📱 **Responsive UI** that adapts to different screen orientations and device sizes
- 🔍 **Zoom controls** with intuitive pinch-to-zoom gesture support
- 🔦 **Flash mode control** (auto, on, off) for photo capture
- 🎯 **Tap-to-focus** functionality with visual focus indicator
- 📊 **Exposure control** for manual brightness adjustment
- 🎚️ **Resolution settings** for both photo and video capture
- 🎬 **Video recording** with customizable quality settings
- 🔒 **Permission handling** with built-in request flow and UI
- 🛠️ **Extensive customization** options for UI elements and camera behavior
- 📱 **Platform-specific optimizations** for Android and iOS

## Platform Support

| Android | iOS |
|:-------:|:---:|
|    ✅    |  ✅  |

## Getting Started

### Prerequisites

Ensure you have:
- Flutter SDK (2.10.0 or higher)
- Dart SDK (2.16.0 or higher)
- For iOS: Xcode 13.0+, iOS 11.0+
- For Android: Android Studio, minSdkVersion 21+

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

## Usage

### Basic Camera Preview

```dart
import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

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
    _controller = CameralyController();
    await _controller.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      body: CameralyPreview(
        controller: _controller,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final photo = await _controller.takePicture();
          // Use the captured photo
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}
```

### Handling Permissions

Cameraly includes built-in permission handling:

```dart
final permissionResult = await _controller.requestCameraPermission();
if (permissionResult == PermissionStatus.granted) {
  // Camera permission granted, proceed with camera initialization
} else {
  // Show permission denied UI
}
```

### Switching Cameras

```dart
// Switch between front and back cameras
await _controller.switchCamera();
```

### Flash Control

```dart
// Cycle through flash modes (auto, on, off)
await _controller.cycleFlashMode();

// Or set a specific flash mode
await _controller.setFlashMode(FlashMode.auto);
```

### Video Recording

```dart
// Start recording
await _controller.startVideoRecording();

// Stop recording and get the video file
final videoFile = await _controller.stopVideoRecording();
```

### Advanced Configuration

```dart
// Configure camera with specific settings
_controller = CameralyController(
  photoSettings: PhotoSettings(
    resolution: PhotoResolution.max,
    flashMode: FlashMode.auto,
  ),
  videoSettings: VideoSettings(
    resolution: VideoResolution.high,
    enableAudio: true,
  ),
);
```

## Complete Example App

A complete example application is included in the `example` directory of the repository. This example demonstrates:

- Responsive camera preview that adapts to different screen orientations
- Photo capture with flash control (auto, on, off)
- Video recording with start/stop functionality
- Front/back camera switching
- Tap-to-focus with visual indicator
- Pinch-to-zoom gesture support
- Permission handling flow
- Proper lifecycle management
- Orientation handling
- UI controls with proper layout in both portrait and landscape

To run the example app:

```bash
cd example
flutter pub get
flutter run
```

The example app provides a comprehensive implementation that you can use as a reference for your own camera integration.

## API Documentation

For detailed API documentation, visit the [API reference](https://pub.dev/documentation/cameraly/latest/).

## Contributing

Contributions are welcome! If you find a bug or want a feature, please open an issue.

If you want to contribute code, please:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please make sure your code follows the project's style guidelines and includes appropriate tests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
