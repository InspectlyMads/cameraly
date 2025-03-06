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
  late CameralyMediaManager _mediaManager;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Initialize the media manager first
    _mediaManager = CameralyMediaManager(
      maxItems: 30, // Keep last 30 photos
      onMediaAdded: (file) {
        print('Media added to manager: ${file.path}'); // Debug print
        // Optional: Show feedback when photo is captured
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Photo captured: ${file.path.split('/').last}'), duration: const Duration(seconds: 2)));
        }
      },
    );

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
    return Stack(
      fit: StackFit.expand, // Make sure stack fills the screen
      children: [
        CameralyPreview(
          controller: _controller,
          overlay: DefaultCameralyOverlay(
            controller: _controller,
            showModeToggle: false, // Hide mode toggle since we're in photo-only mode
            onPictureTaken: (file) {
              print('Picture taken: ${file.path}'); // Debug print
              _mediaManager.addMedia(file);
            },
            customRightButton: FloatingActionButton(
              onPressed: () {
                print('Done button pressed with ${_mediaManager.count} photos'); // Debug print
                Navigator.of(context).pop(_mediaManager.media);
              },
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              child: const Icon(Icons.check),
            ),
            // Configure the media stack
            showMediaStack: true,
            mediaManager: _mediaManager,
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
