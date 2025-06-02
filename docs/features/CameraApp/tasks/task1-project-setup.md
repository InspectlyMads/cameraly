# Task 1: Project Setup & Dependencies

## Status: ⏳ Not Started

## Objective
Set up the Flutter project structure and add all required dependencies for camera functionality, file management, and permissions.

## Subtasks

### 1.1 Create Flutter Project
- [ ] Create new Flutter project: `flutter create camera_test`
- [ ] Verify project builds successfully on Android
- [ ] Set minimum SDK version in `android/app/build.gradle` (API 21+ recommended for camera package)

### 1.2 Update pubspec.yaml
- [ ] Add camera dependency: `camera: ^0.10.5+5`
- [ ] Add path_provider dependency: `path_provider: ^2.1.1`
- [ ] Add permission_handler dependency: `permission_handler: ^11.0.1`
- [ ] Add video_player dependency: `video_player: ^2.8.1`
- [ ] Run `flutter pub get` to install dependencies

### 1.3 Android Configuration
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

### 1.4 Project Structure Setup
- [ ] Create `lib/screens/` directory
- [ ] Create `lib/models/` directory
- [ ] Create `lib/services/` directory
- [ ] Create `lib/widgets/` directory (for reusable components)

### 1.5 Basic App Structure
- [ ] Update `main.dart` with basic app structure
- [ ] Add MaterialApp with proper theme
- [ ] Set up basic routing structure
- [ ] Add error handling for initialization

## Files to Create/Modify
- `pubspec.yaml`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle`
- `lib/main.dart`
- Directory structure under `lib/`

## Acceptance Criteria
- [ ] Flutter project builds successfully
- [ ] All dependencies resolve without conflicts
- [ ] Android permissions are properly declared
- [ ] Project structure is organized and follows Flutter conventions
- [ ] App launches without errors on Android device/emulator

## Notes
- Test on both debug and release builds to ensure camera permissions work correctly
- Verify that the minimum SDK version supports all required camera features
- Consider adding ProGuard rules if needed for release builds

## Estimated Time: 2-4 hours

## Next Task: Task 2 - Permission Handling and App Structure 