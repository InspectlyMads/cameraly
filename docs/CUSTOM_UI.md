# Custom UI Guide

## Overview

Cameraly allows you to customize most UI elements while maintaining core camera functionality. This guide explains which elements can be customized and how to implement custom widgets.

## Customizable Elements

### ✅ Can Be Customized

1. **Gallery Button** - The button that opens the photo gallery
2. **Check Button** - The confirmation/done button
3. **Flash Control** - The flash mode toggle button
4. **Camera Switcher** - The front/back camera switch button
5. **Grid Toggle** - The grid overlay toggle button
6. **Mode Switcher** - The photo/video mode selector (combined mode only)
7. **Left Side Widget** - Custom controls on the left side
8. **Right Side Widget** - Custom controls on the right side

### ❌ Cannot Be Customized

1. **Capture Button** - The photo/video capture button
   - Contains complex logic for photo capture, video recording, haptic feedback, and orientation handling
   - Must remain under package control to ensure proper functionality

## Implementation

### Basic Custom Widgets

```dart
CameraScreen(
  initialMode: CameraMode.photo,
  customWidgets: CameraCustomWidgets(
    // Custom gallery button
    galleryButton: Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.purple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.collections,
        color: Colors.white,
        size: 30,
      ),
    ),
    
    // Custom check button
    checkButton: Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.orange,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.done_all,
        color: Colors.white,
        size: 30,
      ),
    ),
  ),
)
```

### Custom Side Widgets

Add custom controls to the left or right side of the camera:

```dart
customWidgets: CameraCustomWidgets(
  leftSideWidget: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.timer, color: Colors.white),
          onPressed: () {
            // Handle timer
          },
        ),
        IconButton(
          icon: const Icon(Icons.filter_vintage, color: Colors.white),
          onPressed: () {
            // Handle filters
          },
        ),
      ],
    ),
  ),
)
```

## Important Notes

### Interaction with Package Controls

Custom buttons that replace package controls (flash, camera switch, grid) are purely visual. They don't have access to the camera control methods. To make them functional, you would need to:

1. Maintain your own state for these controls
2. Use the camera callbacks to know when changes occur
3. Synchronize your UI with the actual camera state

### Gallery and Check Button Callbacks

For gallery and check buttons, use the provided callbacks:

```dart
CameraScreen(
  onGalleryPressed: () {
    // Handle gallery button tap
    Navigator.push(context, ...);
  },
  onCheckPressed: () {
    // Handle check button tap
    Navigator.pop(context);
  },
)
```

### Layout Considerations

- **Portrait Mode**: Custom widgets appear in their designated positions
- **Landscape Mode**: Layout automatically adjusts for optimal ergonomics
- **Recording Mode**: Some UI elements are hidden during video recording

## Best Practices

1. **Maintain Visual Consistency**: Match the overall app theme
2. **Size Appropriately**: Ensure touch targets are at least 48x48 points
3. **Consider All Modes**: Test custom UI in photo, video, and combined modes
4. **Test Orientations**: Verify custom widgets work in both portrait and landscape
5. **Respect Safe Areas**: Account for device notches and system UI

## Limitations

- Cannot customize the capture button behavior or appearance
- Cannot access internal camera state directly
- Custom widgets are overlays and don't affect core camera functionality
- Some positions may be unavailable during recording