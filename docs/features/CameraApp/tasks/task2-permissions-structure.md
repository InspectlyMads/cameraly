# Task 2: Permission Handling and App Structure

## Status: ⏳ Not Started

## Objective
Implement runtime permission handling for camera and microphone access, and establish the core app structure with models and services.

## Subtasks

### 2.1 Create Core Models
- [ ] Create `CameraMode` enum in `lib/models/camera_mode.dart`
- [ ] Create `MediaType` enum in `lib/models/media_type.dart`
- [ ] Create `MediaItem` class in `lib/models/media_item.dart`
- [ ] Create `OrientationData` class for tracking device orientation during capture

### 2.2 Implement Permission Service
- [ ] Create `PermissionService` class in `lib/services/permission_service.dart`
- [ ] Implement method to check camera permission status
- [ ] Implement method to request camera permission
- [ ] Implement method to check microphone permission status
- [ ] Implement method to request microphone permission
- [ ] Add method to handle permission denial scenarios
- [ ] Add method to check if permissions can be requested (not permanently denied)

### 2.3 Implement Storage Service
- [ ] Create `StorageService` class in `lib/services/storage_service.dart`
- [ ] Implement method to get app-private directory for media storage
- [ ] Add method to generate unique file names for captures
- [ ] Implement method to list captured media files
- [ ] Add method to delete media files
- [ ] Include helper methods for file path management

### 2.4 Update Main App Structure
- [ ] Update `main.dart` to initialize services
- [ ] Add global error handling
- [ ] Implement app lifecycle observer for camera management
- [ ] Set up proper routing with named routes
- [ ] Add loading states for permission checks

### 2.5 Create Common Widgets
- [ ] Create `LoadingWidget` for showing loading states
- [ ] Create `ErrorWidget` for displaying errors with retry options
- [ ] Create `PermissionDeniedWidget` for handling permission denial
- [ ] Create `CaptureButton` widget for reusable capture functionality

## Detailed Implementation

### 2.1 CameraMode Enum
```dart
enum CameraMode {
  photosOnly,
  videosOnly,
  photosAndVideos;
  
  String get displayName {
    switch (this) {
      case CameraMode.photosOnly:
        return 'Photos Only';
      case CameraMode.videosOnly:
        return 'Videos Only';
      case CameraMode.photosAndVideos:
        return 'Photos & Videos';
    }
  }
}
```

### 2.2 PermissionService Key Methods
```dart
class PermissionService {
  Future<bool> checkCameraPermission();
  Future<bool> requestCameraPermission();
  Future<bool> checkMicrophonePermission();
  Future<bool> requestMicrophonePermission();
  Future<bool> areAllPermissionsGranted();
  Future<void> openAppSettings();
}
```

### 2.3 MediaItem Model
```dart
class MediaItem {
  final String path;
  final MediaType type;
  final DateTime capturedAt;
  final String deviceOrientation;
  final File file;
}
```

## Files to Create
- `lib/models/camera_mode.dart`
- `lib/models/media_type.dart`
- `lib/models/media_item.dart`
- `lib/services/permission_service.dart`
- `lib/services/storage_service.dart`
- `lib/widgets/loading_widget.dart`
- `lib/widgets/error_widget.dart`
- `lib/widgets/permission_denied_widget.dart`
- `lib/widgets/capture_button.dart`

## Files to Modify
- `lib/main.dart`

## Acceptance Criteria
- [ ] App properly requests camera and microphone permissions on first launch
- [ ] Permission denial is handled gracefully with user-friendly messages
- [ ] Users can be directed to app settings if permissions are permanently denied
- [ ] Storage service can create and manage media files in app-private directory
- [ ] All models are properly structured with necessary properties
- [ ] Common widgets are reusable and follow Material Design guidelines
- [ ] App handles lifecycle changes without crashes

## Testing Points
- [ ] Test permission flow on fresh app install
- [ ] Test behavior when permissions are denied
- [ ] Test behavior when permissions are permanently denied
- [ ] Verify storage service creates proper file paths
- [ ] Test app behavior when returning from settings

## Notes
- Focus on user experience - clear messaging about why permissions are needed
- Ensure compatibility with different Android versions (permission models changed in API 23+)
- Test on devices with and without external storage
- Consider edge cases like insufficient storage space

## Estimated Time: 4-6 hours

## Next Task: Task 3 - Home Screen Navigation 