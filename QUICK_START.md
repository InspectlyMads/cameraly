# Cameraly - Quick Start Guide

This guide will help you quickly integrate the Cameraly package into your Flutter application.

## Installation

1. Add Cameraly to your `pubspec.yaml`:

```yaml
dependencies:
  cameraly: ^0.1.0
```

2. Run:

```bash
flutter pub get
```

## Platform Configuration

### Android

Add camera permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS

Add camera usage descriptions to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos and record videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record videos</string>
```

## Basic Implementation

### 1. Create a Camera Screen

```dart
import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameralyController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      
      // Initialize the controller with the first camera
      _controller = CameralyController(description: cameras.first);
      await _controller.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: _isInitialized
          ? CameralyPreview(
              controller: _controller,
              onTap: (position) {
                _controller.setFocusAndExposurePoint(position);
              },
            )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              onPressed: _takePicture,
              child: const Icon(Icons.camera),
            )
          : null,
    );
  }

  Future<void> _takePicture() async {
    try {
      final photo = await _controller.takePicture();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo saved to: ${photo.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    }
  }
}
```

### 2. Navigate to the Camera Screen

```dart
ElevatedButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );
  },
  child: const Text('Open Camera'),
)
```

## Common Tasks

### Switch Between Front and Back Cameras

```dart
IconButton(
  icon: const Icon(Icons.switch_camera),
  onPressed: () async {
    try {
      await _controller.switchCamera();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error switching camera: $e')),
        );
      }
    }
  },
)
```

### Toggle Flash Mode

```dart
IconButton(
  icon: Icon(_getFlashIcon(_controller.value.flashMode)),
  onPressed: () async {
    try {
      await _controller.toggleFlash();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling flash: $e')),
        );
      }
    }
  },
)

IconData _getFlashIcon(FlashMode mode) {
  switch (mode) {
    case FlashMode.auto:
      return Icons.flash_auto;
    case FlashMode.always:
      return Icons.flash_on;
    case FlashMode.off:
      return Icons.flash_off;
    default:
      return Icons.flash_auto;
  }
}
```

### Record Video

```dart
FloatingActionButton(
  onPressed: () async {
    if (_controller.value.isRecording) {
      try {
        final video = await _controller.stopVideoRecording();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Video saved to: ${video.path}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error stopping recording: $e')),
          );
        }
      }
    } else {
      try {
        await _controller.startVideoRecording();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error starting recording: $e')),
          );
        }
      }
    }
  },
  child: Icon(
    _controller.value.isRecording ? Icons.stop : Icons.videocam,
  ),
)
```

### Using the Default Overlay

```dart
CameralyPreview(
  controller: _controller,
  // The default overlay is used automatically
  // It includes camera controls like capture button, flash toggle, etc.
)
```

### Using a Custom Overlay

```dart
CameralyPreview(
  controller: _controller,
  overlayType: CameralyOverlayType.custom,
  customOverlay: YourCustomOverlay(
    controller: _controller,
    onCaptureTap: _takePicture,
  ),
)
```

### Using No Overlay

```dart
CameralyPreview(
  controller: _controller,
  overlayType: CameralyOverlayType.none,
)
```

## Advanced Configuration

### Custom Camera Settings

```dart
_controller = CameralyController(
  description: cameras.first,
  settings: CaptureSettings(
    resolution: ResolutionPreset.max,
    enableAudio: true,
    flashMode: FlashMode.auto,
  ),
);
```

### Custom Overlay Theme

```dart
CameralyPreview(
  controller: _controller,
  defaultOverlay: DefaultCameralyOverlay(
    controller: _controller,
    theme: CameralyOverlayTheme(
      primaryColor: Colors.blue,
      secondaryColor: Colors.white,
      backgroundColor: Colors.black54,
      opacity: 0.7,
    ),
  ),
)
```

## Troubleshooting

### Camera Not Initializing

- Check that you've added the required permissions to your Android and iOS configuration files
- Ensure the device has a camera
- Check that you're not trying to access a camera that doesn't exist (e.g., front camera on a device without one)

### Permission Denied

- Use the built-in permission handling:

```dart
final permissionResult = await _controller.requestCameraPermission();
if (permissionResult == PermissionStatus.granted) {
  await _controller.initialize();
} else {
  // Show permission denied UI
}
```

### Camera Preview Not Showing

- Ensure the controller is initialized before showing the preview
- Check that the CameralyPreview widget has a non-zero size
- Verify that the device supports the selected resolution

## Next Steps

For more advanced usage and customization options, check out:

- The complete example app in the `example/` directory
- The API documentation at [pub.dev/documentation/cameraly/latest/](https://pub.dev/documentation/cameraly/latest/)
- The README.md file for additional features and options 