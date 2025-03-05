import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'cameraly_controller.dart';
import 'cameraly_value.dart';
import 'overlays/cameraly_overlay_type.dart';
import 'overlays/default_cameraly_overlay.dart';

/// A widget that displays the camera preview.
class CameralyPreview extends StatelessWidget {
  /// Creates a new [CameralyPreview] widget.
  const CameralyPreview({
    required this.controller,
    this.child,
    this.overlayType = CameralyOverlayType.defaultOverlay,
    this.defaultOverlay,
    this.customOverlay,
    this.onTap,
    this.onScale,
    super.key,
  });

  /// The controller for the camera.
  final CameralyController controller;

  /// Optional child widget to overlay on top of the camera preview.
  ///
  /// This is kept for backward compatibility. For new code, use
  /// [overlayType] and [customOverlay] instead.
  final Widget? child;

  /// The type of overlay to display on top of the camera preview.
  ///
  /// Defaults to [CameralyOverlayType.defaultOverlay], which shows the standard camera UI.
  /// Use [CameralyOverlayType.none] for a clean camera preview without controls,
  /// or [CameralyOverlayType.custom] to provide your own overlay.
  final CameralyOverlayType overlayType;

  /// Configuration for the default overlay.
  ///
  /// This is used when [overlayType] is [CameralyOverlayType.defaultOverlay].
  /// If null, a default configuration will be used.
  final DefaultCameralyOverlay? defaultOverlay;

  /// A custom overlay widget to display on top of the camera preview.
  ///
  /// This is used when [overlayType] is [CameralyOverlayType.custom].
  final Widget? customOverlay;

  /// Callback for tap events on the camera preview.
  ///
  /// The parameter is the position of the tap in the coordinate system of
  /// the camera preview.
  final Function(Offset)? onTap;

  /// Callback for scale (pinch) events on the camera preview.
  ///
  /// The parameter is the scale factor.
  final Function(double)? onScale;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
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
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.no_photography,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Camera permission is required',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => controller.initialize(),
                    child: const Text('Grant Permission'),
                  ),
                ],
              ),
            ),
          );
        }

        // Determine which overlay to show based on the overlayType
        Widget? overlayWidget;
        switch (overlayType) {
          case CameralyOverlayType.none:
            overlayWidget = null;
            break;
          case CameralyOverlayType.defaultOverlay:
            overlayWidget = defaultOverlay ??
                DefaultCameralyOverlay(
                  controller: controller,
                );
            break;
          case CameralyOverlayType.custom:
            overlayWidget = customOverlay;
            break;
        }

        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        final previewRatio = controller.cameraController!.value.aspectRatio;

        return Container(
          color: Colors.black,
          child: GestureDetector(
            onTapUp: onTap != null
                ? (TapUpDetails details) {
                    if (!value.isInitialized) return;

                    final size = MediaQuery.of(context).size;
                    final previewSize = controller.cameraController!.value.previewSize!;
                    final cameraRatio = previewSize.width / previewSize.height;

                    // Get the preview widget size and position
                    final previewAspectRatio = isLandscape ? previewRatio : 1.0 / previewRatio;
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
                        normalizedY = (tapPosition.dx - previewLeft) / previewWidth;

                        // Adjust based on camera orientation
                        final sensorOrientation = controller.description.sensorOrientation;
                        if (sensorOrientation == 90) {
                          // Most Android devices
                          normalizedY = 1.0 - normalizedY;
                        } else if (sensorOrientation == 270) {
                          // Some devices
                          normalizedX = 1.0 - normalizedX;
                        }
                      }

                      // Adjust for front camera mirroring
                      if (value.isFrontCamera) {
                        normalizedX = 1.0 - normalizedX;
                      }

                      // Call the onTap callback with the normalized coordinates
                      onTap!(Offset(normalizedX, normalizedY));
                    }
                  }
                : null,
            onScaleUpdate: onScale != null ? (details) => onScale!(details.scale) : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview with proper aspect ratio handling
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return ClipRect(
                        child: SizedBox.expand(
                          key: ValueKey<bool>(isLandscape),
                          child: isLandscape
                              ? FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: constraints.maxWidth,
                                    height: constraints.maxWidth / previewRatio,
                                    child: Transform.scale(
                                      scaleX: value.isFrontCamera ? -1.0 : 1.0,
                                      scaleY: 1.0,
                                      child: CameraPreview(controller.cameraController!),
                                    ),
                                  ),
                                )
                              : FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    // In portrait mode, we need to use the inverse ratio
                                    // because the camera is sideways
                                    width: constraints.maxHeight * (1 / previewRatio),
                                    height: constraints.maxHeight,
                                    child: Transform.scale(
                                      scaleX: value.isFrontCamera ? -1.0 : 1.0,
                                      scaleY: 1.0,
                                      child: CameraPreview(controller.cameraController!),
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),

                // Show the legacy child for backward compatibility
                if (child != null) child,

                // Show the selected overlay
                if (overlayWidget != null) overlayWidget,

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
          ),
        );
      },
      child: child,
    );
  }
}
