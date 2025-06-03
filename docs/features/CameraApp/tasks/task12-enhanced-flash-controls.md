# Task 12: Enhanced Flash Controls

**Status**: 🔄 Todo  
**Priority**: Medium  
**Estimated Time**: 2-3 hours  
**Dependencies**: Task 11 (Camera Lens Switching)

## Problem Description

The current flash controls need enhancement to provide a more professional camera experience with proper mode distinctions between photo and video capture.

**Current Issues:**
- Flash modes are basic and not contextual
- No distinction between photo and video flash behavior
- Missing "Auto" mode for photos
- Torch mode for video not properly implemented
- Flash availability not properly checked for front camera

## Requirements from Testing Feedback

### Photo Mode Flash States
1. **Off**: Flash disabled
2. **Auto**: Camera decides based on lighting conditions
3. **On**: Flash always fires

### Video Mode Flash States
1. **Off**: No light
2. **On**: Torch/continuous light during recording

### Constraints
- Front camera typically has no flash (hide controls)
- Video mode shouldn't show "Auto" option
- Flash state should persist when switching modes
- Visual feedback for current state

## Solution Approach

### 1. Enhanced Flash Mode System
- Separate photo and video flash modes
- Context-aware controls based on camera mode
- Proper flash availability detection

### 2. Improved UI Feedback
- Clear icons for each flash state
- Mode-specific flash controls
- Visual indication of current state

### 3. Smart Flash Management
- Automatic torch control for video
- Flash state persistence across mode switches
- Camera-specific flash capabilities

## Implementation Plan

### Step 1: Extend Flash Mode Enums
```dart
enum PhotoFlashMode { off, auto, on }
enum VideoFlashMode { off, torch }

class CameraState {
  // Replace single flashMode with context-specific modes
  final PhotoFlashMode photoFlashMode;
  final VideoFlashMode videoFlashMode;
  
  // ... other properties
  
  CameraState copyWith({
    PhotoFlashMode? photoFlashMode,
    VideoFlashMode? videoFlashMode,
    // ... other parameters
  }) {
    return CameraState(
      photoFlashMode: photoFlashMode ?? this.photoFlashMode,
      videoFlashMode: videoFlashMode ?? this.videoFlashMode,
      // ... other assignments
    );
  }
}
```

