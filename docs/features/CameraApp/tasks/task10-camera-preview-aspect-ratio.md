# Task 10: Camera Preview Aspect Ratio Fix

**Status**: 🔄 Todo  
**Priority**: High  
**Estimated Time**: 2-3 hours  
**Dependencies**: Task 4 (Camera Screen Core)

## Problem Description

The current fullscreen camera preview doesn't match what gets captured in the final image/video. This creates a misleading user experience where the preview shows more area than what's actually recorded.

**Current Issues:**
- Preview uses `Positioned.fill()` which stretches to full screen
- Camera sensor aspect ratio doesn't match device screen aspect ratio
- Users can't accurately frame their shots
- Professional camera apps show the actual capture area with bezels

## Solution Approach

### 1. Calculate Proper Aspect Ratio
- Use camera controller's native aspect ratio
- Center the preview within available space
- Add bezels/padding around the actual capture area

### 2. Responsive Preview Container
- Portrait: Center preview with top/bottom bezels
- Landscape: Center preview with left/right bezels
- Maintain camera's native aspect ratio

### 3. Visual Indicators
- Subtle bezel styling to indicate non-capture areas
- Ensure UI controls stay accessible outside preview area

## Implementation Plan

### Step 1: Create Aspect Ratio Calculation Utility
```dart
class CameraPreviewUtils {
  static Size calculatePreviewSize({
    required Size screenSize,
    required double cameraAspectRatio,
    required Orientation orientation,
  }) {
    // Calculate optimal preview size that fits screen while maintaining aspect ratio
  }
  
  static EdgeInsets calculatePreviewPadding({
    required Size screenSize,
    required Size previewSize,
  }) {
    // Calculate padding/bezels around preview
  }
}
```

### Step 2: Update Camera Preview Widget
```dart
Widget _buildCameraPreview(camera.CameraController controller) {
  final screenSize = MediaQuery.of(context).size;
  final orientation = MediaQuery.of(context).orientation;
  final cameraAspectRatio = controller.value.aspectRatio;
  
  final previewSize = CameraPreviewUtils.calculatePreviewSize(
    screenSize: screenSize,
    cameraAspectRatio: cameraAspectRatio,
    orientation: orientation,
  );
  
  return Center(
    child: Container(
      width: previewSize.width,
      height: previewSize.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: camera.CameraPreview(controller),
      ),
    ),
  );
}
```

### Step 3: Update UI Layout
- Ensure controls remain outside preview area
- Adjust overlay positioning for different screen sizes
- Test on various aspect ratios (16:9, 18:9, 19.5:9, etc.)

## Acceptance Criteria

- [ ] Camera preview shows exact capture area
- [ ] Preview is centered with appropriate bezels
- [ ] Works correctly in both portrait and landscape
- [ ] UI controls remain accessible and properly positioned
- [ ] No stretching or distortion of preview
- [ ] Consistent behavior across different screen aspect ratios
- [ ] Captured photos/videos match preview exactly

## Testing Strategy

### Device Testing
- Test on phones with different aspect ratios
- Verify both front and back camera previews
- Test orientation changes

### Capture Verification
- Take photos and compare with preview
- Record videos and verify framing matches
- Test edge cases (very wide/tall content)

## Technical Considerations

### Performance
- Ensure preview calculation doesn't impact frame rate
- Cache calculations when orientation doesn't change
- Optimize for smooth orientation transitions

### Accessibility
- Ensure sufficient contrast for bezel areas
- Maintain touch target sizes for controls
- Screen reader compatibility

## Edge Cases

1. **Extreme Aspect Ratios**: Very wide or narrow devices
2. **Small Screens**: Ensure preview remains usable
3. **Large Screens**: Prevent preview from becoming too large
4. **Orientation Changes**: Smooth transitions without flicker

## Implementation Notes

- Update both portrait and landscape camera overlays
- Consider adding a "full screen" toggle for advanced users
- Ensure orientation handling system works with new sizing
- Test with advanced orientation fixes from Task 4

## Dependencies

- Requires camera controller to be properly initialized
- Needs orientation detection system from existing implementation
- Should work with dual UI overlay system (portrait/landscape) 