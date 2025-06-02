# Task 4: Basic Camera Screen with Shared Functionality

## Status: ⏳ Not Started

## Objective
Implement the core camera screen with shared functionality that will be used across all camera modes, focusing on camera initialization, preview rendering, and lifecycle management. **The UI should look native and immersive, similar to built-in smartphone camera apps, with no app bar and full-screen camera preview.**

## Subtasks

### 4.1 Camera Controller Setup
- [ ] Initialize CameraController with available cameras
- [ ] Implement camera selection (front/rear)
- [ ] Handle camera initialization errors
- [ ] Add camera disposal and cleanup
- [ ] Implement camera resolution configuration

### 4.2 Native Camera Preview Implementation
- [ ] Create full-screen CameraPreview widget integration
- [ ] Handle immersive status bar (transparent/hidden)
- [ ] Implement edge-to-edge camera preview
- [ ] Add preview orientation handling for native feel
- [ ] Implement preview error states with native styling
- [ ] Add loading state during camera initialization

### 4.3 Camera Lifecycle Management
- [ ] Implement WidgetsBindingObserver for app lifecycle
- [ ] Handle app resume/pause camera states
- [ ] Manage camera permissions during lifecycle changes
- [ ] Handle device rotation events
- [ ] Add proper disposal when navigating away

### 4.4 Native Camera Controls Layout
- [ ] Position controls like native camera apps (bottom capture, corner toggles)
- [ ] Implement camera toggle (front/rear) button in top corner
- [ ] Add flash mode controls in top area
- [ ] Create zoom controls with native gestures
- [ ] Add focus tap-to-focus functionality
- [ ] Implement minimal overlay with essential controls only

### 4.5 Immersive UI Layout and Orientation
- [ ] Create full-screen responsive camera UI layout
- [ ] Handle system UI visibility (status bar, navigation bar)
- [ ] Position camera controls for thumb-friendly access
- [ ] Handle different screen orientations natively
- [ ] Add orientation-aware UI elements
- [ ] Implement safe area handling for controls

## Detailed Implementation

### 4.1 Native Camera Screen Structure
```dart
class CameraScreenState extends State<CameraScreen> 
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setNativeUIMode();
    _initializeCamera();
  }

  void _setNativeUIMode() {
    // Hide status bar and navigation for immersive experience
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top], // Keep status bar but transparent
    );
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    // Camera initialization logic
  }
}
```

### 4.2 Native Preview Layout (Full Screen)
```dart
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    extendBodyBehindAppBar: true,
    body: Stack(
      children: [
        _buildFullScreenCameraPreview(),
        _buildNativeCameraOverlay(),
      ],
    ),
  );
}

Widget _buildFullScreenCameraPreview() {
  if (!_isInitialized) {
    return _buildNativeLoadingState();
  }
  
  return SizedBox.expand(
    child: FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.size.width,
        height: _controller!.value.size.height,
        child: CameraPreview(_controller!),
      ),
    ),
  );
}
```

### 4.3 Native Camera Overlay Layout
```dart
Widget _buildNativeCameraOverlay() {
  return SafeArea(
    child: Column(
      children: [
        _buildTopNativeControls(), // Flash, settings, close
        Spacer(),
        _buildBottomNativeControls(), // Mode selector, capture, gallery
      ],
    ),
  );
}

Widget _buildTopNativeControls() {
  return Padding(
    padding: EdgeInsets.all(16.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildBackButton(),
        Row(
          children: [
            _buildFlashButton(),
            SizedBox(width: 16),
            _buildSettingsButton(),
          ],
        ),
        _buildCameraToggleButton(),
      ],
    ),
  );
}

Widget _buildBottomNativeControls() {
  return Padding(
    padding: EdgeInsets.only(bottom: 32.0, left: 16.0, right: 16.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildGalleryThumbnail(),
        _buildNativeCaptureButton(),
        _buildModeSelector(),
      ],
    ),
  );
}
```