### Step 2: Update Camera Service Flash Logic
```dart
class CameraService {
  // Map photo flash modes to camera package flash modes
  FlashMode _mapPhotoFlashMode(PhotoFlashMode mode) {
    switch (mode) {
      case PhotoFlashMode.off:
        return FlashMode.off;
      case PhotoFlashMode.auto:
        return FlashMode.auto;
      case PhotoFlashMode.on:
        return FlashMode.always;
    }
  }

  // Map video flash modes to camera package flash modes
  FlashMode _mapVideoFlashMode(VideoFlashMode mode) {
    switch (mode) {
      case VideoFlashMode.off:
        return FlashMode.off;
      case VideoFlashMode.torch:
        return FlashMode.torch;
    }
  }

  // Set flash mode based on camera mode context
  Future<void> setFlashModeForContext({
    required CameraController controller,
    required CameraMode cameraMode,
    PhotoFlashMode? photoMode,
    VideoFlashMode? videoMode,
  }) async {
    if (!hasFlash(controller)) return;

    FlashMode flashMode;
    if (cameraMode == CameraMode.video) {
      flashMode = _mapVideoFlashMode(videoMode ?? VideoFlashMode.off);
    } else {
      flashMode = _mapPhotoFlashMode(photoMode ?? PhotoFlashMode.off);
    }

    await controller.setFlashMode(flashMode);
    debugPrint('Flash mode set to $flashMode for ${cameraMode.name}');
  }

  // Get next flash mode for cycling
  PhotoFlashMode getNextPhotoFlashMode(PhotoFlashMode current) {
    switch (current) {
      case PhotoFlashMode.off:
        return PhotoFlashMode.auto;
      case PhotoFlashMode.auto:
        return PhotoFlashMode.on;
      case PhotoFlashMode.on:
        return PhotoFlashMode.off;
    }
  }

  VideoFlashMode getNextVideoFlashMode(VideoFlashMode current) {
    switch (current) {
      case VideoFlashMode.off:
        return VideoFlashMode.torch;
      case VideoFlashMode.torch:
        return VideoFlashMode.off;
    }
  }

  // Get display names
  String getPhotoFlashDisplayName(PhotoFlashMode mode) {
    switch (mode) {
      case PhotoFlashMode.off:
        return 'Off';
      case PhotoFlashMode.auto:
        return 'Auto';
      case PhotoFlashMode.on:
        return 'On';
    }
  }

  String getVideoFlashDisplayName(VideoFlashMode mode) {
    switch (mode) {
      case VideoFlashMode.off:
        return 'Off';
      case VideoFlashMode.torch:
        return 'Torch';
    }
  }

  // Get icons for flash modes
  String getPhotoFlashIcon(PhotoFlashMode mode) {
    switch (mode) {
      case PhotoFlashMode.off:
        return '⚫'; // or Icons.flash_off
      case PhotoFlashMode.auto:
        return '⚡'; // or Icons.flash_auto
      case PhotoFlashMode.on:
        return '💡'; // or Icons.flash_on
    }
  }

  String getVideoFlashIcon(VideoFlashMode mode) {
    switch (mode) {
      case VideoFlashMode.off:
        return '⚫'; // or Icons.flash_off
      case VideoFlashMode.torch:
        return '🔦'; // or Icons.flashlight_on
    }
  }
}
```

### Step 3: Update Camera Controller
```dart
class CameraController extends _$CameraController {
  @override
  CameraState build() {
    return const CameraState(
      photoFlashMode: PhotoFlashMode.off,
      videoFlashMode: VideoFlashMode.off,
      // ... other initial values
    );
  }

  /// Cycle flash mode based on current camera mode
  Future<void> cycleFlashMode() async {
    if (!state.isInitialized || state.controller == null) return;

    final service = ref.read(cameraServiceProvider);
    if (!service.hasFlash(state.controller!)) return;

    if (state.mode == CameraMode.video) {
      final nextVideoMode = service.getNextVideoFlashMode(state.videoFlashMode);
      await service.setFlashModeForContext(
        controller: state.controller!,
        cameraMode: state.mode,
        videoMode: nextVideoMode,
      );
      state = state.copyWith(videoFlashMode: nextVideoMode);
    } else {
      final nextPhotoMode = service.getNextPhotoFlashMode(state.photoFlashMode);
      await service.setFlashModeForContext(
        controller: state.controller!,
        cameraMode: state.mode,
        photoMode: nextPhotoMode,
      );
      state = state.copyWith(photoFlashMode: nextPhotoMode);
    }
  }

  /// Update flash mode when camera mode changes
  Future<void> switchMode(CameraMode newMode) async {
    if (state.mode == newMode) return;

    final oldMode = state.mode;
    state = state.copyWith(mode: newMode);

    // Update flash settings for new mode
    if (state.controller != null) {
      final service = ref.read(cameraServiceProvider);
      await service.setFlashModeForContext(
        controller: state.controller!,
        cameraMode: newMode,
        photoMode: state.photoFlashMode,
        videoMode: state.videoFlashMode,
      );
    }

    // Reinitialize camera if switching to/from video mode
    if ((oldMode == CameraMode.video || newMode == CameraMode.video) && 
        state.controller != null) {
      await _reinitializeCamera();
    }
  }
}
```

