import 'package:cameraly/cameraly.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A screen that demonstrates the photo-only camera with a done button
class InspectlyVersionScreen extends StatefulWidget {
  const InspectlyVersionScreen({super.key});

  @override
  State<InspectlyVersionScreen> createState() => _InspectlyVersionScreenState();
}

class _InspectlyVersionScreenState extends State<InspectlyVersionScreen> {
  late CameralyController _controller;
  late CameralyMediaManager _mediaManager;
  bool _isInitialized = false;
  String _orientationInfo = "Tap to check orientation";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Initialize the media manager first
    _mediaManager = CameralyMediaManager(
      maxItems: 9999, // Keep all photos
      onMediaAdded: (file) {},
    );

    final cameras = await CameralyController.getAvailableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras available')));
      }
      return;
    }

    // Create a controller with photo-only mode
    _controller = CameralyController(
      description: cameras.first,
      settings: const CaptureSettings(cameraMode: CameraMode.photoOnly),
      mediaManager: _mediaManager, // Pass the media manager to the controller
    );

    try {
      await _controller.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to initialize camera: $e')));
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

  Widget _buildCameraPreview() {
    return Stack(
      fit: StackFit.expand, // Make sure stack fills the screen
      children: [
        CameralyPreview(
          controller: _controller,
          overlay: DefaultCameralyOverlay(
            controller: _controller,
            // Add camera switch button at the top
            showSwitchCameraButton: true,
            // Add custom done button
            customRightButton: FloatingActionButton(
              onPressed: () {
                debugPrint('Done button pressed with ${_mediaManager.count} photos'); // Debug print
                Navigator.of(context).pop(_mediaManager.media);
              },
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              child: const Icon(Icons.check),
            ),
            // Configure the media stack
            showMediaStack: true,
            // Add the onControllerChanged callback to properly handle camera switching
            onControllerChanged: (CameralyController newController) {
              debugPrint('Camera controller changed in InspectlyVersionScreen');
              // Update the controller reference in the state
              setState(() {
                _controller = newController;
              });
            },
          ),
        ),

        // Add orientation testing button and info display
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(appBar: AppBar(title: const Text('Photo Only with Done Button')), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(body: _buildCameraPreview());
  }
}
