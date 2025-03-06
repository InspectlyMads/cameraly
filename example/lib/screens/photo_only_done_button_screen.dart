import 'dart:io';

import 'package:camera/camera.dart' show XFile;
import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

/// A screen that demonstrates the photo-only camera with a done button
class PhotoOnlyDoneButtonScreen extends StatefulWidget {
  const PhotoOnlyDoneButtonScreen({super.key});

  @override
  State<PhotoOnlyDoneButtonScreen> createState() => _PhotoOnlyDoneButtonScreenState();
}

class _PhotoOnlyDoneButtonScreenState extends State<PhotoOnlyDoneButtonScreen> {
  late CameralyController _controller;
  bool _isInitialized = false;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await CameralyController.getAvailableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras available')));
      }
      return;
    }

    // Create a controller with photo-only mode
    _controller = CameralyController(description: cameras.first, settings: const CaptureSettings(cameraMode: CameraMode.photoOnly));

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

  Widget _buildCameraPreview() {
    return CameralyPreview(
      controller: _controller,
      overlay: DefaultCameralyOverlay(
        controller: _controller,
        showModeToggle: false, // Hide mode toggle since we're in photo-only mode
        onPictureTaken: (file) {
          setState(() {
            _capturedImage = file;
          });
        },
        customRightButton: FloatingActionButton(onPressed: () => Navigator.of(context).pop(), backgroundColor: Colors.white, foregroundColor: Colors.black87, child: const Icon(Icons.check)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(appBar: AppBar(title: const Text('Photo Only with Done Button')), body: const Center(child: CircularProgressIndicator()));
    }

    if (_capturedImage != null) {
      // Show the captured image
      return Scaffold(
        appBar: AppBar(title: const Text('Captured Photo')),
        body: Column(
          children: [
            Expanded(child: Image.file(File(_capturedImage!.path), fit: BoxFit.contain)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _capturedImage = null;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Take Another'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, _capturedImage);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Use This Photo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(body: _buildCameraPreview());
  }
}