### 4.4 Native-Style Control Buttons
```dart
Widget _buildNativeCaptureButton() {
  return Container(
    width: 70,
    height: 70,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      border: Border.all(color: Colors.white.withOpacity(0.3), width: 4),
    ),
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
  );
}

Widget _buildBackButton() {
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.black.withOpacity(0.3),
    ),
    child: IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => Navigator.pop(context),
    ),
  );
}

Widget _buildFlashButton() {
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.black.withOpacity(0.3),
    ),
    child: IconButton(
      icon: Icon(_getFlashIcon(), color: Colors.white),
      onPressed: _toggleFlash,
    ),
  );
}
```

## Files to Create
- `lib/screens/camera_screen.dart`
- `lib/widgets/native_camera_controls.dart`
- `lib/widgets/native_capture_button.dart`
- `lib/widgets/native_flash_button.dart`
- `lib/widgets/native_camera_toggle.dart`
- `lib/services/camera_service.dart`
- `lib/utils/native_ui_helper.dart`

## Files to Modify
- `lib/main.dart` (add camera screen route)

## Native UI Requirements

### Immersive Experience
- Full-screen camera preview with edge-to-edge content
- Transparent/hidden status bar and navigation bar
- No app bar or traditional Material navigation
- Black background for loading states and transitions

### Native Control Positioning
- Back button: Top-left corner
- Flash/Settings: Top-right area
- Camera toggle: Top-right corner
- Capture button: Bottom center (thumb-friendly)
- Gallery thumbnail: Bottom-left
- Mode selector: Bottom-right

### Visual Design (Native Style)
- Semi-transparent circular backgrounds for top controls
- Large, prominent capture button with native styling
- Minimal text, icon-focused interface
- White icons on dark semi-transparent backgrounds
- Smooth animations matching native camera apps

### Gesture Support
- Tap-to-focus anywhere on preview
- Pinch-to-zoom gesture support
- Swipe gestures for mode switching (optional)
- Long press for additional options (optional)

## Orientation Considerations (Critical)

### Native Orientation Handling
- Controls maintain position relative to device orientation
- Preview always fills screen appropriately
- UI elements rotate naturally with device
- Safe area respected for notched devices

### Immersive Rotation
```dart
class NativeOrientationHandler {
  static void handleOrientationChange(Orientation orientation) {
    // Maintain immersive mode during rotation
    // Reposition controls naturally
    // Update safe areas
  }
}
```

## Acceptance Criteria
- [ ] Camera screen looks and feels like native camera app
- [ ] Full-screen preview with no app bar
- [ ] Immersive status bar handling
- [ ] Controls positioned like native apps
- [ ] Smooth transitions and animations
- [ ] Proper safe area handling
- [ ] Camera initializes without UI distractions
- [ ] Native gesture support (tap-to-focus, pinch-zoom)
- [ ] Orientation changes feel natural
- [ ] Back navigation works intuitively

## Testing Points
- [ ] Test immersive mode on various devices
- [ ] Verify control positioning on different screen sizes
- [ ] Test safe area handling on notched devices
- [ ] Verify status bar behavior
- [ ] Test gesture recognition
- [ ] Check orientation changes
- [ ] Verify back navigation
- [ ] Test on different Android versions
- [ ] Ensure controls remain accessible
- [ ] Verify performance with immersive mode

## Performance Considerations
- Optimize for full-screen rendering
- Minimize UI overlay impact on preview
- Smooth orientation transitions
- Efficient gesture handling
- Battery-conscious immersive mode

## Accessibility Considerations
- Maintain accessibility with immersive design
- Proper touch targets despite native styling
- Voice control compatibility
- High contrast mode support

## Notes
- Prioritize native feel over Material Design conventions
- Study popular camera apps for UI patterns
- Test extensively on different device form factors
- Consider edge cases like notched displays and gesture navigation
- Document any device-specific immersive mode behaviors

## Estimated Time: 6-8 hours

## Next Task: Task 5 - Photo Capture Implementation 