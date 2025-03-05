import 'dart:async';

import 'package:camera/camera.dart' as camera;
import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

/// Example app demonstrating the Cameraly overlay system.
class OverlayExample extends StatefulWidget {
  /// Creates a new [OverlayExample] widget.
  const OverlayExample({super.key});

  @override
  State<OverlayExample> createState() => _OverlayExampleState();
}

class _OverlayExampleState extends State<OverlayExample> {
  late CameralyController _controller;
  bool _isInitialized = false;
  final CameralyOverlayTheme _theme = const CameralyOverlayTheme(primaryColor: Colors.deepPurple, secondaryColor: Colors.red, backgroundColor: Colors.black54, opacity: 0.7);
  bool _showZoomSlider = false;
  double _currentZoom = 1.0;
  Timer? _zoomSliderTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // Get available cameras
      final cameras = await camera.availableCameras();
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
    _zoomSliderTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          _isInitialized
              ? CameralyPreview(
                controller: _controller,
                overlayType: CameralyOverlayType.defaultOverlay,
                defaultOverlay: DefaultCameralyOverlay(
                  controller: _controller,
                  theme: _theme,
                  showGalleryButton: true,
                  showFocusCircle: true,
                  onGalleryTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery button tapped')));
                  },
                ),
                onTap: (position) {
                  // Handle tap to focus using the normalized position from CameralyPreview
                  if (_isInitialized) {
                    // Debug print
                    print('Tap detected at normalized position: $position');

                    // Set focus and exposure point directly with the normalized coordinates
                    _controller.setFocusAndExposurePoint(position);
                  }
                },
                onScale: (scale) {
                  // Handle pinch to zoom
                  if (_isInitialized) {
                    final newZoom = (_currentZoom * scale).clamp(0.5, 5.0);
                    _controller.setZoomLevel(newZoom);
                    setState(() {
                      _currentZoom = newZoom;

                      // Show zoom slider when zooming with pinch
                      _showZoomSlider = true;

                      // Reset the auto-hide timer
                      _resetZoomSliderTimer();
                    });
                  }
                },
              )
              : const Center(child: CircularProgressIndicator()),

          // On-screen zoom slider - only show when explicitly shown
          if (_showZoomSlider && _isInitialized)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('0.5x', style: TextStyle(color: Colors.white)),
                        Text('${_currentZoom.toStringAsFixed(1)}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const Text('5.0x', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    Slider(
                      value: _currentZoom,
                      min: 0.5,
                      max: 5.0,
                      divisions: 9,
                      activeColor: _theme.primaryColor,
                      inactiveColor: Colors.white30,
                      onChanged: (value) {
                        setState(() {
                          _currentZoom = value;
                        });
                        _controller.setZoomLevel(value);

                        // Reset the auto-hide timer when slider is adjusted
                        _resetZoomSliderTimer();
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Add this method to handle the zoom slider timer
  void _resetZoomSliderTimer() {
    // Cancel any existing timer
    _zoomSliderTimer?.cancel();

    // Create a new timer
    _zoomSliderTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showZoomSlider = false;
        });
      }
    });
  }

  void _showOverlayInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Overlay System'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The Cameraly package provides three overlay options:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Text('• Default Overlay: Matches the Basic Camera Example UI with photo/video toggle, capture button, flash control, etc.'),
                SizedBox(height: 8),
                Text('• Custom Overlay: Create your own camera UI by providing a custom widget.'),
                SizedBox(height: 8),
                Text('• No Overlay: Clean camera preview without any controls.'),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
          ),
    );
  }
}
