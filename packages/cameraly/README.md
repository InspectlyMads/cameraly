# Cameraly

A comprehensive Flutter camera package with advanced features including orientation handling, flash modes, zoom controls, and focus management.

## Features

- 📸 **Camera capture** - Photos and videos with proper orientation handling
- 🔦 **Smart flash modes** - Context-aware flash options (Photo: Off/Auto/On, Video: Off/Torch)
- 🔍 **Zoom controls** - Smooth zoom with device-specific presets
- 🎯 **Tap to focus** - Automatic exposure and focus adjustment
- 📐 **Grid overlay** - Rule of thirds composition guide
- 🔄 **Orientation support** - Correct metadata for all device orientations
- 🎨 **Customizable UI** - Adapt layouts based on device orientation
- ⚡ **Performance optimized** - Efficient state management with Riverpod
- 🛡️ **Permission handling** - Race condition protection

## Getting Started

### Installation

Add `cameraly` to your `pubspec.yaml`:

```yaml
dependencies:
  cameraly: ^0.1.0
```

### Platform Setup

**Important**: Permission descriptions must be added to YOUR app's platform files, not the package. The package will request permissions at runtime, but iOS and Android require these descriptions to be present in the consuming app.

#### iOS

Add the following to your app's `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos and videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record videos</string>
<!-- Only if captureLocationMetadata is enabled (default: true) -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to add GPS metadata to photos</string>
```

#### Android

Add the following permissions to your app's `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Only if captureLocationMetadata is enabled (default: true) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- For saving media -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
```

### Basic Usage

```dart
import 'package:cameraly/cameraly.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Wrap your app with ProviderScope
void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

// Use the CameraScreen widget
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraScreen(
        initialMode: CameraMode.photo,
        onMediaCaptured: (MediaItem media) {
          // Handle captured photo/video
          print('Captured: ${media.path}');
        },
      ),
    );
  }
}
```

### Advanced Configuration

```dart
CameraScreen(
  initialMode: CameraMode.photo, // or .video, .combined
  showGridButton: true, // Show grid toggle button
  showGalleryButton: true, // Show gallery button
  showCheckButton: true, // Show check/done button
  captureLocationMetadata: true, // Capture GPS metadata (default: true)
  onMediaCaptured: (MediaItem media) {
    // Handle captured media
  },
  onGalleryPressed: () {
    // Handle gallery button tap
  },
  onCheckPressed: () {
    // Handle check button tap
  },
  onError: (String error) {
    // Handle errors
  },
)
```

### Custom UI

```dart
CameraScreen(
  initialMode: CameraMode.photo,
  customWidgets: CameraCustomWidgets(
    galleryButton: MyCustomGalleryWidget(),
    checkButton: MyCustomCheckWidget(),
    captureButton: MyCustomCaptureButton(),
    flashControl: MyCustomFlashControl(),
    leftSideWidget: MyCustomControlPanel(),
  ),
  onMediaCaptured: (media) {
    // Handle capture
  },
)
```

## Architecture

The package uses a service-oriented architecture:

- **CameraService** - Core camera operations
- **OrientationService** - Device orientation handling
- **MediaService** - File operations
- **PermissionService** - Runtime permissions
- **CameraUIService** - UI helpers

State management is handled with Riverpod providers for reactive updates.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.