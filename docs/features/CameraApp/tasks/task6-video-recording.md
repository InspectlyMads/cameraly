# Task 6: Video Recording Implementation

## Status: ⏳ Not Started

## Objective
Implement video recording functionality with native camera UI styling and comprehensive orientation testing to verify video rotation metadata across different device orientations.

## Subtasks

### 6.1 Video Recording Core Logic
- [ ] Implement `startVideoRecording()` and `stopVideoRecording()` methods
- [ ] Add native video recording button UI
- [ ] Handle recording state management
- [ ] Implement recording timer display
- [ ] Add video compression settings

### 6.2 Orientation-Aware Video Recording
- [ ] Track device orientation during video recording
- [ ] Ensure video rotation metadata is correctly set
- [ ] Handle camera sensor orientation vs device orientation for video
- [ ] Test recording in all four device orientations
- [ ] Verify metadata preservation in video files

### 6.3 Video Storage and Management
- [ ] Save videos to app-private directory
- [ ] Generate unique, descriptive video filenames
- [ ] Include orientation metadata in filename/database
- [ ] Implement video quality settings
- [ ] Add storage space monitoring during recording

### 6.4 Native Video Recording UI
- [ ] Design native-style video recording interface
- [ ] Add recording indicator (red dot/pulse animation)
- [ ] Implement recording timer display
- [ ] Create video-specific capture button styling
- [ ] Add orientation indicator for testing

### 6.5 Video Recording Features
- [ ] Configure optimal video resolution and quality
- [ ] Implement video stabilization if available
- [ ] Add microphone audio recording
- [ ] Handle different video formats
- [ ] Add pause/resume functionality (optional)

## Detailed Implementation

### 6.1 Video Recording Method
```dart
Future<void> _startVideoRecording() async {
  if (!_controller.value.isInitialized || _controller.value.isRecordingVideo) {
    return;
  }
  
  try {
    // Track orientation at recording start
    final orientation = await _getDeviceOrientation();
    
    await _controller.startVideoRecording();
    
    setState(() {
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _recordingOrientation = orientation;
    });
    
    _startRecordingTimer();
    _showRecordingIndicator();
    
  } catch (e) {
    _showRecordingError(e.toString());
  }
}

Future<void> _stopVideoRecording() async {
  if (!_controller.value.isRecordingVideo) return;
  
  try {
    final XFile video = await _controller.stopVideoRecording();
    
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
    
    await _saveVideoWithMetadata(video, _recordingOrientation);
    _showRecordingSuccess();
    
  } catch (e) {
    _showRecordingError(e.toString());
  }
}
```

### 6.2 Native Video Recording Button
```dart
Widget _buildNativeVideoRecordButton() {
  return GestureDetector(
    onTap: _isRecording ? _stopVideoRecording : _startVideoRecording,
    child: Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: _isRecording 
            ? Colors.red.withOpacity(0.8) 
            : Colors.white.withOpacity(0.3), 
          width: 4
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: _isRecording ? 25 : 50,
          height: _isRecording ? 25 : 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_isRecording ? 4 : 25),
            color: _isRecording ? Colors.red : Colors.white,
          ),
        ),
      ),
    ),
  );
}
```

### 6.3 Native Recording Indicator
```dart
Widget _buildRecordingIndicator() {
  if (!_isRecording) return SizedBox.shrink();
  
  return Positioned(
    top: 60,
    left: 20,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(_pulseAnimation.value),
                ),
              );
            },
          ),
          SizedBox(width: 8),
          Text(
            _formatRecordingTime(_recordingDuration),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

String _formatRecordingTime(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(duration.inMinutes);
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '$minutes:$seconds';
}
```

### 6.4 Video Metadata Structure
```dart
class VideoMetadata {
  final String deviceOrientation;
  final DateTime recordingStarted;
  final Duration recordingDuration;
  final String cameraLens; // front/rear
  final String resolution;
  final String deviceModel;
  final String androidVersion;
  final String appVersion;
  final bool hasAudio;
}
```

## Files to Create
- `lib/features/video_recording.dart`
- `lib/models/video_metadata.dart`
- `lib/widgets/native_video_record_button.dart`
- `lib/widgets/native_recording_indicator.dart`
- `lib/widgets/native_recording_timer.dart`
- `lib/services/video_storage_service.dart`

