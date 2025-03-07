import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'cameraly_controller.dart';
import 'cameraly_value.dart';
import 'overlays/default_cameraly_overlay.dart';
import 'utils/permission_landing_page.dart';

/// A widget that displays the camera preview.
class CameralyPreview extends StatefulWidget {
  /// Creates a new [CameralyPreview] widget.
  const CameralyPreview({
    required this.controller,
    this.overlay,
    this.onTap,
    this.onScale,
    super.key,
  });

  /// The controller for the camera.
  final CameralyController controller;

  /// The overlay widget to display on top of the camera preview.
  ///
  /// This can be a [DefaultCameralyOverlay] or any custom widget.
  /// If null, no overlay will be shown.
  final Widget? overlay;

  /// Callback for tap events on the camera preview.
  ///
  /// The parameter is the position of the tap in the coordinate system of
  /// the camera preview.
  final Function(Offset)? onTap;

  /// Callback for scale (pinch) events on the camera preview.
  ///
  /// The parameter is the scale factor.
  ///
  /// Note: The zoom functionality is now handled internally by the CameralyController.
  /// This callback is optional and can be used to update UI elements or perform
  /// additional actions when zooming occurs.
  final Function(double)? onScale;

  @override
  State<CameralyPreview> createState() => _CameralyPreviewState();
}

