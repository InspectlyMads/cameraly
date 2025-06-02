# Task 4: Advanced Camera Screen with Comprehensive Orientation Handling

## Status: ⏳ Not Started

## Objective
Implement a sophisticated camera screen with native UI that handles the complex orientation challenges common in Android camera development. This includes comprehensive orientation detection, separate UI overlays for portrait/landscape, and solutions for device-specific rotation issues.

## ⚠️ Critical Orientation Challenges to Address

### Common Android Camera Issues
1. **Preview Rotation Misalignment**: Camera preview appears rotated 90° relative to device orientation
2. **Manufacturer Variations**: Different camera sensor orientations (0°, 90°, 180°, 270°)
3. **UI Overlay Positioning**: Controls appearing in wrong positions during orientation changes
4. **System UI Interference**: Status bar and navigation bar affecting layout calculations
5. **Device Natural Orientation**: Some devices have landscape as natural orientation
6. **Touch Target Misalignment**: Control areas not matching visual positions

## Subtasks

### 4.1 Advanced Camera Controller Setup
- [ ] Implement camera controller with orientation-aware initialization
- [ ] Handle camera sensor orientation detection and compensation
- [ ] Add device orientation monitoring with proper listeners
- [ ] Implement camera rotation calculation and preview adjustment
- [ ] Create fallback mechanisms for orientation detection failures

### 4.2 Dual-Mode UI Architecture
- [ ] Design separate portrait and landscape UI overlay systems
- [ ] Implement orientation-based UI switching logic
- [ ] Create responsive control positioning for each orientation
- [ ] Handle smooth transitions between orientation modes
- [ ] Implement orientation-specific safe area calculations

### 4.3 Advanced Orientation Detection
- [ ] Implement multiple orientation detection methods (sensor, display, camera)
- [ ] Create orientation change debouncing to prevent UI flicker
- [ ] Add device-specific orientation compensation
- [ ] Handle edge cases (flat position, rapid rotation)
- [ ] Implement manual orientation override for testing

### 4.4 Native Camera Preview Management
- [ ] Calculate correct preview transform matrices
- [ ] Handle preview scaling and aspect ratio across orientations
- [ ] Implement preview rotation compensation
- [ ] Manage camera sensor orientation vs display orientation
- [ ] Add preview quality optimization for different orientations

### 4.5 Immersive System UI Management
- [ ] Implement dynamic system UI hiding/showing
- [ ] Handle orientation-specific status bar behavior
- [ ] Manage navigation bar interaction in landscape
- [ ] Calculate accurate safe areas for each orientation
- [ ] Handle notch and cutout positioning

## Detailed Implementation Strategy

