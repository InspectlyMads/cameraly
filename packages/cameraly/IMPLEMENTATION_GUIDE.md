# Cameraly - Complete Implementation Guide

This guide provides step-by-step instructions for implementing the Cameraly camera package in a Flutter application. Follow these instructions to add camera functionality with photo/video capture, localization, and advanced features to your app.

## Table of Contents
1. [Installation](#installation)
2. [Platform Setup](#platform-setup)
3. [Basic Implementation](#basic-implementation)
4. [Complete Feature Implementation](#complete-feature-implementation)
5. [Localization Setup](#localization-setup)
6. [Advanced Features](#advanced-features)
7. [Error Handling](#error-handling)
8. [Testing](#testing)

## Installation

### Step 1: Add Dependency
Add to `pubspec.yaml`:
```yaml
dependencies:
  cameraly: ^1.0.0
```

### Step 2: Install
Run:
```bash
flutter pub get
```

## Platform Setup

### iOS Setup (Required)
Add these permissions to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos and videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record videos</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to tag photos with location</string>
```

### Android Setup (Required)
Add these permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## Basic Implementation

### Step 1: Import Package
```dart
import 'package:cameraly/cameraly.dart';
import 'dart:io';
```

### Step 2: Basic Camera Screen
```dart
class CameraPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CameraScreen(
      mode: CameraMode.combined, // Allows both photo and video
      onMediaCaptured: (MediaItem media) {
        // Handle captured media
        print('Captured: ${media.path}');
        print('Type: ${media.type}'); // MediaType.photo or MediaType.video
        
        // Navigate back or process media
        Navigator.pop(context, media);
      },
    );
  }
}
```

### Step 3: Navigate to Camera
```dart
// In your app
ElevatedButton(
  onPressed: () async {
    final MediaItem? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraPage()),
    );
    
    if (result != null) {
      // Process captured media
      if (result.type == MediaType.photo) {
        // Handle photo
      } else {
        // Handle video
      }
    }
  },
  child: Text('Open Camera'),
)
```

## Complete Feature Implementation

### Full-Featured Camera Screen
```dart
class AdvancedCameraPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CameraScreen(
      // Mode configuration
      mode: CameraMode.combined, // or .photo or .video
      
      // Camera settings
      settings: CameraSettings(
        // Photo settings
        photoQuality: PhotoQuality.high,
        photoTimerSeconds: 3, // 0, 3, 5, or 10 seconds
        
        // Video settings
        videoQuality: VideoQuality.fullHd,
        maxVideoSizeMB: 100, // Limit video file size
        
        // Common settings
        aspectRatio: CameraAspectRatio.ratio_16_9,
        enableSounds: true,
        enableHaptics: true,
        autoSaveToGallery: false, // We'll handle saving manually
      ),
      
      // Video duration limit (in seconds)
      videoDurationLimit: 60, // Max 60 seconds videos
      
      // Location metadata
      captureLocationMetadata: true, // Adds GPS data to photos
      
      // UI configuration
      showGridButton: true,
      showGalleryButton: false, // Hide if you have custom gallery
      
      // Callbacks
      onMediaCaptured: (MediaItem media) async {
        // Access all media information
        print('Path: ${media.path}');
        print('Type: ${media.type}');
        print('Captured at: ${media.capturedAt}');
        print('File size: ${media.fileSizeFormatted}');
        
        // Access metadata if location was enabled
        if (media.metadata != null) {
          print('Location: ${media.metadata!.latitude}, ${media.metadata!.longitude}');
          print('Device: ${media.metadata!.deviceModel}');
          print('Zoom level: ${media.metadata!.zoomLevel}');
        }
        
        // Save to custom location if needed
        await _saveToCustomLocation(media);
        
        Navigator.pop(context, media);
      },
      
      onError: (String error) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
  }
  
  Future<void> _saveToCustomLocation(MediaItem media) async {
    // Example: Copy to custom directory
    final file = File(media.path);
    final customDir = Directory('/path/to/custom/directory');
    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }
    
    final fileName = media.type == MediaType.photo ? 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg' : 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    await file.copy('${customDir.path}/$fileName');
  }
}
```

## Localization Setup

### Step 1: Create Localization Class
Create `lib/localization/camera_localizations.dart`:
```dart
import 'package:cameraly/cameraly.dart';
import 'package:easy_localization/easy_localization.dart'; // or your localization package

class AppCameraLocalizations extends CameralyLocalizations {
  // Camera modes
  @override
  String get modePhoto => 'camera.mode.photo'.tr();
  
  @override
  String get modeVideo => 'camera.mode.video'.tr();
  
  // Flash modes
  @override
  String get flashOff => 'camera.flash.off'.tr();
  
  @override
  String get flashAuto => 'camera.flash.auto'.tr();
  
  @override
  String get flashOn => 'camera.flash.on'.tr();
  
  @override
  String get flashTorch => 'camera.flash.torch'.tr();
  
  // Permissions
  @override
  String get permissionCameraRequired => 'camera.permission.camera_required'.tr();
  
  @override
  String get permissionCameraAndMicrophoneRequired => 'camera.permission.camera_mic_required'.tr();
  
  // Buttons
  @override
  String get buttonTakePhoto => 'camera.button.take_photo'.tr();
  
  @override
  String get buttonStartRecording => 'camera.button.start_recording'.tr();
  
  @override
  String get buttonStopRecording => 'camera.button.stop_recording'.tr();
  
  @override
  String get buttonRetry => 'camera.button.retry'.tr();
  
  @override
  String get buttonGoBack => 'camera.button.go_back'.tr();
  
  @override
  String get buttonGrantPermissions => 'camera.button.grant_permissions'.tr();
  
  // Errors
  @override
  String get errorCameraNotFound => 'camera.error.not_found'.tr();
  
  @override
  String get errorCaptureFailed => 'camera.error.capture_failed'.tr();
  
  @override
  String get errorStorageFull => 'camera.error.storage_full'.tr();
  
  // Recording
  @override
  String recordingDuration(String duration) => duration; // Usually no translation needed
  
  @override
  String recordingCountdown(int seconds) => seconds.toString();
  
  @override
  String photoTimerCountdown(int seconds) => seconds.toString();
  
  // Zoom
  @override
  String zoomLevel(double zoom) => '${zoom.toStringAsFixed(1)}x';
}
```

### Step 2: Add Translations
Add to your translation files:

`assets/translations/en.json`:
```json
{
  "camera": {
    "mode": {
      "photo": "Photo",
      "video": "Video"
    },
    "flash": {
      "off": "Off",
      "auto": "Auto",
      "on": "On",
      "torch": "Torch"
    },
    "permission": {
      "camera_required": "Camera permission is required",
      "camera_mic_required": "Camera and microphone permissions are required"
    },
    "button": {
      "take_photo": "Take Photo",
      "start_recording": "Start Recording",
      "stop_recording": "Stop Recording",
      "retry": "Retry",
      "go_back": "Go Back",
      "grant_permissions": "Grant Permissions"
    },
    "error": {
      "not_found": "No camera found on this device",
      "capture_failed": "Failed to capture photo",
      "storage_full": "Not enough storage space"
    }
  }
}
```

### Step 3: Initialize Localization
In `main.dart`:
```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:cameraly/cameraly.dart';
import 'localization/camera_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize easy_localization
  await EasyLocalization.ensureInitialized();
  
  // Set camera localization
  CameralyLocalizations.setInstance(AppCameraLocalizations());
  
  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en'), Locale('es'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: Locale('en'),
      child: MyApp(),
    ),
  );
}
```

## Advanced Features

### Custom UI Widgets
```dart
CameraScreen(
  customWidgets: CameraCustomWidgets(
    // Replace top controls
    topControls: Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text('Custom Camera', style: TextStyle(color: Colors.white)),
        ],
      ),
    ),
    
    // Custom flash button
    flashButton: Container(
      decoration: BoxDecoration(
        color: Colors.white24,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(Icons.flash_auto, color: Colors.white),
        onPressed: () {
          // Custom flash logic
        },
      ),
    ),
  ),
)
```

### Memory Management
```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // Start automatic cleanup
    MemoryManager.startPeriodicCleanup(
      interval: Duration(hours: 24),
      maxMediaAge: Duration(days: 7),
      maxMediaFiles: 500,
    );
  }
  
  @override
  void dispose() {
    // Stop cleanup when app closes
    MemoryManager.stopPeriodicCleanup();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ... your app
    );
  }
}
```

### Processing Captured Media
```dart
void processMedia(MediaItem media) async {
  if (media.type == MediaType.photo) {
    // Process photo
    final file = File(media.path);
    final bytes = await file.readAsBytes();
    
    // Get EXIF data
    if (media.metadata != null) {
      print('Camera: ${media.metadata!.cameraName}');
      print('ISO: ${media.metadata!.iso}');
      print('Zoom: ${media.metadata!.zoomLevel}x');
      print('Flash: ${media.metadata!.flashMode}');
    }
    
    // Upload or process image
    await uploadPhoto(bytes);
    
  } else if (media.type == MediaType.video) {
    // Process video
    final file = File(media.path);
    
    // Get video info
    print('Duration: ${media.videoDuration?.inSeconds} seconds');
    print('Size: ${media.fileSizeFormatted}');
    
    // Upload or process video
    await uploadVideo(file);
  }
}
```

## Error Handling

### Comprehensive Error Handling
```dart
CameraScreen(
  onError: (String errorMessage) {
    // Parse error type from message
    if (errorMessage.contains('permission')) {
      _showPermissionDialog();
    } else if (errorMessage.contains('storage')) {
      _showStorageFullDialog();
    } else {
      _showGenericError(errorMessage);
    }
  },
)

