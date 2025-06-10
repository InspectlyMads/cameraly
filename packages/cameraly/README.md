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

#### iOS

Add the following to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos and videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record videos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to save photos and videos</string>
```

#### Android

Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
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
        onMediaCaptured: (MediaItem media) {
          // Handle captured photo/video
          print('Captured: ${media.path}');
        },
        showDebugInfo: false, // Set to true for orientation debug overlay
      ),
    );
  }
}
```

### Advanced Configuration

```dart
CameraScreen(
  onMediaCaptured: (MediaItem media) {
    // Handle captured media
  },
  onError: (String error) {
    // Handle errors
  },
  showGrid: true, // Show composition grid
  showDebugInfo: false, // Show orientation debug info
  enableZoom: true, // Enable zoom controls
  enableFocus: true, // Enable tap to focus
  flashMode: FlashMode.auto, // Initial flash mode
  cameraMode: CameraMode.photo, // Initial camera mode
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