### 4.1 Enhanced Camera Controller Architecture
```dart
class OrientationAwareCameraController {
  CameraController? _controller;
  StreamSubscription<DeviceOrientationChangedEvent>? _orientationSubscription;
  
  // Multiple orientation sources for accuracy
  DeviceOrientation _deviceOrientation = DeviceOrientation.portraitUp;
  int _cameraRotation = 0;
  int _sensorOrientation = 0;
  int _displayRotation = 0;
  
  Future<void> initializeCamera() async {
    await _detectCameraCapabilities();
    await _setupOrientationListeners();
    await _initializeCameraWithOrientation();
  }
  
  Future<void> _detectCameraCapabilities() async {
    // Detect camera sensor orientation
    _sensorOrientation = await _getCameraSensorOrientation();
    
    // Get display rotation
    _displayRotation = await _getDisplayRotation();
    
    // Calculate initial camera rotation
    _calculateCameraRotation();
  }
  
  Future<void> _setupOrientationListeners() async {
    // Listen to device orientation changes
    _orientationSubscription = DeviceOrientationManager.stream.listen(
      _handleOrientationChange,
    );
    
    // Also listen to display rotation changes
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  void _handleOrientationChange(DeviceOrientationChangedEvent event) {
    final newOrientation = event.orientation;
    
    // Debounce rapid orientation changes
    if (_shouldIgnoreOrientationChange(newOrientation)) return;
    
    _deviceOrientation = newOrientation;
    _calculateCameraRotation();
    _updateUIOrientation();
  }
  
  void _calculateCameraRotation() {
    // Complex calculation accounting for:
    // 1. Camera sensor orientation
    // 2. Device orientation
    // 3. Display rotation
    // 4. Manufacturer-specific offsets
    
    int rotation = 0;
    
    switch (_deviceOrientation) {
      case DeviceOrientation.portraitUp:
        rotation = _sensorOrientation;
        break;
      case DeviceOrientation.landscapeLeft:
        rotation = (_sensorOrientation + 90) % 360;
        break;
      case DeviceOrientation.landscapeRight:
        rotation = (_sensorOrientation + 270) % 360;
        break;
      case DeviceOrientation.portraitDown:
        rotation = (_sensorOrientation + 180) % 360;
        break;
    }
    
    // Apply manufacturer-specific corrections
    rotation = _applyManufacturerCorrection(rotation);
    
    _cameraRotation = rotation;
  }
  
  int _applyManufacturerCorrection(int rotation) {
    // Device-specific corrections for known orientation issues
    final deviceModel = Platform.deviceModel;
    final manufacturer = Platform.manufacturer;
    
    // Add known device corrections here
    if (manufacturer.toLowerCase().contains('samsung')) {
      // Samsung devices often have different sensor orientations
      return (rotation + _getSamsungCorrection()) % 360;
    } else if (manufacturer.toLowerCase().contains('xiaomi')) {
      // Xiaomi corrections
      return (rotation + _getXiaomiCorrection()) % 360;
    }
    
    return rotation;
  }
}
```

### 4.2 Dual-Mode UI Architecture
```dart
class OrientationAwareUI extends StatefulWidget {
  @override
  _OrientationAwareUIState createState() => _OrientationAwareUIState();
}

class _OrientationAwareUIState extends State<OrientationAwareUI> 
    with TickerProviderStateMixin {
  
  bool _isPortrait = true;
  AnimationController? _orientationTransitionController;
  
  @override
  void initState() {
    super.initState();
    _orientationTransitionController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isPortrait = orientation == Orientation.portrait;
        
        // Trigger smooth transition when orientation changes
        if (isPortrait != _isPortrait) {
          _isPortrait = isPortrait;
          _orientationTransitionController?.forward(from: 0);
        }
        
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              _buildCameraPreview(),
              if (_isPortrait)
                _buildPortraitUI()
              else
                _buildLandscapeUI(),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPortraitUI() {
    return PortraitCameraOverlay(
      animationController: _orientationTransitionController!,
      onCapturePhoto: _capturePhoto,
      onStartRecording: _startRecording,
      onStopRecording: _stopRecording,
      onToggleCamera: _toggleCamera,
      onToggleFlash: _toggleFlash,
    );
  }
  
  Widget _buildLandscapeUI() {
    return LandscapeCameraOverlay(
      animationController: _orientationTransitionController!,
      onCapturePhoto: _capturePhoto,
      onStartRecording: _startRecording,
      onStopRecording: _stopRecording,
      onToggleCamera: _toggleCamera,
      onToggleFlash: _toggleFlash,
    );
  }
}
```

