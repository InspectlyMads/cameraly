import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

/// A minimal camera screen example using the simplified CameralyCamera API.
///
/// This example demonstrates how to use the CameralyCamera widget with a
/// single settings object, eliminating the need for controller management.
class SimpleCameraScreen extends StatelessWidget {
  const SimpleCameraScreen({this.useEnhanced = false, super.key});

  final bool useEnhanced;

  @override
  Widget build(BuildContext context) {
    // If useEnhanced is true, use the new enhanced preview implementation
    if (useEnhanced) {
      return const EnhancedSimpleCameraScreen();
    }

    // Original implementation using CameralyCamera
    return Scaffold(
      body: CameralyCamera(
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

/// Enhanced version of the simple camera screen that uses CameralyCamera
/// with improved error handling and permission management.
class EnhancedSimpleCameraScreen extends StatefulWidget {
  const EnhancedSimpleCameraScreen({super.key});

  @override
  State<EnhancedSimpleCameraScreen> createState() => _EnhancedSimpleCameraScreenState();
}

class _EnhancedSimpleCameraScreenState extends State<EnhancedSimpleCameraScreen> {
  // Keep track of captured media for return value
  final List<XFile> _capturedMedia = [];
  String? _errorMessage;

  void _handleError(String source, String message, {Object? error, bool isRecoverable = false}) {
    debugPrint('Camera error from $source: $message');
    debugPrint('Original error: $error');

    // Only update the error state in this example
    setState(() {
      _errorMessage = message;
    });

    // Removed snackbar notification to let parent component handle it
  }

  void _handleCapture(XFile file) {
    debugPrint('Captured: ${file.path}');
    setState(() {
      _capturedMedia.add(file);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show error screen if there's an error
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Camera Error: $_errorMessage'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
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

    return Scaffold(
      body: CameralyCamera(
        settings: CameraPreviewSettings(
          // Camera settings
          cameraMode: CameraMode.photoOnly,
          resolution: ResolutionPreset.high,
          flashMode: FlashMode.auto,

          // UI settings
          showFlashButton: true,
          showSwitchCameraButton: true,
          showMediaStack: true,
          showZoomControls: true,

          // Error handling
          onError: _handleError,

          // Custom UI elements
          customRightButton: FloatingActionButton(
            onPressed: () {
              debugPrint('Done button pressed with ${_capturedMedia.length} photos');
              Navigator.of(context).pop(_capturedMedia);
            },
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            child: const Icon(Icons.check),
          ),

          // Appearance
          loadingText: 'Enhanced camera starting...',
          loadingBackgroundColor: Colors.black,
          loadingIndicatorColor: Colors.white,
          loadingTextColor: Colors.white,

          // Callbacks
          onCapture: _handleCapture,
          onInitialized: (controller) {
            debugPrint('Camera initialized successfully');
          },
        ),
      ),
    );
  }
}
