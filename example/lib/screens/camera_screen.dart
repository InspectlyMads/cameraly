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
  CameralyController? _controller;
  final CameralyMediaManager _mediaManager = CameralyMediaManager(
    maxItems: 30, // Keep only the last 30 items
    onMediaAdded: _handleMediaAdded,
  );

  // Keep orientation info ValueNotifier
  final ValueNotifier<String> _orientationInfo = ValueNotifier<String>("Tap to check orientation");

  static void _handleMediaAdded(XFile file) {
    // Note: we can't show snackbar here since it's static
    // The UI feedback will be handled by the overlay itself
  }

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

    // Initialize the camera controller
    final controller = CameralyController(
      description: cameras.first,
      settings: CaptureSettings(cameraMode: widget.cameraMode),
      mediaManager: _mediaManager, // Pass the already created media manager
    );

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
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
    if (_controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Build the camera preview widget
    Widget cameraWidget;

    // Create the camera preview with overlay
    final previewWithOverlay = CameralyControllerProvider(
      controller: _controller!,
      child: CameralyPreview(
        controller: _controller!,
        // We don't need to pass the controller to the overlay anymore!
        // It will get it from the CameralyControllerProvider
        overlay: DefaultCameralyOverlay(
          // Customize which buttons to show
          showFlashButton: true,
          showSwitchCameraButton: true,
          showGalleryButton: true,
          showZoomControls: true,
          showMediaStack: true, // Ensure media stack is enabled
          showZoomSlider: true,
          onControllerChanged: (CameralyController newController) {
            // This still needs setState because we're changing a field
            setState(() {
              _controller = newController;
            });
          },
        ),
      ),
    );

    // Use the enhanced permission handling if requested
    if (widget.useEnhanced) {
      cameraWidget = CameralyPreviewEnhanced(
        controller: _controller!,
        // Custom loading widget
        loadingWidget: Container(
          color: Colors.black,
          child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Colors.white), SizedBox(height: 16), Text('Preparing camera...', style: TextStyle(color: Colors.white))])),
        ),
        // Pass the preview widget as the child
        child: previewWithOverlay,
      );
    } else {
      // Use the original implementation
      cameraWidget = previewWithOverlay;
    }

    return Scaffold(body: cameraWidget);
  }
}