### 4.3 Portrait UI Overlay
```dart
class PortraitCameraOverlay extends StatelessWidget {
  final AnimationController animationController;
  final VoidCallback onCapturePhoto;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onToggleCamera;
  final VoidCallback onToggleFlash;
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildPortraitTopControls(),
          Spacer(),
          _buildPortraitBottomControls(),
        ],
      ),
    );
  }
  
  Widget _buildPortraitTopControls() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBackButton(),
          Spacer(),
          _buildFlashButton(),
          SizedBox(width: 16),
          _buildCameraToggleButton(),
        ],
      ),
    );
  }
  
  Widget _buildPortraitBottomControls() {
    return Padding(
      padding: EdgeInsets.only(bottom: 40, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildGalleryButton(),
          _buildPortraitCaptureButton(),
          _buildModeSelector(),
        ],
      ),
    );
  }
  
  Widget _buildPortraitCaptureButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: Colors.white.withOpacity(0.3), 
          width: 4
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onCapturePhoto,
          child: Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### 4.4 Landscape UI Overlay
```dart
class LandscapeCameraOverlay extends StatelessWidget {
  final AnimationController animationController;
  final VoidCallback onCapturePhoto;
  // ... other callbacks
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          _buildLandscapeLeftControls(),
          Spacer(),
          _buildLandscapeRightControls(),
        ],
      ),
    );
  }
  
  Widget _buildLandscapeLeftControls() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildBackButton(),
          Spacer(),
          _buildGalleryButton(),
        ],
      ),
    );
  }
  
  Widget _buildLandscapeRightControls() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildFlashButton(),
          SizedBox(height: 16),
          _buildCameraToggleButton(),
          Spacer(),
          _buildLandscapeCaptureButton(),
          Spacer(),
          _buildModeSelector(),
        ],
      ),
    );
  }
  
  Widget _buildLandscapeCaptureButton() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: Colors.white.withOpacity(0.3), 
          width: 4
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(35),
          onTap: onCapturePhoto,
          child: Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### 4.5 Advanced Camera Preview with Orientation Handling
```dart
class OrientationAwareCameraPreview extends StatefulWidget {
  final CameraController controller;
  final int cameraRotation;
  final DeviceOrientation deviceOrientation;
  
  @override
  _OrientationAwareCameraPreviewState createState() => 
      _OrientationAwareCameraPreviewState();
}

class _OrientationAwareCameraPreviewState 
    extends State<OrientationAwareCameraPreview> {
  
  @override
  Widget build(BuildContext context) {
    if (!widget.controller.value.isInitialized) {
      return _buildLoadingState();
    }
    
    return _buildPreviewWithCorrectOrientation();
  }
  
  Widget _buildPreviewWithCorrectOrientation() {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    
    // Calculate preview size with orientation compensation
    final previewSize = _calculatePreviewSize();
    final scale = _calculatePreviewScale(previewSize, size);
    
    return ClipRect(
      child: Transform.scale(
        scale: scale,
        child: Center(
          child: AspectRatio(
            aspectRatio: previewSize.aspectRatio,
            child: Transform.rotate(
              angle: _calculatePreviewRotation() * math.pi / 180,
              child: CameraPreview(widget.controller),
            ),
          ),
        ),
      ),
    );
  }
  
  Size _calculatePreviewSize() {
    final controller = widget.controller;
    
    // Get camera preview size
    var previewSize = controller.value.previewSize!;
    
    // Adjust for camera rotation
    if (widget.cameraRotation % 180 == 90) {
      previewSize = Size(previewSize.height, previewSize.width);
    }
    
    return previewSize;
  }
  
  double _calculatePreviewScale(Size previewSize, Size screenSize) {
    final previewAspectRatio = previewSize.width / previewSize.height;
    final screenAspectRatio = screenSize.width / screenSize.height;
    
    if (previewAspectRatio > screenAspectRatio) {
      return screenSize.height / previewSize.height;
    } else {
      return screenSize.width / previewSize.width;
    }
  }
  
  double _calculatePreviewRotation() {
    // Calculate rotation needed to display preview correctly
    switch (widget.deviceOrientation) {
      case DeviceOrientation.portraitUp:
        return 0;
      case DeviceOrientation.landscapeLeft:
        return 90;
      case DeviceOrientation.landscapeRight:
        return -90;
      case DeviceOrientation.portraitDown:
        return 180;
      default:
        return 0;
    }
  }
}
```

