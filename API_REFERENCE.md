# Cameraly API Reference

## CameraScreen

The main camera interface widget.

### Constructor
```dart
CameraScreen({
  Key? key,
  required CameraMode mode,
  CameraSettings? settings,
  CameraCustomWidgets? customWidgets,
  int? videoDurationLimit,
  bool captureLocationMetadata = true,
  bool showGridButton = true,
  bool showGalleryButton = false,
  bool showCheckButton = false,
  Function(MediaItem)? onMediaCaptured,
  Function()? onGalleryPressed,
  Function()? onCheckPressed,
  Function(String)? onError,
})
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| mode | CameraMode | required | Camera mode (photo/video/combined) |
| settings | CameraSettings? | null | Camera configuration settings |
| customWidgets | CameraCustomWidgets? | null | Custom UI widgets |
| videoDurationLimit | int? | null | Max video duration in seconds |
| captureLocationMetadata | bool | true | Include GPS data in photos |
| showGridButton | bool | true | Show grid overlay toggle |
| showGalleryButton | bool | false | Show gallery button |
| showCheckButton | bool | false | Show check/done button |
| onMediaCaptured | Function(MediaItem)? | null | Called when media is captured |
| onGalleryPressed | Function()? | null | Gallery button callback |
| onCheckPressed | Function()? | null | Check button callback |
| onError | Function(String)? | null | Error callback |

## CameraMode

Enum for camera operation modes.

```dart
enum CameraMode {
  photo,    // Photo only (no microphone permission)
  video,    // Video only
  combined  // Both photo and video with mode switcher
}
```

## CameraSettings

Configuration for camera behavior and quality.

```dart
class CameraSettings {
  final PhotoQuality photoQuality;
  final VideoQuality videoQuality;
  final CameraAspectRatio aspectRatio;
  final int? photoTimerSeconds;
  final bool enableSounds;
  final bool enableHaptics;
  final int? maxVideoSizeMB;
  final bool autoSaveToGallery;
}
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| photoQuality | PhotoQuality | high | Photo capture quality |
| videoQuality | VideoQuality | fullHd | Video recording quality |
| aspectRatio | CameraAspectRatio | ratio_4_3 | Camera preview aspect ratio |
| photoTimerSeconds | int? | null | Photo timer (0, 3, 5, or 10) |
| enableSounds | bool | true | Camera shutter sounds |
| enableHaptics | bool | true | Haptic feedback |
| maxVideoSizeMB | int? | null | Max video file size |
| autoSaveToGallery | bool | true | Auto-save to device gallery |

## Enums

### PhotoQuality
```dart
enum PhotoQuality {
  low,    // Lower resolution, smaller file
  medium, // Balanced quality
  high,   // High quality (default)
  max     // Maximum available quality
}
```

### VideoQuality
```dart
enum VideoQuality {
  hd,     // 720p
  fullHd, // 1080p (default)
  uhd     // 4K (if available)
}
```

### CameraAspectRatio
```dart
enum CameraAspectRatio {
  ratio_4_3,  // 4:3 (default)
  ratio_16_9, // 16:9 widescreen
  ratio_1_1,  // 1:1 square
  full        // Full sensor
}
```

## MediaItem

Represents captured media with metadata.

```dart
class MediaItem {
  final String path;
  final MediaType type;
  final DateTime capturedAt;
  final String? thumbnailPath;
  final Duration? videoDuration;
  final int? fileSize;
  final PhotoMetadata? metadata;
  
  // Getters
  String get fileName;
  String get fileExtension;
  bool get isVideo;
  String get fileSizeFormatted;
  
  // Methods
  Future<bool> exists();
  static Future<MediaItem?> fromFile(File file);
}
```

### MediaType
```dart
enum MediaType {
  photo,
  video
}
```

## PhotoMetadata

Detailed metadata for captured photos.

