# Task 7: Advanced Combined Photo/Video Mode with Orientation Intelligence

## Status: ⏳ Not Started

## Objective
Implement a sophisticated combined photo and video mode that seamlessly integrates with the advanced orientation-aware camera controller and dual UI system, allowing users to switch between capture modes while maintaining full orientation intelligence and native camera app experience.

## Subtasks

### 7.1 Orientation-Aware Mode Switching
- [ ] Integrate combined mode with OrientationAwareCameraController from Task 4
- [ ] Implement mode switching that preserves orientation state
- [ ] Handle manufacturer-specific considerations during mode changes
- [ ] Add orientation-aware mode indicator UI
- [ ] Implement smooth mode transitions without camera reinitialization

### 7.2 Dual-UI Mode Integration
- [ ] Implement combined mode for portrait UI overlay
- [ ] Implement combined mode for landscape UI overlay
- [ ] Handle mode switching in both orientations seamlessly
- [ ] Add orientation-specific mode selector positioning
- [ ] Implement adaptive UI elements for different modes

### 7.3 Unified Capture Logic with Orientation Intelligence
- [ ] Create adaptive capture button that works with orientation system
- [ ] Implement orientation-aware photo capture in combined mode
- [ ] Implement orientation-aware video recording in combined mode
- [ ] Handle mode-specific orientation optimizations
- [ ] Add capture feedback appropriate for each mode and orientation

### 7.4 Advanced Mode State Management
- [ ] Maintain mode state across orientation changes
- [ ] Preserve camera settings during mode switches
- [ ] Handle permission requirements for both modes with orientation context
- [ ] Implement mode-specific UI state management
- [ ] Add mode change analytics and testing logging

### 7.5 Testing-Focused Combined Mode Features
- [ ] Add mode-specific orientation testing indicators
- [ ] Implement combined mode orientation logging
- [ ] Create mode switching test protocols
- [ ] Add automatic orientation verification for both modes
- [ ] Implement mode switch accuracy statistics tracking

## Detailed Implementation

### 7.1 Orientation-Aware Combined Mode Controller
```dart
class OrientationAwareCombinedModeController {
  final OrientationAwareCameraController _cameraController;
  final OrientationAwarePhotoCapture _photoCapture;
  final OrientationAwareVideoRecording _videoRecording;
  
  CaptureMode _currentMode = CaptureMode.photo;
  OrientationData? _lastOrientationAtModeSwitch;
  
  CaptureMode get currentMode => _currentMode;
  bool get isVideoMode => _currentMode == CaptureMode.video;
  bool get isPhotoMode => _currentMode == CaptureMode.photo;
  
  Future<void> switchToMode(CaptureMode newMode) async {
    if (_currentMode == newMode) return;
    
    try {
      // Capture current orientation state
      final currentOrientation = await _cameraController.getCurrentOrientationData();
      
      // Stop any ongoing recording if switching from video mode
      if (_currentMode == CaptureMode.video && _videoRecording.isRecording) {
        await _videoRecording.stopVideoRecordingWithOrientation();
      }
      
      // Apply mode-specific camera optimizations while preserving orientation
      await _optimizeCameraForMode(newMode, currentOrientation);
      
      // Update mode state
      final previousMode = _currentMode;
      _currentMode = newMode;
      _lastOrientationAtModeSwitch = currentOrientation;
      
      // Trigger haptic feedback
      HapticFeedback.selectionClick();
      
      // Log mode switch for testing
      await _logModeSwitch(previousMode, newMode, currentOrientation);
      
      // Notify UI of mode change
      _modeChangeController.add(CombinedModeEvent(
        previousMode: previousMode,
        newMode: newMode,
        orientation: currentOrientation,
        timestamp: DateTime.now(),
      ));
      
    } catch (e) {
      throw CombinedModeException('Failed to switch mode: $e');
    }
  }
  
  Future<void> _optimizeCameraForMode(CaptureMode mode, OrientationData orientation) async {
    switch (mode) {
      case CaptureMode.photo:
        await _cameraController.optimizeForPhotoCapture(orientation);
        break;
      case CaptureMode.video:
        await _cameraController.optimizeForVideoRecording(orientation);
        break;
    }
  }
  
  Future<CaptureResult> handleCaptureAction() async {
    final currentOrientation = await _cameraController.getCurrentOrientationData();
    
    switch (_currentMode) {
      case CaptureMode.photo:
        return await _photoCapture.capturePhotoWithOrientation();
      case CaptureMode.video:
        if (_videoRecording.isRecording) {
          final result = await _videoRecording.stopVideoRecordingWithOrientation();
          return CaptureResult.fromVideoResult(result);
        } else {
          final result = await _videoRecording.startVideoRecordingWithOrientation();
          return CaptureResult.fromVideoResult(result);
        }
    }
  }
  
  Future<void> _logModeSwitch(
    CaptureMode from, 
    CaptureMode to, 
    OrientationData orientation
  ) async {
    final modeSwichLog = {
      'timestamp': DateTime.now().toIso8601String(),
      'fromMode': from.toString(),
      'toMode': to.toString(),
      'deviceOrientation': orientation.deviceOrientation.toString(),
      'cameraRotation': orientation.cameraRotation,
      'deviceInfo': {
        'manufacturer': orientation.deviceManufacturer,
        'model': orientation.deviceModel,
      },
    };
    
    await TestingLogger.logModeSwitch(modeSwichLog);
  }
}
```

