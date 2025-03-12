import 'package:cameraly/cameraly.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  String _orientationInfo = "Tap to check orientation";

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

  /// Tests the orientation detection using the platform method channel
  Future<void> _testOrientationDetection() async {
    if (!_isInitialized) return;

    setState(() {
      _orientationInfo = "Checking orientation...";
    });

    try {
      // Get raw rotation value for debugging
      final int rawRotation = await OrientationChannel.getRawRotationValue();

      // Get orientation from platform channel
      final DeviceOrientation channelOrientation = await OrientationChannel.getPlatformOrientation();

      // Get device dimensions
      final size = MediaQuery.of(context).size;
      final isLandscape = size.width > size.height;

      // Update state with the results
      setState(() {
        _orientationInfo = '''
Orientation Info:
• Raw Rotation: $rawRotation
• Device Orientation: ${channelOrientation.toString().split('.').last}
• Is Landscape: $isLandscape
• Screen Size: ${size.width.toInt()}x${size.height.toInt()}
''';
      });
    } catch (e) {
      setState(() {
        _orientationInfo = "Error checking orientation: $e";
      });
    }
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

                  // Customize which buttons to show
                  showFlashButton: true,
                  showSwitchCameraButton: true,
                  showGalleryButton: true,
                  showZoomControls: true,
                  showMediaStack: true, // Ensure media stack is enabled
                  showZoomSlider: true,
                  onControllerChanged: (CameralyController newController) {
                    setState(() {
                      _controller = newController;
                    });
                  },
                ),
              ),

          // Orientation testing button and info
          if (kDebugMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _testOrientationDetection,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(10)),
                    child: Text(_orientationInfo, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
