# Task 11: Camera Lens Switching Fix

**Status**: 🔄 Todo  
**Priority**: High  
**Estimated Time**: 1-2 hours  
**Dependencies**: Camera Service Implementation

## Problem Description

The camera lens switching button is not working - users cannot switch from back camera to front camera. This is a critical feature for selfies and video calls.

**Current Issues:**
- Camera switch button appears but doesn't function
- No visual feedback when button is pressed
- Front camera never initializes
- Error handling for switching failures is insufficient

## Root Cause Analysis

Based on the current implementation, likely issues:

1. **Camera Service Logic**: `switchCamera()` method may have bugs
2. **Camera Description Mapping**: Lens direction enum vs camera description mismatch
3. **Controller Disposal**: Issues with disposing/reinitializing camera
4. **State Management**: Riverpod state not updating correctly
5. **Permission Issues**: Front camera may need additional permissions

## Solution Approach

### 1. Debug Current Implementation
- Add logging to camera switching process
- Verify available cameras detection
- Check camera description mappings

### 2. Fix Camera Service Logic
- Ensure proper camera disposal/reinitialization
- Handle lens direction mapping correctly
- Add error handling for switching failures

### 3. Improve User Feedback
- Show loading state during switch
- Provide error messages for failures
- Animate button state changes

## Implementation Plan

### Step 1: Debug Camera Availability
```dart
// Add to CameraService
Future<void> debugAvailableCameras() async {
  final cameras = await availableCameras();
  for (final camera in cameras) {
    debugPrint('Camera: ${camera.name}');
    debugPrint('  Lens Direction: ${camera.lensDirection}');
    debugPrint('  Sensor Orientation: ${camera.sensorOrientation}');
  }
}
```

### Step 2: Fix Lens Direction Mapping
```dart
// Update CameraService.switchCamera()
Future<CameraController> switchCamera({
  required CameraController currentController,
  required List<CameraDescription> cameras,
  required CameraLensDirection newLensDirection,
}) async {
  debugPrint('Switching to ${newLensDirection.name} camera');

  // Find camera with desired lens direction
  CameraDescription? targetCamera;
  for (final camera in cameras) {
    if (_mapLensDirection(camera.lensDirection) == newLensDirection) {
      targetCamera = camera;
      break;
    }
  }

  if (targetCamera == null) {
    throw Exception('No ${newLensDirection.name} camera found');
  }

  // Dispose current controller
  await currentController.dispose();

  // Initialize new camera
  final newController = CameraController(
    targetCamera,
    ResolutionPreset.high,
    enableAudio: true,
    imageFormatGroup: ImageFormatGroup.jpeg,
  );

  await newController.initialize();
  return newController;
}

// Fix lens direction mapping
CameraLensDirection _mapLensDirection(camera.CameraLensDirection lensDirection) {
  switch (lensDirection) {
    case camera.CameraLensDirection.front:
      return CameraLensDirection.front;
    case camera.CameraLensDirection.back:
      return CameraLensDirection.back;
    case camera.CameraLensDirection.external:
      return CameraLensDirection.back; // Default to back for external cameras
  }
}
```

### Step 3: Improve State Management
```dart
// Update CameraController.switchCamera()
Future<void> switchCamera() async {
  if (!state.isInitialized || state.availableCameras.length < 2) {
    return;
  }

  final service = ref.read(cameraServiceProvider);
  final newLensDirection = service.getOppositeLensDirection(state.lensDirection);

  state = state.copyWith(isLoading: true, errorMessage: null);

  try {
    final newController = await service.switchCamera(
      currentController: state.controller!,
      cameras: state.availableCameras,
      newLensDirection: newLensDirection,
    );

    state = state.copyWith(
      controller: newController,
      lensDirection: newLensDirection,
      isLoading: false,
      errorMessage: null,
    );

    // Reset flash mode after switching (front camera usually doesn't have flash)
    await _setInitialFlashMode(newController);
    
  } catch (e) {
    debugPrint('Camera switch failed: $e');
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Failed to switch camera: ${e.toString()}',
    );
  }
}
```

### Step 4: Enhance UI Feedback
```dart
// Update camera switch button in CameraScreen
Widget _buildCameraSwitchControl() {
  final canSwitch = ref.watch(canSwitchCameraProvider);
  final cameraState = ref.watch(cameraControllerProvider);

  if (!canSwitch) {
    return const SizedBox(width: 48);
  }

  return CircleAvatar(
    backgroundColor: Colors.black54,
    child: cameraState.isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : IconButton(
            icon: Icon(
              cameraState.lensDirection == CameraLensDirection.front
                  ? Icons.camera_front
                  : Icons.camera_rear,
              color: Colors.white,
            ),
            onPressed: () async {
              await ref.read(cameraControllerProvider.notifier).switchCamera();
              
              // Show feedback
              if (mounted) {
                final newDirection = ref.read(cameraControllerProvider).lensDirection;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Switched to ${newDirection.name} camera'),
                    duration: const Duration(milliseconds: 1500),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
  );
}
```

## Acceptance Criteria

- [ ] Camera switch button works reliably
- [ ] Can switch between front and back cameras
- [ ] Button shows correct icon for current camera
- [ ] Loading state displayed during switch
- [ ] Error handling for switching failures
- [ ] Flash controls update appropriately (front camera typically has no flash)
- [ ] Smooth transition without preview flicker
- [ ] Works in both portrait and landscape orientations

## Testing Strategy

### Functional Testing
- Verify switching works on devices with front cameras
- Test on devices with only back camera (button should be hidden)
- Test rapid switching (prevent multiple simultaneous switches)
- Verify flash controls update correctly

### Error Testing
- Test behavior when front camera is not available
- Test switching while recording (should be disabled)
- Test switching during photo capture
- Handle permissions issues for front camera

### Performance Testing
- Ensure switching is smooth and fast
- Verify no memory leaks from improper disposal
- Test impact on preview frame rate

## Technical Considerations

### Camera Disposal
- Ensure proper cleanup of previous controller
- Prevent memory leaks from retained cameras
- Handle disposal errors gracefully

### Orientation Handling
- Maintain orientation state during switch
- Ensure preview transforms correctly for new camera
- Update orientation-specific UI elements

### Flash Controls
- Front cameras typically don't have flash
- Update flash button visibility/state
- Reset flash mode when switching

## Edge Cases

1. **Single Camera Devices**: Hide switch button appropriately
2. **Permission Issues**: Handle front camera permission denials
3. **Hardware Failures**: Graceful degradation if camera fails
4. **App Lifecycle**: Handle switching during background transitions
5. **Memory Pressure**: Ensure switching works under low memory conditions

## Implementation Notes

- Add comprehensive logging for debugging
- Test on multiple device types and manufacturers
- Consider adding unit tests for camera switching logic
- Ensure compatibility with orientation handling system

## Dependencies

- Camera service must be properly implemented
- Riverpod state management for loading states
- Error handling utilities
- Orientation detection system integration 