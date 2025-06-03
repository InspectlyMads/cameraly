# Task 13: Orientation-Specific UI Layouts

**Status**: 🔄 Todo  
**Priority**: Medium  
**Estimated Time**: 3-4 hours  
**Dependencies**: Task 4 (Orientation-Aware Camera), Tasks 10-12 (UI Improvements)

## Problem Description

The current camera UI uses the same layout for both portrait and landscape orientations. This doesn't provide an optimal user experience, especially in landscape mode where the capture button should be positioned for better ergonomics.

**Current Issues:**
- Capture button always at bottom center, awkward in landscape
- UI controls don't adapt to orientation optimally
- No consideration for device grip and thumb reach
- Landscape mode feels like rotated portrait instead of native landscape

## Requirements from Testing Feedback

### Landscape Mode Improvements
- **Capture Button**: Move to right-center for right-hand thumb access
- **Controls Layout**: Optimize for landscape thumb reach
- **Mode Selector**: Reposition for landscape usability
- **Flash/Camera Switch**: Adjust positioning for landscape

### Portrait Mode (Keep Current)
- Bottom-center capture button works well
- Current control layout is appropriate
- Mode selector positioning is good

## Solution Approach

### 1. Orientation-Aware UI Components
- Create separate UI layouts for portrait and landscape
- Dynamic positioning based on current orientation
- Smooth transitions between orientations

### 2. Ergonomic Button Placement
- Right-center capture button in landscape
- Optimize for single-hand operation
- Consider left/right-handed users

### 3. Adaptive Control Layouts
- Reposition all UI elements for each orientation
- Maintain visual hierarchy and accessibility
- Ensure consistent user experience

## Implementation Plan

### Step 1: Create Orientation Detection Utility
```dart
class OrientationUIHelper {
  static bool isLandscape(Orientation orientation) {
    return orientation == Orientation.landscape;
  }

  static bool isPortrait(Orientation orientation) {
    return orientation == Orientation.portrait;
  }

  // Calculate optimal button positions based on orientation and screen size
  static Offset getCaptureButtonPosition({
    required Size screenSize,
    required Orientation orientation,
    required EdgeInsets safeArea,
  }) {
    if (isLandscape(orientation)) {
      // Right-center for landscape
      return Offset(
        screenSize.width - 80 - safeArea.right - 16, // 80px button + 16px margin
        screenSize.height / 2, // Center vertically
      );
    } else {
      // Bottom-center for portrait
      return Offset(
        screenSize.width / 2, // Center horizontally
        screenSize.height - 120 - safeArea.bottom, // 120px from bottom
      );
    }
  }

  static MainAxisAlignment getControlsAlignment(Orientation orientation) {
    return isLandscape(orientation) 
        ? MainAxisAlignment.spaceAround 
        : MainAxisAlignment.spaceEvenly;
  }
}
```

### Step 2: Create Landscape-Specific UI Layout
```dart
class LandscapeCameraOverlay extends StatelessWidget {
  const LandscapeCameraOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    return Stack(
      children: [
        // Top controls - positioned along top edge
        _buildLandscapeTopControls(safeArea),
        
        // Right-side capture button
        _buildLandscapeCaptureButton(screenSize, safeArea),
        
        // Left-side controls (gallery, mode info)
        _buildLandscapeLeftControls(screenSize, safeArea),
        
        // Mode selector for combined mode
        _buildLandscapeModeSelector(screenSize, safeArea),
      ],
    );
  }

  Widget _buildLandscapeTopControls(EdgeInsets safeArea) {
    return Positioned(
      top: 16 + safeArea.top,
      left: 16 + safeArea.left,
      right: 16 + safeArea.right,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          _buildBackButton(),
          
          // Flash and camera switch controls
          Row(
            children: [
              _buildFlashControl(),
              const SizedBox(width: 12),
              _buildCameraSwitchControl(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeCaptureButton(Size screenSize, EdgeInsets safeArea) {
    final position = OrientationUIHelper.getCaptureButtonPosition(
      screenSize: screenSize,
      orientation: Orientation.landscape,
      safeArea: safeArea,
    );

    return Positioned(
      right: 16 + safeArea.right,
      top: position.dy - 40, // Center the 80px button
      child: _buildCaptureButton(),
    );
  }

  Widget _buildLandscapeLeftControls(Size screenSize, EdgeInsets safeArea) {
    return Positioned(
      left: 16 + safeArea.left,
      top: screenSize.height / 2 - 60, // Center vertically with some spacing
      child: Column(
        children: [
          // Gallery button
          _buildGalleryButton(),
          const SizedBox(height: 20),
          // Mode info
          _buildModeInfo(),
        ],
      ),
    );
  }

  Widget _buildLandscapeModeSelector(Size screenSize, EdgeInsets safeArea) {
    return Positioned(
      bottom: 16 + safeArea.bottom,
      left: screenSize.width / 2 - 80, // Center horizontally
      child: _buildModeSelector(),
    );
  }
}
```

