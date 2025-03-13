import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

/// A screen that demonstrates the Inspectly-styled video camera with a time limit
/// Uses the enhanced permission system and simplified API
class InspectlyLimitedVideoScreen extends StatefulWidget {
  const InspectlyLimitedVideoScreen({super.key});

  @override
  State<InspectlyLimitedVideoScreen> createState() => _InspectlyLimitedVideoScreenState();
}

class _InspectlyLimitedVideoScreenState extends State<InspectlyLimitedVideoScreen> {
  // Keep track of captured media
  final List<XFile> _capturedMedia = [];

  // The maximum recording duration in seconds
  static const int _maxDurationSeconds = 15;

  @override
  void initState() {
    super.initState();
    // Log the max duration to verify it's being set correctly
    debugPrint('📹 Setting up InspectlyLimitedVideoScreen with max duration: $_maxDurationSeconds seconds');
  }

  @override
  Widget build(BuildContext context) {
    // Create the duration object here for better debugging
    final maxDuration = Duration(seconds: _maxDurationSeconds);
    debugPrint('📹 Building camera with duration limit: $maxDuration');

    return Scaffold(
      body: CameralyCamera(
        settings: CameraPreviewSettings(
          // Camera settings - video only mode
          cameraMode: CameraMode.videoOnly,
          resolution: ResolutionPreset.high,
          flashMode: FlashMode.auto,
          enableAudio: true, // Enable audio for video recording
          // Video specific settings
          videoDurationLimit: maxDuration,

          // UI configuration
          showSwitchCameraButton: true,
          showFlashButton: true,
          showMediaStack: true,
          showCaptureButton: true,

          // Theme customization
          theme: const CameralyOverlayTheme(primaryColor: Colors.blue, secondaryColor: Colors.red, backgroundColor: Colors.black87, opacity: 0.8, buttonSize: 72.0, iconSize: 32.0),

          // Add custom done button
          customRightButton: SizedBox(
            height: 56, // Explicit height to ensure consistent sizing
            width: 56, // Explicit width to ensure consistent sizing
            child: FloatingActionButton(
              onPressed: () {
                debugPrint('Done button pressed with ${_capturedMedia.length} videos');
                Navigator.of(context).pop(_capturedMedia);
              },
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              child: const Icon(Icons.check),
            ),
          ),

          // Loading text
          loadingText: 'Initializing Inspectly video camera...',

          // Capture callback to store media
          onCapture: (file) {
            debugPrint('Captured video: ${file.path}');
            setState(() {
              _capturedMedia.add(file);
            });
          },

          // Add a callback to verify when recording reaches max duration
          // The CameraPreviewSettings doesn't have onMaxDurationReached callback directly
          // Instead we can add a listener within onInitialized
          onInitialized: (controller) {
            debugPrint('📹 Camera initialized with settings: ${controller.settings}');
            debugPrint('📹 Has video duration limit: ${controller.settings.maxVideoDuration != null}');
            if (controller.settings.maxVideoDuration != null) {
              debugPrint('📹 Video duration limit: ${controller.settings.maxVideoDuration}');
            }
          },
        ),
      ),
    );
  }
}
