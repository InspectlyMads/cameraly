# Task 7: Combined Photo/Video Mode

## Status: ⏳ Not Started

## Objective
Implement a combined photo and video mode that mimics standard smartphone camera apps, allowing users to switch between photo and video capture seamlessly with native UI patterns.

## Subtasks

### 7.1 Mode Switching Interface
- [ ] Design native-style mode selector (Photo/Video toggle)
- [ ] Implement smooth mode transition animations
- [ ] Add mode indicator in camera UI
- [ ] Handle mode switching during camera preview
- [ ] Add haptic feedback for mode changes

### 7.2 Unified Capture Button Logic
- [ ] Implement capture button that adapts to current mode
- [ ] Handle photo capture in photo mode
- [ ] Handle video recording in video mode
- [ ] Add mode-appropriate visual feedback
- [ ] Implement long-press for video in photo mode (optional)

### 7.3 Mode-Specific UI States
- [ ] Show/hide mode-specific controls
- [ ] Adapt capture button appearance per mode
- [ ] Display appropriate indicators (timer for video, flash for photo)
- [ ] Handle orientation indicators for both modes
- [ ] Manage storage indicators per mode

### 7.4 Seamless Mode Transitions
- [ ] Maintain camera preview during mode switches
- [ ] Preserve camera settings across modes
- [ ] Handle permission requirements for both modes
- [ ] Smooth UI transitions without flickering
- [ ] Maintain focus and exposure settings

## Detailed Implementation

### 7.1 Native Mode Selector
```dart
Widget _buildNativeModeSelector() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.3),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModeOption('Photo', CaptureMode.photo),
        _buildModeOption('Video', CaptureMode.video),
      ],
    ),
  );
}

Widget _buildModeOption(String title, CaptureMode mode) {
  final isSelected = _currentMode == mode;
  return GestureDetector(
    onTap: () => _switchMode(mode),
    child: AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  );
}
```

### 7.2 Adaptive Capture Button
```dart
Widget _buildAdaptiveCaptureButton() {
  switch (_currentMode) {
    case CaptureMode.photo:
      return _buildNativePhotoCaptureButton();
    case CaptureMode.video:
      return _buildNativeVideoRecordButton();
  }
}

void _handleCaptureAction() {
  switch (_currentMode) {
    case CaptureMode.photo:
      _capturePhoto();
      break;
    case CaptureMode.video:
      if (_isRecording) {
        _stopVideoRecording();
      } else {
        _startVideoRecording();
      }
      break;
  }
}
```

### 7.3 Mode-Specific UI Manager
```dart
class CameraModeManager {
  static Widget buildModeSpecificOverlay(CaptureMode mode, bool isRecording) {
    switch (mode) {
      case CaptureMode.photo:
        return PhotoModeOverlay();
      case CaptureMode.video:
        return VideoModeOverlay(isRecording: isRecording);
    }
  }
  
  static List<Widget> getModeSpecificControls(CaptureMode mode) {
    switch (mode) {
      case CaptureMode.photo:
        return [
          FlashButton(),
          TimerButton(),
          HDRButton(),
        ];
      case CaptureMode.video:
        return [
          FlashButton(),
          VideoQualityButton(),
          AudioMuteButton(),
        ];
    }
  }
}
```

### 7.4 Mode Transition Handler
```dart
Future<void> _switchMode(CaptureMode newMode) async {
  if (_currentMode == newMode) return;
  
  // Stop any ongoing recording
  if (_isRecording && _currentMode == CaptureMode.video) {
    await _stopVideoRecording();
  }
  
  setState(() {
    _currentMode = newMode;
  });
  
  // Trigger haptic feedback
  HapticFeedback.lightImpact();
  
  // Update UI elements
  _updateModeSpecificUI();
  
  // Track mode change for analytics
  _trackModeSwitch(newMode);
}
```

## Files to Create
- `lib/features/combined_camera_mode.dart`
- `lib/widgets/native_mode_selector.dart`
- `lib/widgets/adaptive_capture_button.dart`
- `lib/widgets/photo_mode_overlay.dart`
- `lib/widgets/video_mode_overlay.dart`
- `lib/utils/camera_mode_manager.dart`

## Files to Modify
- `lib/screens/camera_screen.dart` (add combined mode logic)
- `lib/models/camera_mode.dart` (extend for combined mode)

## Native UI Requirements

### Mode Selector Design
- Positioned at bottom-right of screen
- Semi-transparent background with rounded corners
- Smooth sliding animation for selection
- White text on transparent, black text on white selection
- Maintains thumb-friendly touch targets

### Unified Control Layout
- Single capture button that adapts to current mode
- Mode-specific controls shown/hidden smoothly
- Consistent positioning regardless of mode
- Natural transitions without jarring layout changes

### Visual Continuity
- Camera preview remains stable during mode switches
- No interruption to focus or exposure settings
- Smooth color/icon transitions
- Maintain immersive full-screen experience

## Orientation Testing for Combined Mode

### Mode Switching in Different Orientations
- [ ] Test mode switching in portrait orientation
- [ ] Test mode switching in landscape left
- [ ] Test mode switching in landscape right
- [ ] Verify UI elements maintain proper positioning
- [ ] Test capture in each mode after orientation change

### Cross-Mode Orientation Testing
- [ ] Switch from photo to video in different orientations
- [ ] Verify both modes handle orientation correctly
- [ ] Test orientation metadata consistency across modes
- [ ] Verify gallery display works for both modes

## Acceptance Criteria
- [ ] Mode switching works smoothly without preview interruption
- [ ] Capture button adapts correctly to current mode
- [ ] Mode-specific controls appear/disappear appropriately
- [ ] UI maintains native look and feel in both modes
- [ ] Orientation handling works consistently across modes
- [ ] No memory leaks during frequent mode switching
- [ ] Performance remains smooth during mode transitions
- [ ] Both photo and video capture work correctly
- [ ] Haptic feedback provides appropriate user feedback
- [ ] Mode state persists across app lifecycle events

## Testing Points
- [ ] Test rapid mode switching
- [ ] Verify mode persistence after app backgrounding
- [ ] Test mode switching during ongoing video recording
- [ ] Verify UI layout in all orientations
- [ ] Test capture functionality in both modes
- [ ] Check for memory leaks during extended use
- [ ] Verify smooth animations and transitions
- [ ] Test on devices with different screen sizes
- [ ] Verify accessibility features work in both modes
- [ ] Test mode switching with gesture navigation

## Performance Considerations
- Minimize mode switching overhead
- Maintain smooth 60fps during transitions
- Efficient memory usage across mode changes
- Battery-conscious implementation
- No camera reinitialization during mode switch

## User Experience Guidelines
- Mode switch should be intuitive and discoverable
- Visual feedback should be immediate and clear
- Current mode should always be obvious to user
- Transitions should feel natural and responsive
- Controls should remain familiar across modes

## Notes
- This mode simulates the standard camera app experience
- Focus on maintaining the immersive, native feel
- Ensure orientation testing works seamlessly in both modes
- Consider adding mode-specific shortcuts (volume buttons, gestures)
- Document any performance differences between modes

## Estimated Time: 3-4 hours

## Next Task: Task 8 - Gallery Screen for Media Verification 