### Step 3: Update Portrait Layout
```dart
class PortraitCameraOverlay extends StatelessWidget {
  const PortraitCameraOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    return Stack(
      children: [
        // Top controls - current implementation
        _buildPortraitTopControls(safeArea),
        
        // Bottom controls with capture button
        _buildPortraitBottomControls(screenSize, safeArea),
        
        // Mode selector for combined mode
        _buildPortraitModeSelector(screenSize, safeArea),
      ],
    );
  }

  // Keep existing portrait implementations but extracted into methods
  Widget _buildPortraitTopControls(EdgeInsets safeArea) {
    return Positioned(
      top: 16 + safeArea.top,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBackButton(),
          _buildFlashControl(),
          _buildCameraSwitchControl(),
        ],
      ),
    );
  }

  Widget _buildPortraitBottomControls(Size screenSize, EdgeInsets safeArea) {
    return Positioned(
      bottom: 32 + safeArea.bottom,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildGalleryButton(),
          _buildCaptureButton(),
          _buildModeInfo(),
        ],
      ),
    );
  }

  Widget _buildPortraitModeSelector(Size screenSize, EdgeInsets safeArea) {
    return Positioned(
      bottom: 120 + safeArea.bottom,
      left: 0,
      right: 0,
      child: _buildModeSelector(),
    );
  }
}
```

### Step 4: Update Main Camera Screen
```dart
Widget _buildCameraInterface() {
  final cameraState = ref.watch(cameraControllerProvider);
  final orientation = MediaQuery.of(context).orientation;

  if (cameraState.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (cameraState.errorMessage != null) {
    return _buildErrorState(cameraState.errorMessage!);
  }

  if (!cameraState.isInitialized || cameraState.controller == null) {
    return _buildPermissionOrInitializationState();
  }

  return Stack(
    children: [
      // Camera preview (updated with aspect ratio fix from Task 10)
      _buildCameraPreview(cameraState.controller!),

      // Orientation-specific UI overlay
      if (OrientationUIHelper.isLandscape(orientation))
        const LandscapeCameraOverlay()
      else
        const PortraitCameraOverlay(),
    ],
  );
}
```

### Step 5: Smooth Orientation Transitions
```dart
class _CameraScreenState extends ConsumerState<CameraScreen> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  
  late AnimationController _orientationController;
  late Animation<double> _orientationAnimation;

  @override
  void initState() {
    super.initState();
    
    _orientationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _orientationAnimation = CurvedAnimation(
      parent: _orientationController,
      curve: Curves.easeInOut,
    );
  }

  void _handleOrientationChange(Orientation newOrientation) {
    _orientationController.forward(from: 0.0);
    
    // Update any orientation-specific state
    setState(() {
      // Trigger rebuild with new orientation
    });
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        // Trigger smooth transition when orientation changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleOrientationChange(orientation);
        });

        return AnimatedBuilder(
          animation: _orientationAnimation,
          builder: (context, child) {
            return _buildCameraInterface();
          },
        );
      },
    );
  }
}
```

## Acceptance Criteria

- [ ] Landscape mode shows capture button at right-center
- [ ] Portrait mode keeps current bottom-center layout
- [ ] UI controls reposition appropriately for each orientation
- [ ] Smooth transitions between orientations
- [ ] All controls remain accessible in both orientations
- [ ] Mode selector adapts to orientation layout
- [ ] Flash and camera switch controls work in both layouts
- [ ] Gallery access remains convenient in both modes
- [ ] Touch targets are appropriately sized for orientation
- [ ] Visual hierarchy maintained in both layouts

## Testing Strategy

### Orientation Testing
- Test orientation changes during camera preview
- Verify smooth transitions without UI flicker
- Test rapid orientation changes
- Ensure controls remain functional during transitions

### Usability Testing
- Test single-hand operation in landscape
- Verify thumb reach for all controls
- Test with different device sizes
- Ensure accessibility compliance

### Edge Case Testing
- Test on devices with notches/cutouts
- Verify behavior with different aspect ratios
- Test with system UI bars visible/hidden
- Handle forced orientations (some apps lock orientation)

## Technical Considerations

### Performance
- Minimize layout recalculations during orientation changes
- Optimize animations for smooth transitions
- Consider impact on camera preview performance

### Accessibility
- Maintain accessibility labels for all orientations
- Ensure touch targets meet minimum size requirements
- Support screen readers in both orientations

### Device Compatibility
- Test on phones with different aspect ratios
- Handle devices with hardware navigation buttons
- Consider tablets and foldable devices

## Edge Cases

1. **Rapid Orientation Changes**: Debounce to prevent animation conflicts
2. **Locked Orientations**: Handle apps that force specific orientations
3. **Small Screens**: Ensure UI doesn't become too cramped
4. **Large Screens**: Prevent UI from becoming too spread out
5. **Notches/Cutouts**: Adapt layouts for screen irregularities

## Implementation Notes

- Build on existing orientation detection from Task 4
- Ensure compatibility with camera preview aspect ratio fixes
- Consider future tablet support
- Add analytics for orientation usage patterns
- Test extensively on different manufacturers' devices

## Dependencies

- Task 4: Advanced orientation handling system
- Task 10: Camera preview aspect ratio fix
- Task 11: Camera lens switching functionality
- Task 12: Enhanced flash controls
- Existing camera state management system 