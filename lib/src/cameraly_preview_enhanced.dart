import 'dart:async';

import 'package:flutter/material.dart';

import 'cameraly_controller.dart';
import 'types/camera_mode.dart';
import 'utils/permission_manager.dart';
import 'widgets/permission_ui.dart';

/// An enhanced version of the CameralyPreview widget that includes better permission handling
class CameralyPreviewEnhanced extends StatefulWidget {
  /// Creates a new enhanced camera preview widget
  const CameralyPreviewEnhanced({
    required this.controller,
    this.child,
    this.backgroundColor = Colors.black,
    this.textColor = Colors.white,
    this.buttonColor,
    this.iconColor,
    this.loadingWidget,
    super.key,
  });

  /// The camera controller to use
  final CameralyController controller;

  /// The child widget to display when permissions are granted and the camera is initialized
  /// This typically would be a CameralyPreview or your own custom preview widget
  final Widget? child;

  /// The background color to use for permission UI and loading screens
  final Color backgroundColor;

  /// The text color to use for permission UI and loading screens
  final Color textColor;

  /// The button color to use for permission UI
  final Color? buttonColor;

  /// The icon color to use for permission UI
  final Color? iconColor;

  /// A custom loading widget to display while the camera is initializing
  final Widget? loadingWidget;

  @override
  State<CameralyPreviewEnhanced> createState() => _CameralyPreviewEnhancedState();
}

class _CameralyPreviewEnhancedState extends State<CameralyPreviewEnhanced> {
  late CameralyPermissionManager _permissionManager;
  bool _isInitializing = true;
  late CameralyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;

    // Get the camera mode from controller settings
    final cameraMode = _controller.settings.cameraMode;

    // Log the camera mode for debugging
    debugPrint('📸 CameralyPreviewEnhanced: Initializing with camera mode: $cameraMode');
    debugPrint('📸 Audio enabled in settings: ${_controller.settings.enableAudio}');

    // In photo-only mode, we should never request audio permissions
    final requireAudio = cameraMode != CameraMode.photoOnly && _controller.settings.enableAudio;
    debugPrint('📸 Will request audio permissions: $requireAudio');

    // Initialize permission manager with the right requirements
    _permissionManager = CameralyPermissionManager(
      cameraMode: cameraMode,
      requireMicrophoneForVideo: requireAudio,
    );

    // Initialize the camera if the controller exists
    _initializeCamera();
  }

  @override
  void didUpdateWidget(CameralyPreviewEnhanced oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the controller changes, update the permission manager
    if (widget.controller != oldWidget.controller) {
      final cameraMode = widget.controller.settings.cameraMode;

      // Log the camera mode change
      debugPrint('📸 CameralyPreviewEnhanced: Camera mode changed to: $cameraMode');
      debugPrint('📸 Audio enabled in settings: ${widget.controller.settings.enableAudio}');

      _permissionManager.updateCameraMode(cameraMode);
      setState(() {
        _isInitializing = true;
      });

      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
    });

    // Request permissions
    debugPrint('📸 CameralyPreviewEnhanced: Requesting permissions...');
    final hasPermissions = await _permissionManager.requestPermissions();
    debugPrint('📸 CameralyPreviewEnhanced: Permission result: $hasPermissions');

    if (hasPermissions && mounted) {
      try {
        // Initialize the controller
        debugPrint('📸 CameralyPreviewEnhanced: Initializing camera controller...');
        await widget.controller.initialize();
        debugPrint('📸 CameralyPreviewEnhanced: Camera initialized successfully');
      } catch (e) {
        debugPrint('❌ Error initializing camera: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    // No need to dispose the permission manager as it has no resources to clean up
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // First, handle permissions with our new permission UI
    return CameralyPermissionUI(
      permissionManager: _permissionManager,
      backgroundColor: widget.backgroundColor,
      textColor: widget.textColor,
      buttonColor: widget.buttonColor,
      iconColor: widget.iconColor,
      child: _buildCameraContent(),
    );
  }

  Widget _buildCameraContent() {
    // If still initializing, show loading widget
    if (_isInitializing) {
      return _buildLoadingWidget();
    }

    // If we have the child widget, use it
    if (widget.child != null) {
      return widget.child!;
    }

    // If no child was provided, show a message
    return Container(
      color: widget.backgroundColor,
      child: Center(
        child: Text(
          'Camera preview widget not provided',
          style: TextStyle(color: widget.textColor),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    if (widget.loadingWidget != null) {
      return widget.loadingWidget!;
    }

    return Container(
      color: widget.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: widget.buttonColor ?? Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: widget.textColor),
            ),
          ],
        ),
      ),
    );
  }
}
