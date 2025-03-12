import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

/// A screen that demonstrates video recording with a duration limit
class LimitedVideoExample extends StatefulWidget {
  const LimitedVideoExample({super.key});

  @override
  State<LimitedVideoExample> createState() => _LimitedVideoExampleState();
}

class _LimitedVideoExampleState extends State<LimitedVideoExample> {
  // Keep track of captured media
  final List<XFile> _capturedMedia = [];
  bool _showError = false;
  String? _errorMessage;

  void _handleError(String source, String message, {Object? error, bool isRecoverable = false}) {
    debugPrint('Camera error from $source: $message');
    debugPrint('Original error: $error');
    debugPrint('Is recoverable: $isRecoverable');

    // Only update the error state in this example
    setState(() {
      _showError = true;
      _errorMessage = message;
    });

    // Removed snackbar notification to let parent component handle it
  }

  void _handleMaxDurationReached(List<XFile> mediaList) {
    // Handle the list of captured media
    if (mediaList.isNotEmpty) {
      final XFile lastFile = mediaList.last;
      debugPrint('Maximum duration reached: ${lastFile.path}');
      setState(() {
        _capturedMedia.addAll(mediaList);
      });
    } else {
      debugPrint('No files were captured');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video Recording Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'An unknown error occurred'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showError = false;
                    _errorMessage = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Use the CameralyCamera for simplified camera handling
    return Scaffold(
      body: CameralyCamera(
        settings: CameraPreviewSettings(
          // Configure for video-only mode with audio
          cameraMode: CameraMode.videoOnly,
          enableAudio: true,

          // Set maximum video duration to 15 seconds
          videoDurationLimit: const Duration(seconds: 15),

          // UI customization
          showFlashButton: true,
          showSwitchCameraButton: true,
          showGalleryButton: true,

          // Handle video recording completion
          onComplete: _handleMaxDurationReached,

          // Handle errors
          onError: _handleError,

          // Handle media capture
          onCapture: (file) {
            debugPrint('Video recorded: ${file.path}');
            // Implement your file handling here
          },
        ),
      ),
    );
  }
}