void _showPermissionDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Permissions Required'),
      content: Text('Please grant camera permissions in settings'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Open app settings
            openAppSettings();
          },
          child: Text('Open Settings'),
        ),
      ],
    ),
  );
}
```

## Testing

### Test Implementation
```dart
void main() {
  testWidgets('Camera screen opens correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CameraScreen(
          mode: CameraMode.photo,
          onMediaCaptured: (media) {
            expect(media, isNotNull);
            expect(media.type, MediaType.photo);
          },
        ),
      ),
    );
    
    // Camera should initialize
    await tester.pump(Duration(seconds: 2));
    
    // Find capture button
    expect(find.byType(GestureDetector), findsWidgets);
  });
}
```

## Common Issues and Solutions

### 1. Black Screen on iOS
Ensure Info.plist permissions are added correctly.

### 2. Camera Not Initializing
Check that all permissions are granted in device settings.

### 3. Storage Errors
Implement storage space checking before capture:
```dart
import 'package:cameraly/cameraly.dart';

// Before opening camera
final hasSpace = await StorageService.hasEnoughSpace(requiredMB: 100);
if (!hasSpace) {
  // Show storage full dialog
}
```

### 4. Orientation Issues
The package handles orientation automatically, but ensure your app supports all orientations in the manifest files.

## Complete Example App

See `/example` folder in the package for a complete working example with all features implemented.