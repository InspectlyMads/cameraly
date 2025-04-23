import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

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

  // Add a variable to track first orientation change
  bool _isFirstOrientationChange = true;

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

    // Track first orientation change
    _isFirstOrientationChange = true;

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
          _isFirstOrientationChange = false;
          _isAnyOrientationChangeInProgress = false;
        });
      }
      return;
    }

    if (mounted) {
      // Update the orientation change flag based on the new state
      if (newState == CameraLifecycleState.ready) {
        // When camera is ready, immediately hide the loading indicator
        // Only if we're currently showing it
        if (_isChangingOrientation) {
          debugPrint('🎥 Camera is ready - hiding orientation change indicator');
          setState(() {
            _isChangingOrientation = false;
            // Reset camera visible time to now
            _cameraVisibleSince = DateTime.now();
            _isFirstOrientationChange = false;
            _isAnyOrientationChangeInProgress = false;
          });

          // Clear any existing safety timer
          _orientationDebounceTimer?.cancel();
        } else {
          // If we're not in changing state but flags might be set, reset them
          if (_isAnyOrientationChangeInProgress || _isFirstOrientationChange) {
            debugPrint('🎥 Camera is ready - resetting orientation flags');
            setState(() {
              // Reset camera visible time to now
              _cameraVisibleSince = DateTime.now();
              _isFirstOrientationChange = false;
              _isAnyOrientationChangeInProgress = false;
            });
          }
        }
      } else if ((newState == CameraLifecycleState.recreating || newState == CameraLifecycleState.resuming) && !_isChangingOrientation) {
        // Only set to true if it wasn't already true and this isn't just a minor update
        // We don't want to show loading for every tiny lifecycle event

        // For iOS, greatly minimize showing the loading indicator
        if (Platform.isIOS && !_isFirstOrientationChange) {
          debugPrint('🎥 iOS camera is recreating/resuming - NOT showing orientation change indicator');
          return;
        }

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
              _isFirstOrientationChange = false;
              _isAnyOrientationChangeInProgress = false;
            });
          }
        });

        // If this is the first orientation change on Android, add a shorter safety timeout
        if (_isFirstOrientationChange && Platform.isAndroid) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted && _isChangingOrientation && _isFirstOrientationChange) {
              debugPrint('🎥 First Android orientation: safety timeout in state change handler');
              setState(() {
                _isChangingOrientation = false;
                _cameraVisibleSince = DateTime.now();
                _isFirstOrientationChange = false;
                _isAnyOrientationChangeInProgress = false;
              });
            }
          });
        }
      } else if (newState == CameraLifecycleState.error) {
        // Handle error state by resetting any orientation change flags
        debugPrint('🎥 Camera entered error state - resetting orientation flags');
        setState(() {
          _isChangingOrientation = false;
          _isFirstOrientationChange = false;
          _isAnyOrientationChangeInProgress = false;
          _cameraVisibleSince = DateTime.now();
        });

        // Try to recover after a short delay
        if (Platform.isAndroid) {
          Future.delayed(const Duration(seconds: 1), () {
            if (_controller != null && mounted) {
              debugPrint('🎥 Attempting camera recovery after error');
              try {
                _controller!.handleCameraResume();
              } catch (e) {
                debugPrint('🎥 Error during camera recovery: $e');
              }
            }
          });
        }
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

        // Special handling for first orientation change if it's taking too long
        if (_isFirstOrientationChange) {
          // Check if it's been more than 2 seconds since we started changing orientation
          final now = DateTime.now();
          final startTime = _cameraVisibleSince ?? now.subtract(const Duration(seconds: 3));
          final timeElapsed = now.difference(startTime).inSeconds;

          if (timeElapsed > 2) {
            debugPrint('🎥 First orientation change stuck for $timeElapsed seconds - forcing reset');
            _lifecycleMachine?.forceResetToReady();
            _isFirstOrientationChange = false;

            // Update UI
            setState(() {
              _isChangingOrientation = false;
              _cameraVisibleSince = DateTime.now();
              _isAnyOrientationChangeInProgress = false;
            });

            // Force camera to be active again, especially important for Android
            if (Platform.isAndroid && _controller != null) {
              try {
                _controller!.handleCameraResume();
              } catch (e) {
                debugPrint('🎥 Error during camera resume after stuck orientation: $e');
              }
            }
          }
        } else if (Platform.isAndroid) {
          // For non-first orientation changes on Android that might still get stuck
          final now = DateTime.now();
          final startTime = _cameraVisibleSince ?? now.subtract(const Duration(seconds: 5));
          final timeElapsed = now.difference(startTime).inSeconds;

          // If any orientation change has been stuck for more than 5 seconds, force a reset
          if (timeElapsed > 5) {
            debugPrint('🎥 Orientation change stuck for $timeElapsed seconds - force resetting');
            _lifecycleMachine?.forceResetToReady();

            setState(() {
              _isChangingOrientation = false;
              _cameraVisibleSince = DateTime.now();
              _isAnyOrientationChangeInProgress = false;
            });

            // Try to resume camera activity
            if (_controller != null) {
              try {
                _controller!.handleCameraResume();
              } catch (e) {
                debugPrint('🎥 Error during camera resume after stuck orientation: $e');
              }
            }
          }
        }

        super.didChangeMetrics();
        return;
      }

      // Get current orientation to check if it actually changed
      final newOrientation = _getPreciseDeviceOrientation(context);

      // Check if this is actually a significant orientation change that needs handling
      if (!_isSignificantOrientationChange(newOrientation)) {
        debugPrint('🎥 Minor orientation adjustment detected, ignoring: $newOrientation');
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
      // Use a longer debounce time to avoid unnecessary changes
      final debounceTime = _getOrientationDebounceTime(isFirstMetricChange, orientationBefore, newOrientation);

      debugPrint('🎥 Orientation metrics changed, using ${isFirstMetricChange ? "first-run" : "standard"} debounce ($debounceTime ms)');

      // Use debounce to ensure we catch rapid orientation changes
      _orientationDebounceTimer = Timer(Duration(milliseconds: debounceTime), () {
        if (mounted && _controller != null && _lifecycleMachine != null) {
          // Get current orientation from context with improved precision
          final currentOrientation = _getPreciseDeviceOrientation(context);

          // Skip if orientation changed again during debounce
          if (currentOrientation != newOrientation) {
            debugPrint('🎥 Orientation changed during debounce, skipping: $newOrientation → $currentOrientation');
            return;
          }

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

          // Special handling for iOS to avoid infinite loading
          if (Platform.isIOS) {
            debugPrint('🎥 iOS detected: Using direct orientation update');

            // Update controller value with the new orientation
            _controller!.value = _controller!.value.copyWith(deviceOrientation: currentOrientation);

            // Very short delay for iOS then remove the loading indicator
            Future.delayed(const Duration(milliseconds: 150), () {
              // Release global lock
              _isAnyOrientationChangeInProgress = false;
              _isFirstOrientationChange = false;

              if (mounted) {
                setState(() {
                  _isChangingOrientation = false;
                  _cameraVisibleSince = DateTime.now();
                });
              }
            });

            return;
          }

          // Add extreme timeout for stuck orientation changes - force reset after 5 seconds
          final longTimeoutTimer = Timer(const Duration(seconds: 5), () {
            if (mounted && _isChangingOrientation) {
              debugPrint('🎥 EXTREME TIMEOUT: Orientation change has been stuck for 5 seconds - force resetting');

              // Force reset to ready state
              _lifecycleMachine?.forceResetToReady();

              // Release the global lock
              _isAnyOrientationChangeInProgress = false;
              _isFirstOrientationChange = false;

              // Update UI
              if (mounted) {
                setState(() {
                  _isChangingOrientation = false;
                  _cameraVisibleSince = DateTime.now();
                });

                // Try to resume camera activity if needed
                if (_controller != null) {
                  try {
                    _controller!.handleCameraResume();
                  } catch (e) {
                    debugPrint('🎥 Error during camera resume after extreme timeout: $e');
                  }
                }
              }
            }
          });

          // Special handling for first orientation change on Android
          final isFirstAndroidOrientation = _isFirstOrientationChange && Platform.isAndroid;
          if (isFirstAndroidOrientation) {
            // For first Android orientation change, add a shorter timeout
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted && _isChangingOrientation && _isFirstOrientationChange) {
                debugPrint('🎥 First Android orientation change: early timeout in didChangeMetrics');
                _lifecycleMachine?.forceResetToReady();
                _isFirstOrientationChange = false;

                setState(() {
                  _isChangingOrientation = false;
                  _cameraVisibleSince = DateTime.now();
                });

                // Cancel the long timeout since we've handled it
                longTimeoutTimer.cancel();
                _isAnyOrientationChangeInProgress = false;
              }
            });

            // Add another failsafe for Android
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _isChangingOrientation) {
                debugPrint('🎥 First Android orientation change: 2-second failsafe in didChangeMetrics');
                _lifecycleMachine?.forceResetToReady();
                _isFirstOrientationChange = false;

                setState(() {
                  _isChangingOrientation = false;
                  _cameraVisibleSince = DateTime.now();
                });

                longTimeoutTimer.cancel();
                _isAnyOrientationChangeInProgress = false;
              }
            });
          }

          // Regular Android handling
          // For rapid landscape transitions, use special handling
          if (isRapidLandscapeTransition) {
            // Use higher priority for rapid landscape transitions
            _lifecycleMachine!.handleOrientationChange(currentOrientation, priority: true).then((_) {
              longTimeoutTimer.cancel();
              _isAnyOrientationChangeInProgress = false;
              _isFirstOrientationChange = false;
            }).catchError((error) {
              longTimeoutTimer.cancel();
              debugPrint('🎥 Error during rapid orientation change: $error');
              _isAnyOrientationChangeInProgress = false;
              _isFirstOrientationChange = false;

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
              _isFirstOrientationChange = false;

              // The flag should be reset by the lifecycle state change handler
              // No need for a timeout here as the lifecycle machine will call
              // _handleLifecycleStateChange with the ready state when done
            }).catchError((error) {
              longTimeoutTimer.cancel();
              debugPrint('🎥 Error during orientation change: $error');
              _isAnyOrientationChangeInProgress = false;
              _isFirstOrientationChange = false;

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

    // Reduce the debug logs to minimize performance impact
    // Only log when absolutely necessary for debugging
    // debugPrint('🎥 PREVIEW BUILDING:');
    // debugPrint('🎥 Camera type: ${_controller!.description.lensDirection}');
    // debugPrint('🎥 isFrontCamera value: ${value.isFrontCamera}');
    // debugPrint('🎥 isFrontCamera by lens: $isFrontCameraByLens');
    // debugPrint('🎥 Platform: ${Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Other'}');
    // debugPrint('🎥 Should mirror: $shouldMirror');
    // debugPrint('🎥 scaleX will be: ${shouldMirror ? -1.0 : 1.0}');

    // Generate a stable key based on camera lens and orientation, not a dynamic timestamp
    // This prevents unnecessary widget rebuilds
    final previewKey = ValueKey('camera_${_controller!.description.name}_${value.deviceOrientation.index}_$isLandscape');

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

        // Use AnimatedOpacity for smoother loading indicator transitions
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: _shouldShowLoadingIndicator(value) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: IgnorePointer(
              ignoring: true, // Don't intercept touch events
              child: Container(
                key: const ValueKey('loading_overlay'),
                // Make overlay semi-transparent based on state
                color: Colors.black.withAlpha(_isFirstOrientationChange
                        ? 160
                        : // More opaque for first orientation change
                        (value.isInitialized ? 45 : 120) // Less opaque once initialized
                    ),
                child: Center(
                  // Make indicator style based on state
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Show different size indicator based on state
                      value.isInitialized
                          ? const SizedBox(
                              height: 32,
                              width: 32,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const CircularProgressIndicator(color: Colors.white),

                      // Add status text for first orientation change on Android
                      if (_isFirstOrientationChange && Platform.isAndroid)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            'Preparing camera...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
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

  // Helper method to decide when to show loading indicator
  bool _shouldShowLoadingIndicator(CameralyValue value) {
    // Always show loading if camera is not initialized at all
    if (!value.isInitialized) return true;

    // Skip loading indicator if camera is initialized and we're not in a special state
    if (value.isInitialized && !_isChangingOrientation && !value.isChangingController) {
      return false;
    }

    // Always show loading during controller changes, but only if camera isn't already visible
    if (value.isChangingController) {
      // If camera has been visible for a while, don't show loading for minor updates
      if (_cameraVisibleSince != null) {
        final visibleTime = DateTime.now().difference(_cameraVisibleSince!).inMilliseconds;
        if (visibleTime > 1000) return false;
      }
      return true;
    }

    // For first orientation change on Android, always show loading
    if (_isFirstOrientationChange && _isChangingOrientation && Platform.isAndroid) return true;

    // For iOS, rarely show loading indicator as transitions are usually very fast
    if (Platform.isIOS && !_isFirstOrientationChange) return false;

    // For subsequent orientation changes, only show loading if:
    // 1. We're in the changing state AND
    // 2. It's been less than 350ms since the change started OR
    // 3. It's a major orientation change (portrait <-> landscape)
    if (_isChangingOrientation) {
      final changeStartTime = _cameraVisibleSince ?? DateTime.now();
      final changeTimeMs = DateTime.now().difference(changeStartTime).inMilliseconds;
      return changeTimeMs < 350; // Shorter time to reduce blinks
    }

    return false;
  }

  // Add a dedicated method for first orientation update
  void _initializeFirstOrientationUpdate() async {
    if (mounted && _controller != null && _lifecycleMachine != null && _controller!.value.isInitialized) {
      // During first orientation update, always trigger the handler even if
      // we don't think the orientation changed - the API will determine this
      setState(() {
        _isChangingOrientation = true;
      });

      // Get the current device orientation from MediaQuery for reliability
      late DeviceOrientation currentOrientation;
      final orientation = await NativeDeviceOrientationCommunicator().orientation(useSensor: true);
      //Landscape orientation is reversed on iOS
      if (Platform.isIOS && (orientation == NativeDeviceOrientation.landscapeLeft || orientation == NativeDeviceOrientation.landscapeRight)) {
        if (orientation.deviceOrientation == DeviceOrientation.landscapeLeft) {
          currentOrientation = DeviceOrientation.landscapeRight;
        } else {
          currentOrientation = DeviceOrientation.landscapeLeft;
        }
      } else {
        currentOrientation = orientation.deviceOrientation!;
      }

      debugPrint('🎥 Initializing first orientation to: $currentOrientation');

      // Add a safety timeout for first orientation change - this is our ultimate fallback
      _orientationDebounceTimer?.cancel();
      _orientationDebounceTimer = Timer(const Duration(seconds: 3), () {
        debugPrint('🎥 First orientation change safety timeout reached - forcing indicator to hide');
        if (mounted && _isChangingOrientation) {
          setState(() {
            _isChangingOrientation = false;
            _cameraVisibleSince = DateTime.now();
            _isFirstOrientationChange = false;
            _isAnyOrientationChangeInProgress = false;
          });
        }
      });

      // Special case for iOS - orientation handling is skipped but we still need to update the UI
      if (Platform.isIOS) {
        debugPrint('🎥 iOS detected: Using simplified orientation handling');
        // Update controller value with the current orientation
        _controller!.value = _controller!.value.copyWith(deviceOrientation: currentOrientation);

        // Short delay to allow camera to stabilize, then clear the loading indicator
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _isChangingOrientation = false;
              _cameraVisibleSince = DateTime.now();
              _isFirstOrientationChange = false;
              _isAnyOrientationChangeInProgress = false;
            });

            // Force lifecycle machine to ready state
            _lifecycleMachine?.forceResetToReady();
          }
        });
        return;
      }

      // Special case for Android's first orientation change - use more aggressive timeouts
      if (Platform.isAndroid) {
        debugPrint('🎥 Android detected: Adding more aggressive first-change timeouts');

        // Critical immediate reset on Android to prevent any chance of stuck loader
        // This ensures we never get stuck in loading state on first orientation
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            // Update controller with orientation but don't wait for full camera update
            _controller!.value = _controller!.value.copyWith(deviceOrientation: currentOrientation);

            // Continue showing loading state briefly, but set a flag for faster cleanup
            if (_isFirstOrientationChange) {
              debugPrint('🎥 Setting start time for Android first orientation change');
              _cameraVisibleSince = DateTime.now();
            }
          }
        });

        // Add multiple timeouts to ensure we don't get stuck
        // First timeout - very quick check after 500ms
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _isChangingOrientation && _isFirstOrientationChange) {
            debugPrint('🎥 Android first orientation change: applying initial quick check');
            // Just check if we need to force reset yet
            if (_controller != null && !_controller!.value.isInitialized) {
              debugPrint('🎥 Camera not fully initialized at 500ms, waiting longer...');
            }
          }
        });

        // Second timeout - applies after 1 second
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && _isChangingOrientation && _isFirstOrientationChange) {
            debugPrint('🎥 Android first orientation change: applying early timeout');
            // Try force resetting the camera lifecycle machine
            _lifecycleMachine?.forceResetToReady();

            setState(() {
              _isChangingOrientation = false;
              _cameraVisibleSince = DateTime.now();
              _isFirstOrientationChange = false;
              _isAnyOrientationChangeInProgress = false;
            });

            // Force complete UI refresh
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {});
              }
            });
          }
        });

        // Third timeout - fail-safe after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _isChangingOrientation) {
            debugPrint('🎥 Android first orientation change: applying fail-safe timeout');
            // Even more aggressive reset
            if (_lifecycleMachine != null) {
              _lifecycleMachine!.forceResetToReady();
            }

            // Reset important flags
            _isFirstOrientationChange = false;
            _isAnyOrientationChangeInProgress = false;

            setState(() {
              _isChangingOrientation = false;
              _cameraVisibleSince = DateTime.now();
            });
          }
        });
      }

      // Regular handling for Android and other platforms
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
            _isFirstOrientationChange = false;
            _isAnyOrientationChangeInProgress = false;
          });
        }
      }).catchError((error) {
        debugPrint('🎥 Error during first orientation change: $error');
        // Also clear the flag on error
        if (mounted) {
          setState(() {
            _isChangingOrientation = false;
            _cameraVisibleSince = DateTime.now();
            _isFirstOrientationChange = false;
            _isAnyOrientationChangeInProgress = false;
          });
        }
      });
    } else {
      debugPrint('🎥 Skipping first orientation update - camera not ready');
      // Even if we skip, make sure we're not in a changing state
      if (mounted && _isChangingOrientation) {
        setState(() {
          _isChangingOrientation = false;
          _isFirstOrientationChange = false;
          _isAnyOrientationChangeInProgress = false;
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

  // Check if an orientation change is significant enough to handle
  bool _isSignificantOrientationChange(DeviceOrientation newOrientation) {
    // If this is the first orientation change, always treat it as significant
    if (_isFirstOrientationChange) return true;

    // If controller hasn't stored an orientation yet, treat as significant
    if (_controller == null || !_controller!.value.isInitialized) return true;

    // Get the current orientation
    final currentOrientation = _controller!.value.deviceOrientation;

    // Changes between portrait and landscape are always significant
    final isCurrentPortrait = currentOrientation == DeviceOrientation.portraitUp || currentOrientation == DeviceOrientation.portraitDown;
    final isNewPortrait = newOrientation == DeviceOrientation.portraitUp || newOrientation == DeviceOrientation.portraitDown;

    if (isCurrentPortrait != isNewPortrait) return true;

    // For iOS, orientation changes within the same mode (e.g., landscape left to landscape right)
    // are handled well by the platform and don't need special handling
    if (Platform.isIOS) {
      if (isCurrentPortrait && isNewPortrait) return false;
      if (!isCurrentPortrait && !isNewPortrait) return false;
    }

    // For Android landscape to landscape changes, be selective
    if (Platform.isAndroid && !isCurrentPortrait && !isNewPortrait) {
      // If changing directly between left and right, it's significant
      if ((currentOrientation == DeviceOrientation.landscapeLeft && newOrientation == DeviceOrientation.landscapeRight) || (currentOrientation == DeviceOrientation.landscapeRight && newOrientation == DeviceOrientation.landscapeLeft)) {
        return true;
      }
    }

    // Skip if orientation is the same
    return currentOrientation != newOrientation;
  }

  // Get appropriate debounce time based on conditions
  int _getOrientationDebounceTime(bool isFirstChange, DeviceOrientation oldOrientation, DeviceOrientation newOrientation) {
    // First metric change needs longer debounce
    if (isFirstChange) return 250;

    // iOS handles orientation changes quickly
    if (Platform.isIOS) return 150;

    // Rapid landscape-to-landscape transitions need quick response
    if ((oldOrientation == DeviceOrientation.landscapeLeft && newOrientation == DeviceOrientation.landscapeRight) || (oldOrientation == DeviceOrientation.landscapeRight && newOrientation == DeviceOrientation.landscapeLeft)) {
      return 150; // Quick debounce for landscape switches
    }

    // Standard debounce - slightly longer to avoid unneeded changes
    return 300;
  }
}
