import 'package:camera/camera.dart' show XFile;
import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

/// A basic camera screen example.
class CameraScreen extends StatefulWidget {
  const CameraScreen({this.cameraMode = CameraMode.both, super.key});

  final CameraMode cameraMode;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameralyController _controller;
  final CameralyMediaManager _mediaManager = CameralyMediaManager(
    maxItems: 30, // Keep only the last 30 items
    onMediaAdded: _handleMediaAdded,
  );
  bool _isInitialized = false;

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
    _controller = CameralyController(
      description: cameras.first,
      settings: CaptureSettings(cameraMode: widget.cameraMode),
      mediaManager: _mediaManager, // Pass the already created media manager
    );

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error initializing camera: $e')));
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
    return Scaffold(
      body: Stack(
        children: [
          // Camera preview or loading indicator
          !_isInitialized
              ? Container(
                color: Colors.black,
                child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Colors.white), SizedBox(height: 16), Text('Initializing Camera...', style: TextStyle(color: Colors.white))])),
              )
              : CameralyPreview(
                controller: _controller,
                overlay: DefaultCameralyOverlay(
                  controller: _controller,
                  onPictureTaken: (file) => _mediaManager.addMedia(file),
                  onMediaSelected: (files) {
                    for (final file in files) {
                      _mediaManager.addMedia(file);
                    }
                  },
                  // Customize which buttons to show
                  showFlashButton: true,
                  showSwitchCameraButton: true,
                  showGalleryButton: true,
                  showZoomControls: true,
                  showFocusCircle: true,
                  showMediaStack: true, // Ensure media stack is enabled
                ),
              ),
        ],
      ),
    );
  }
}
