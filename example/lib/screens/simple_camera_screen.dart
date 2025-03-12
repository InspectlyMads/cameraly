import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

/// A minimal camera screen example using the simplified CameraPreviewer API.
///
/// This example demonstrates how to use the CameraPreviewer widget with a
/// single settings object, eliminating the need for controller management.
class SimpleCameraScreen extends StatelessWidget {
  const SimpleCameraScreen({this.useEnhanced = false, super.key});

  final bool useEnhanced;

  @override
  Widget build(BuildContext context) {
    // If useEnhanced is true, use the new enhanced preview implementation
    if (useEnhanced) {
      return EnhancedSimpleCameraScreen();
    }

    // Original implementation using CameraPreviewer
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

/// Enhanced version of the simple camera screen that uses CameralyPreviewEnhanced
/// with improved permission handling.
class EnhancedSimpleCameraScreen extends StatefulWidget {
  const EnhancedSimpleCameraScreen({super.key});

  @override
  State<EnhancedSimpleCameraScreen> createState() => _EnhancedSimpleCameraScreenState();
}

class _EnhancedSimpleCameraScreenState extends State<EnhancedSimpleCameraScreen> {
  CameralyController? _controller;
  final List<XFile> _capturedMedia = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    // Get available cameras
    final cameras = await CameralyController.getAvailableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras available')));
      }
      return;
    }

    // Create controller with photo-only mode
    final controller = CameralyController(description: cameras.first, settings: const CaptureSettings(cameraMode: CameraMode.photoOnly, resolution: ResolutionPreset.high, flashMode: FlashMode.auto));

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CameralyPreviewEnhanced(
        controller: _controller!,
        // Custom colors for permission UI
        backgroundColor: Colors.black,
        textColor: Colors.white,
        buttonColor: Theme.of(context).primaryColor,
        // Pass the CameralyPreview with overlay as child
        child: CameralyControllerProvider(
          controller: _controller!,
          child: CameralyPreview(
            controller: _controller!,
            overlay: DefaultCameralyOverlay(
              showFlashButton: true,
              showSwitchCameraButton: true,
              showGalleryButton: false,
              showZoomControls: true,
              showMediaStack: true,
              customRightButton: FloatingActionButton(
                onPressed: () {
                  debugPrint('Done button pressed with ${_capturedMedia.length} photos');
                  Navigator.of(context).pop(_capturedMedia);
                },
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                child: const Icon(Icons.check),
              ),
              onCapture: (file) {
                debugPrint('Captured: ${file.path}');
                setState(() {
                  _capturedMedia.add(file);
                });
              },
              onControllerChanged: (newController) {
                setState(() {
                  _controller = newController;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
