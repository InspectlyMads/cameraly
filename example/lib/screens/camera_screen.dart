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
  late CameralyMediaManager _mediaManager;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    // Create the media manager
    _mediaManager = CameralyMediaManager(
      maxItems: 30, // Keep only the last 30 items
      onMediaAdded: (file) {
        // Show a snackbar when media is captured
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Captured: ${file.path.split('/').last}'), duration: const Duration(seconds: 2)));
        }
      },
    );

    // Get available cameras
    final cameras = await CameralyController.getAvailableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras available')));
      }
      return;
    }

    // Initialize the camera controller
    _controller = CameralyController(description: cameras.first, settings: CaptureSettings(cameraMode: widget.cameraMode));

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
      body:
          !_isInitialized
              ? Container(
                color: Colors.black,
                child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Colors.white), SizedBox(height: 16), Text('Initializing Camera...', style: TextStyle(color: Colors.white))])),
              )
              : Stack(
                children: [
                  // Camera preview with default overlay
                  CameralyPreview(
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
                      showModeToggle: widget.cameraMode == CameraMode.both,
                      showFocusCircle: true,
                    ),
                  ),

                  // Media stack in the bottom-right corner
                  SafeArea(
                    child: Positioned(
                      right: 16,
                      bottom: 100,
                      child: CameralyMediaStack(mediaManager: _mediaManager, itemSize: 60, maxDisplayItems: 3, borderColor: Colors.white, borderWidth: 2, borderRadius: 8, showCountBadge: true, countBadgeColor: Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              ),
    );
  }
}
