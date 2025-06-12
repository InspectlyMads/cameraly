# Task 1: Advanced Project Setup & State Management Architecture

## Status: ⏳ Not Started

## Objective
Set up the Flutter project with a robust state management architecture capable of handling complex orientation-aware camera functionality, real-time orientation monitoring, and comprehensive testing data management.

## Subtasks

### 1.1 Create Flutter Project
- [ ] Create new Flutter project: `flutter create cameraly`
- [ ] Verify project builds successfully on Android
- [ ] Set minimum SDK version in `android/app/build.gradle` (API 21+ recommended for camera package)

### 1.2 State Management Architecture Decision
- [ ] **Recommended: Riverpod** for advanced state management
- [ ] Plan global state architecture for orientation-aware system
- [ ] Design provider structure for camera controllers and services
- [ ] Plan state persistence and testing data management

### 1.3 Core Dependencies
- [ ] Add camera dependency: `camera: ^0.10.5+5`
- [ ] Add path_provider dependency: `path_provider: ^2.1.1`
- [ ] Add permission_handler dependency: `permission_handler: ^11.0.1`
- [ ] Add video_player dependency: `video_player: ^2.8.1`

### 1.4 State Management Dependencies
- [ ] Add riverpod dependency: `flutter_riverpod: ^2.4.9`
- [ ] Add riverpod_annotation: `riverpod_annotation: ^2.3.3`
- [ ] Add riverpod_generator: `riverpod_generator: ^2.3.9` (dev dependency)
- [ ] Add build_runner: `build_runner: ^2.4.7` (dev dependency)

### 1.5 Additional Testing & Utility Dependencies
- [ ] Add sensors_plus: `sensors_plus: ^4.0.2` (for orientation sensors)
- [ ] Add device_info_plus: `device_info_plus: ^9.1.1` (for device identification)
- [ ] Add shared_preferences: `shared_preferences: ^2.2.2` (for test data persistence)
- [ ] Add json_annotation: `json_annotation: ^4.8.1` (for test data serialization)
- [ ] Run `flutter pub get` to install dependencies

### 1.6 Android Configuration
- [ ] Update `android/app/src/main/AndroidManifest.xml` with permissions:
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                   android:maxSdkVersion="28" />
  <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
  <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
  ```
- [ ] Set minimum SDK version to 21 in `android/app/build.gradle`
- [ ] Add camera hardware requirement in AndroidManifest.xml:
  ```xml
  <uses-feature android:name="android.hardware.camera" android:required="true" />
  <uses-feature android:name="android.hardware.camera.autofocus" />
  ```

### 1.7 Advanced Project Structure Setup
- [ ] Create `lib/providers/` directory (Riverpod providers)
- [ ] Create `lib/controllers/` directory (orientation-aware controllers)
- [ ] Create `lib/services/` directory (camera, storage, metadata services)
- [ ] Create `lib/models/` directory (data models with JSON serialization)
- [ ] Create `lib/screens/` directory (UI screens)
- [ ] Create `lib/widgets/` directory (reusable components)
- [ ] Create `lib/utils/` directory (helper utilities)
- [ ] Create `lib/features/` directory (feature-specific implementations)

### 1.8 State Management Architecture Design
- [ ] Design global camera controller provider
- [ ] Design orientation monitoring provider
- [ ] Design testing data collection provider
- [ ] Plan provider dependencies and lifecycle management
- [ ] Design state persistence strategy

## Detailed State Management Architecture

### 1.8.1 Riverpod Provider Architecture
```dart
// Core Camera System Providers
final orientationAwareCameraControllerProvider = 
    StateNotifierProvider<OrientationAwareCameraController, CameraState>(...);

final deviceOrientationProvider = 
    StreamProvider<OrientationData>(...);

final cameraPermissionProvider = 
    FutureProvider<PermissionStatus>(...);

// Capture Feature Providers
final photoCapturerProvider = 
    Provider<OrientationAwarePhotoCapture>(...);

final videoRecorderProvider = 
    Provider<OrientationAwareVideoRecording>(...);

final combinedModeControllerProvider = 
    StateNotifierProvider<CombinedModeController, CombinedModeState>(...);

