import 'dart:async';

import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CameralyApp());
}

class CameralyApp extends StatelessWidget {
  const CameralyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Cameraly Example', theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true), home: const CameraScreen());
  }
}

/// The main camera screen that uses the Cameraly package with default overlay
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameralyController _controller;
  bool _isInitialized = false;
  final CameralyOverlayTheme _theme = const CameralyOverlayTheme(primaryColor: Colors.deepPurple, secondaryColor: Colors.red, backgroundColor: Colors.black54, opacity: 0.7);

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // Initialize the camera with photo only mode using the specialized method
      final controller = await CameralyController.initializeForPhotos(
        settings: const PhotoSettings(
          resolution: ResolutionPreset.max,
          flashMode: FlashMode.auto,
          // CameraMode.photoOnly is already the default for PhotoSettings
        ),
      );

      if (controller == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras available or initialization failed')));
        }
        return;
      }

      _controller = controller;

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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Show loading UI while camera initializes
          if (!_isInitialized)
            Container(
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade700])),
              child: const SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 100, color: Colors.white),
                      SizedBox(height: 32),
                      Text('Cameraly', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 16),
                      Text('Loading camera...', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white70)),
                      SizedBox(height: 32),
                      CircularProgressIndicator(color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),

          // Camera preview (only shown when initialized)
          if (_isInitialized)
            CameralyPreview(
              controller: _controller,
              overlayType: CameralyOverlayType.defaultOverlay,
              defaultOverlay: DefaultCameralyOverlay(
                controller: _controller,
                theme: _theme,
                showGalleryButton: true,
                showFocusCircle: true,
                showZoomControls: true,
                onGalleryTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery button tapped')));
                },
              ),
            ),
        ],
      ),
    );
  }
}
