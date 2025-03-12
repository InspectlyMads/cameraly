import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

/// A basic camera screen example using the enhanced preview with improved permission handling.
class CameraScreen extends StatefulWidget {
  const CameraScreen({this.cameraMode = CameraMode.both, this.useEnhanced = true, super.key});

  final CameraMode cameraMode;
  final bool useEnhanced;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // Keep orientation info ValueNotifier
  final ValueNotifier<String> _orientationInfo = ValueNotifier<String>("Tap to check orientation");
  String? _errorMessage;
  CameralyController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.useEnhanced) {
      _initializeController();
    }
  }

  Future<void> _initializeController() async {
    try {
      final cameras = await CameralyController.getAvailableCameras();
      if (cameras.isEmpty) {
        _handleError('initialization', 'No cameras available');
        return;
      }

      final controller = CameralyController(description: cameras.first, settings: CaptureSettings(cameraMode: widget.cameraMode, resolution: ResolutionPreset.high, flashMode: FlashMode.auto, enableAudio: widget.cameraMode != CameraMode.photoOnly));

      await controller.initialize();

      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (e) {
      _handleError('initialization', 'Failed to initialize camera', error: e);
    }
  }

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
    // Just log the capture in this example
    debugPrint('Captured: ${file.path}');

    // Removed snackbar notification to let parent component handle it
  }

  @override
  void dispose() {
    // Dispose ValueNotifiers
    _orientationInfo.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useEnhanced) {
      // Using the enhanced preview with the new overlay system
      if (_controller == null) {
        return Scaffold(appBar: AppBar(title: const Text('Enhanced Camera')), body: Center(child: _errorMessage != null ? Text('Error: $_errorMessage') : const CircularProgressIndicator()));
      }

      return Scaffold(
        appBar: AppBar(title: const Text('Enhanced Camera')),
        body: CameralyPreviewEnhanced(
          controller: _controller!,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          child: CameralyPreview(
            controller: _controller!,
            overlay: DefaultCameralyOverlay(showFlashButton: true, showSwitchCameraButton: true, showGalleryButton: true, showZoomControls: true, showMediaStack: true, onCapture: _handleCapture, onError: _handleError),
          ),
        ),
      );
    }

    // Simple implementation using CameralyCamera with default overlay
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: CameralyCamera(
        settings: CameraPreviewSettings(
          // Camera mode from widget parameter
          cameraMode: widget.cameraMode,

          // Higher resolution for better quality
          resolution: ResolutionPreset.high,

          // Default to auto flash
          flashMode: FlashMode.auto,

          // UI visibility settings
          showFlashButton: true,
          showSwitchCameraButton: true,
          showGalleryButton: true,
          showZoomControls: true,
          showMediaStack: true,

          // Media settings
          maxMediaItems: 30,

          // Loading indicator
          loadingText: 'Preparing camera...',
          loadingBackgroundColor: Colors.black,
          loadingIndicatorColor: Colors.white,
          loadingTextColor: Colors.white,

          // Callbacks
          onError: _handleError,
          onCapture: _handleCapture,
          onInitialized: (controller) {
            debugPrint('Camera initialized successfully');
          },
        ),
      ),
    );
  }
}
