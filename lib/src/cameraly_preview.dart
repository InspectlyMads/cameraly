import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cameraly_controller.dart';
import 'cameraly_value.dart';
import 'overlays/cameraly_overlay_theme.dart';
import 'overlays/default_cameraly_overlay.dart';
import 'utils/camera_lifecycle_machine.dart';
import 'utils/cameraly_controller_provider.dart';
import 'utils/media_manager.dart';

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
          maxVideoDuration: maxVideoDuration,
          theme: theme,
          customLeftButton: customLeftButton,
          customRightButton: customRightButton,
          topLeftWidget: topLeftWidget,
          centerLeftWidget: centerLeftWidget,
          bottomOverlayWidget: bottomOverlayWidget,
          onCapture: onCapture,
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
  bool _isChangingOrientation = false;
  Timer? _orientationDebounceTimer;
  // Add a flag to track initial stabilization
  bool _isInitializing = true;

  // Add the lifecycle state machine
  CameraLifecycleMachine? _lifecycleMachine;

  // Add a property to track when camera became visible
  DateTime? _cameraVisibleSince;

  // Add a static flag
  static bool _isAnyOrientationChangeInProgress = false;

  // Add a method to check if camera has been visible long enough
  bool _isCameraStable() {
    if (_cameraVisibleSince == null) return false;
    return DateTime.now().difference(_cameraVisibleSince!).inMilliseconds > 1000;
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _setupController();
    WidgetsBinding.instance.addObserver(this);

    // Mark camera as not yet stable
    _cameraVisibleSince = null;

    // Don't use artificial delay on any platform - if camera is ready, show it immediately
    if (_controller != null && _controller!.value.isInitialized) {
      // Already initialized, set flag to false immediately
      _isInitializing = false;
      // Start stabilization timer
      _cameraVisibleSince = DateTime.now();
    } else {
      // Only use a minimal delay to prevent flickering during fast initialization
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
        }
      });
    }

    // Add post-frame callback to update orientation after first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFirstOrientationUpdate();
    });
  }

  void _setupController() {
    // Only setup controller if it's not null
    if (_controller != null) {
      _controller!.addListener(_handleControllerUpdate);

      // Create the lifecycle machine
      _lifecycleMachine = CameraLifecycleMachine(
        controller: _controller!,
        onStateChange: _handleLifecycleStateChange,
        onError: _handleLifecycleError,
      );

      // We'll handle orientation initialization separately in _initializeFirstOrientationUpdate
      // to avoid double orientation changes and allow better control of loading indicators
    }
  }

  // Handle lifecycle state changes
  void _handleLifecycleStateChange(CameraLifecycleState oldState, CameraLifecycleState newState) {
    debugPrint('CameralyPreview: Lifecycle state changed from $oldState to $newState');

    // Safety check for if both old and new state are "ready" - this is a forced redispatch
    // from the lifecycle machine to ensure the UI updates
    if (oldState == CameraLifecycleState.ready && newState == CameraLifecycleState.ready && _isChangingOrientation) {
      debugPrint('🎥 Received forced ready state notification - immediately updating UI');
      if (mounted) {
        setState(() {
          _isChangingOrientation = false;
          _cameraVisibleSince = DateTime.now();
        });
      }
      return;
    }

    if (mounted) {
      // Update the orientation change flag based on the new state
      if (newState == CameraLifecycleState.ready && _isChangingOrientation) {
        // When camera is ready, immediately hide the loading indicator
        debugPrint('🎥 Camera is ready - hiding orientation change indicator');
        setState(() {
          _isChangingOrientation = false;
          // Reset camera visible time to now
          _cameraVisibleSince = DateTime.now();
        });

        // Clear any existing safety timer
        _orientationDebounceTimer?.cancel();
      } else if ((newState == CameraLifecycleState.recreating || newState == CameraLifecycleState.resuming) && !_isChangingOrientation) {
        // Only set to true if it wasn't already true
        debugPrint('🎥 Camera is recreating/resuming - showing orientation change indicator');
        setState(() {
          _isChangingOrientation = true;
        });

        // Add a safety timeout to ensure the loading indicator doesn't stay forever
        _orientationDebounceTimer?.cancel();
        _orientationDebounceTimer = Timer(const Duration(seconds: 3), () {
          debugPrint('🎥 Safety timeout reached - forcing orientation change indicator to hide');
          if (mounted && _isChangingOrientation) {
            setState(() {
              _isChangingOrientation = false;
              _cameraVisibleSince = DateTime.now();
            });
          }
        });
      }
    }
  }

  // Handle lifecycle errors
  void _handleLifecycleError(String message, Object? error) {
    debugPrint('CameralyPreview: Lifecycle error: $message');

    // Show error to user if needed
    if (mounted) {
      setState(() {
        _isChangingOrientation = false;
      });
    }
  }

  @override
  void dispose() {
    // Clean up the lifecycle machine
    _lifecycleMachine?.dispose();

    // Only remove listener if controller exists
    if (_controller != null) {
      _controller!.removeListener(_handleControllerUpdate);
    }
    WidgetsBinding.instance.removeObserver(this);
    _focusTimer?.cancel();
    _orientationDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CameralyPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the controller has changed, update our reference and listeners
    if (widget.controller != oldWidget.controller) {
      debugPrint('CameralyPreview: Controller changed, updating references');

      // Clean up old controller resources
      _lifecycleMachine?.dispose();

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
    // Use the lifecycle state machine to handle orientation changes
    if (mounted && _controller != null && _lifecycleMachine != null) {
      // Check global lock first
      if (_isAnyOrientationChangeInProgress) {
        debugPrint('🎥 Another orientation change already in progress globally, skipping');
        super.didChangeMetrics();
        return;
      }

      // Don't reinitialize if we're already changing orientation
      if (_isChangingOrientation) {
        debugPrint('🎥 Skipping orientation change - already in progress');
        super.didChangeMetrics();
        return;
      }

      // Cancel any ongoing orientation change timer
      _orientationDebounceTimer?.cancel();

      // For rapid landscape-to-landscape transitions, use a much shorter debounce time
      // This helps capture the rapid changes better and prevents getting stuck
      final isFirstMetricChange = _cameraVisibleSince == null;

      // Get orientation before debounce to compare later
      final orientationBefore = _getPreciseDeviceOrientation(context);
      debugPrint('🎥 Orientation before debounce: $orientationBefore');

      // Adjust debounce time based on the scenario
      // Very short debounce for landscape-to-landscape transitions
      // Slightly longer for first orientation after launch
      // Standard debounce for normal transitions
      final debounceTime = isFirstMetricChange ? 250 : 100;

      debugPrint('🎥 Orientation metrics changed, using ${isFirstMetricChange ? "first-run" : "rapid"} debounce ($debounceTime ms)');

      // Use a much shorter debounce to ensure we catch rapid orientation changes
      _orientationDebounceTimer = Timer(Duration(milliseconds: debounceTime), () {
        if (mounted && _controller != null && _lifecycleMachine != null) {
          // Get current orientation from context with improved precision
          final currentOrientation = _getPreciseDeviceOrientation(context);

          // Detect rapid landscape-to-landscape transition
          final isRapidLandscapeTransition =
              (orientationBefore == DeviceOrientation.landscapeLeft && currentOrientation == DeviceOrientation.landscapeRight) || (orientationBefore == DeviceOrientation.landscapeRight && currentOrientation == DeviceOrientation.landscapeLeft);

          if (isRapidLandscapeTransition) {
            debugPrint('🎥 Detected rapid landscape transition: $orientationBefore → $currentOrientation');
          }

          // Set global flag
          _isAnyOrientationChangeInProgress = true;

          // Show loading indicator
          setState(() {
            _isChangingOrientation = true;

            // During first orientation change, track that we've started the process
            // but don't set _cameraVisibleSince yet - that happens when it completes
            if (!isFirstMetricChange) {
              _cameraVisibleSince = null;
            }
          });

          debugPrint('🎥 Handling orientation change to: $currentOrientation');

          // Add extreme timeout for stuck orientation changes - force reset after 5 seconds
          final longTimeoutTimer = Timer(const Duration(seconds: 5), () {
            if (mounted && _isChangingOrientation) {
              debugPrint('🎥 EXTREME TIMEOUT: Orientation change has been stuck for 5 seconds - force resetting');

              // Force reset to ready state
              _lifecycleMachine?.forceResetToReady();

              // Release the global lock
              _isAnyOrientationChangeInProgress = false;

              // Update UI
              if (mounted) {
                setState(() {
                  _isChangingOrientation = false;
                  _cameraVisibleSince = DateTime.now();
                });
              }
            }
          });

          // For rapid landscape transitions, use special handling
          if (isRapidLandscapeTransition) {
            // Use higher priority for rapid landscape transitions
            _lifecycleMachine!.handleOrientationChange(currentOrientation, priority: true).then((_) {
              longTimeoutTimer.cancel();
              _isAnyOrientationChangeInProgress = false;
            }).catchError((error) {
              longTimeoutTimer.cancel();
              debugPrint('🎥 Error during rapid orientation change: $error');
              _isAnyOrientationChangeInProgress = false;

              // Ensure orientation flag is cleared even on error
              if (mounted && _isChangingOrientation) {
                setState(() {
                  _isChangingOrientation = false;
                  _cameraVisibleSince ??= DateTime.now();
                });
              }
            });
          } else {
            // Use standard handling for normal transitions
            _lifecycleMachine!.handleOrientationChange(currentOrientation).then((_) {
              longTimeoutTimer.cancel();
              // Release global lock
              _isAnyOrientationChangeInProgress = false;

              // The flag should be reset by the lifecycle state change handler
              // No need for a timeout here as the lifecycle machine will call
              // _handleLifecycleStateChange with the ready state when done
            }).catchError((error) {
              longTimeoutTimer.cancel();
              debugPrint('🎥 Error during orientation change: $error');
              _isAnyOrientationChangeInProgress = false;

              // Ensure orientation flag is cleared even on error
              if (mounted && _isChangingOrientation) {
                setState(() {
                  _isChangingOrientation = false;
                  _cameraVisibleSince ??= DateTime.now();
                });
              }
            });
          }
        }
      });
    }
    super.didChangeMetrics();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Use the lifecycle state machine to handle app state changes
    if (_controller != null && _lifecycleMachine != null) {
      _lifecycleMachine!.handleAppLifecycleChange(state);
    }
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
        final previewRatio = _controller!.getAdjustedAspectRatio();

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
    // Check for null controller before proceeding
    if (_controller == null || !_controller!.value.isInitialized) return;

    // Store the initial scale value to use as a reference point
    _controller!.value = _controller!.value.copyWith(
      initialZoomLevel: _controller!.value.zoomLevel,
    );
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // Check for null controller before proceeding
    if (_controller == null || !_controller!.value.isInitialized) return;

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

  double getPreviewRatio() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return 1.0;
    }

    // Use the new method to get the corrected aspect ratio
    final previewRatio = _controller!.getAdjustedAspectRatio();

    // Additional aspect ratio correction for specific orientations
    final mediaQueryData = MediaQuery.of(context);
    final deviceOrientation = mediaQueryData.orientation;

    // For landscape orientation on tablets, we might need additional adjustments
    final view = PlatformDispatcher.instance.views.first;
    final isTablet = view.physicalSize.shortestSide > 900;

    // Log the adjustments we're making for debugging
    debugPrint('📏 Camera aspect ratio: raw=${_controller!.cameraController?.value.aspectRatio}, '
        'adjusted=$previewRatio, isTablet=$isTablet, orientation=$deviceOrientation');

    return previewRatio;
  }

  Widget _buildCameraPreview(CameralyValue value, BoxConstraints constraints) {
    // First check if controller and camera controller are valid
    if (_controller == null || _controller!.cameraController == null) {
      // Return a placeholder if controller is null or not fully initialized
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Camera initializing...',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    // Get the current orientation
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    // Get the camera's natural aspect ratio

    final cameraAspectRatio = getPreviewRatio();

    // In portrait mode, we need to invert the aspect ratio
    // This is because the camera sensor is naturally in landscape orientation
    final previewRatio = isLandscape ? cameraAspectRatio : 1.0 / cameraAspectRatio;

    // Check if front camera by using both the value and the lens direction
    // This double-verification approach ensures mirroring works even if the value isn't updated correctly
    final bool isFrontCameraByLens = _controller!.description.lensDirection == CameraLensDirection.front;
    final bool isFrontCamera = isFrontCameraByLens || value.isFrontCamera;

    // Platform-specific mirroring logic
    bool shouldMirror = false;

    if (isFrontCamera) {
      if (Platform.isAndroid) {
        // On Android: Front camera preview should be mirrored (default behavior is already mirrored)
        shouldMirror = true;
      } else if (Platform.isIOS) {
        // On iOS: Is mirrored by default
        shouldMirror = false;
      }
    }

    // Debug logs for mirroring diagnosis
    debugPrint('🎥 PREVIEW BUILDING:');
    debugPrint('🎥 Camera type: ${_controller!.description.lensDirection}');
    debugPrint('🎥 isFrontCamera value: ${value.isFrontCamera}');
    debugPrint('🎥 isFrontCamera by lens: $isFrontCameraByLens');
    debugPrint('🎥 Platform: ${Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Other'}');
    debugPrint('🎥 Should mirror: $shouldMirror');
    debugPrint('🎥 scaleX will be: ${shouldMirror ? -1.0 : 1.0}');

    // Generate a unique key based on orientation to force recreation when orientation changes
    final previewKey = ValueKey('camera_preview_${value.deviceOrientation}_$isLandscape');

    // Use the standard preview with the correct aspect ratio for the current orientation
    return AspectRatio(
      aspectRatio: previewRatio,
      child: Transform.scale(
        scaleX: shouldMirror ? -1.0 : 1.0, // Flip based on platform-specific logic
        scaleY: 1.0,
        child: Container(
          key: previewKey,
          child: _controller!.cameraController != null ? CameraPreview(_controller!.cameraController!) : Container(color: Colors.black), // Fallback if controller becomes null
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If controller exists, wrap everything in the provider and use ValueListenableBuilder
    // even during initialization - this shows camera preview as soon as it's available
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
                      color: Colors.white.withAlpha(179),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
    }

    // Use the CameralyControllerProvider to provide the controller to descendants
    return CameralyControllerProvider(
      controller: _controller!,
      child: ValueListenableBuilder<CameralyValue>(
        valueListenable: _controller!,
        builder: (context, value, child) {
          return _buildOrientationAwarePreview(value);
        },
      ),
    );
  }

  Widget _buildOrientationAwarePreview(CameralyValue value) {
    // If camera is initialized but we haven't started tracking time, start doing so
    if (value.isInitialized && _cameraVisibleSince == null) {
      _cameraVisibleSince = DateTime.now();
    }

    // Always show camera if it exists, with loading indicator overlay
    // This makes camera appear faster even while it's still initializing
    Widget cameraStack = Stack(
      fit: StackFit.expand,
      children: [
        // Black background
        Container(color: Colors.black),

        // Camera preview with orientation handling and gesture detection
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Only build the camera preview if controller is valid
              if (_controller?.cameraController != null) {
                // Build the preview widget with null-safety
                final previewWidget = _buildCameraPreview(value, constraints);

                // Wrap the preview in RepaintBoundary to optimize rendering
                return RepaintBoundary(
                  child: GestureDetector(
                    onTapDown: _controller != null ? _handleTap : null,
                    onScaleStart: _controller != null ? _handleScaleStart : null,
                    onScaleUpdate: _controller != null ? _handleScaleUpdate : null,
                    child: previewWidget,
                  ),
                );
              } else {
                // Return a placeholder while waiting for controller to initialize
                return Container(color: Colors.black);
              }
            },
          ),
        ),

        // Focus circle position indicator
        if (_showFocusCircle && _focusPoint != null)
          Positioned(
            left: _focusPoint!.dx - 40,
            top: _focusPoint!.dy - 40,
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                shape: BoxShape.circle,
              ),
            ),
          ),

        // Loading indicator - only show when needed and with more reliable logic
        if (!value.isInitialized || (_isChangingOrientation && (!_isCameraStable() || DateTime.now().difference(_cameraVisibleSince ?? DateTime.now()).inSeconds < 5)) || value.isChangingController)
          Container(
            key: const ValueKey('loading_overlay'),
            // Make overlay very transparent when camera is already initialized
            color: Colors.black.withAlpha(value.isInitialized ? 25 : 120),
            child: Center(
              // Make indicator smaller when camera is initialized to be less disruptive
              child: value.isInitialized
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );

    // Use the custom overlay if provided, otherwise return the standard camera stack
    if (widget.overlay != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          cameraStack,
          widget.overlay!,
        ],
      );
    } else {
      return cameraStack;
    }
  }

  // Add a dedicated method for first orientation update
  void _initializeFirstOrientationUpdate() {
    if (mounted && _controller != null && _lifecycleMachine != null && _controller!.value.isInitialized) {
      // During first orientation update, always trigger the handler even if
      // we don't think the orientation changed - the API will determine this
      setState(() {
        _isChangingOrientation = true;
      });

      // Get the current device orientation from MediaQuery for reliability
      final currentOrientation = MediaQuery.of(context).orientation == Orientation.landscape
          ? DeviceOrientation.landscapeRight // Default to right for first orientation
          : DeviceOrientation.portraitUp; // Default to up for portrait

      debugPrint('🎥 Initializing first orientation to: $currentOrientation');

      // Add a safety timeout for first orientation change
      _orientationDebounceTimer?.cancel();
      _orientationDebounceTimer = Timer(const Duration(seconds: 3), () {
        debugPrint('🎥 First orientation change safety timeout reached - forcing indicator to hide');
        if (mounted && _isChangingOrientation) {
          setState(() {
            _isChangingOrientation = false;
            _cameraVisibleSince = DateTime.now();
          });
        }
      });

      // Let the lifecycle machine handle orientation with the first-change flag
      // This ensures it treats it as a first orientation change
      _lifecycleMachine!.handleOrientationChange(currentOrientation).then((_) {
        debugPrint('🎥 First orientation change completed successfully');
        // Always make sure we reset the orientation change flag
        if (mounted) {
          setState(() {
            _isChangingOrientation = false;
            // Mark camera as stable
            _cameraVisibleSince = DateTime.now();
          });
        }
      }).catchError((error) {
        debugPrint('🎥 Error during first orientation change: $error');
        // Also clear the flag on error
        if (mounted) {
          setState(() {
            _isChangingOrientation = false;
            _cameraVisibleSince = DateTime.now();
          });
        }
      });
    } else {
      debugPrint('🎥 Skipping first orientation update - camera not ready');
      // Even if we skip, make sure we're not in a changing state
      if (mounted && _isChangingOrientation) {
        setState(() {
          _isChangingOrientation = false;
        });
      }
    }
  }

  /// Get a more precise device orientation from MediaQuery and sensor values
  DeviceOrientation _getPreciseDeviceOrientation(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // First check if we're in landscape or portrait
    if (mediaQuery.orientation == Orientation.landscape) {
      // For landscape, we need to be more careful when determining left vs right

      // Try using view padding which is typically more reliable
      // Left paddings are typically larger on landscape right, and right paddings larger on landscape left
      final leftPadding = mediaQuery.padding.left + mediaQuery.viewPadding.left;
      final rightPadding = mediaQuery.padding.right + mediaQuery.viewPadding.right;

      // Also use system gesture insets as backup
      final leftGesture = mediaQuery.systemGestureInsets.left;
      final rightGesture = mediaQuery.systemGestureInsets.right;

      // Use window metrics for additional accuracy
      final size = WidgetsBinding.instance.window.physicalSize;
      final viewInsets = WidgetsBinding.instance.window.viewInsets;

      // Combine all metrics for best determination
      final isLikelyLandscapeLeft = leftPadding > rightPadding || leftGesture > rightGesture || viewInsets.left > viewInsets.right;

      // For the rare case when metrics are equal, use controller's existing value or default to right
      if (leftPadding == rightPadding && leftGesture == rightGesture && viewInsets.left == viewInsets.right) {
        // Use current value if available, otherwise default to landscape right
        if (_controller != null && _controller!.value.isInitialized) {
          final currentOrientation = _controller!.value.deviceOrientation;
          if (currentOrientation == DeviceOrientation.landscapeLeft || currentOrientation == DeviceOrientation.landscapeRight) {
            return currentOrientation;
          }
        }
        return DeviceOrientation.landscapeRight; // Default
      }

      debugPrint('🔄 Landscape detection: left=$leftPadding, right=$rightPadding, leftGesture=$leftGesture, rightGesture=$rightGesture');
      return isLikelyLandscapeLeft ? DeviceOrientation.landscapeLeft : DeviceOrientation.landscapeRight;
    } else {
      // For portrait, determine up vs down (though down is rare)
      final topPadding = mediaQuery.padding.top + mediaQuery.viewPadding.top;
      final bottomPadding = mediaQuery.padding.bottom + mediaQuery.viewPadding.bottom;
      final isUpsideDown = topPadding < bottomPadding;

      return isUpsideDown ? DeviceOrientation.portraitDown : DeviceOrientation.portraitUp;
    }
  }
}
