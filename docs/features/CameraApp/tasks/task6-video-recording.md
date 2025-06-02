# Task 6: Advanced Video Recording with Orientation Intelligence

## Status: ⏳ Not Started

## Objective
Implement sophisticated video recording functionality that integrates seamlessly with the advanced orientation-aware camera controller and dual UI system from Task 4, ensuring perfect video rotation metadata and comprehensive orientation testing across device rotations and manufacturer variations.

## Subtasks

### 6.1 Orientation-Integrated Video Recording
- [ ] Integrate with OrientationAwareCameraController from Task 4
- [ ] Implement recording with real-time orientation compensation
- [ ] Handle manufacturer-specific video orientation corrections
- [ ] Add multi-sensor orientation validation during recording
- [ ] Implement orientation override for video testing scenarios

### 6.2 Advanced Video Metadata Management
- [ ] Generate comprehensive video rotation metadata with device-specific corrections
- [ ] Include camera sensor orientation in video metadata
- [ ] Add device manufacturer and model information to video files
- [ ] Implement custom orientation metadata fields for testing
- [ ] Validate video metadata accuracy across different device types

### 6.3 Dual-UI Video Recording Integration
- [ ] Implement video recording for portrait UI overlay
- [ ] Implement video recording for landscape UI overlay
- [ ] Handle recording button adaptation across orientations
- [ ] Add orientation-aware recording feedback animations
- [ ] Implement touch target validation for recording controls

### 6.4 Enhanced Video Storage with Orientation Context
- [ ] Save videos with comprehensive orientation metadata
- [ ] Include recording orientation context in filename/database
- [ ] Store device orientation vs sensor orientation data during recording
- [ ] Implement orientation verification during video storage
- [ ] Add batch orientation analysis for recorded videos

### 6.5 Testing-Focused Video Features
- [ ] Add real-time orientation indicator during recording
- [ ] Implement recording orientation logging for analysis
- [ ] Create video orientation test mode with enhanced debugging
- [ ] Add automatic orientation verification post-recording
- [ ] Implement recording accuracy statistics tracking

## Detailed Implementation

### 6.1 Orientation-Aware Video Recording
```dart
class OrientationAwareVideoRecording {
  final OrientationAwareCameraController _cameraController;
  final VideoMetadataService _metadataService;
  
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  OrientationData? _recordingStartOrientation;
  List<OrientationEvent> _orientationEventsWhileRecording = [];
  
  Future<VideoRecordingResult> startVideoRecordingWithOrientation() async {
    if (!_cameraController.isInitialized || _isRecording) {
      throw VideoRecordingException('Cannot start recording: Invalid state');
    }
    
    try {
      // Gather comprehensive orientation data before recording starts
      final startOrientationData = await _gatherOrientationData();
      
      // Validate orientation data consistency
      await _validateOrientationConsistency(startOrientationData);
      
      // Configure camera for optimal video recording based on orientation
      await _optimizeCameraForVideoOrientation(startOrientationData);
      
      // Start video recording with orientation context
      await _cameraController.startVideoRecording();
      
      // Set up orientation monitoring during recording
      _setupRecordingOrientationMonitoring();
      
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _recordingStartOrientation = startOrientationData;
      
      return VideoRecordingResult.started(
        startOrientation: startOrientationData,
        timestamp: _recordingStartTime!,
      );
      
    } catch (e) {
      throw VideoRecordingException('Failed to start recording with orientation: $e');
    }
  }
  
  Future<VideoRecordingResult> stopVideoRecordingWithOrientation() async {
    if (!_isRecording) {
      throw VideoRecordingException('No recording in progress');
    }
    
    try {
      // Gather orientation data at recording end
      final endOrientationData = await _gatherOrientationData();
      
      // Stop video recording
      final XFile videoFile = await _cameraController.stopVideoRecording();
      
      // Calculate recording duration and orientation changes
      final recordingDuration = DateTime.now().difference(_recordingStartTime!);
      
      // Enhance video with comprehensive orientation metadata
      final enhancedVideo = await _enhanceVideoWithOrientationData(
        videoFile,
        _recordingStartOrientation!,
        endOrientationData,
        _orientationEventsWhileRecording,
        recordingDuration,
      );
      
      // Verify video orientation accuracy
      final verificationResult = await _verifyVideoOrientationAccuracy(
        enhancedVideo,
        _recordingStartOrientation!,
      );
      
      // Clean up recording state
      _isRecording = false;
      _recordingStartTime = null;
      _recordingStartOrientation = null;
      _orientationEventsWhileRecording.clear();
      
      return VideoRecordingResult.completed(
        video: enhancedVideo,
        startOrientation: _recordingStartOrientation!,
        endOrientation: endOrientationData,
        orientationEvents: List.from(_orientationEventsWhileRecording),
        duration: recordingDuration,
        verificationResult: verificationResult,
      );
      
    } catch (e) {
      _isRecording = false;
      throw VideoRecordingException('Failed to stop recording with orientation: $e');
    }
  }
  
  void _setupRecordingOrientationMonitoring() {
    // Monitor orientation changes during recording
    _cameraController.orientationStream.listen((orientationData) {
      if (_isRecording) {
        _orientationEventsWhileRecording.add(
          OrientationEvent(
            timestamp: DateTime.now(),
            orientation: orientationData,
            timeSinceRecordingStart: DateTime.now().difference(_recordingStartTime!),
          ),
        );
      }
    });
  }
}
```