// Testing & Analytics Providers
final testingDataProvider = 
    StateNotifierProvider<TestingDataController, TestingState>(...);

final orientationAccuracyProvider = 
    Provider<OrientationAccuracyTracker>(...);

// Storage & Gallery Providers
final mediaStorageProvider = 
    Provider<MediaStorageService>(...);

final galleryProvider = 
    StateNotifierProvider<GalleryController, GalleryState>(...);
```

### 1.8.2 State Management Benefits for Our Use Case
- **Reactive Orientation Handling**: Automatic UI updates when orientation changes
- **Global Camera State**: Shared camera controller across all screens
- **Testing Data Collection**: Centralized logging and analytics
- **Performance**: Efficient rebuilds only when needed
- **Error Handling**: Centralized error state management
- **Testing**: Easy to mock providers for unit tests

### 1.8.3 Provider Lifecycle Management
```dart
// Example provider setup in main.dart
void main() {
  runApp(
    ProviderScope(
      observers: [
        OrientationTestingObserver(), // Log all state changes for testing
      ],
      child: CameraTestApp(),
    ),
  );
}
```

## Files to Create/Modify
- `pubspec.yaml` (comprehensive dependencies)
- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle`
- `lib/main.dart` (with ProviderScope setup)
- `lib/providers/` directory with provider definitions
- Advanced directory structure under `lib/`

## State Management Provider Plan

### Core Providers
```dart
// lib/providers/camera_providers.dart
@riverpod
class OrientationAwareCameraController extends _$OrientationAwareCameraController {
  // Camera controller with orientation intelligence
}

@riverpod
Stream<OrientationData> deviceOrientation(DeviceOrientationRef ref) {
  // Real-time orientation monitoring
}

// lib/providers/capture_providers.dart
@riverpod
OrientationAwarePhotoCapture photoCapture(PhotoCaptureRef ref) {
  // Photo capture with orientation awareness
}

@riverpod
OrientationAwareVideoRecording videoRecording(VideoRecordingRef ref) {
  // Video recording with orientation tracking
}

// lib/providers/testing_providers.dart
@riverpod
class TestingDataController extends _$TestingDataController {
  // Centralized testing data collection and analysis
}
```

### State Models
```dart
// lib/models/camera_state.dart
@freezed
class CameraState with _$CameraState {
  const factory CameraState({
    required bool isInitialized,
    required OrientationData currentOrientation,
    required List<CameraDescription> availableCameras,
    required int currentCameraIndex,
    String? errorMessage,
  }) = _CameraState;
}

// lib/models/orientation_data.dart
@freezed
class OrientationData with _$OrientationData {
  const factory OrientationData({
    required DeviceOrientation deviceOrientation,
    required int cameraRotation,
    required int sensorOrientation,
    required String deviceManufacturer,
    required String deviceModel,
    required DateTime timestamp,
  }) = _OrientationData;
}
```

## Acceptance Criteria
- [ ] Flutter project builds successfully with all dependencies
- [ ] Riverpod providers are properly configured and accessible
- [ ] State management architecture supports complex orientation handling
- [ ] All dependencies resolve without conflicts
- [ ] Android permissions are properly declared
- [ ] Project structure supports scalable development
- [ ] Provider code generation works correctly
- [ ] App launches without errors on Android device/emulator
- [ ] State management enables efficient testing data collection

## Testing Considerations
- **Provider Testing**: Easy to test individual providers in isolation
- **State Persistence**: Testing data can be saved and analyzed
- **Debugging**: Riverpod DevTools integration for state inspection
- **Performance**: Provider dependency optimization for smooth orientation changes

## Notes
- **Riverpod Choice Rationale**: 
  - Superior performance for frequent orientation updates
  - Excellent testing capabilities crucial for our MVP
  - Compile-time safety for complex state dependencies
  - Built-in caching perfect for orientation calculations
- Test on both debug and release builds to ensure camera permissions work correctly
- Verify that the minimum SDK version supports all required camera features
- Consider adding ProGuard rules if needed for release builds
- Set up code generation workflow early for seamless development

## Estimated Time: 3-5 hours (increased for state management setup)

## Next Task: Task 2 - Permission Handling and App Structure 