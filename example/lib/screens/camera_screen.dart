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

    try {
      await controller.initialize();
      // Controller's value.isInitialized will be true after initialization
      if (mounted) {
        setState(() {
          _controller = controller;
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
    // Dispose ValueNotifiers
    _orientationInfo.dispose();
    _controller?.dispose();
    super.dispose();
  }

  /// Tests the orientation detection using the platform method channel
  Future<void> _testOrientationDetection() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // Update the ValueNotifier instead of calling setState
    _orientationInfo.value = "Checking orientation...";

    try {
      // Get raw rotation value for debugging
      final int rawRotation = await OrientationChannel.getRawRotationValue();

      // Get orientation from platform channel
      final DeviceOrientation channelOrientation = await OrientationChannel.getPlatformOrientation();

      // Get device dimensions
      final size = MediaQuery.of(context).size;
      final isLandscape = size.width > size.height;

      // Update ValueNotifier with the results instead of calling setState
      _orientationInfo.value = '''
Orientation Info:
• Raw Rotation: $rawRotation
• Device Orientation: ${channelOrientation.toString().split('.').last}
• Is Landscape: $isLandscape
• Screen Size: ${size.width.toInt()}x${size.height.toInt()}
''';
    } catch (e) {
      // Update ValueNotifier with error instead of calling setState
      _orientationInfo.value = "Error checking orientation: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // If controller is null, show a loading indicator
          if (_controller == null)
            const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Starting camera...')]))
          else
            // If controller exists, wrap with CameralyControllerProvider
            CameralyControllerProvider(
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
                // Optional custom loading builder example
                loadingBuilder:
                    (context, value) => Container(
                      color: Colors.black,
                      child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Colors.white), SizedBox(height: 16), Text('Preparing camera...', style: TextStyle(color: Colors.white))])),
                    ),
              ),
            ),

          // Orientation testing button and info - use ValueListenableBuilder
          if (kDebugMode && _controller != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 0,
              right: 0,
              child: Center(
                child: ValueListenableBuilder<String>(
                  valueListenable: _orientationInfo,
                  builder: (context, orientationInfo, child) {
                    return GestureDetector(
                      onTap: _testOrientationDetection,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(10)),
                        child: Text(orientationInfo, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
