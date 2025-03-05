# Video Limiter Overlay Example

This document provides examples of how to use the `VideoLimiterOverlay` in your Flutter applications to limit video recording duration with a visual timer.

## Basic Usage

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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // Initialize the controller optimized for video recording
      final controller = await CameralyController.initializeForVideos(
        settings: const VideoSettings(
          resolution: ResolutionPreset.high,
          cameraMode: CameraMode.videoOnly, // Set to video-only mode
        ),
      );
      
      if (controller != null) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CameralyPreview(
        controller: _controller,
        overlayType: CameralyOverlayType.custom,
        customOverlay: VideoLimiterOverlay(
          controller: _controller,
          maxDuration: const Duration(seconds: 30), // Set maximum recording duration to 30 seconds
          onMaxDurationReached: () {
            // Handle when maximum duration is reached
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maximum recording duration reached')),
            );
          },
        ),
      ),
    );
  }
}
```

## Customizing the Video Limiter Overlay

You can customize the appearance and behavior of the `VideoLimiterOverlay`:

```dart
VideoLimiterOverlay(
  controller: _controller,
  // Set maximum recording duration
  maxDuration: const Duration(seconds: 15),
  
  // Customize the theme
  theme: CameralyOverlayTheme(
    primaryColor: Colors.amber,
    secondaryColor: Colors.red,
    backgroundColor: Colors.black.withOpacity(0.5),
    buttonSize: 72.0,
  ),
  
  // Control which buttons are visible
  showCaptureButton: true,
  showFlashButton: true,
  showSwitchCameraButton: true,
  showGalleryButton: true,
  showZoomControls: true,
  showModeToggle: false, // Hide mode toggle since we're in video-only mode
  
  // Handle when maximum duration is reached
  onMaxDurationReached: () {
    // Navigate to preview screen with the recorded video
    final videoFile = _controller.value.lastRecordedVideoFile;
    if (videoFile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoPreviewScreen(videoFile: videoFile),
        ),
      );
    }
  },
)
```

## Handling the Recorded Video

When the maximum duration is reached, the `onMaxDurationReached` callback is triggered. You can use this to handle the recorded video:

```dart
VideoLimiterOverlay(
  controller: _controller,
  maxDuration: const Duration(seconds: 30),
  onMaxDurationReached: () async {
    // The video recording has already been stopped automatically
    // You can access the last recorded video file from the controller
    final videoFile = await _controller.value.lastRecordedVideoFile;
    
    if (videoFile != null && mounted) {
      // Do something with the video file
      // For example, navigate to a preview screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoPreviewScreen(videoFile: videoFile),
        ),
      );
    }
  },
)
```

## Using with Different Maximum Durations

You can create different recording experiences by adjusting the maximum duration:

```dart
// Short-form video (15 seconds)
VideoLimiterOverlay(
  controller: _controller,
  maxDuration: const Duration(seconds: 15),
  onMaxDurationReached: () {
    // Handle short video completion
  },
)

// Medium-form video (60 seconds)
VideoLimiterOverlay(
  controller: _controller,
  maxDuration: const Duration(minutes: 1),
  onMaxDurationReached: () {
    // Handle medium video completion
  },
)

// Long-form video (3 minutes)
VideoLimiterOverlay(
  controller: _controller,
  maxDuration: const Duration(minutes: 3),
  onMaxDurationReached: () {
    // Handle long video completion
  },
)
```

## Responsive Layout Example

```dart
@override
Widget build(BuildContext context) {
  final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
  
  return Scaffold(
    body: CameralyPreview(
      controller: _controller,
      overlayType: CameralyOverlayType.custom,
      customOverlay: VideoLimiterOverlay(
        controller: _controller,
        maxDuration: const Duration(seconds: 30),
        // Adjust UI based on orientation
        showZoomControls: !isLandscape, // Hide zoom controls in landscape
        onMaxDurationReached: () {
          // Handle maximum duration reached
        },
      ),
    ),
  );
}
```

## Integration with State Management

When using a state management solution like BLoC, you can integrate the `VideoLimiterOverlay` as follows:

```dart
BlocConsumer<CameraBloc, CameraState>(
  listener: (context, state) {
    // Handle state changes
  },
  builder: (context, state) {
    return CameralyPreview(
      controller: state.controller,
      overlayType: CameralyOverlayType.custom,
      customOverlay: VideoLimiterOverlay(
        controller: state.controller,
        maxDuration: state.maxRecordingDuration,
        onMaxDurationReached: () {
          // Dispatch event to BLoC
          context.read<CameraBloc>().add(const CameraEvent.maxDurationReached());
        },
      ),
    );
  },
)
```

These examples demonstrate the flexibility of the `VideoLimiterOverlay` and how it can be used in different scenarios. 