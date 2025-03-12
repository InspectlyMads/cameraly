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
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraPreviewer(
        settings: CameraPreviewSettings(
          // Camera settings - video only mode
          cameraMode: CameraMode.videoOnly,
          resolution: ResolutionPreset.high,
          flashMode: FlashMode.auto,
          enableAudio: true, // Enable audio for video recording
          // Video specific settings
          videoDurationLimit: Duration(seconds: _maxDurationSeconds),

          // UI configuration
          showSwitchCameraButton: true,
          showFlashButton: true,
          showMediaStack: true,
          showCaptureButton: true,

          // Theme customization
          theme: const CameralyOverlayTheme(primaryColor: Colors.blue, secondaryColor: Colors.red, backgroundColor: Colors.black87, opacity: 0.8, buttonSize: 72.0, iconSize: 32.0),

          // Add custom done button
          customRightButton: FloatingActionButton(
            onPressed: () {
              debugPrint('Done button pressed with ${_capturedMedia.length} videos');
              Navigator.of(context).pop(_capturedMedia);
            },
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            child: const Icon(Icons.check),
          ),

          // Add duration indicator at the top
          topLeftWidget: Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
            child: Text('Maximum Duration: $_maxDurationSeconds seconds', style: const TextStyle(color: Colors.white)),
          ),

          // Loading text
          loadingText: 'Initializing Inspectly video camera...',

          // Capture callback to store media
          onCapture: (file) {
            debugPrint('Captured video: ${file.path}');
            setState(() {
              _capturedMedia.add(file);
            });

            // For video recordings that reach maximum duration
            if (file.path.isNotEmpty) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video saved'), backgroundColor: Colors.green));
            }
          },
        ),
      ),
    );
  }
}
