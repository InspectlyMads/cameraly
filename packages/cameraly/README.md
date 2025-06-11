# Cameraly

A comprehensive Flutter camera package with advanced features including orientation handling, metadata capture, custom UI, and smart permissions.

[![pub package](https://img.shields.io/pub/v/cameraly.svg)](https://pub.dev/packages/cameraly)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 📸 **Photo & Video Capture** - High-quality photo and video recording
- 🔄 **Orientation Handling** - Automatic orientation detection and correction
- 📍 **Metadata Capture** - GPS location, device sensors, and camera settings
- 🎨 **Custom UI** - Replace UI elements with your own widgets
- 🔐 **Smart Permissions** - Mode-specific permission handling
- 🎯 **Tap to Focus** - Touch anywhere to focus
- 🔍 **Zoom Controls** - Pinch to zoom with visual feedback
- ⚡ **Flash Modes** - Context-aware flash options
- 📐 **Grid Overlay** - Rule of thirds composition guide
- ⏱️ **Photo Timer** - Countdown timer for photos
- 💾 **Memory Management** - Automatic cleanup and optimization

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  cameraly: ^1.0.0
```

## Basic Usage

```dart
import 'package:cameraly/cameraly.dart';

// Simple camera screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CameraScreen(
      mode: CameraMode.combined,
      onMediaCaptured: (XFile? media) {
        // Handle captured photo/video
        print('Media captured: ${media?.path}');
      },
    ),
  ),
);
```

## Advanced Configuration

### Custom Settings

```dart
CameraScreen(
  mode: CameraMode.photo,
  settings: CameraSettings(
    photoQuality: PhotoQuality.high,
    videoQuality: VideoQuality.fullHd,
    aspectRatio: CameraAspectRatio.ratio_16_9,
    photoTimerSeconds: 5,
    enableSounds: true,
    enableHaptics: true,
    autoSaveToGallery: true,
  ),
  onMediaCaptured: (media) { /* ... */ },
)
```

### Custom UI

```dart
CameraScreen(
  customWidgets: CameraCustomWidgets(
    topControls: MyCustomTopBar(),
    bottomControls: MyCustomBottomBar(),
    flashButton: MyCustomFlashButton(),
    gridButton: MyCustomGridButton(),
    switchCameraButton: MyCustomSwitchButton(),
  ),
  onMediaCaptured: (media) { /* ... */ },
)
```

### Metadata Capture

```dart
CameraScreen(
  captureLocationMetadata: true, // Enable GPS
  onMediaCaptured: (media) async {
    // Access metadata
    final item = await MediaItem.fromFile(File(media.path));
    print('Location: ${item.metadata?.latitude}, ${item.metadata?.longitude}');
    print('Device: ${item.metadata?.deviceModel}');
    print('Zoom: ${item.metadata?.zoomLevel}');
  },
)
```

## Localization

Cameraly supports custom localization for all UI strings. You can provide your own translations:

```dart
// Create custom localization class
class MyCameraLocalizations extends CameralyLocalizations {
  @override
  String get modePhoto => 'photo_mode'.tr(); // Using easy_localization
  
  @override
  String get modeVideo => 'video_mode'.tr();
  
  @override
  String get flashOff => 'flash_off'.tr();
  
  // ... override all strings
}

// Set custom localization before using camera
void main() {
  CameralyLocalizations.setInstance(MyCameraLocalizations());
  runApp(MyApp());
}
```

## Memory Management

Cameraly includes built-in memory management to prevent memory leaks and optimize performance:

```dart
// Start automatic memory cleanup
MemoryManager.startPeriodicCleanup(
  interval: Duration(hours: 12),
  maxMediaAge: Duration(days: 7),
  maxMediaFiles: 500,
);

// Manual cleanup
await MemoryManager.performCleanup();

// Check memory usage
final stats = await MemoryManager.getMemoryStats();
print('Memory usage: ${stats.totalMemoryMB}MB');
```

## Platform Setup

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos and videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record videos</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to tag photos with location</string>
```

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

## Camera Modes

- `CameraMode.photo` - Photo only (no microphone permission needed)
- `CameraMode.video` - Video only
- `CameraMode.combined` - Both photo and video

## Error Handling

```dart
CameraScreen(
  onError: (error) {
    // Handle camera errors
    if (error.type == CameraErrorType.permissionDenied) {
      // Show permission dialog
    }
  },
)
```

## Documentation

- [Implementation Guide](IMPLEMENTATION_GUIDE.md) - Complete step-by-step implementation guide
- [Quick Start Guide](QUICK_START.md) - Quick reference for common use cases
- [API Reference](API_REFERENCE.md) - Complete API documentation
- [Example App](example/) - Full working example with all features

## License

MIT License - see LICENSE file for details