### 7.2 Dual-UI Mode Selector Components
```dart
// Portrait Mode Selector
class PortraitModeSelector extends StatefulWidget {
  final CaptureMode currentMode;
  final Function(CaptureMode) onModeChanged;
  final OrientationData? currentOrientation;
  
  @override
  _PortraitModeSelectorState createState() => _PortraitModeSelectorState();
}

class _PortraitModeSelectorState extends State<PortraitModeSelector> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _slideAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(1, 0),
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void didUpdateWidget(PortraitModeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentMode != oldWidget.currentMode) {
      if (widget.currentMode == CaptureMode.video) {
        _slideAnimationController.forward();
      } else {
        _slideAnimationController.reverse();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120,
      right: 20,
      child: Container(
        height: 40,
        width: 120,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_slideAnimation.value.dx * 60, 0),
                  child: Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onModeChanged(CaptureMode.photo),
                    child: Container(
                      height: 40,
                      child: Center(
                        child: Text(
                          'Photo',
                          style: TextStyle(
                            color: widget.currentMode == CaptureMode.photo 
                              ? Colors.black 
                              : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onModeChanged(CaptureMode.video),
                    child: Container(
                      height: 40,
                      child: Center(
                        child: Text(
                          'Video',
                          style: TextStyle(
                            color: widget.currentMode == CaptureMode.video 
                              ? Colors.black 
                              : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Landscape Mode Selector (Adapted for landscape orientation)
class LandscapeModeSelector extends StatefulWidget {
  final CaptureMode currentMode;
  final Function(CaptureMode) onModeChanged;
  final OrientationData? currentOrientation;
  
  @override
  _LandscapeModeSelectorState createState() => _LandscapeModeSelectorState();
}

class _LandscapeModeSelectorState extends State<LandscapeModeSelector> 
    with TickerProviderStateMixin {
  
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _slideAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, 1),
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 80,
      child: Container(
        height: 100,
        width: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value.dy * 50),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                );
              },
            ),
            Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onModeChanged(CaptureMode.photo),
                    child: Container(
                      width: 50,
                      child: Center(
                        child: Icon(
                          Icons.camera_alt,
                          color: widget.currentMode == CaptureMode.photo 
                            ? Colors.black 
                            : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onModeChanged(CaptureMode.video),
                    child: Container(
                      width: 50,
                      child: Center(
                        child: Icon(
                          Icons.videocam,
                          color: widget.currentMode == CaptureMode.video 
                            ? Colors.black 
                            : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### 7.3 Adaptive Capture Button for Combined Mode
```dart
class OrientationAwareAdaptiveCaptureButton extends StatefulWidget {
  final OrientationAwareCombinedModeController modeController;
  final bool isPortrait;
  final Function(CaptureResult) onCaptureComplete;
  
  @override
  _OrientationAwareAdaptiveCaptureButtonState createState() => 
      _OrientationAwareAdaptiveCaptureButtonState();
}

