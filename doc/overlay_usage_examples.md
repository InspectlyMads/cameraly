# Cameraly Overlay System Usage Examples

This document provides examples of how to use the Cameraly overlay system in your Flutter applications.

## Basic Example with Default Overlay

```dart
import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameralyController _controller;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    // Simplified camera initialization
    final controller = await CameralyController.initializeCamera();
    if (controller != null) {
      _controller = controller;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CameralyPreview(
        controller: _controller,
        // Default overlay is used automatically
      ),
    );
  }
}
```

## Customized Default Overlay

```dart
CameralyPreview(
  controller: _controller,
  overlayType: CameralyOverlayType.defaultOverlay,
  defaultOverlay: DefaultCameralyOverlay(
    // Customize theme
    theme: CameralyOverlayTheme(
      primaryColor: Colors.amber,
      secondaryColor: Colors.deepOrange,
      backgroundColor: Colors.black38,
      buttonSize: 64.0,
    ),
    
    // Control visibility
    showFlashToggle: true,
    showCameraSwitchButton: true,
    showZoomControls: true,
    showGalleryThumbnail: false,
    
    // Control positioning
    captureButtonPosition: OverlayPosition.bottomCenter,
    flashTogglePosition: OverlayPosition.topRight,
    cameraSwitchPosition: OverlayPosition.topLeft,
    zoomControlsPosition: OverlayPosition.centerRight,
  ),
)
```

## Custom Overlay Example

```dart
CameralyPreview(
  controller: _controller,
  overlayType: CameralyOverlayType.custom,
  customOverlay: Builder(
    builder: (context) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Capture Button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  final photo = await _controller.takePicture();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Photo saved to: ${photo.path}')),
                    );
                  }
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Camera Switch Button
          Positioned(
            top: 30,
            right: 30,
            child: GestureDetector(
              onTap: () {
                _controller.switchCamera();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.flip_camera_ios,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          
          // Flash Mode Button
          Positioned(
            top: 30,
            left: 30,
            child: GestureDetector(
              onTap: () {
                _controller.cycleFlashMode();
              },
              child: ValueListenableBuilder<CameralyValue>(
                valueListenable: _controller,
                builder: (context, value, child) {
                  IconData iconData;
                  switch (value.flashMode) {
                    case FlashMode.auto:
                      iconData = Icons.flash_auto;
                      break;
                    case FlashMode.always:
                      iconData = Icons.flash_on;
                      break;
                    case FlashMode.torch:
                      iconData = Icons.highlight;
                      break;
                    case FlashMode.off:
                    default:
                      iconData = Icons.flash_off;
                      break;
                  }
                  
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      iconData,
                      color: Colors.white,
                      size: 28,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    },
  ),
)
```

## No Overlay Example

```dart
CameralyPreview(
  controller: _controller,
  overlayType: CameralyOverlayType.none,
  // No overlay will be shown, just the camera preview
)
```

## Switching Between Overlay Types

```dart
class _CameraScreenState extends State<CameraScreen> {
  late CameralyController _controller;
  CameralyOverlayType _overlayType = CameralyOverlayType.defaultOverlay;

  // ... initialization code ...

  void _toggleOverlayType() {
    setState(() {
      switch (_overlayType) {
        case CameralyOverlayType.none:
          _overlayType = CameralyOverlayType.defaultOverlay;
          break;
        case CameralyOverlayType.defaultOverlay:
          _overlayType = CameralyOverlayType.custom;
          break;
        case CameralyOverlayType.custom:
          _overlayType = CameralyOverlayType.none;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CameralyPreview(
        controller: _controller,
        overlayType: _overlayType,
        customOverlay: _buildCustomOverlay(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleOverlayType,
        child: const Icon(Icons.switch_access_shortcut),
      ),
    );
  }

  Widget _buildCustomOverlay() {
    // Custom overlay implementation
    return const Placeholder();
  }
}
```

## Advanced Example: Combining with Other Features

```dart
CameralyPreview(
  controller: _controller,
  overlayType: CameralyOverlayType.defaultOverlay,
  defaultOverlay: DefaultCameralyOverlay(
    theme: CameralyOverlayTheme(
      primaryColor: Theme.of(context).primaryColor,
      secondaryColor: Theme.of(context).colorScheme.secondary,
      // Adapt to the app's theme
    ),
  ),
  onTap: (point) {
    // Handle tap-to-focus
    _controller.setFocusPoint(point);
  },
  onScale: (scale) {
    // Handle pinch-to-zoom
    _controller.setZoomLevel(scale);
  },
)
```

## Video Limiter Overlay Example

The `VideoLimiterOverlay` extends the default overlay to add a time limit for video recording with a visual timer and progress indicator.

```dart
CameralyPreview(
  controller: _controller,
  overlayType: CameralyOverlayType.custom,
  customOverlay: VideoLimiterOverlay(
    controller: _controller,
    // Set maximum recording duration
    maxDuration: const Duration(seconds: 30),
    
    // Customize the theme
    theme: CameralyOverlayTheme(
      primaryColor: Colors.white,
      secondaryColor: Colors.red,
      backgroundColor: Colors.black.withOpacity(0.5),
    ),
    
    // Control which buttons are visible
    showCaptureButton: true,
    showFlashButton: true,
    showSwitchCameraButton: true,
    showGalleryButton: true,
    showZoomControls: true,
    showModeToggle: true,
    showFocusCircle: true,
    
    // Handle when maximum duration is reached
    onMaxDurationReached: () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum recording duration reached')),
      );
    },
  ),
)
```

The `VideoLimiterOverlay` displays a timer and progress bar at the top of the screen when recording is in progress. The progress bar changes color to red when approaching the maximum duration.

## Responsive Layout Example

```dart
@override
Widget build(BuildContext context) {
  final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
  
  return Scaffold(
    body: CameralyPreview(
      controller: _controller,
      overlayType: CameralyOverlayType.defaultOverlay,
      defaultOverlay: DefaultCameralyOverlay(
        // Adjust positions based on orientation
        captureButtonPosition: isLandscape 
            ? OverlayPosition.centerRight 
            : OverlayPosition.bottomCenter,
        cameraSwitchPosition: isLandscape
            ? OverlayPosition.topRight
            : OverlayPosition.topLeft,
        // Other customizations
      ),
    ),
  );
}
```

These examples demonstrate the flexibility of the Cameraly overlay system and how it can be used in different scenarios. 