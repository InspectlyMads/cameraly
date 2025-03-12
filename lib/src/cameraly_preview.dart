import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'cameraly_controller.dart';
import 'cameraly_value.dart';
import 'overlays/cameraly_overlay_theme.dart';
import 'overlays/default_cameraly_overlay.dart';
import 'utils/cameraly_controller_provider.dart';
import 'utils/media_manager.dart';
import 'utils/permission_landing_page.dart';

/// A widget that displays the camera preview.
class CameralyPreview extends StatefulWidget {
  /// Creates a new [CameralyPreview] widget.
  const CameralyPreview({
    required this.controller,
    this.overlay,
    this.onTap,
    this.onScale,
    this.loadingBuilder,
    this.uninitializedBuilder,
    super.key,
  });

  /// The controller for the camera.
  final CameralyController controller;

  /// The overlay widget to display on top of the camera preview.
  ///
  /// This can be a [DefaultCameralyOverlay] or any custom widget.
  /// If null, no overlay will be shown.
  ///
  /// Note: When using [DefaultCameralyOverlay], you don't need to pass the controller
  /// to it as it will automatically use the controller from this [CameralyPreview].
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

  /// Builder for the loading widget shown when the camera is initializing.
  ///
  /// If null, a default loading widget will be shown.
  final Widget Function(BuildContext, CameralyValue)? loadingBuilder;

  /// Builder for the widget shown when the controller is not yet assigned or created.
  ///
  /// This is different from loadingBuilder which is shown when the controller exists
  /// but is not yet initialized. Use this for handling the async gap between
  /// widget creation and controller initialization.
  ///
  /// If null, a default placeholder will be shown.
  final Widget Function(BuildContext)? uninitializedBuilder;

  /// Creates a [DefaultCameralyOverlay] with the same controller as this [CameralyPreview].
  ///
  /// This is a convenience method to create a default overlay without having to
  /// pass the controller explicitly.
  static Widget defaultOverlay({
    bool showCaptureButton = true,
    bool showFlashButton = true,
    bool showSwitchCameraButton = true,
    bool showGalleryButton = true,
    bool showMediaStack = false,
    bool showZoomControls = false,
    bool showZoomSlider = false,
    Duration? maxVideoDuration,
    CameralyOverlayTheme? theme,
    Widget? customLeftButton,
    Widget? customRightButton,
    Widget? topLeftWidget,
    Widget? centerLeftWidget,
    Widget? bottomOverlayWidget,
    Function(XFile)? onCapture,
    Function(String)? onCaptureError,
    Function(bool)? onCaptureMode,
    VoidCallback? onClose,
    VoidCallback? onFlashTap,
    VoidCallback? onGalleryTap,
    VoidCallback? onSwitchCamera,
    Function(CameralyController)? onControllerChanged,
    Function(double)? onZoomChanged,
    CameralyMediaManager? mediaManager,
    VoidCallback? onMaxDurationReached,
  }) {
    return Builder(
      builder: (context) {
        final controller = CameralyControllerProvider.of(context);
        if (controller == null) {
          throw FlutterError(
            'DefaultCameralyOverlay created with CameralyPreview.defaultOverlay() '
            'must be used inside a CameralyPreview widget.',
          );
        }

        return DefaultCameralyOverlay(
          controller: controller,
          showCaptureButton: showCaptureButton,
          showFlashButton: showFlashButton,
          showSwitchCameraButton: showSwitchCameraButton,
          showGalleryButton: showGalleryButton,
          showMediaStack: showMediaStack,
          showZoomControls: showZoomControls,
          showZoomSlider: showZoomSlider,
          maxVideoDuration: maxVideoDuration,
          theme: theme,
          customLeftButton: customLeftButton,
          customRightButton: customRightButton,
          topLeftWidget: topLeftWidget,
          centerLeftWidget: centerLeftWidget,
          bottomOverlayWidget: bottomOverlayWidget,
          onCapture: onCapture,
          onCaptureError: onCaptureError,
          onCaptureMode: onCaptureMode,
          onClose: onClose,
          onFlashTap: onFlashTap,
          onGalleryTap: onGalleryTap,
          onSwitchCamera: onSwitchCamera,
          onControllerChanged: onControllerChanged,
          onZoomChanged: onZoomChanged,
          mediaManager: mediaManager,
          onMaxDurationReached: onMaxDurationReached,
        );
      },
    );
  }

  @override
  State<CameralyPreview> createState() => _CameralyPreviewState();
}

