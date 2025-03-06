import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

/// A screen that demonstrates how to create custom camera overlays
class CustomOverlayExample extends StatefulWidget {
  const CustomOverlayExample({super.key});

  @override
  State<CustomOverlayExample> createState() => _CustomOverlayExampleState();
}

class _CustomOverlayExampleState extends State<CustomOverlayExample> {
  late CameralyController _controller;
  bool _isInitialized = false;
  double _currentZoom = 1.0;
  bool _isRecording = false;
  bool _isVideoMode = false;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await CameralyController.getAvailableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras available')));
      }
      return;
    }

    _controller = CameralyController(description: cameras.first, settings: const CaptureSettings(cameraMode: CameraMode.both));

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

  // Custom overlay widget that demonstrates various UI elements
  Widget _buildCustomOverlay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Top bar with camera controls
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 50),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flash toggle button
                ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    // Only show flash controls for photo mode or video mode with torch
                    final isPhotoMode = _controller.settings.cameraMode == CameraMode.photoOnly;
                    if (!isPhotoMode && !_isRecording) {
                      return IconButton(
                        icon: Icon(_torchEnabled ? Icons.flashlight_on : Icons.flashlight_off, color: Colors.white),
                        onPressed: () async {
                          setState(() => _torchEnabled = !_torchEnabled);
                          await _controller.setFlashMode(_torchEnabled ? FlashMode.torch : FlashMode.off);
                        },
                      );
                    }

                    if (isPhotoMode) {
                      return IconButton(
                        icon: Icon(
                          value.flashMode == FlashMode.off
                              ? Icons.flash_off
                              : value.flashMode == FlashMode.auto
                              ? Icons.flash_auto
                              : Icons.flash_on,
                          color: Colors.white,
                        ),
                        onPressed: _controller.toggleFlash,
                      );
                    }

                    return const SizedBox.shrink(); // Hide during recording
                  },
                ),
                // Camera switch button
                IconButton(icon: const Icon(Icons.cameraswitch, color: Colors.white), onPressed: _controller.switchCamera),
              ],
            ),
          ),
        ),

        // Center focus area indicator
        Center(child: Container(width: 80, height: 80, decoration: BoxDecoration(border: Border.all(color: Colors.white30, width: 1), borderRadius: BorderRadius.circular(8)))),

        // Bottom controls
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 50),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Custom mode toggle
                ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    final isPhotoMode = _controller.settings.cameraMode == CameraMode.photoOnly;
                    return TextButton(
                      onPressed: () async {
                        // Create new settings with the opposite mode
                        final newSettings = CaptureSettings(
                          cameraMode: isPhotoMode ? CameraMode.videoOnly : CameraMode.photoOnly,
                          resolution: _controller.settings.resolution,
                          enableAudio: !isPhotoMode, // Enable audio for video mode
                        );

                        // Create and initialize a new controller with the new mode
                        final cameras = await CameralyController.getAvailableCameras();
                        if (cameras.isEmpty) return;

                        final newController = CameralyController(description: _controller.description, settings: newSettings);

                        await newController.initialize();

                        // Dispose the old controller and update state
                        _controller.dispose();
                        setState(() {
                          _controller = newController;
                          _isVideoMode = !isPhotoMode;
                        });
                      },
                      child: Text(isPhotoMode ? 'PHOTO' : 'VIDEO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
                // Capture/record button
                GestureDetector(
                  onTapDown: (_) async {
                    if (_controller.settings.cameraMode == CameraMode.photoOnly) {
                      final photo = await _controller.takePicture();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Photo captured: ${photo.path}')));
                      }
                    } else {
                      if (_isRecording) {
                        final video = await _controller.stopVideoRecording();
                        setState(() => _isRecording = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video saved: ${video.path}')));
                        }
                      } else {
                        await _controller.startVideoRecording();
                        setState(() => _isRecording = true);
                      }
                    }
                  },
                  child: ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, value, child) {
                      final isPhoto = _controller.settings.cameraMode == CameraMode.photoOnly;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isPhoto ? 80 : 60,
                        height: isPhoto ? 80 : 60,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red : Colors.white,
                          shape: isPhoto ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: isPhoto ? null : BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: _isRecording ? const Icon(Icons.stop, color: Colors.white) : null,
                      );
                    },
                  ),
                ),
                // Zoom indicator
                ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                      child: Text('${value.zoomLevel.toStringAsFixed(1)}x', style: const TextStyle(color: Colors.white)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Recording indicator
        if (_isRecording)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    const Text('RECORDING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CameralyPreview(
        controller: _controller,
        overlay: _buildCustomOverlay(),
        onScale: (scale) {
          setState(() => _currentZoom = _controller.value.zoomLevel);
        },
      ),
    );
  }
}
