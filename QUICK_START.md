# Cameraly Quick Start Guide

## 1. Installation
```yaml
dependencies:
  cameraly: ^1.0.0
```

## 2. Platform Setup

### iOS (ios/Runner/Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access for photos and videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access for video recording</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access for photo geotagging</string>
```

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

## 3. Basic Implementation
```dart
import 'package:cameraly/cameraly.dart';

// Open camera
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CameraScreen(
      mode: CameraMode.combined,
      onMediaCaptured: (MediaItem media) {
        print('Captured: ${media.path}');
        Navigator.pop(context, media);
      },
    ),
  ),
);
```

## 4. With All Features
```dart
CameraScreen(
  // Mode
  mode: CameraMode.combined, // photo, video, or combined
  
  // Settings
  settings: CameraSettings(
    photoQuality: PhotoQuality.high,
    videoQuality: VideoQuality.fullHd,
    aspectRatio: CameraAspectRatio.ratio_16_9,
    photoTimerSeconds: 3, // 0, 3, 5, or 10
    enableSounds: true,
    enableHaptics: true,
  ),
  
  // Limits
  videoDurationLimit: 60, // seconds
  
  // Features
  captureLocationMetadata: true,
  showGridButton: true,
  
  // Callbacks
  onMediaCaptured: (MediaItem media) {
    // Handle captured media
  },
  onError: (String error) {
    // Handle errors
  },
)
```

## 5. Localization (with easy_localization)
```dart
// Create localization class
class MyCameraL10n extends CameralyLocalizations {
  @override
  String get modePhoto => 'photo'.tr();
  
  @override
  String get modeVideo => 'video'.tr();
  // ... override other strings
}

// In main.dart
void main() {
  CameralyLocalizations.setInstance(MyCameraL10n());
  runApp(MyApp());
}
```

## 6. Camera Modes
- `CameraMode.photo` - Photo only (no mic permission)
- `CameraMode.video` - Video only
- `CameraMode.combined` - Switch between photo/video

## 7. Settings Options
```dart
CameraSettings(
  // Photo
  photoQuality: PhotoQuality.low/medium/high/max,
  photoTimerSeconds: 0/3/5/10,
  
  // Video  
  videoQuality: VideoQuality.hd/fullHd/uhd,
  maxVideoSizeMB: 100,
  
  // Display
  aspectRatio: CameraAspectRatio.ratio_4_3/ratio_16_9/ratio_1_1/full,
  
  // Behavior
  enableSounds: true/false,
  enableHaptics: true/false,
  autoSaveToGallery: true/false,
)
```

## 8. MediaItem Properties
```dart
MediaItem {
  String path,              // File path
  MediaType type,          // .photo or .video
  DateTime capturedAt,     // Timestamp
  PhotoMetadata? metadata, // GPS, device info, etc
  Duration? videoDuration, // For videos
  int? fileSize,          // In bytes
  String fileSizeFormatted // "1.5 MB"
}
```

## 9. Memory Management
```dart
// In app initialization
MemoryManager.startPeriodicCleanup(
  interval: Duration(hours: 24),
  maxMediaAge: Duration(days: 7),
  maxMediaFiles: 500,
);
```

## 10. Common Patterns

### Open and Get Result
```dart
final MediaItem? result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => CameraScreen(...)),
);

if (result != null) {
  // User captured media
  if (result.type == MediaType.photo) {
    // Handle photo
  } else {
    // Handle video
  }
}
```

### Custom UI
```dart
CameraScreen(
  customWidgets: CameraCustomWidgets(
    topControls: MyTopBar(),
    flashButton: MyFlashButton(),
    // Note: capture button cannot be customized
  ),
)
```

### Error Handling
```dart
onError: (error) {
  if (error.contains('permission')) {
    // Handle permission error
  } else if (error.contains('storage')) {
    // Handle storage full
  } else {
    // Generic error
  }
}
```