```dart
class PhotoMetadata {
  // Location
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? speed;
  final double? accuracy;
  
  // Device
  final String deviceManufacturer;
  final String deviceModel;
  final String osVersion;
  
  // Camera
  final String cameraName;
  final String lensDirection;
  final double? zoomLevel;
  final String? flashMode;
  
  // Timestamps
  final DateTime capturedAt;
  final int captureTimeMillis;
}
```

## CameraCustomWidgets

Custom UI widget replacements.

```dart
class CameraCustomWidgets {
  final Widget? topControls;
  final Widget? bottomControls;
  final Widget? flashControl;
  final Widget? gridToggle;
  final Widget? cameraSwitcher;
  final Widget? zoomControl;
  final Widget? leftSideWidget;
  final Widget? rightSideWidget;
  // Note: captureButton cannot be customized
}
```

## CameralyLocalizations

Base class for custom translations.

```dart
abstract class CameralyLocalizations {
  // Override these getters for custom translations
  String get modePhoto;
  String get modeVideo;
  String get flashOff;
  String get flashAuto;
  String get flashOn;
  String get flashTorch;
  String get permissionCameraRequired;
  String get permissionMicrophoneRequired;
  String get errorCameraNotFound;
  String get errorCaptureFailed;
  String get buttonTakePhoto;
  String get buttonStartRecording;
  // ... many more
  
  // Dynamic strings
  String recordingDuration(String duration);
  String recordingCountdown(int seconds);
  String zoomLevel(double zoom);
  
  // Set custom instance
  static void setInstance(CameralyLocalizations localizations);
}
```

## MemoryManager

Manages media storage and cleanup.

```dart
class MemoryManager {
  // Start automatic cleanup
  static void startPeriodicCleanup({
    Duration interval = const Duration(hours: 24),
    Duration maxMediaAge = const Duration(days: 7),
    int maxMediaFiles = 500,
  });
  
  // Stop cleanup
  static void stopPeriodicCleanup();
  
  // Manual cleanup
  static Future<void> performCleanup({
    Duration maxMediaAge = const Duration(days: 7),
    int maxMediaFiles = 500,
  });
  
  // Get memory stats
  static Future<MemoryStats> getMemoryStats();
  
  // Clear all media
  static Future<void> clearAllMedia();
}
```

## StorageService

Check available storage space.

```dart
class StorageService {
  static Future<bool> hasEnoughSpace({
    int requiredMB = 100,
  });
  
  static Future<int> getAvailableSpaceMB();
}
```

## Error Types

```dart
enum CameraErrorType {
  permissionDenied,
  cameraNotFound,
  initialization,
  recording,
  capture,
  unknown,
}

class CameraErrorInfo {
  final CameraErrorType type;
  final String message;
  final String? userMessage;
  final bool isRecoverable;
  final Duration? retryDelay;
}
```

## Complete Example

```dart
import 'package:cameraly/cameraly.dart';

class CameraExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CameraScreen(
      mode: CameraMode.combined,
      settings: CameraSettings(
        photoQuality: PhotoQuality.high,
        videoQuality: VideoQuality.fullHd,
        aspectRatio: CameraAspectRatio.ratio_16_9,
        photoTimerSeconds: 3,
        enableSounds: true,
        enableHaptics: true,
        maxVideoSizeMB: 100,
        autoSaveToGallery: false,
      ),
      videoDurationLimit: 60,
      captureLocationMetadata: true,
      showGridButton: true,
      customWidgets: CameraCustomWidgets(
        topControls: MyCustomTopBar(),
      ),
      onMediaCaptured: (MediaItem media) async {
        print('Type: ${media.type}');
        print('Path: ${media.path}');
        print('Size: ${media.fileSizeFormatted}');
        
        if (media.metadata != null) {
          print('Location: ${media.metadata!.latitude}, ${media.metadata!.longitude}');
        }
        
        Navigator.pop(context, media);
      },
      onError: (String error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
  }
}
```