class _CameralyPreviewState extends State<CameralyPreview> with WidgetsBindingObserver {
  Offset? _focusPoint;
  bool _showFocusCircle = false;
  Timer? _focusTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Force an orientation update when the widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.controller.value.isInitialized) {
        // Print the current orientation for debugging
        widget.controller.printCurrentOrientation(context);

        // Force an orientation update
        widget.controller.handleOrientationChange(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Handle orientation changes
    if (mounted) {
      // Use a post-frame callback to ensure the context is valid
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only call handleOrientationChange if the controller is initialized
        if (widget.controller.value.isInitialized) {
          // Print the current orientation for debugging
          widget.controller.printCurrentOrientation(context);

          // The controller now handles orientation changes directly in its didChangeMetrics
          // We just need to force a rebuild to update the UI
          if (mounted) {
            setState(() {});
          }
        }
      });
    }
    super.didChangeMetrics();
  }

  void _showFocusCircleAtPosition(Offset screenPosition) {
    setState(() {
      _focusPoint = screenPosition;
      _showFocusCircle = true;
    });

    // Hide focus circle after 2 seconds
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showFocusCircle = false;
        });
      }
    });
  }

  void _handleTap(TapDownDetails details) {
    if (!widget.controller.value.isInitialized) return;

    final size = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Get the camera's natural aspect ratio
    final cameraAspectRatio = widget.controller.cameraController?.value.aspectRatio ?? 1.0;

    // In portrait mode, we need to invert the aspect ratio
    // This is because the camera sensor is naturally in landscape orientation
    final previewAspectRatio = isLandscape ? cameraAspectRatio : 1.0 / cameraAspectRatio;

    // Calculate preview dimensions based on the correct aspect ratio
    final previewWidth = isLandscape ? size.width : size.height * previewAspectRatio;
    final previewHeight = isLandscape ? size.width / previewAspectRatio : size.height;

    // Calculate the preview's position on screen
    final previewLeft = (size.width - previewWidth) / 2;
    final previewTop = (size.height - previewHeight) / 2;

    // Check if tap is within the preview bounds
    final tapPosition = details.globalPosition;

    if (tapPosition.dx >= previewLeft && tapPosition.dx <= previewLeft + previewWidth && tapPosition.dy >= previewTop && tapPosition.dy <= previewTop + previewHeight) {
      // Calculate normalized coordinates (0-1) for the camera controller
      double normalizedX;
      double normalizedY;

      if (isLandscape) {
        // In landscape, map directly to the preview
        normalizedX = (tapPosition.dx - previewLeft) / previewWidth;
        normalizedY = (tapPosition.dy - previewTop) / previewHeight;
      } else {
        // In portrait, we need to account for the rotated camera preview
        // The camera is sideways, so we swap x and y
        normalizedX = (tapPosition.dy - previewTop) / previewHeight;
        normalizedY = 1.0 - ((tapPosition.dx - previewLeft) / previewWidth);
      }

      // Adjust for front camera mirroring
      if (widget.controller.value.isFrontCamera) {
        normalizedX = 1.0 - normalizedX;
      }

      // Create the normalized position
      final normalizedPosition = Offset(normalizedX, normalizedY);

      // Call the onTap callback if provided
      if (widget.onTap != null) {
        widget.onTap!(normalizedPosition);
      }

      // Always set focus and exposure point when tapping
      widget.controller.setFocusAndExposurePoint(normalizedPosition);

      // Always show focus circle at tap position
      _showFocusCircleAtPosition(tapPosition);
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    // Store the initial scale value to use as a reference point
    widget.controller.value = widget.controller.value.copyWith(
      initialZoomLevel: widget.controller.value.zoomLevel,
    );
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (widget.onScale != null) {
      // Call the user's onScale callback if provided
      widget.onScale!(details.scale);

      // Also handle the scale internally using the controller's method
      // This allows the package to handle zoom internally while still
      // notifying the app about scale changes via the callback
      widget.controller.handleScale(details.scale);
    } else {
      // If no onScale callback is provided, still handle zoom internally
      widget.controller.handleScale(details.scale);
    }
  }

  Widget _buildCameraPreview(CameralyValue value, BoxConstraints constraints) {
    // Get the current orientation
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Get the camera's natural aspect ratio
    final cameraAspectRatio = widget.controller.cameraController?.value.aspectRatio ?? 1.0;

    // In portrait mode, we need to invert the aspect ratio
    // This is because the camera sensor is naturally in landscape orientation
    final previewRatio = isLandscape ? cameraAspectRatio : 1.0 / cameraAspectRatio;

    // Use the standard preview with the correct aspect ratio for the current orientation
    return AspectRatio(
      aspectRatio: previewRatio,
      child: Transform.scale(
        scaleX: value.isFrontCamera ? -1.0 : 1.0, // Only flip for front camera
        scaleY: 1.0,
        child: CameraPreview(widget.controller.cameraController!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        if (!value.isInitialized) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (value.permissionState == CameraPermissionState.denied) {
          return CameralyPermissionLandingPage(
            controller: widget.controller,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            buttonColor: Theme.of(context).primaryColor,
          );
        }

        // If permissions are denied but user chose to continue, show a placeholder
        if (value.permissionState == CameraPermissionState.deniedButContinued) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.no_photography,
                    color: Colors.white54,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Camera access not available',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Reset permission state and try again
                      widget.controller.value = widget.controller.value.copyWith(
                        permissionState: CameraPermissionState.unknown,
                      );
                      widget.controller.initialize();
                    },
                    child: const Text('Enable Camera'),
                  ),
                ],
              ),
            ),
          );
        }

        // If camera is initialized, show the preview
        return GestureDetector(
          onTapDown: _handleTap,
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview with orientation handling
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: _buildCameraPreview(value, constraints),
                    ),
                  );
                },
              ),

              // Show the legacy child for backward compatibility
              if (child != null) child,

              // Show the overlay
              if (widget.overlay != null) widget.overlay!,

              // Show focus circle when tapping - enhanced visibility
              if (_showFocusCircle && _focusPoint != null)
                Positioned(
                  left: _focusPoint!.dx - 30, // Larger offset for bigger circle
                  top: _focusPoint!.dy - 30, // Larger offset for bigger circle
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300), // Slower animation
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) => Transform.scale(
                      scale: 2.5 - value * 1.5, // More dramatic scale effect
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          height: 60, // Larger circle
                          width: 60, // Larger circle
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 3), // Thick white border
                            shape: BoxShape.circle,
                            color: Colors.transparent, // Transparent center to see through
                          ),
                          child: Center(
                            child: Container(
                              height: 10, // Inner dot
                              width: 10,
                              decoration: const BoxDecoration(
                                color: Colors.white, // Bright center dot
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Error display
              if (value.error != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      value.error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
