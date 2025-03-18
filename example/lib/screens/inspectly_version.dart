import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

/// A screen that demonstrates the photo-only camera with a done button
/// This implementation uses the simplified CameralyCamera API
class InspectlyVersionScreen extends StatefulWidget {
  const InspectlyVersionScreen({super.key});

  @override
  State<InspectlyVersionScreen> createState() => _InspectlyVersionScreenState();
}

class _InspectlyVersionScreenState extends State<InspectlyVersionScreen> {
  // Keep track of captured media
  final List<XFile> _capturedMedia = [];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: CameralyCamera(
          settings: CameraPreviewSettings(
            // Camera settings - photo only mode
            cameraMode: CameraMode.photoOnly,
            resolution: ResolutionPreset.high,
            flashMode: FlashMode.auto,
            enableAudio: false,

            // UI configuration
            showSwitchCameraButton: true,
            showFlashButton: true,
            showMediaStack: true,
            showCaptureButton: true,

            // Keep all photos (no limit)
            maxMediaItems: 9999,

            // Add custom done button that can be disabled during recording
            customRightButtonBuilder: (context, state) {
              // Disable button while recording
              final bool isDisabled = state.isRecording;

              return SizedBox(
                height: 56, // Explicit height to ensure consistent sizing
                width: 56, // Explicit width to ensure consistent sizing
                child: FloatingActionButton(
                  onPressed:
                      isDisabled
                          ? null
                          : () {
                            debugPrint('Done button pressed with ${_capturedMedia.length} photos');
                            Navigator.of(context).pop(_capturedMedia);
                          },
                  backgroundColor: isDisabled ? Colors.grey : Colors.white,
                  foregroundColor: Colors.black87,
                  child: const Icon(Icons.check),
                ),
              );
            },

            // Loading text
            loadingText: 'Initializing Inspectly camera...',

            // Capture callback to store media
            onCapture: (file) {
              debugPrint('Captured: ${file.path}');
              setState(() {
                _capturedMedia.add(file);
              });
            },
            onError: (source, message, {error, isRecoverable = false}) {
              debugPrint('❌ Camera error ($source): $message');
              if (error != null) {
                debugPrint('❌ Error details: $error');
              }
            },
          ),
        ),
      ),
    );
  }
}