### Step 4: Update Flash Control UI
```dart
Widget _buildFlashControl() {
  final cameraState = ref.watch(cameraControllerProvider);
  final hasFlash = ref.watch(cameraHasFlashProvider);

  if (!hasFlash) {
    return const SizedBox(width: 48);
  }

  // Get current flash mode and icon based on camera mode
  String icon;
  String displayName;
  
  if (cameraState.mode == CameraMode.video) {
    final service = ref.read(cameraServiceProvider);
    icon = service.getVideoFlashIcon(cameraState.videoFlashMode);
    displayName = service.getVideoFlashDisplayName(cameraState.videoFlashMode);
  } else {
    final service = ref.read(cameraServiceProvider);
    icon = service.getPhotoFlashIcon(cameraState.photoFlashMode);
    displayName = service.getPhotoFlashDisplayName(cameraState.photoFlashMode);
  }

  return CircleAvatar(
    backgroundColor: Colors.black54,
    child: IconButton(
      icon: Text(
        icon,
        style: const TextStyle(fontSize: 20),
      ),
      onPressed: () async {
        await ref.read(cameraControllerProvider.notifier).cycleFlashMode();

        // Show flash mode change feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Flash: $displayName'),
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

### Step 5: Update Provider Dependencies
```dart
@riverpod
String currentFlashDisplayName(CurrentFlashDisplayNameRef ref) {
  final cameraState = ref.watch(cameraControllerProvider);
  final service = ref.read(cameraServiceProvider);
  
  if (cameraState.mode == CameraMode.video) {
    return service.getVideoFlashDisplayName(cameraState.videoFlashMode);
  } else {
    return service.getPhotoFlashDisplayName(cameraState.photoFlashMode);
  }
}

@riverpod
String currentFlashIcon(CurrentFlashIconRef ref) {
  final cameraState = ref.watch(cameraControllerProvider);
  final service = ref.read(cameraServiceProvider);
  
  if (cameraState.mode == CameraMode.video) {
    return service.getVideoFlashIcon(cameraState.videoFlashMode);
  } else {
    return service.getPhotoFlashIcon(cameraState.photoFlashMode);
  }
}
```

## Acceptance Criteria

- [ ] Photo mode shows Off/Auto/On flash options
- [ ] Video mode shows Off/Torch flash options  
- [ ] Flash controls hidden when front camera is active
- [ ] Flash state persists when switching between photo/video modes
- [ ] Visual feedback shows current flash mode
- [ ] Torch works properly during video recording
- [ ] Auto flash works for photo capture
- [ ] Smooth cycling through flash modes
- [ ] Flash controls work in both portrait and landscape

## Testing Strategy

### Functional Testing
- Test all flash modes in photo mode
- Test torch functionality in video mode
- Verify flash persistence across mode switches
- Test auto flash in various lighting conditions

### Camera Switching
- Verify flash controls hide/show when switching cameras
- Test flash state reset when switching to front camera
- Ensure flash settings apply to new camera after switch

### Video Recording
- Test torch activation during recording
- Verify torch deactivation when stopping recording
- Test flash mode changes during recording (should be disabled)

## Technical Considerations

### Performance
- Minimize flash mode switching overhead
- Avoid flash flicker during mode changes
- Ensure smooth video recording with torch

### Hardware Compatibility
- Handle devices without flash gracefully
- Account for different flash implementations
- Test on various manufacturers (Samsung, Pixel, etc.)

### Battery Impact
- Consider battery usage of torch mode
- Provide warnings for extended torch use
- Optimize flash initialization

## Edge Cases

1. **No Flash Hardware**: Gracefully hide all flash controls
2. **Flash Hardware Failure**: Show error state, disable controls
3. **Low Battery**: Consider torch limitations
4. **Overheating**: Handle flash/torch thermal protection
5. **Rapid Mode Switching**: Debounce flash mode changes

## Implementation Notes

- Test extensively on different lighting conditions
- Consider adding flash intensity controls in future
- Ensure flash works with orientation handling system
- Add analytics for flash usage patterns

## Dependencies

- Camera service flash detection logic
- Updated camera state management
- UI components for flash controls
- Camera lens switching functionality (Task 11) 