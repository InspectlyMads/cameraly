# Cameraly

A comprehensive Flutter camera package with advanced features including orientation handling, metadata capture, custom UI, and smart permissions management.

[![pub package](https://img.shields.io/pub/v/cameraly.svg)](https://pub.dev/packages/cameraly)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

### 📸 Core Camera Features
- **Photo & Video Capture** - High-quality photo and video recording
- **Multiple Camera Modes** - Photo, Video, and Combined modes
- **Front/Back Camera** - Easy camera switching with smooth transitions
- **Flash Control** - Smart flash modes (Off/Auto/On for photos, Off/Torch for video)
- **Zoom Control** - Pinch-to-zoom and slider control with smooth animations
- **Focus Control** - Tap-to-focus with visual feedback
- **Grid Overlay** - Rule of thirds grid for better composition

### 🎯 Advanced Features
- **Orientation Handling** - Correct photo/video orientation regardless of device position
- **Location Metadata** - Optional GPS metadata capture (EXIF)
- **Custom Aspect Ratios** - 16:9, 4:3, 1:1, or full sensor
- **Photo Timer** - Configurable countdown timer (3s, 5s, 10s)
- **Video Duration Limits** - Set maximum recording duration with countdown
- **Photo Quality Control** - Low, Medium, High, Very High, Max quality options
- **Smart Permissions** - Intelligent permission handling with race condition prevention

### 🎨 UI Customization
- **Custom Widgets** - Replace any UI element with your own widgets
- **Theming Support** - Full control over colors, styles, and layouts
- **Orientation-Specific Layouts** - Optimized UI for portrait and landscape
- **Localization Ready** - Easy to add multiple language support

### 📱 Platform Support
- **iOS** ✅ (iOS 11.0+)
- **Android** ✅ (API 21+)
- **Web** 🚧 (Coming soon)
- **macOS** 🚧 (Coming soon)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  cameraly: ^1.0.1
```

### iOS Setup

Add the following to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos and videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record videos with audio</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to add GPS data to photos</string>
```

### Android Setup

Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## Quick Start

### Basic Usage

```dart
import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

// Simple photo capture
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CameraScreen(
      initialMode: CameraMode.photo,
      onMediaCaptured: (MediaItem media) {
        print('Photo saved at: ${media.path}');
      },
    ),
  ),
);
```

### Video Recording with Duration Limit

```dart
CameraScreen(
  initialMode: CameraMode.video,
  videoDurationLimit: 30, // 30 seconds max
  onMediaCaptured: (MediaItem media) {
    print('Video saved at: ${media.path}');
  },
  onError: (String error) {
    print('Error: $error');
  },
)
```

### Combined Mode (Photo + Video)

```dart
CameraScreen(
  initialMode: CameraMode.combined,
  showGridButton: true,
  onMediaCaptured: (MediaItem media) {
    if (media.type == MediaType.photo) {
      print('Photo captured');
    } else {
      print('Video recorded');
    }
  },
)
```

## Advanced Usage

### Custom UI Elements

```dart
CameraScreen(
  initialMode: CameraMode.photo,
  customWidgets: CameraCustomWidgets(
    // Custom gallery button
    galleryButton: Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.purple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.photo_library, color: Colors.white),
    ),
    
    // Custom capture button
    captureButton: YourCustomCaptureButton(),
    
    // Custom flash control
    flashControl: YourCustomFlashButton(),
    
    // Add custom widgets to the left side
    leftSideWidget: Column(
      children: [
        IconButton(icon: Icon(Icons.filter), onPressed: () {}),
        IconButton(icon: Icon(Icons.timer), onPressed: () {}),
      ],
    ),
  ),
)
```

### Camera Settings

```dart
CameraScreen(
  initialMode: CameraMode.photo,
  settings: const CameraSettings(
    // Photo settings
    photoQuality: PhotoQuality.high,
    aspectRatio: CameraAspectRatio.ratio_16_9,
    photoTimerSeconds: 3,
    
    // Focus and exposure
    enableAutoFocus: true,
    enableAutoExposure: true,
    
    // Initial camera
    initialCameraLens: CameraLensDirection.back,
  ),
  captureLocationMetadata: true, // Add GPS to photos
)
```

### Handling Permissions

The package handles permissions automatically, but you can also manage them manually:

```dart
// Check permissions before opening camera
final hasPermissions = await CameraPermissionHelper.checkPermissions(
  requireAudio: true, // For video mode
  requireLocation: true, // For GPS metadata
);

if (!hasPermissions) {
  final granted = await CameraPermissionHelper.requestPermissions(
    requireAudio: true,
    requireLocation: true,
  );
  
  if (!granted) {
    // Handle permission denial
  }
}
```

### Minimal UI Mode

```dart
CameraScreen(
  initialMode: CameraMode.photo,
  showGalleryButton: false,
  showCheckButton: false,
  showGridButton: false,
  onMediaCaptured: (media) {
    // Auto-close after capture
    Navigator.pop(context, media);
  },
)
```

## Features in Detail

### 🎬 Smart Orientation Handling

Cameraly ensures photos and videos are always correctly oriented:
- Handles device rotation during capture
- Fixes orientation metadata automatically
- Works across all Android devices and orientations
- No more sideways or upside-down media!

### 📍 Location Metadata

When enabled, Cameraly adds GPS coordinates to photos:
```dart
CameraScreen(
  captureLocationMetadata: true,
  onMediaCaptured: (media) {
    // Photo EXIF data includes GPS coordinates
  },
)
```

### ⏱️ Photo Timer

Perfect for selfies and group photos:
```dart
CameraScreen(
  settings: const CameraSettings(
    photoTimerSeconds: 5, // 5-second countdown
  ),
)
```

### 🎥 Video Recording Features

- Duration limits with countdown display
- Torch mode for continuous lighting
- Pause/resume recording (device dependent)
- Audio level monitoring (coming soon)

### 🔐 Smart Permission Management

Cameraly includes intelligent permission handling:
- Requests only required permissions based on mode
- Handles race conditions during initialization
- Graceful degradation when permissions are denied
- Clear user feedback for permission states

## Memory Management

Cameraly includes built-in memory optimization:
- Automatic cleanup of temporary files
- Efficient bitmap handling
- Memory pressure monitoring
- Configurable cache limits

## Example App

Check out the [example app](example/) for comprehensive demonstrations of all features:

```bash
cd example
flutter run
```

## Troubleshooting

### Common Issues

1. **Black Screen on Android**
   - Ensure you have the correct permissions in AndroidManifest.xml
   - Check that your device supports Camera2 API

2. **Orientation Issues**
   - Cameraly handles this automatically, but ensure you're using the latest version
   - For custom implementations, use the `OrientationService` class

3. **Permission Errors**
   - iOS: Ensure Info.plist descriptions are present
   - Android: Check that permissions are declared in the manifest

### Debug Mode

Enable debug logging:
```dart
CameraScreen(
  enableDebugLogs: true,
  // ... other parameters
)
```

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Clone the repository
2. Run `flutter pub get`
3. Run the example app to test changes

### Running Tests

```bash
flutter test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

Built with ❤️ by the Inspectly team.

Special thanks to all [contributors](https://github.com/InspectlyMads/cameraly/graphs/contributors) who have helped make this package better.

## Support

- 📧 Email: dev@inspectly.com
- 🐛 Issues: [GitHub Issues](https://github.com/InspectlyMads/cameraly/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/InspectlyMads/cameraly/discussions)