## Files to Modify
- `lib/screens/camera_screen.dart` (add video mode logic)
- `lib/services/storage_service.dart` (extend for videos)

## Critical Orientation Testing for Video

### Test Matrix for Video Recording
For each device orientation, record multiple videos and verify:

#### Portrait Upright
- [ ] Start recording in portrait upright position
- [ ] Verify video rotation metadata is correct
- [ ] Check video plays correctly in gallery without manual rotation
- [ ] Test with both front and rear cameras

#### Landscape Left (USB port right)
- [ ] Start recording in landscape left position
- [ ] Verify video metadata compensates for rotation
- [ ] Check video auto-rotates correctly in players
- [ ] Test different recording durations

#### Landscape Right (USB port left)
- [ ] Start recording in landscape right position
- [ ] Verify video orientation metadata
- [ ] Confirm proper rotation in gallery apps
- [ ] Test across different video resolutions

#### Portrait Upside Down
- [ ] Record video upside down (if supported)
- [ ] Verify orientation handling edge case
- [ ] Check for proper video rotation data
- [ ] Test system gallery playback

### Orientation Change During Recording
- [ ] Start recording in one orientation, rotate device mid-recording
- [ ] Verify video maintains consistent orientation
- [ ] Test preview behavior during rotation while recording
- [ ] Check final video metadata and playback

## Native Video Recording UI Requirements

### Recording State Visual Design
- Recording button transforms from circle to rounded square
- Red border and fill color during recording
- Pulsing red dot indicator with timer
- Minimal overlay disruption during recording
- Smooth transitions between recording states

### Audio Recording Integration
- Microphone permission handling
- Audio level indicator (optional)
- Mute toggle during recording
- Audio quality settings

### Storage Management
- Real-time storage space monitoring
- Warning when storage is low
- Automatic stop when storage full
- File size estimation display

## Video Quality Settings

### Resolution Options
- 1080p (default for testing)
- 720p (for storage efficiency)
- 4K (if device supports)
- Match preview resolution

### Compression Settings
- Balanced quality/size ratio
- Maintain metadata integrity
- Optimize for sharing
- Consider battery impact

## Acceptance Criteria
- [ ] Videos record successfully in all orientations
- [ ] Video rotation metadata is correctly set
- [ ] Recorded videos play properly in device gallery
- [ ] Video files are saved with descriptive metadata
- [ ] Recording button provides native-style feedback
- [ ] Recording timer displays accurately
- [ ] Audio recording works properly
- [ ] Storage management functions correctly
- [ ] UI remains responsive during recording
- [ ] Memory usage is stable during long recordings

## Testing Points
- [ ] Test video recording in all four orientations
- [ ] Verify video metadata with third-party tools
- [ ] Test with front and rear cameras
- [ ] Verify gallery playback on multiple devices
- [ ] Test audio synchronization
- [ ] Verify file naming conventions
- [ ] Test recording button responsiveness
- [ ] Check for memory leaks during long recordings
- [ ] Test error scenarios (low storage, permission revoked)
- [ ] Verify video quality consistency

## Performance Requirements
- Video recording starts within 1 second
- UI remains responsive during recording
- Memory usage stable during extended recording
- Battery usage optimized
- Storage operations are efficient
- No frame drops during recording

## Testing Documentation

### Video Test Log Template
```
Device: [Model Name]
Android Version: [Version]
Test Date: [Date]
Camera: [Front/Rear]
Video Quality: [Resolution]

Orientation Tests:
- Portrait Up: PASS/FAIL [Notes]
- Landscape Left: PASS/FAIL [Notes]  
- Landscape Right: PASS/FAIL [Notes]
- Portrait Down: PASS/FAIL [Notes]
- Mid-Recording Rotation: PASS/FAIL [Notes]

Video Playback:
- In-App Gallery: PASS/FAIL
- Device Gallery: PASS/FAIL
- Third-Party Players: PASS/FAIL

Issues Found: [Description]
```

## Notes
- Video orientation is more complex than photos due to temporal nature
- Test extensively with different video players
- Pay special attention to metadata preservation
- Document any device-specific video orientation behaviors
- Consider creating sample videos for each orientation as reference

## Estimated Time: 5-7 hours

## Next Task: Task 7 - Combined Photo/Video Mode 