### 6.2 Enhanced Video Metadata Service
```dart
class EnhancedVideoMetadataService {
  static Future<File> enhanceVideoWithOrientationData(
    XFile video,
    OrientationData startOrientation,
    OrientationData endOrientation,
    List<OrientationEvent> orientationEvents,
    Duration recordingDuration,
  ) async {
    // Calculate video rotation metadata
    final videoRotation = _calculateVideoRotation(startOrientation);
    
    // Create comprehensive video metadata
    final videoMetadata = {
      'rotation': videoRotation,
      'startOrientation': {
        'device': startOrientation.deviceOrientation.toString(),
        'camera': startOrientation.cameraRotation,
        'sensor': startOrientation.sensorOrientation,
        'timestamp': startOrientation.timestamp.toIso8601String(),
      },
      'endOrientation': {
        'device': endOrientation.deviceOrientation.toString(),
        'camera': endOrientation.cameraRotation,
        'sensor': endOrientation.sensorOrientation,
        'timestamp': endOrientation.timestamp.toIso8601String(),
      },
      'orientationChanges': orientationEvents.map((e) => {
        'timestamp': e.timestamp.toIso8601String(),
        'timeSinceStart': e.timeSinceRecordingStart.inMilliseconds,
        'orientation': e.orientation.deviceOrientation.toString(),
        'cameraRotation': e.orientation.cameraRotation,
      }).toList(),
      'deviceInfo': {
        'manufacturer': startOrientation.deviceManufacturer,
        'model': startOrientation.deviceModel,
        'androidVersion': startOrientation.androidVersion,
      },
      'recordingDuration': recordingDuration.inMilliseconds,
      'orientationStability': _calculateOrientationStability(orientationEvents),
      'testingMetadata': _generateVideoTestingMetadata(
        startOrientation, 
        endOrientation, 
        orientationEvents
      ),
    };
    
    // Write metadata to video file (using FFmpeg or similar)
    final enhancedVideo = await _writeVideoMetadata(video, videoMetadata);
    
    return enhancedVideo;
  }
  
  static int _calculateVideoRotation(OrientationData orientation) {
    // Calculate video rotation based on device orientation and manufacturer corrections
    switch (orientation.deviceOrientation) {
      case DeviceOrientation.portraitUp:
        return _applyVideoManufacturerCorrection(0, orientation);
      case DeviceOrientation.landscapeLeft:
        return _applyVideoManufacturerCorrection(270, orientation);
      case DeviceOrientation.landscapeRight:
        return _applyVideoManufacturerCorrection(90, orientation);
      case DeviceOrientation.portraitDown:
        return _applyVideoManufacturerCorrection(180, orientation);
      default:
        return 0;
    }
  }
  
  static int _applyVideoManufacturerCorrection(int baseRotation, OrientationData data) {
    // Apply device-specific video rotation corrections
    if (data.deviceManufacturer.toLowerCase().contains('samsung')) {
      return _applySamsungVideoCorrection(baseRotation, data);
    } else if (data.deviceManufacturer.toLowerCase().contains('xiaomi')) {
      return _applyXiaomiVideoCorrection(baseRotation, data);
    }
    return baseRotation;
  }
  
  static String _calculateOrientationStability(List<OrientationEvent> events) {
    if (events.length <= 1) return 'Stable';
    
    final uniqueOrientations = events
        .map((e) => e.orientation.deviceOrientation)
        .toSet()
        .length;
    
    if (uniqueOrientations == 1) return 'Stable';
    if (uniqueOrientations == 2) return 'Minor Changes';
    return 'Multiple Changes';
  }
}
```