class _OrientationAwareAdaptiveCaptureButtonState 
    extends State<OrientationAwareAdaptiveCaptureButton> 
    with TickerProviderStateMixin {
  
  bool _isCapturing = false;
  bool _isRecording = false;
  late AnimationController _captureAnimationController;
  late AnimationController _recordingPulseController;
  
  @override
  void initState() {
    super.initState();
    _captureAnimationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _recordingPulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final buttonSize = widget.isPortrait ? 80.0 : 70.0;
    
    return GestureDetector(
      onTapDown: (_) => _captureAnimationController.forward(),
      onTapUp: (_) => _captureAnimationController.reverse(),
      onTapCancel: () => _captureAnimationController.reverse(),
      onTap: _handleCaptureAction,
      child: AnimatedBuilder(
        animation: _captureAnimationController,
        builder: (context, child) {
          final scale = 1.0 - (_captureAnimationController.value * 0.1);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: _getBorderColor(),
                  width: 4,
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
                child: _buildButtonContent(buttonSize),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildButtonContent(double buttonSize) {
    if (widget.modeController.isVideoMode) {
      return AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: _isRecording ? buttonSize * 0.4 : buttonSize * 0.75,
        height: _isRecording ? buttonSize * 0.4 : buttonSize * 0.75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_isRecording ? 6 : buttonSize * 0.375),
          color: _isRecording ? Colors.red : Colors.white,
        ),
        child: !_isRecording 
          ? Icon(
              Icons.videocam,
              color: Colors.black,
              size: buttonSize * 0.35,
            )
          : null,
      );
    } else {
      return Container(
        width: buttonSize * 0.75,
        height: buttonSize * 0.75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isCapturing ? Colors.grey : Colors.white,
        ),
        child: _isCapturing 
          ? SizedBox(
              width: buttonSize * 0.3,
              height: buttonSize * 0.3,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          : Icon(
              Icons.camera_alt,
              color: Colors.black,
              size: buttonSize * 0.35,
            ),
      );
    }
  }
  
  Color _getBorderColor() {
    if (widget.modeController.isVideoMode && _isRecording) {
      return Colors.red.withOpacity(0.8);
    } else if (widget.modeController.isPhotoMode && _isCapturing) {
      return Colors.orange.withOpacity(0.8);
    } else {
      return Colors.white.withOpacity(0.3);
    }
  }
  
  Future<void> _handleCaptureAction() async {
    if (_isCapturing) return;
    
    try {
      if (widget.modeController.isPhotoMode) {
        setState(() => _isCapturing = true);
        HapticFeedback.mediumImpact();
      } else if (widget.modeController.isVideoMode) {
        setState(() => _isRecording = !_isRecording);
        if (_isRecording) {
          _recordingPulseController.repeat(reverse: true);
          HapticFeedback.mediumImpact();
        } else {
          _recordingPulseController.stop();
          HapticFeedback.lightImpact();
        }
      }
      
      final result = await widget.modeController.handleCaptureAction();
      widget.onCaptureComplete(result);
      
    } catch (e) {
      _showCaptureError(e.toString());
    } finally {
      if (widget.modeController.isPhotoMode) {
        setState(() => _isCapturing = false);
      }
    }
  }
}
```

### 7.4 Combined Mode Testing Overlay
```dart
class CombinedModeOrientationTester {
  static Widget buildCombinedModeTestingOverlay(
    CaptureMode currentMode,
    OrientationData? currentOrientation,
    bool isRecording,
  ) {
    return Positioned(
      top: 100,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getModeColor(currentMode),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'COMBINED MODE TEST',
              style: TextStyle(
                color: _getModeColor(currentMode),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  currentMode == CaptureMode.photo ? Icons.camera_alt : Icons.videocam,
                  color: _getModeColor(currentMode),
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  currentMode == CaptureMode.photo ? 'PHOTO' : 'VIDEO',
                  style: TextStyle(
                    color: _getModeColor(currentMode),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (currentOrientation != null) ...[
              SizedBox(height: 4),
              Text(
                'Orient: ${_getOrientationText(currentOrientation.deviceOrientation)}',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                'Camera: ${currentOrientation.cameraRotation}°',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
            if (isRecording) ...[
              SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'RECORDING',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  static Color _getModeColor(CaptureMode mode) {
    return mode == CaptureMode.photo ? Colors.orange : Colors.red;
  }
  
  static Future<void> logCombinedModeAction(
    CaptureMode mode,
    CaptureResult result,
    OrientationData orientation,
  ) async {
    final combinedModeLog = {
      'timestamp': DateTime.now().toIso8601String(),
      'mode': mode.toString(),
      'action': mode == CaptureMode.photo ? 'photo_capture' : 'video_action',
      'deviceOrientation': orientation.deviceOrientation.toString(),
      'cameraRotation': orientation.cameraRotation,
      'result': result.toJson(),
    };
    
    await TestingLogger.logCombinedModeAction(combinedModeLog);
  }
}
```

## Files to Create
- `lib/features/orientation_aware_combined_mode_controller.dart`
- `lib/widgets/portrait_mode_selector.dart`
- `lib/widgets/landscape_mode_selector.dart`
- `lib/widgets/orientation_aware_adaptive_capture_button.dart`
- `lib/models/combined_mode_event.dart`
- `lib/models/capture_result.dart` (extend if needed)
- `lib/utils/combined_mode_orientation_tester.dart`

## Files to Modify
- `lib/widgets/portrait_camera_overlay.dart` (integrate combined mode components)
- `lib/widgets/landscape_camera_overlay.dart` (integrate combined mode components)
- `lib/screens/camera_screen.dart` (integrate combined mode controller)
- `lib/services/testing_logger.dart` (extend for combined mode logging)

## Integration with Previous Tasks

### Complete Combined Mode Screen
```dart
class CombinedModeScreen extends StatefulWidget {
  @override
  _CombinedModeScreenState createState() => _CombinedModeScreenState();
}

class _CombinedModeScreenState extends State<CombinedModeScreen> {
  late OrientationAwareCameraController _cameraController;
  late OrientationAwareCombinedModeController _combinedModeController;
  
  @override
  void initState() {
    super.initState();
    _cameraController = OrientationAwareCameraController();
    _combinedModeController = OrientationAwareCombinedModeController(
      _cameraController,
      OrientationAwarePhotoCapture(_cameraController),
      OrientationAwareVideoRecording(_cameraController),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isPortrait = orientation == Orientation.portrait;
        
        return Scaffold(
          body: Stack(
            children: [
              OrientationAwareCameraPreview(
                controller: _cameraController,
                cameraRotation: _cameraController.cameraRotation,
                deviceOrientation: _cameraController.deviceOrientation,
              ),
              if (isPortrait)
                _buildPortraitCombinedModeUI()
              else
                _buildLandscapeCombinedModeUI(),
              CombinedModeOrientationTester.buildCombinedModeTestingOverlay(
                _combinedModeController.currentMode,
                _cameraController.currentOrientationData,
                _combinedModeController.isVideoMode && 
                _combinedModeController.videoRecording.isRecording,
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPortraitCombinedModeUI() {
    return PortraitCameraOverlay(
      combinedModeController: _combinedModeController,
      onCaptureComplete: _handleCaptureComplete,
      onModeChanged: _handleModeChange,
    );
  }
  
  Widget _buildLandscapeCombinedModeUI() {
    return LandscapeCameraOverlay(
      combinedModeController: _combinedModeController,
      onCaptureComplete: _handleCaptureComplete,
      onModeChanged: _handleModeChange,
    );
  }
  
  void _handleCaptureComplete(CaptureResult result) {
    CombinedModeOrientationTester.logCombinedModeAction(
      _combinedModeController.currentMode,
      result,
      _cameraController.currentOrientationData!,
    );
  }
  
  void _handleModeChange(CaptureMode newMode) {
    _combinedModeController.switchToMode(newMode);
  }
}
```

## Advanced Testing Protocol for Combined Mode

### Mode Switching Orientation Tests
```markdown
For each device orientation:

#### Mode Switch Testing Protocol
1. [ ] Start in photo mode in specific orientation
2. [ ] Verify photo mode orientation handling works correctly
3. [ ] Switch to video mode while maintaining orientation
4. [ ] Verify video mode orientation handling works correctly
5. [ ] Switch back to photo mode
6. [ ] Verify orientation state is preserved across mode switches
7. [ ] Test rapid mode switching in same orientation
8. [ ] Change device orientation while in each mode
9. [ ] Verify mode-specific orientation handling persists
10. [ ] Log mode switching performance and accuracy

#### Cross-Orientation Mode Switch Testing
- [ ] Start in portrait photo mode, rotate to landscape, switch to video
- [ ] Start in landscape video mode, rotate to portrait, switch to photo
- [ ] Test mode switching during orientation transition
- [ ] Verify no orientation confusion during rapid mode/orientation changes
```

## Acceptance Criteria
- [ ] Combined mode works flawlessly with orientation-aware camera controller
- [ ] Mode switching preserves orientation intelligence and accuracy
- [ ] Dual UI (portrait/landscape) mode selectors work perfectly
- [ ] Adaptive capture button responds correctly to current mode and orientation
- [ ] Photo capture maintains 100% orientation accuracy in combined mode
- [ ] Video recording maintains 100% orientation accuracy in combined mode
- [ ] Mode switching performance is smooth (<500ms) regardless of orientation
- [ ] UI state is preserved across orientation changes and mode switches
- [ ] Touch targets work correctly in both orientations and all modes
- [ ] Testing overlay provides clear indication of current mode and orientation

## Enhanced Testing Requirements
- **Mode Switch Accuracy**: 100% success rate for mode transitions
- **Orientation Preservation**: Orientation accuracy maintained across mode switches
- **Performance**: Mode switching completes within 500ms
- **UI Consistency**: Smooth animations and no visual glitches during mode changes
- **Cross-Platform**: Consistent behavior across all tested device manufacturers

## Notes
- This task represents the culmination of all previous orientation intelligence work
- Mode switching must not interfere with orientation accuracy or camera performance
- Testing should verify that combined mode doesn't introduce orientation regressions
- Enhanced logging provides valuable data about mode switching patterns and performance
- The dual UI system ensures optimal user experience in all orientations

## Estimated Time: 4-5 hours

## Next Task: Task 8 - Gallery Screen for Media Verification 