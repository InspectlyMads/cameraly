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
/// * Flash mode control (auto, on, off) for photo and video capture
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

// Re-export camera types that are needed
export 'package:camera/camera.dart' show XFile, FlashMode, ResolutionPreset, ExposureMode, FocusMode, CameraLensDirection;

// Export both old and new names for backward compatibility
export 'src/cameraly_camera.dart' hide CameraPreviewSettings, CameralyCamera, OverlayPreset;
export 'src/cameraly_camera.dart';
// Export controller and values
export 'src/cameraly_controller.dart';
// Export preview widgets
export 'src/cameraly_preview.dart';
export 'src/cameraly_preview_enhanced.dart';
export 'src/cameraly_value.dart';
// Export overlay classes
export 'src/overlays/cameraly_overlay_theme.dart';
export 'src/overlays/default_cameraly_overlay.dart';
// Export types
export 'src/types/camera_mode.dart';
export 'src/types/capture_settings.dart';
export 'src/utils/camera_lifecycle_machine.dart';
// Export utilities
export 'src/utils/cameraly_controller_provider.dart';
export 'src/utils/exif_manager.dart';
export 'src/utils/media_manager.dart';
// Export the new permission management system
export 'src/utils/permission_manager.dart';
export 'src/widgets/permission_ui.dart';
