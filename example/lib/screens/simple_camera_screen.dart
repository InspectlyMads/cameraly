import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

/// A minimal camera screen example using the simplified CameraPreviewer API.
///
/// This example demonstrates how to use the new CameraPreviewer widget with a
/// single settings object, eliminating the need for controller management.
class SimpleCameraScreen extends StatelessWidget {
  const SimpleCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraPreviewer(
        settings: CameraPreviewSettings(
          // Camera settings
          cameraMode: CameraMode.photoOnly,
          resolution: ResolutionPreset.high,
          flashMode: FlashMode.auto,

          // UI settings
          showSwitchCameraButton: true,
          showFlashButton: true,
          showMediaStack: true,

          // Custom UI elements
          customRightButton: FloatingActionButton(onPressed: () => Navigator.pop(context), backgroundColor: Colors.white, foregroundColor: Colors.black87, child: const Icon(Icons.check)),

          // Appearance
          loadingText: 'Starting camera...',

          // Callbacks
          onCapture: (file) {
            debugPrint('Captured: ${file.path}');
          },
          onComplete: (mediaList) {
            Navigator.pop(context, mediaList);
          },
        ),
      ),
    );
  }
}