class _CameralyPreviewState extends State<CameralyPreview> with WidgetsBindingObserver {
  late CameralyController? _controller;
  Offset? _focusPoint;
  bool _showFocusCircle = false;
  Timer? _focusTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _setupController();
    WidgetsBinding.instance.addObserver(this);
  }

  void _setupController() {
    // Only setup controller if it's not null
    if (_controller != null) {
      _controller!.addListener(_handleControllerUpdate);

      // Force an orientation update when the widget is first built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller != null && _controller!.value.isInitialized) {
          // Print the current orientation for debugging
          _controller!.printCurrentOrientation(context);

          // Force an orientation update
          _controller!.handleDeviceOrientationChange();
        }
      });
    }
  }

  @override
  void dispose() {
    // Only remove listener if controller exists
    if (_controller != null) {
      _controller!.removeListener(_handleControllerUpdate);
    }
    WidgetsBinding.instance.removeObserver(this);
    _focusTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CameralyPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the controller has changed, update our reference and listeners
    if (widget.controller != oldWidget.controller) {
      debugPrint('CameralyPreview: Controller changed, updating references');

      // Remove listener from old controller if it exists
      if (_controller != null) {
        _controller!.removeListener(_handleControllerUpdate);
      }

      // Update controller reference
      _controller = widget.controller;

      // Setup the new controller
      _setupController();

      // Force a rebuild with the new controller
      setState(() {});
    }
  }

  @override
  void didChangeMetrics() {
    // Handle orientation changes
    if (mounted && _controller != null) {
      // Use a post-frame callback to ensure the context is valid
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only call handleOrientationChange if the controller is initialized
        if (_controller!.value.isInitialized) {
          // Print the current orientation for debugging
          _controller!.printCurrentOrientation(context);

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

  void _handleControllerUpdate() {
    if (_controller == null) return;

    final value = _controller!.value;

    // Update focus point - process immediately when it changes
    if (value.focusPoint != null && mounted) {
      setState(() {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final size = box.size;
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

        // Get the camera preview's aspect ratio
        final previewRatio = _controller!.cameraController!.value.aspectRatio;

        // Calculate preview dimensions based on the container size and aspect ratio
        final previewAspectRatio = isLandscape ? previewRatio : 1.0 / previewRatio;
        final previewWidth = isLandscape ? size.width : size.height * previewAspectRatio;
        final previewHeight = isLandscape ? size.width / previewAspectRatio : size.height;

        // Calculate preview position within the container
        final previewLeft = (size.width - previewWidth) / 2;
        final previewTop = (size.height - previewHeight) / 2;

        // Convert normalized position to screen coordinates
        final normalizedPoint = value.focusPoint!;
        double screenX, screenY;

        if (isLandscape) {
          screenX = previewLeft + (normalizedPoint.dx * previewWidth);
          screenY = previewTop + (normalizedPoint.dy * previewHeight);
        } else {
          // In portrait, we need to convert from the camera's coordinate system
          screenX = previewLeft + ((1.0 - normalizedPoint.dy) * previewWidth);
          screenY = previewTop + (normalizedPoint.dx * previewHeight);
        }

        _focusPoint = Offset(screenX, screenY);
        _showFocusCircle = true;

        // Hide focus circle after 2 seconds
        _focusTimer?.cancel();
        _focusTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showFocusCircle = false;
            });
          }
        });
      });
    }
  }

  void _handleTap(TapDownDetails details) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    final size = box.size;

    // Convert tap position to normalized coordinates (0,0 to 1,1)
    final normalizedX = localPosition.dx / size.width;
    final normalizedY = localPosition.dy / size.height;

    // Clamp coordinates to ensure they're within bounds
    final clampedX = normalizedX.clamp(0.0, 1.0);
    final clampedY = normalizedY.clamp(0.0, 1.0);

    // Create normalized point
    Offset normalizedPoint;
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      // In portrait mode, swap x and y coordinates for the camera
      normalizedPoint = Offset(clampedY, 1.0 - clampedX);
    } else {
      normalizedPoint = Offset(clampedX, clampedY);
    }

    // Mirror coordinates for front camera
    if (_controller!.description.lensDirection == CameraLensDirection.front) {
      normalizedPoint = Offset(1.0 - normalizedPoint.dx, normalizedPoint.dy);
    }

    // Call onTap callback if provided
    widget.onTap?.call(normalizedPoint);

    // Set focus and exposure point
    _controller!.setFocusAndExposurePoint(normalizedPoint);

    // Update focus circle position
    setState(() {
      _focusPoint = localPosition;
      _showFocusCircle = true;

      // Hide focus circle after 2 seconds
      _focusTimer?.cancel();
      _focusTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showFocusCircle = false;
          });
        }
      });
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    // Store the initial scale value to use as a reference point
    _controller!.value = _controller!.value.copyWith(
      initialZoomLevel: _controller!.value.zoomLevel,
    );
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (widget.onScale != null) {
      // Call the user's onScale callback if provided
      widget.onScale!(details.scale);

      // Also handle the scale internally using the controller's method
      // This allows the package to handle zoom internally while still
      // notifying the app about scale changes via the callback
      _controller!.handleScale(details.scale);
    } else {
      // If no onScale callback is provided, still handle zoom internally
      _controller!.handleScale(details.scale);
    }
  }

  Widget _buildCameraPreview(CameralyValue value, BoxConstraints constraints) {
    // Get the current orientation
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Get the camera's natural aspect ratio
    final cameraAspectRatio = _controller!.cameraController?.value.aspectRatio ?? 1.0;

    // In portrait mode, we need to invert the aspect ratio
    // This is because the camera sensor is naturally in landscape orientation
    final previewRatio = isLandscape ? cameraAspectRatio : 1.0 / cameraAspectRatio;

    // Check if front camera by using both the value and the lens direction
    // This double-verification approach ensures mirroring works even if the value isn't updated correctly
    final bool isFrontCameraByLens = _controller!.description.lensDirection == CameraLensDirection.front;
    final bool shouldMirror = isFrontCameraByLens || value.isFrontCamera;

    // Debug logs for mirroring diagnosis
    debugPrint('🎥 PREVIEW BUILDING:');
    debugPrint('🎥 Camera type: ${_controller!.description.lensDirection}');
    debugPrint('🎥 isFrontCamera value: ${value.isFrontCamera}');
    debugPrint('🎥 isFrontCamera by lens: $isFrontCameraByLens');
    debugPrint('🎥 Should mirror: $shouldMirror');
    debugPrint('🎥 scaleX will be: ${shouldMirror ? -1.0 : 1.0}');

    // Use the standard preview with the correct aspect ratio for the current orientation
    return AspectRatio(
      aspectRatio: previewRatio,
      child: Transform.scale(
        scaleX: shouldMirror ? -1.0 : 1.0, // Flip if either indicator says it's a front camera
        scaleY: 1.0,
        child: CameraPreview(_controller!.cameraController!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if controller is null - handle this case first
    if (_controller == null) {
      return widget.uninitializedBuilder != null
          ? widget.uninitializedBuilder!(context)
          : Container(
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Preparing camera...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
    }

    // If controller exists, wrap everything in the provider and use ValueListenableBuilder
    return CameralyControllerProvider(
      controller: _controller!,
      child: ValueListenableBuilder<CameralyValue>(
        valueListenable: _controller!,
        builder: (context, value, child) {
          // Handle initialization state
          if (!value.isInitialized) {
            // Use custom loading builder if provided, otherwise use default
            return widget.loadingBuilder != null
                ? widget.loadingBuilder!(context, value)
                : Container(
                    color: Colors.black,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          'Initializing camera...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
          }

          // Handle permission denied state
          if (value.permissionState == CameraPermissionState.denied) {
            return CameralyPermissionLandingPage(
              controller: _controller!,
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
                        _controller!.value = _controller!.value.copyWith(
                          permissionState: CameraPermissionState.unknown,
                        );
                        _controller!.initialize();
                      },
                      child: const Text('Enable Camera'),
                    ),
                  ],
                ),
              ),
            );
          }

          // If camera is initialized, show the preview
          return Stack(
            fit: StackFit.expand,
            children: [
              // Black background
              Container(color: Colors.black),

              // Camera preview with orientation handling and gesture detection
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Build the preview widget
                    final previewWidget = _buildCameraPreview(value, constraints);

                    // Wrap only the preview in GestureDetector
                    return GestureDetector(
                      onTapDown: _handleTap,
                      onScaleStart: _handleScaleStart,
                      onScaleUpdate: _handleScaleUpdate,
                      child: previewWidget,
                    );
                  },
                ),
              ),

              // Show the overlay
              if (widget.overlay != null) widget.overlay!,

              // Show focus circle when tapping - enhanced visibility
              if (_showFocusCircle && _focusPoint != null)
                Positioned(
                  left: _focusPoint!.dx - 25,
                  top: _focusPoint!.dy - 25,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) => Transform.scale(
                      scale: 2.5 - (1.5 * value),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
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
          );
        },
      ),
    );
  }
}