### 4.6 System UI Management
```dart
class ImmersiveSystemUI {
  static Future<void> setupImmersiveMode() async {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    
    // Enable immersive mode
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }
  
  static Future<void> handleOrientationChange(Orientation orientation) async {
    if (orientation == Orientation.landscape) {
      // Hide system UI completely in landscape
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersive,
        overlays: [],
      );
    } else {
      // Show transparent status bar in portrait
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [SystemUiOverlay.top],
      );
    }
  }
  
  static EdgeInsets calculateSafeArea(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final orientation = mediaQuery.orientation;
    
    if (orientation == Orientation.landscape) {
      // In landscape, account for notches and rounded corners
      return EdgeInsets.only(
        left: mediaQuery.padding.left,
        right: mediaQuery.padding.right,
        top: 8.0, // Minimal top padding
        bottom: 8.0, // Minimal bottom padding
      );
    } else {
      // In portrait, use standard safe area
      return mediaQuery.padding;
    }
  }
}
```

## Files to Create
- `lib/screens/camera_screen.dart` (Main camera screen)
- `lib/widgets/orientation_aware_camera_preview.dart`
- `lib/widgets/portrait_camera_overlay.dart`
- `lib/widgets/landscape_camera_overlay.dart`
- `lib/services/orientation_aware_camera_controller.dart`
- `lib/services/device_orientation_manager.dart`
- `lib/utils/immersive_system_ui.dart`
- `lib/utils/camera_orientation_calculator.dart`
- `lib/models/camera_orientation_data.dart`

## Files to Modify
- `lib/main.dart` (add camera screen route and orientation setup)

## Critical Orientation Solutions

### Preview Rotation Issues
- **Problem**: Camera preview appears rotated 90° on some devices
- **Solution**: Calculate correct transform matrix based on camera sensor orientation and display rotation
- **Implementation**: Multi-layer rotation calculation with device-specific corrections

### UI Control Positioning
- **Problem**: Controls appear in wrong positions during orientation changes
- **Solution**: Separate UI overlays for portrait and landscape with proper safe area calculations
- **Implementation**: Dual overlay system with smooth transitions

### Manufacturer Variations
- **Problem**: Different camera sensor orientations across manufacturers
- **Solution**: Device-specific orientation corrections with fallback detection
- **Implementation**: Manufacturer detection with correction tables

### Touch Target Alignment
- **Problem**: Touch areas don't match visual button positions
- **Solution**: Orientation-aware hit testing with proper coordinate transformation
- **Implementation**: Custom gesture detectors with coordinate mapping

## Acceptance Criteria
- [ ] Camera preview displays correctly in all orientations on all test devices
- [ ] UI controls remain properly positioned during orientation changes
- [ ] No 90° rotation issues on any tested device
- [ ] Smooth transitions between portrait and landscape modes
- [ ] Touch targets align perfectly with visual controls
- [ ] System UI behaves consistently across orientations
- [ ] Camera initialization handles orientation correctly
- [ ] Memory usage remains stable during orientation changes
- [ ] No UI flickering during rapid orientation changes
- [ ] Fallback mechanisms work when orientation detection fails

## Testing Protocol for Orientation Issues

### Device-Specific Testing
```markdown
For each test device:
1. [ ] Test camera preview orientation in all 4 device orientations
2. [ ] Verify UI controls remain in correct positions
3. [ ] Check for any 90° rotation offset issues
4. [ ] Test rapid orientation changes (shake test)
5. [ ] Verify touch target alignment
6. [ ] Test camera toggle in all orientations
7. [ ] Document any device-specific quirks
```

### Edge Case Testing
- [ ] Test with auto-rotate disabled
- [ ] Test during camera initialization
- [ ] Test with app backgrounding/foregrounding
- [ ] Test with other apps using camera simultaneously
- [ ] Test with accessibility features enabled

## Performance Considerations
- Minimize orientation calculation overhead
- Cache transformation matrices when possible
- Optimize preview rendering for different orientations
- Efficient UI overlay switching
- Smooth animation performance during transitions

## Notes
- This implementation addresses the most common Android camera orientation issues
- Extensive device testing is crucial for validation
- Manufacturer-specific corrections may need updates as new devices are tested
- Consider creating automated orientation testing tools
- Document all discovered device-specific behaviors

## Estimated Time: 8-10 hours (increased due to complexity)

## Next Task: Task 5 - Photo Capture Implementation 