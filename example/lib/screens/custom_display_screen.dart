import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

/// A screen that demonstrates the customizable widgets with colored boxes.
class CustomDisplayScreen extends StatefulWidget {
  const CustomDisplayScreen({super.key});

  @override
  State<CustomDisplayScreen> createState() => _CustomDisplayScreenState();
}

class _CustomDisplayScreenState extends State<CustomDisplayScreen> {
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
    _mediaManager = CameralyMediaManager(maxItems: 30);

    // Get available cameras
    final cameras = await CameralyController.getAvailableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras available')));
      }
      return;
    }

    // Initialize the camera controller
    _controller = CameralyController(description: cameras.first, settings: CaptureSettings(cameraMode: CameraMode.both));

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
                      // Show colored boxes for customizable widgets
                      showPlaceholders: true,
                      // Show flash and zoom controls
                      showFlashButton: true,
                      showZoomControls: true,
                      // Enable camera switch button (it will move to top)
                      showSwitchCameraButton: true,
                      // Disable media stack since we're providing centerLeftWidget
                      showMediaStack: false,
                      // Add custom buttons with colored boxes
                      customLeftButton: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(244, 67, 54, 0.7), // Red
                          shape: BoxShape.circle,
                        ),
                        child: const Center(child: Text('Custom\nLeft', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      ),
                      customRightButton: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(33, 150, 243, 0.7), // Blue
                          shape: BoxShape.circle,
                        ),
                        child: const Center(child: Text('Custom\nRight', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      ),
                      // Add custom widgets to demonstrate positions
                      topLeftWidget: Container(
                        width: 120,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(33, 150, 243, 0.7), // Blue
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('Top Left', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
                      centerLeftWidget: Container(
                        width: 100,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(76, 175, 80, 0.7), // Green
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('Center Left', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
                      bottomOverlayWidget: Container(
                        width: double.infinity,
                        height: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(156, 39, 176, 0.7), // Purple
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('Bottom Overlay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
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