### 6.3 Dual-UI Video Recording Buttons
```dart
// Portrait Video Recording Button
class PortraitVideoRecordButton extends StatefulWidget {
  final OrientationAwareVideoRecording videoRecording;
  final Function(VideoRecordingResult) onRecordingStateChange;
  
  @override
  _PortraitVideoRecordButtonState createState() => _PortraitVideoRecordButtonState();
}

class _PortraitVideoRecordButtonState extends State<PortraitVideoRecordButton> 
    with TickerProviderStateMixin {
  
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  late AnimationController _pulseAnimationController;
  late AnimationController _recordButtonAnimationController;
  
  @override
  void initState() {
    super.initState();
    _pulseAnimationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _recordButtonAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleRecordingToggle,
      child: AnimatedBuilder(
        animation: _recordButtonAnimationController,
        builder: (context, child) {
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: _isRecording 
                  ? Colors.red.withOpacity(0.8)
                  : Colors.white.withOpacity(0.3), 
                width: 4
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: _isRecording ? 30 : 60,
                height: _isRecording ? 30 : 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_isRecording ? 6 : 30),
                  color: _isRecording ? Colors.red : Colors.white,
                ),
                child: _isRecording 
                  ? null
                  : Icon(
                      Icons.videocam,
                      color: Colors.black,
                      size: 28,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Future<void> _handleRecordingToggle() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }
  
  Future<void> _startRecording() async {
    try {
      HapticFeedback.mediumImpact();
      
      final result = await widget.videoRecording.startVideoRecordingWithOrientation();
      
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      
      _recordButtonAnimationController.forward();
      _startRecordingTimer();
      
      widget.onRecordingStateChange(result);
      
    } catch (e) {
      _showRecordingError(e.toString());
    }
  }
  
  Future<void> _stopRecording() async {
    try {
      HapticFeedback.lightImpact();
      
      final result = await widget.videoRecording.stopVideoRecordingWithOrientation();
      
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });
      
      _recordButtonAnimationController.reverse();
      _stopRecordingTimer();
      
      widget.onRecordingStateChange(result);
      
    } catch (e) {
      _showRecordingError(e.toString());
    }
  }
  
  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });
  }
  
  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }
}

// Landscape Video Recording Button (Similar structure adapted for landscape)
class LandscapeVideoRecordButton extends StatefulWidget {
  // Similar implementation adapted for landscape orientation
  // Positioned on right side, slightly smaller size (70x70)
  // Same orientation-aware recording logic
}
```

### 6.4 Recording Indicator with Orientation Info
```dart
class OrientationAwareRecordingIndicator extends StatefulWidget {
  final bool isRecording;
  final Duration recordingDuration;
  final OrientationData? currentOrientation;
  final List<OrientationEvent> orientationEvents;
  
  @override
  _OrientationAwareRecordingIndicatorState createState() => 
      _OrientationAwareRecordingIndicatorState();
}

class _OrientationAwareRecordingIndicatorState 
    extends State<OrientationAwareRecordingIndicator> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(OrientationAwareRecordingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) return SizedBox.shrink();
    
    return Positioned(
      top: 60,
      left: 20,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3 + (_pulseController.value * 0.7)),
                      ),
                    );
                  },
                ),
                SizedBox(width: 8),
                Text(
                  _formatRecordingTime(widget.recordingDuration),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (widget.currentOrientation != null) ...[
              SizedBox(height: 4),
              Text(
                'Orient: ${_getOrientationShortText(widget.currentOrientation!.deviceOrientation)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
                ),
              ),
              if (widget.orientationEvents.length > 1)
                Text(
                  '${widget.orientationEvents.length} changes',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _formatRecordingTime(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  String _getOrientationShortText(DeviceOrientation orientation) {
    switch (orientation) {
      case DeviceOrientation.portraitUp: return 'Port';
      case DeviceOrientation.landscapeLeft: return 'Land-L';
      case DeviceOrientation.landscapeRight: return 'Land-R';
      case DeviceOrientation.portraitDown: return 'Port-D';
      default: return 'Unknown';
    }
  }
}
```

## Files to Create
- `lib/features/orientation_aware_video_recording.dart`
- `lib/services/enhanced_video_metadata_service.dart`
- `lib/widgets/portrait_video_record_button.dart`
- `lib/widgets/landscape_video_record_button.dart`
- `lib/widgets/orientation_aware_recording_indicator.dart`
- `lib/models/video_recording_result.dart`
- `lib/models/orientation_event.dart`
- `lib/utils/video_orientation_tester.dart`

## Files to Modify
- `lib/widgets/portrait_camera_overlay.dart` (integrate new recording button and indicator)
- `lib/widgets/landscape_camera_overlay.dart` (integrate new recording button and indicator)
- `lib/screens/camera_screen.dart` (integrate orientation-aware video recording)
- `lib/services/testing_logger.dart` (extend for video recording logs)

## Advanced Orientation Testing Matrix for Video

