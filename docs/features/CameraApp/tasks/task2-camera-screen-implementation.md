# Task 2: Camera Screen Implementation

**Status:** In Progress  
**Priority:** HIGH (Core MVP functionality)  
**Estimated Completion:** 2-3 hours

## Objective

Implement the core camera screen with live preview, capture functionality, and mode-specific UI that will serve as our primary orientation testing platform for Android devices.

## Success Criteria

1. ✅ Camera preview displays correctly on Pixel 8
2. ✅ Photo capture works with proper orientation metadata
3. ✅ Video recording works with proper orientation metadata
4. ✅ Camera switches between front/rear cameras
5. ✅ Flash controls function properly
6. ✅ App handles lifecycle events (background/foreground)
7. ✅ Orientation testing data is captured and logged

## Implementation Breakdown

### Core Components to Create/Modify

1. **CameraScreen.dart** - Main camera interface
2. **CameraController Provider** - Riverpod provider for camera state
3. **CameraService** - Camera operations service
4. **OrientationService** - Capture device orientation data
5. **CaptureService** - Handle photo/video capture and saving
6. **Navigation Updates** - Route from HomeScreen to CameraScreen

### Key Data Structures

```dart
enum CameraMode { photo, video, combined }
enum FlashMode { off, auto, on, torch }
enum CameraLensDirection { front, back }

class CameraState {
  final CameraController? controller;
  final bool isInitialized;
  final bool isRecording;
  final CameraMode mode;
  final FlashMode flashMode;
  final CameraLensDirection lensDirection;
  final String? errorMessage;
}
```

### Architecture

- **State Management:** Riverpod providers for camera state
- **Service Layer:** Separation of camera operations, file handling, orientation detection
- **UI Layer:** Responsive camera interface with mode-specific controls
- **Error Handling:** Comprehensive error states and user feedback

## Phase 1: Core Camera Infrastructure (30 min)

### 1.1 CameraService Implementation
- Camera initialization and disposal
- Permission checking integration
- Camera switching (front/rear)
- Flash mode control
- Error handling and recovery

### 1.2 Riverpod Providers
- `cameraControllerProvider` - Main camera state
- `availableCamerasProvider` - List available cameras
- `cameraPermissionProvider` - Integration with existing permission system

### 1.3 Basic CameraScreen Structure
- Scaffold with camera preview
- App lifecycle observer integration
- Navigation from HomeScreen

## Phase 2: Photo Capture Mode (45 min)

### 2.1 Photo Capture Implementation
- `takePicture()` functionality
- Save to app-private directory
- EXIF orientation metadata handling
- Visual feedback (flash animation, success/error states)

### 2.2 Photo Mode UI
- Capture button with proper styling
- Camera toggle button
- Flash control toggle
- Mode indicator

### 2.3 Orientation Testing Integration
- Capture device orientation at time of photo
- Log orientation data with captured image
- Store orientation metadata for analysis

## Phase 3: Video Recording Mode (45 min)

### 3.1 Video Recording Implementation
- `startVideoRecording()` and `stopVideoRecording()`
- Recording state management
- Video file saving with proper metadata
- Recording duration timer

### 3.2 Video Mode UI
- Record button with recording indicator
- Recording timer display
- Visual recording feedback (red dot, etc.)

### 3.3 Video Orientation Testing
- Capture orientation data during recording
- Video metadata orientation handling
- Recording session data logging

## Phase 4: Combined Mode & UI Polish (30 min)

### 4.1 Combined Mode Implementation
- Mode selector (Photo/Video toggle)
- Dynamic UI based on current mode
- Seamless mode switching

### 4.2 UI Enhancements
- Material 3 design consistency
- Responsive layout for different screen sizes
- Accessibility improvements
- Loading states and animations

### 4.3 Error Handling & Edge Cases
- Camera initialization failures
- Permission denied scenarios
- Storage full scenarios
- Device rotation during capture

## Testing Strategy

### Unit Tests (15 tests)
- CameraService camera operations
- CaptureService file operations
- OrientationService data capture
- State management providers

### Widget Tests (10 tests)
- CameraScreen UI rendering
- Mode switching functionality
- Button interactions
- Error state displays

### Integration Tests (5 tests)
- End-to-end photo capture flow
- End-to-end video recording flow
- Camera switching functionality
- Orientation data capture accuracy

### Device Testing Focus
- **Primary:** Pixel 8 real device testing
- **Orientations:** Portrait, Landscape Left, Landscape Right, Upside Down
- **Scenarios:** Photo capture, video recording, camera switching
- **Verification:** Native gallery app orientation verification

## Potential Challenges

1. **Camera Initialization:** Different Android devices may have varying camera capabilities
2. **Orientation Handling:** Ensuring EXIF data is correctly written across device orientations
3. **Lifecycle Management:** Properly handling app backgrounding during camera operations
4. **Performance:** Maintaining smooth preview while capturing orientation data
5. **Storage Permissions:** Handling different Android API level storage requirements

## Dependencies

- Existing camera package (already added)
- Existing sensors_plus package (for orientation data)
- Existing path_provider package (for file storage)
- Integration with existing permission system

## Risk Mitigation

- **Camera Failures:** Comprehensive error handling with user-friendly messages
- **Orientation Issues:** Extensive testing across all device orientations
- **Storage Issues:** Graceful handling of storage permission changes
- **Performance:** Minimal orientation polling to avoid battery drain

## Deliverables

1. Fully functional CameraScreen with all three modes
2. Orientation data capture and logging system
3. Comprehensive test suite covering camera operations
4. Documentation of orientation behavior on Pixel 8
5. Error handling for common camera failure scenarios

---

**Next Steps After Completion:**
- Task 3: Gallery Screen for verification
- Task 4: Orientation data analysis and reporting
- Task 5: Additional device testing and comparison 