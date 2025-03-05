/// Cameraly - A powerful and flexible camera package for Flutter
///
/// Cameraly provides an enhanced, easy-to-use interface on top of the official
/// camera plugin, simplifying camera integration while offering advanced features
/// and better error handling.
///
/// ## Key Features
///
/// * Simple API for camera preview, photo capture, and video recording
/// * Seamless switching between front and back cameras
/// * Zoom controls with intuitive pinch-to-zoom gesture support
/// * Flash mode control (auto, on, off) for photo capture
/// * Tap-to-focus functionality with visual focus indicator
/// * Exposure control for manual brightness adjustment
/// * Resolution settings for both photo and video capture
/// * Video recording with customizable quality settings
/// * Permission handling with built-in request flow and UI
/// * Extensive customization options for UI elements and camera behavior
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:cameraly/cameraly.dart';
/// import 'package:flutter/material.dart';
///
/// class CameraScreen extends StatefulWidget {
///   @override
///   _CameraScreenState createState() => _CameraScreenState();
/// }
///
/// class _CameraScreenState extends State<CameraScreen> {
///   late CameralyController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _initCamera();
///   }
///
///   Future<void> _initCamera() async {
///     _controller = CameralyController();
///     await _controller.initialize();
///     setState(() {});
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     if (!_controller.value.isInitialized) {
///       return const Center(child: CircularProgressIndicator());
///     }
///
///     return Scaffold(
///       body: CameralyPreview(
///         controller: _controller,
///       ),
///       floatingActionButton: FloatingActionButton(
///         onPressed: () async {
///           final photo = await _controller.takePicture();
///           // Use the captured photo
///         },
///         child: const Icon(Icons.camera),
///       ),
///     );
///   }
/// }
/// ```
library cameraly;

// Re-export necessary types from the camera package
/// Re-exports from the official camera package
///
/// These types are used throughout the Cameraly API and are re-exported
/// for convenience so you don't need to import the camera package directly.
export 'package:camera/camera.dart' show CameraException, CameraImage, FlashMode, ExposureMode, FocusMode, ResolutionPreset;

/// The main controller class for camera operations
///
/// [CameralyController] is the primary class for interacting with the camera.
/// It provides methods for initialization, taking pictures, recording videos,
/// and controlling camera settings.
export 'src/cameraly_controller.dart';

/// The camera preview widget
///
/// [CameralyPreview] displays the camera feed and handles user interactions
/// like tap-to-focus and pinch-to-zoom.
export 'src/cameraly_preview.dart';

/// The state container for camera information
///
/// [CameralyValue] contains the current state of the camera, including
/// initialization status, recording status, and current settings.
export 'src/cameraly_value.dart';

/// Camera device information
///
/// Contains information about available camera devices and their capabilities.
export 'src/types/camera_device.dart';

/// Base class for camera capture settings
///
/// [CaptureSettings] is the base class for both photo and video settings.
export 'src/types/capture_settings.dart';

/// Settings specific to photo capture
///
/// [PhotoSettings] allows configuration of photo-specific options like
/// resolution and flash mode.
export 'src/types/photo_settings.dart';

/// Settings specific to video recording
///
/// [VideoSettings] allows configuration of video-specific options like
/// resolution, frame rate, and audio settings.
export 'src/types/video_settings.dart';

/// Utility functions for camera operations
///
/// [CameralyUtils] provides helper functions for common camera operations.
export 'src/utils/cameraly_utils.dart';

/// Permission handling utilities
///
/// Provides methods for requesting and checking camera and microphone permissions.
export 'src/utils/permission_handler.dart';