### Enhanced Video Testing Protocol
```markdown
For each device orientation and camera (front/rear):

#### Comprehensive Video Recording Test
1. [ ] Start recording in specific orientation
2. [ ] Verify real-time orientation data accuracy during recording
3. [ ] Check video rotation metadata calculation
4. [ ] Test mid-recording orientation changes
5. [ ] Validate manufacturer-specific corrections applied
6. [ ] Stop recording and verify final metadata
7. [ ] Test in-app video playback (should play upright)
8. [ ] Test device gallery playback (should play upright)
9. [ ] Test third-party video player playback (should play upright)
10. [ ] Verify metadata completeness and accuracy
11. [ ] Log recording accuracy statistics
12. [ ] Document any device-specific behaviors

#### Advanced Video Edge Case Testing
- [ ] Test recording during rapid orientation changes
- [ ] Test with multiple orientation changes within single recording
- [ ] Test very short recordings (< 3 seconds)
- [ ] Test long recordings (> 5 minutes)
- [ ] Test recording immediately after orientation change
- [ ] Test with device flat (face up/down) during recording
- [ ] Test recording interruption and resume scenarios
```

### Video Orientation Stability Analysis
```dart
class VideoOrientationAnalyzer {
  static VideoOrientationReport analyzeRecording(VideoRecordingResult result) {
    return VideoOrientationReport(
      startOrientation: result.startOrientation.deviceOrientation,
      endOrientation: result.endOrientation.deviceOrientation,
      orientationChanges: result.orientationEvents.length,
      stabilityScore: _calculateStabilityScore(result.orientationEvents),
      rotationMetadataAccuracy: _verifyRotationMetadata(result),
      playbackCompatibility: _testPlaybackCompatibility(result.video),
      recommendations: _generateRecommendations(result),
    );
  }
}
```

## Integration with Task 4

### OrientationAwareCameraController Integration
```dart
class VideoRecordingScreen extends StatefulWidget {
  @override
  _VideoRecordingScreenState createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> {
  late OrientationAwareCameraController _cameraController;
  late OrientationAwareVideoRecording _videoRecording;
  bool _isRecording = false;
  List<OrientationEvent> _currentOrientationEvents = [];
  
  @override
  void initState() {
    super.initState();
    _cameraController = OrientationAwareCameraController();
    _videoRecording = OrientationAwareVideoRecording(_cameraController);
  }
  
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          body: Stack(
            children: [
              OrientationAwareCameraPreview(
                controller: _cameraController,
                cameraRotation: _cameraController.cameraRotation,
                deviceOrientation: _cameraController.deviceOrientation,
              ),
              if (orientation == Orientation.portrait)
                PortraitCameraOverlay(
                  videoRecording: _videoRecording,
                  onRecordingStateChange: _handleRecordingStateChange,
                )
              else
                LandscapeCameraOverlay(
                  videoRecording: _videoRecording,
                  onRecordingStateChange: _handleRecordingStateChange,
                ),
              OrientationAwareRecordingIndicator(
                isRecording: _isRecording,
                recordingDuration: _recordingDuration,
                currentOrientation: _cameraController.currentOrientationData,
                orientationEvents: _currentOrientationEvents,
              ),
              // Testing overlay
              VideoOrientationTester.buildOrientationTestingOverlay(
                _cameraController.currentOrientationData,
                _isRecording,
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _handleRecordingStateChange(VideoRecordingResult result) {
    setState(() {
      _isRecording = result.isRecording;
      if (result.isCompleted) {
        _currentOrientationEvents = result.orientationEvents;
        VideoOrientationTester.logRecordingForTesting(result);
      }
    });
  }
}
```

## Acceptance Criteria
- [ ] Video recording works flawlessly with orientation-aware camera controller
- [ ] Video rotation metadata is 100% accurate across all tested devices
- [ ] Dual UI (portrait/landscape) recording buttons work perfectly
- [ ] Manufacturer-specific corrections are applied correctly to videos
- [ ] Recorded videos play upright in all video player apps
- [ ] Real-time orientation monitoring during recording works correctly
- [ ] Recording performance remains smooth during orientation changes
- [ ] Memory usage is stable during extended video recording testing
- [ ] Touch targets work correctly in both UI orientations
- [ ] Mid-recording orientation changes are handled gracefully

## Enhanced Testing Requirements
- **Orientation Accuracy**: 100% success rate for video rotation metadata
- **Cross-App Compatibility**: Videos play correctly in 5+ different video players
- **Device Coverage**: Test on minimum 4 different manufacturers
- **Performance**: Video recording starts/stops within 1 second regardless of orientation
- **Metadata Integrity**: All orientation metadata survives video processing and sharing
- **Stability**: Handle orientation changes during recording without corruption

## Notes
- This task is fully integrated with the advanced orientation system from Task 4
- Video orientation is more complex than photo orientation due to temporal nature
- Real-time orientation monitoring enables analysis of mid-recording orientation changes
- Enhanced metadata includes comprehensive orientation event tracking
- Manufacturer-specific corrections ensure video compatibility across device ecosystem
- Testing overlay provides real-time feedback for video orientation validation

## Estimated Time: 6-8 hours

## Next Task: Task 7 - Combined Photo/Video Mode 