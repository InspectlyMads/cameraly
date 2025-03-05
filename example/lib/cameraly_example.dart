import 'package:camera/camera.dart';
import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

/// Example app demonstrating the Cameraly package with the default overlay.
class CameralyExample extends StatefulWidget {
  /// Creates a new [CameralyExample] widget.
  const CameralyExample({super.key});

  @override
  State<CameralyExample> createState() => _CameralyExampleState();
}

class _CameralyExampleState extends State<CameralyExample> {
  late CameralyController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras available')));
        }
        return;
      }

      // Initialize the controller with the first camera
      _controller = CameralyController(description: cameras.first);
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

  void _showCapturedMedia(String filePath) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Media saved to: $filePath'), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cameraly Example'), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body:
          _isInitialized
              ? CameralyPreview(
                controller: _controller,
                // The default overlay is used automatically
                onTap: (position) {
                  _controller.setFocusAndExposurePoint(position);
                },
                onScale: (scale) {
                  // Handle pinch to zoom
                },
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}
