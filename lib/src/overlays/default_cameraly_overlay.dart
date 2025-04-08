import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../cameraly_controller.dart';
import '../types/camera_mode.dart';
import '../utils/cameraly_controller_provider.dart';
import '../utils/media_manager.dart';
import 'cameraly_overlay_theme.dart';
import 'zoom_ruler_widget.dart';

/// A reusable button widget for camera overlay controls.
///
/// This widget provides consistent styling for circular buttons in the camera overlay,
/// with a semi-transparent black background and customizable content.
class CameralyOverlayButton extends StatelessWidget {
  /// Creates a new [CameralyOverlayButton].
  const CameralyOverlayButton({
    required this.child,
    this.onTap,
    this.margin = const EdgeInsets.only(top: 16),
    this.backgroundColor = const Color.fromARGB(77, 0, 0, 0),
    this.size = 40.0,
    this.borderColor = const Color.fromARGB(77, 255, 255, 255),
    this.borderWidth = 1.0,
    this.useHapticFeedback = false,
    this.hapticFeedbackType = HapticFeedbackType.light,
    super.key,
  });

  /// The widget to display inside the button.
  final Widget child;

  /// Callback when the button is tapped.
  final VoidCallback? onTap;

  /// The margin around the button.
  final EdgeInsets margin;

  /// The background color of the button.
  final Color backgroundColor;

  /// The size of the button.
  final double size;

  /// The color of the button's border.
  final Color borderColor;

  /// The width of the button's border.
  final double borderWidth;

  /// Whether to use haptic feedback when the button is tapped.
  final bool useHapticFeedback;

  /// The type of haptic feedback to provide.
  final HapticFeedbackType hapticFeedbackType;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              if (useHapticFeedback) {
                switch (hapticFeedbackType) {
                  case HapticFeedbackType.light:
                    HapticFeedback.lightImpact();
                    break;
                  case HapticFeedbackType.medium:
                    HapticFeedback.mediumImpact();
                    break;
                  case HapticFeedbackType.heavy:
                    HapticFeedback.heavyImpact();
                    break;
                  case HapticFeedbackType.selection:
                    HapticFeedback.selectionClick();
                    break;
                  case HapticFeedbackType.vibrate:
                    HapticFeedback.vibrate();
                    break;
                }
              }
              onTap!();
            }
          : null,
      child: Container(margin: margin, width: size, height: size, decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle, border: Border.all(color: borderColor, width: borderWidth)), child: child),
    );
  }
}

/// Enum defining the types of haptic feedback available.
enum HapticFeedbackType {
  /// Light impact feedback
  light,

  /// Medium impact feedback
  medium,

  /// Heavy impact feedback
  heavy,

  /// Selection click feedback
  selection,

  /// Vibration feedback
  vibrate,
}

/// A default overlay for the camera preview with standard controls.
///
/// This widget provides a customizable camera UI with controls for
/// capturing photos, recording videos, switching cameras, toggling flash,
/// and more. The UI matches the basic camera example.
///
/// Key features:
/// - Customizable buttons and controls
/// - Support for both photo and video modes
/// - Flash and torch controls
/// - Focus and zoom capabilities
/// - Gallery access (automatically disabled during recording)
/// - Camera state notifications for parent widgets
/// - Responsive layout for both portrait and landscape orientations
///
/// ## Automatic Button Positioning
///
/// When you provide custom buttons using `customRightButton` or `customLeftButton`,
/// the default buttons are automatically moved to the top-right area:
///
/// - If `customRightButton` is provided, the camera switch button moves to the top-right
/// - If `customLeftButton` is provided, the gallery button moves to the top-right
///
/// This makes it easy to customize the camera interface without worrying about
/// button positioning or visibility.
///
/// ## Button State Management
///
/// The camera controls automatically respond to the camera's state:
///
/// - During recording, certain buttons are disabled
/// - When the file picker is active (during gallery imports), all buttons are disabled
/// - Custom buttons can also respond to these states via the builder pattern
///
/// When using custom button builders, you can check the `isFilePickerActive` state
/// to disable your buttons while the file picker is working:
///
/// ```dart
/// customRightButtonBuilder: (context, state) {
///   // Disable button while picker is active
///   if (state.isFilePickerActive) {
///     return const Opacity(opacity: 0.5, child: SizedBox(width: 56, height: 56));
///   }
///
///   return FloatingActionButton(
///     onPressed: () => Navigator.of(context).pop(),
///     backgroundColor: Colors.white,
///     child: const Icon(Icons.check),
///   );
/// }
/// ```
///
/// ## Example Usage
///
/// ```dart
/// // Basic usage with default controls
/// DefaultCameralyOverlay(
///   controller: cameralyController,
/// )
///
/// // Photo-only camera with a done button that pops the view
/// DefaultCameralyOverlay(
///   controller: cameralyController,
///   showModeToggle: false, // Hide mode toggle for photo-only mode
///   onPictureTaken: (file) {
///     // Handle the captured photo
///   },
///   customRightButton: Builder(
///     builder: (context) {
///       final overlay = DefaultCameralyOverlay.of(context);
///       final isRecording = overlay?._isRecording ?? false;
///
///       return FloatingActionButton(
///         onPressed: isRecording ? null : () => Navigator.of(context).pop(),
///         backgroundColor: isRecording ? Colors.grey : Colors.white,
///         foregroundColor: Colors.black87,
///         mini: true,
///         child: const Icon(Icons.check),
///       );
///     },
///   ),
/// )
class DefaultCameralyOverlay extends StatefulWidget {
  /// Creates a new [DefaultCameralyOverlay] widget.
  ///
  /// The [controller] can be provided explicitly or obtained automatically from a
  /// [CameralyControllerProvider] ancestor widget, but it must be available from one of these sources.
  const DefaultCameralyOverlay({
    this.controller,
    this.theme,
    this.onCapture,
    this.onCaptureMode,
    this.onClose,
    this.onFlashTap,
    this.onGalleryTap,
    this.onSwitchCamera,
    this.onControllerChanged,
    this.onZoomChanged,
    this.showCaptureAnimation = true,
    this.showFlashButton = true,
    this.showGalleryButton = true,
    this.showSwitchCameraButton = true,
    this.showZoomControls = true,
    this.maxVideoDuration,
    this.captureButtonBuilder,
    this.flashButtonBuilder,
    this.galleryButtonBuilder,
    this.switchCameraButtonBuilder,
    this.zoomSliderBuilder,
    this.mediaManager,
    this.onCameraStateChanged,
    this.onMaxDurationReached,
    this.customBackButton,
    this.backButtonBuilder,
    this.bottomOverlayWidget,
    this.showPlaceholders = false,
    this.topLeftWidget,
    this.showMediaStack = true,
    this.customLeftButton,
    this.customRightButton,
    this.customLeftButtonBuilder,
    this.customRightButtonBuilder,
    this.centerLeftWidget,
    this.showCaptureButton = true,
    this.onError,
    this.multiImageSelect = true,
    this.useHapticFeedbackOnCustomButtons = true,
    this.customButtonHapticFeedbackType = HapticFeedbackType.light,
    super.key,
  });

  /// The controller for the camera.
  ///
  /// This can be null if a [CameralyControllerProvider] ancestor provides the controller.
  final CameralyController? controller;

  /// The theme for the overlay.
  final CameralyOverlayTheme? theme;

  /// Callback when a photo is captured or video recording is stopped.
  final Function(XFile)? onCapture;

  /// Callback when the capture mode is changed (photo/video).
  final Function(bool)? onCaptureMode;

  /// Callback when the overlay is closed.
  final VoidCallback? onClose;

  /// Callback when the flash button is tapped.
  final VoidCallback? onFlashTap;

  /// Callback when the gallery button is tapped.
  final VoidCallback? onGalleryTap;

  /// Callback when the switch camera button is tapped.
  final VoidCallback? onSwitchCamera;

  /// Callback when the controller is changed (e.g., after switching cameras).
  /// This allows the parent widget to update its reference to the controller.
  final Function(CameralyController)? onControllerChanged;

  /// Callback when the zoom level changes.
  final Function(double)? onZoomChanged;

  /// Whether to show the capture animation.
  final bool showCaptureAnimation;

  /// Whether to show the flash button.
  final bool showFlashButton;

  /// Whether to show the gallery button.
  final bool showGalleryButton;

  /// Whether to show the switch camera button.
  final bool showSwitchCameraButton;

  /// Whether to show zoom controls.
  final bool showZoomControls;

  /// The maximum duration for video recording.
  final Duration? maxVideoDuration;

  /// Builder for the capture button.
  final Widget Function(BuildContext, bool)? captureButtonBuilder;

  /// Builder for the flash button.
  final Widget Function(BuildContext, FlashMode)? flashButtonBuilder;

  /// Builder for the gallery button.
  final Widget Function(BuildContext)? galleryButtonBuilder;

  /// Builder for the switch camera button.
  final Widget Function(BuildContext)? switchCameraButtonBuilder;

  /// Builder for the zoom slider.
  final Widget Function(BuildContext, double)? zoomSliderBuilder;

  /// The media manager for handling captured photos and videos.
  final CameralyMediaManager? mediaManager;

  /// Callback when the camera state changes.
  final Function(CameralyOverlayState)? onCameraStateChanged;

  /// Callback when the maximum video duration is reached.
  final VoidCallback? onMaxDurationReached;

  /// Custom back button to display.
  ///
  /// Note: This property is deprecated. Use [backButtonBuilder] instead
  /// for more flexible customization.
  final Widget? customBackButton;

  /// Builder for a fully customizable back button.
  ///
  /// This provides access to the context and the current overlay state,
  /// allowing for more dynamic customization based on camera state.
  ///
  /// Example:
  /// ```dart
  /// backButtonBuilder: (context, overlayState) {
  ///   return GestureDetector(
  ///     onTap: () {
  ///       // Custom back action
  ///       if (overlayState.isRecording) {
  ///         // Show confirmation dialog when recording
  ///         showDialog(...);
  ///       } else {
  ///         Navigator.of(context).pop();
  ///       }
  ///     },
  ///     child: Container(
  ///       padding: EdgeInsets.all(12),
  ///       decoration: BoxDecoration(
  ///         color: Colors.blue,
  ///         shape: BoxShape.circle,
  ///       ),
  ///       child: Icon(Icons.close, color: Colors.white),
  ///     ),
  ///   );
  /// }
  final Widget Function(BuildContext context, CameralyOverlayState state)? backButtonBuilder;

  /// Widget to display in the bottom overlay area.
  final Widget? bottomOverlayWidget;

  /// Whether to show placeholders for customizable widgets.
  final bool showPlaceholders;

  /// Widget to display in the top-left corner.
  final Widget? topLeftWidget;

  /// Whether to show the media stack.
  final bool showMediaStack;

  /// Custom button to display on the left side.
  final Widget? customLeftButton;

  /// Custom button to display on the right side.
  final Widget? customRightButton;

  /// Builder for a dynamic left button that can change based on camera state.
  ///
  /// This provides access to the context and the current camera overlay state,
  /// allowing for conditional rendering based on camera status (recording, video mode, etc).
  ///
  /// Example:
  /// ```dart
  /// customLeftButtonBuilder: (context, state) {
  ///   // Hide button while recording
  ///   if (state.isRecording) {
  ///     return const SizedBox.shrink();
  ///   }
  ///   return FloatingActionButton(
  ///     onPressed: () => doSomething(),
  ///     child: const Icon(Icons.settings),
  ///   );
  /// }
  /// ```
  ///
  /// Note: This takes precedence over [customLeftButton] if both are provided.
  final Widget Function(BuildContext context, CameralyOverlayState state)? customLeftButtonBuilder;

  /// Builder for a dynamic right button that can change based on camera state.
  ///
  /// This provides access to the context and the current camera overlay state,
  /// allowing for conditional rendering based on camera status (recording, video mode, etc).
  ///
  /// Example:
  /// ```dart
  /// customRightButtonBuilder: (context, state) {
  ///   // Disable button while recording
  ///   if (state.isRecording) {
  ///     return const SizedBox.shrink();
  ///   }
  ///   return FloatingActionButton(
  ///     onPressed: () => Navigator.of(context).pop(),
  ///     child: const Icon(Icons.check),
  ///   );
  /// }
  /// ```
  ///
  /// Note: This takes precedence over [customRightButton] if both are provided.
  final Widget Function(BuildContext context, CameralyOverlayState state)? customRightButtonBuilder;

  /// Widget to display in the center-left area.
  final Widget? centerLeftWidget;

  /// Whether to show the capture button.
  final bool showCaptureButton;

  /// Whether to allow multiple image selection in the gallery picker.
  final bool multiImageSelect;

  /// Callback for any camera error that occurs.
  ///
  /// This provides comprehensive error information including:
  /// - source: The source of the error (e.g., 'initialization', 'capture', etc.)
  /// - message: A human-readable error message
  /// - error: The original error object (if available)
  /// - isRecoverable: Whether the error is potentially recoverable
  final Function(String source, String message, {Object? error, bool isRecoverable})? onError;

  /// Whether to use haptic feedback when custom buttons are tapped.
  /// Note: This applies to the built-in buttons like the gallery and camera switch buttons.
  /// Custom buttons provided via customLeftButton or customRightButton need to implement
  /// their own haptic feedback.
  final bool useHapticFeedbackOnCustomButtons;

  /// The type of haptic feedback to provide for custom buttons.
  final HapticFeedbackType customButtonHapticFeedbackType;

  @override
  State<DefaultCameralyOverlay> createState() => _DefaultCameralyOverlayState();

  /// Returns the [State] from the closest [DefaultCameralyOverlay]
  /// ancestor, or null if none exists.
  ///
  /// This allows other widgets to interact with the overlay's state.
  static State<DefaultCameralyOverlay>? of(BuildContext context) {
    final DefaultCameralyOverlayScope? scope = context.dependOnInheritedWidgetOfExactType<DefaultCameralyOverlayScope>();
    return scope?.state;
  }

  /// Creates a styled back button that can be used with [backButtonBuilder].
  ///
  /// This helper method makes it easy to create a custom back button with
  /// the default styling but custom behavior.
  ///
  /// Parameters:
  /// - [onPressed]: The callback to execute when the button is pressed
  /// - [icon]: The icon to display (defaults to Icons.arrow_back)
  /// - [backgroundColor]: The background color (defaults to semi-transparent black)
  /// - [iconColor]: The icon color (defaults to white)
  /// - [size]: The size of the button (defaults to 40)
  ///
  /// Example:
  /// ```dart
  /// backButtonBuilder: (context, state) => DefaultCameralyOverlay.createStyledBackButton(
  ///   onPressed: () {
  ///     if (state.isRecording) {
  ///       // Show confirmation dialog
  ///       showDialog(...);
  ///     } else {
  ///       Navigator.of(context).pop();
  ///     }
  ///   },
  ///   icon: Icons.close,
  ///   backgroundColor: Colors.red.withAlpha(179),
  /// ),
  /// ```
  static Widget createStyledBackButton({
    required VoidCallback onPressed,
    IconData icon = Icons.arrow_back,
    Color backgroundColor = const Color.fromARGB(102, 0, 0, 0),
    Color iconColor = Colors.white,
    double size = 40,
  }) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor,
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        iconSize: size * 0.6,
      ),
    );
  }
}

/// Represents the current state of the camera overlay.
class CameralyOverlayState {
  /// Creates a new camera overlay state.
  const CameralyOverlayState({
    required this.isRecording,
    required this.isVideoMode,
    required this.isFrontCamera,
    required this.flashMode,
    required this.torchEnabled,
    required this.recordingDuration,
    this.isFilePickerActive = false,
  });

  /// Whether the camera is currently recording video.
  final bool isRecording;

  /// Whether the camera is in video mode (as opposed to photo mode).
  final bool isVideoMode;

  /// Whether the front camera is currently active.
  final bool isFrontCamera;

  /// The current flash mode.
  final FlashMode flashMode;

  /// Whether the torch is enabled (in video mode).
  final bool torchEnabled;

  /// The current recording duration (zero if not recording).
  final Duration recordingDuration;

  /// Whether a file picker is currently active and processing files.
  final bool isFilePickerActive;

  /// Creates a copy of this state with the specified fields replaced.
  CameralyOverlayState copyWith({
    bool? isRecording,
    bool? isVideoMode,
    bool? isFrontCamera,
    FlashMode? flashMode,
    bool? torchEnabled,
    Duration? recordingDuration,
    bool? isFilePickerActive,
  }) {
    return CameralyOverlayState(
      isRecording: isRecording ?? this.isRecording,
      isVideoMode: isVideoMode ?? this.isVideoMode,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      flashMode: flashMode ?? this.flashMode,
      torchEnabled: torchEnabled ?? this.torchEnabled,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      isFilePickerActive: isFilePickerActive ?? this.isFilePickerActive,
    );
  }
}

/// An InheritedWidget that provides access to the DefaultCameralyOverlay's state.
///
/// This allows descendant widgets to access the overlay's state directly.
class DefaultCameralyOverlayScope extends InheritedWidget {
  /// Creates a new [DefaultCameralyOverlayScope] widget.
  const DefaultCameralyOverlayScope({required this.state, required super.child, super.key});

  /// The state of the [DefaultCameralyOverlay] widget.
  final State<DefaultCameralyOverlay> state;

  @override
  bool updateShouldNotify(DefaultCameralyOverlayScope oldWidget) {
    return state != oldWidget.state;
  }
}

class _DefaultCameralyOverlayState extends State<DefaultCameralyOverlay> with WidgetsBindingObserver, TickerProviderStateMixin {
  // Changed from late to nullable
  CameralyController? _controller;
  bool _isFrontCamera = false;
  bool _isVideoMode = false;
  bool _isRecording = false;
  bool _isFilePickerActive = false; // Track when file picker is active
  bool _isProcessingVideo = false; // Track when video is being processed after recording
  FlashMode _flashMode = FlashMode.auto;
  bool _torchEnabled = false;

  // Zoom related variables
  double _currentZoom = 1.0;
  var _previousZoom = 1.0; // Track previous zoom to detect changes - using var to ensure it's mutable
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  List<double> _availableZoomLevels = [1.0];

  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _recordingLimitTimer;
  bool _hasVideoDurationLimit = false;
  Duration? _maxVideoDuration;
  // Flag to track orientation changes in progress
  bool _orientationChangeInProgress = false;

  // Animation controller for zoom
  late AnimationController _zoomAnimationController;
  Animation<double>? _zoomAnimation;

  // Add a variable to track the saved orientation for gallery navigation
  DeviceOrientation? _savedGalleryOrientation;
  bool _returningFromGallery = false;

  // Add zoom ruler visibility control
  bool _isZoomRulerVisible = false;
  Timer? _zoomRulerTimer;

  // Add variables to track pinch gesture
  final double _baseScale = 1.0;
  double _startZoom = 1.0;

  // Track if we're in a snap zone to prevent repeated haptic feedback
  bool _isInPinchSnapZone = false;

  /// Whether to show the mode toggle button.
  /// This is determined by the camera mode - only shown when mode is [CameraMode.both].
  bool get effectiveShowModeToggle => _controller?.settings.cameraMode == CameraMode.both;

  @override
  void initState() {
    super.initState();

    // Initialize zoom animation controller
    _zoomAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _zoomAnimationController.addListener(_handleZoomAnimation);

    // Initialize video duration limit settings
    _hasVideoDurationLimit = widget.maxVideoDuration != null;
    _maxVideoDuration = widget.maxVideoDuration;

    // Initialize with widget.controller (which might be null)
    _controller = widget.controller;

    // We'll look for a controller in didChangeDependencies if needed
    if (_controller != null) {
      // IMPORTANT: Always initialize _isFrontCamera based on the actual lens direction
      _isFrontCamera = _controller!.description.lensDirection == CameraLensDirection.front;
      debugPrint('🎥 Initial camera is front-facing: $_isFrontCamera');

      _initializeValues();
      _initializeZoomLevels();

      // Listen for controller value changes
      _controller!.addListener(_handleControllerChanged);
    }

    // Register for lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Debug logging for lifecycle management
    debugPrint('🎥 DefaultCameralyOverlay initState complete, registered as lifecycle observer');
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleControllerChanged);

    // Unregister from lifecycle events
    WidgetsBinding.instance.removeObserver(this);

    _recordingTimer?.cancel();
    _recordingLimitTimer?.cancel();

    // Cancel zoom ruler timer
    _zoomRulerTimer?.cancel();

    _zoomAnimationController.removeListener(_handleZoomAnimation);
    _zoomAnimationController.dispose();

    debugPrint('🎥 DefaultCameralyOverlay dispose complete, unregistered as lifecycle observer');
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // If we don't have a controller yet, try to get one from the provider
    if (_controller == null) {
      final controller = CameralyControllerProvider.of(context);
      if (controller != null) {
        _controller = controller;

        // Set initial front camera status
        _isFrontCamera = _controller!.description.lensDirection == CameraLensDirection.front;
        debugPrint('🎥 Initial camera is front-facing (from provider): $_isFrontCamera');

        _initializeValues();
        _initializeZoomLevels();

        // Listen for controller value changes
        _controller!.addListener(_handleControllerChanged);
      }
    }
  }

  @override
  void didUpdateWidget(DefaultCameralyOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update video duration settings if they've changed
    if (oldWidget.maxVideoDuration != widget.maxVideoDuration) {
      setState(() {
        _hasVideoDurationLimit = widget.maxVideoDuration != null;
        _maxVideoDuration = widget.maxVideoDuration;
        debugPrint('📹 Video duration limit updated: $_hasVideoDurationLimit, duration: $_maxVideoDuration');
      });
    }
  }

  @override
  void didChangeMetrics() {
    // This will be called when the screen rotates
    if (mounted && !_orientationChangeInProgress) {
      debugPrint('🎥 Screen metrics changed (likely orientation change)');

      // Set flag to prevent multiple calls during the same orientation change
      _orientationChangeInProgress = true;

      // First pause the camera to prevent issues during orientation change
      _pauseCamera();

      // Use longer delay for Android to ensure UI fully stabilizes
      // Android needs more time to handle orientation changes properly
      final delay = Platform.isAndroid ? const Duration(milliseconds: 800) : const Duration(milliseconds: 300);

      // Then recover the camera after a delay to allow UI to stabilize
      Future.delayed(delay, () {
        if (mounted && _controller != null) {
          debugPrint('🎥 Starting camera recovery after orientation change');

          // Set loading indicator state
          setState(() {
            _isFilePickerActive = true;
          });

          // Use the controller's aggressive recovery method
          _controller!.handleCameraResume().then((_) {
            if (mounted) {
              debugPrint('🎥 Camera recovered after orientation change');

              // Reset the orientation change flag
              _orientationChangeInProgress = false;

              // Refresh the UI and explicitly reset loading state
              setState(() {
                _isFilePickerActive = false;
              });

              // Update buttons and UI state
              _updateButtonStates();
            }
          }).catchError((error) {
            debugPrint('🎥 Error recovering camera after orientation change: $error');

            // Reset the flag even if there's an error
            _orientationChangeInProgress = false;

            // Reset loading state on error too
            if (mounted) {
              setState(() {
                _isFilePickerActive = false;
              });
            }

            // Try one more time with a simple approach
            if (mounted && _controller != null && _controller!.cameraController != null) {
              try {
                _controller!.cameraController!.resumePreview();
                debugPrint('🎥 Attempted simple resumePreview as fallback');
              } catch (e) {
                debugPrint('🎥 Fallback resumePreview also failed: $e');
              }

              // Update UI regardless
              setState(() {});
            }
          });
        } else {
          // Reset the flag if widget is no longer mounted
          _orientationChangeInProgress = false;
        }
      });
    }
    super.didChangeMetrics();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('🎥 App lifecycle state changed: $state');

    // If we're in the middle of an orientation change, don't interrupt that process
    if (_orientationChangeInProgress) {
      debugPrint('🎥 Ignoring lifecycle state change during orientation change');
      super.didChangeAppLifecycleState(state);
      return;
    }

    // Basic state detection and logging
    switch (state) {
      case AppLifecycleState.inactive:
        // App is partially obscured (e.g., in app switcher)
        debugPrint('🎥 App inactive: camera may need to pause');

        // Check if recording and stop/discard if necessary
        if (_controller != null && _controller!.value.isRecordingVideo) {
          debugPrint('🎥 Recording in progress while app going inactive - stopping and discarding');
          _stopAndDiscardRecording();
        } else {
          _pauseCamera();
        }
        break;

      case AppLifecycleState.paused:
        // App is completely hidden, in background
        debugPrint('🎥 App paused: camera should be paused');
        _pauseCamera();
        break;

      case AppLifecycleState.resumed:
        // App is visible again - resume camera
        debugPrint('🎥 App resumed: camera should be resumed');
        // Call _resumeCamera asynchronously
        _resumeCamera().then((_) {
          debugPrint('🎥 Camera resume completed');
        }).catchError((error) {
          debugPrint('🎥 Error resuming camera: $error');
        });
        break;

      case AppLifecycleState.detached:
        // App is being terminated
        debugPrint('🎥 App detached: cleaning up camera resources');
        // No need to pause here as the app is being terminated
        break;

      default:
        // Handle any new lifecycle states that might be added in future Flutter versions
        debugPrint('🎥 Unhandled lifecycle state: $state');
        break;
    }

    super.didChangeAppLifecycleState(state);
  }

  /// Pauses the camera preview when the app is not visible
  void _pauseCamera() {
    // Validate controller exists and is initialized
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('🎥 Cannot pause camera: Controller is null or not initialized');
      return;
    }

    try {
      if (_controller!.cameraController != null) {
        // Save current flash mode and torch state for later restoration
        if (!_isFrontCamera) {
          // Only save if using back camera (front doesn't support flash)
          debugPrint('🎥 Saving flash state - mode: $_flashMode, torch: $_torchEnabled');
        }

        // Save current orientation for when we resume from gallery
        _savedGalleryOrientation = _controller!.value.deviceOrientation;
        debugPrint('🎥 Saving orientation before pause: $_savedGalleryOrientation');

        debugPrint('🎥 Pausing camera preview');
        _controller!.cameraController!.pausePreview();

        // Update UI if needed
        if (mounted) {
          setState(() {
            // Update any UI elements that need to reflect paused state
          });
        }
      }
    } catch (e) {
      debugPrint('🎥 Error pausing camera: $e');
    }
  }

  /// Resumes the camera preview when the app becomes visible again
  Future<void> _resumeCamera() async {
    // Validate controller exists and is initialized
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('🎥 Cannot resume camera: Controller is null or not initialized');
      return;
    }

    try {
      debugPrint('🎥 Resuming camera preview');
      _returningFromGallery = true;

      // On Android, use our more aggressive recovery method for better reliability
      if (Platform.isAndroid) {
        try {
          if (mounted) {
            setState(() {
              // Update UI to show loading state
              _isFilePickerActive = true; // Reuse this flag to indicate camera recovery
            });
          }

          // Use the enhanced camera resume method that recreates the controller if needed
          await _controller!.handleCameraResume();

          // After resume is complete, explicitly set the saved orientation if available
          if (_savedGalleryOrientation != null) {
            debugPrint('🎥 Restoring orientation after gallery return: $_savedGalleryOrientation');
            try {
              await _controller!.setDeviceOrientation(_savedGalleryOrientation!);
            } catch (e) {
              debugPrint('🎥 Error restoring orientation after gallery: $e');
            }
          }

          debugPrint('🎥 Android camera resumed with aggressive recovery method');
        } catch (e) {
          debugPrint('🎥 Error in aggressive Android camera recovery: $e');

          // Fallback to simple resume as a last resort
          try {
            _controller!.cameraController!.resumePreview();

            // Still try to restore orientation even with fallback
            if (_savedGalleryOrientation != null) {
              await _controller!.setDeviceOrientation(_savedGalleryOrientation!);
            }
          } catch (e2) {
            debugPrint('🎥 Fallback resume also failed: $e2');
          }
        } finally {
          // Always reset UI state
          if (mounted) {
            setState(() {
              _isFilePickerActive = false;
            });
          }
        }
      } else {
        // For iOS, the normal resume works fine
        _controller!.cameraController!.resumePreview();

        // Ensure orientation is correct on iOS too
        if (_savedGalleryOrientation != null) {
          try {
            await _controller!.setDeviceOrientation(_savedGalleryOrientation!);
          } catch (e) {
            debugPrint('🎥 Error restoring iOS orientation after gallery: $e');
          }
        }
      }

      // Restore flash mode and torch settings
      if (!_isFrontCamera) {
        if (_isVideoMode) {
          // For video mode, first set flash off then enable torch if it was on
          debugPrint('🎥 Restoring video mode torch state: $_torchEnabled');
          await _controller!.setFlashMode(FlashMode.off);
          if (_torchEnabled) {
            await _controller!.setFlashMode(FlashMode.torch);
          }
        } else {
          // For photo mode, restore the previous flash mode
          debugPrint('🎥 Restoring photo mode flash: $_flashMode');
          await _controller!.setFlashMode(_flashMode);
        }
      }

      // Add a delayed orientation check to catch any issues with the first attempt
      if (_savedGalleryOrientation != null) {
        Future.delayed(const Duration(milliseconds: 500), () async {
          try {
            if (_controller != null && _controller!.value.isInitialized && mounted && _returningFromGallery) {
              debugPrint('🎥 Performing delayed orientation check after gallery return');
              await _controller!.setDeviceOrientation(_savedGalleryOrientation!);
              _returningFromGallery = false;
            }
          } catch (e) {
            debugPrint('🎥 Error in delayed orientation check: $e');
          }
        });
      }

      debugPrint('🎥 Camera resumed with flash mode: $_flashMode, torch: $_torchEnabled');
    } catch (e) {
      debugPrint('🎥 Error resuming camera: $e');

      // Always make sure to reset loading state on error
      if (mounted) {
        setState(() {
          _isFilePickerActive = false;
        });
      }

      // Force a rebuild to help with recovery
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Stops recording and discards the footage if recording is in progress
  /// This is used when the app goes to background while recording
  Future<void> _stopAndDiscardRecording() async {
    // Check if we're currently recording
    if (_controller == null || _controller!.cameraController == null || !_controller!.value.isRecordingVideo) {
      debugPrint('🎥 Not recording, nothing to discard');
      return;
    }

    debugPrint('🎥 App lost focus while recording, stopping and discarding recording');

    try {
      // Stop recording and get the file
      final XFile videoFile = await _controller!.stopVideoRecording();

      // Turn off torch if it was enabled
      if (_torchEnabled && !_isFrontCamera) {
        debugPrint('🎥 Turning off torch after stopping recording');
        await _controller!.setFlashMode(FlashMode.off);
        setState(() {
          _torchEnabled = false;
        });
      }

      // If we have a file, delete it
      try {
        // Get the file path
        final String filePath = videoFile.path;
        debugPrint('🎥 Discarding interrupted recording: $filePath');

        // Delete the file
        final File file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('🎥 Successfully deleted interrupted recording');
        }
      } catch (e) {
        debugPrint('🎥 Error deleting interrupted recording: $e');
      }

      // Update UI state
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      debugPrint('🎥 Error stopping recording: $e');
    }
  }

  Future<void> _initializeValues() async {
    final value = _controller?.value;

    // Initialize zoom levels
    _currentZoom = value?.zoomLevel ?? 1.0;

    // Set _isVideoMode based on camera mode
    if (_controller != null) {
      setState(() {
        // Set _isVideoMode to true if CameraMode is VideoOnly
        _isVideoMode = _controller!.settings.cameraMode == CameraMode.videoOnly;
      });
    }
  }

  Future<void> _initializeZoomLevels() async {
    try {
      _minZoom = await _controller?.getMinZoomLevel() ?? 1.0;
      _maxZoom = await _controller?.getMaxZoomLevel() ?? 1.0;

      // Create a list of available zoom levels based on device capabilities
      final zoomLevels = <double>[];

      // Add ultra-wide if available (usually 0.5x or 0.6x)
      if (_minZoom <= 0.5) {
        zoomLevels.add(0.5);
      } else if (_minZoom <= 0.6) {
        zoomLevels.add(0.6);
      }

      // Always add 1x
      zoomLevels.add(1.0);

      // Add 2x if available
      if (_maxZoom >= 2.0) {
        zoomLevels.add(2.0);
      }

      // Add 5x if available
      if (_maxZoom >= 5.0) {
        zoomLevels.add(5.0);
      }

      setState(() {
        _availableZoomLevels = zoomLevels;
      });

      debugPrint('📸 Available zoom levels: $_availableZoomLevels (min: $_minZoom, max: $_maxZoom)');
    } catch (e) {
      debugPrint('Error initializing zoom levels: $e');
    }
  }

  void _handleZoomAnimation() {
    if (_zoomAnimation != null) {
      _controller?.setZoomLevel(_zoomAnimation!.value);
    }
  }

  Future<void> _setZoomLevel(double targetZoom) async {
    if (_controller == null) return;

    try {
      // Provide different haptic feedback based on the magnitude of zoom change
      if (widget.useHapticFeedbackOnCustomButtons) {
        // Calculate the zoom change magnitude
        final zoomChangeMagnitude = (_currentZoom - targetZoom).abs();

        // Provide appropriate haptic feedback based on zoom change magnitude
        if (zoomChangeMagnitude > 2.0) {
          // For large zoom changes (e.g., 1x to 5x), use heavy impact
          HapticFeedback.heavyImpact();
        } else if (zoomChangeMagnitude > 0.5) {
          // For medium zoom changes (e.g., 1x to 2x), use medium impact
          HapticFeedback.mediumImpact();
        } else {
          // For small zoom changes, just use selection click feedback
          // We've already provided this in the onTap handler, so no need to duplicate
        }
      }

      // Show zoom ruler immediately - do this BEFORE animation starts
      _showZoomRuler();

      // Update current zoom state immediately to ensure ruler position is correct
      setState(() {
        _currentZoom = targetZoom;
        _previousZoom = targetZoom; // Update previous zoom
      });

      // If an animation is already running, stop it
      if (_zoomAnimationController.isAnimating) {
        _zoomAnimationController.stop();
      }

      // Set the camera zoom level directly
      await _controller?.setZoomLevel(targetZoom);
    } catch (e) {
      debugPrint('Error setting zoom level: $e');
    }
  }

  Widget _buildZoomLevelButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      decoration: BoxDecoration(color: Colors.black.withAlpha(102), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _availableZoomLevels.map((zoom) {
          // Find which button should be selected: the largest button that's <= current zoom
          // For example: 1.9x should still be shown in the 1x button, not the 2x button

          // For each zoom button, we need to find if it's the largest one that's <= currentZoom
          // First get all the zoom levels that are <= currentZoom
          final List<double> zoomLevelsLessThanCurrent = _availableZoomLevels.where((level) => level <= _currentZoom).toList();

          // If no zoom levels are <= currentZoom, use the smallest available
          if (zoomLevelsLessThanCurrent.isEmpty) {
            zoomLevelsLessThanCurrent.add(_availableZoomLevels.reduce((a, b) => a < b ? a : b));
          }

          // Find the largest one among these
          final largestLowerZoom = zoomLevelsLessThanCurrent.reduce((a, b) => a > b ? a : b);

          // This button is selected if it equals the largest lower zoom level
          final isSelected = zoom == largestLowerZoom;

          // Format zoom text based on whether it's selected
          String zoomText;
          if (isSelected) {
            // If selected, show actual zoom value with 'x' suffix
            final actualZoom = _currentZoom.toStringAsFixed(1);
            // Remove trailing zeros (e.g., 2.0 -> 2)
            final cleanZoom = actualZoom.endsWith('.0') ? actualZoom.substring(0, actualZoom.length - 2) : actualZoom;
            zoomText = '${cleanZoom}x';
          } else {
            // For non-selected buttons, just show the number without "x" suffix
            // Remove .0 for integer values
            zoomText = zoom % 1 == 0 ? '${zoom.toInt()}' : '$zoom';
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Provide haptic feedback when zoom level is changed
                  if (widget.useHapticFeedbackOnCustomButtons) {
                    HapticFeedback.selectionClick();
                  }
                  _setZoomLevel(zoom);

                  // Show zoom ruler when zoom button is tapped
                  _showZoomRuler();
                },
                // Use a circular border radius to match design
                borderRadius: BorderRadius.circular(16),
                // Add splash color for visual feedback
                splashColor: Colors.white.withAlpha(77),
                highlightColor: Colors.white.withAlpha(26),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 150),
                  tween: Tween<double>(begin: 2.0, end: isSelected ? 0.8 : 0.8),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        // Increase padding for larger hit target
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withAlpha(26),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withAlpha(77),
                                    blurRadius: 4,
                                    spreadRadius: 0.5,
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            zoomText,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14, // Slightly larger text
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Add a method to handle pinch-to-zoom gesture
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) return;

    if (details.scale != 1.0) {
      // Calculate new zoom level based on gesture scale
      // Decrease sensitivity for more precise control
      double scaleFactor = details.scale > 1.0
          ? 1.0 + (details.scale - 1.0) * 0.8 // Zoom in: reduced sensitivity (was 2.0)
          : 1.0 / (1.0 + (1.0 - details.scale) * 0.8); // Zoom out: reduced sensitivity (was 2.0)

      double newZoom = _startZoom * scaleFactor;

      // Clamp to min/max zoom
      newZoom = newZoom.clamp(_minZoom, _maxZoom);

      // Store original zoom value to check if it changed
      final originalZoom = newZoom;

      // Implement snapping behavior for integer values - use a smaller threshold
      const double snapThreshold = 0.03; // Reduced from 0.08 to 0.03 (3% instead of 8%)
      final double fractionalPart = newZoom - newZoom.floor();
      final double distanceToNextInteger = 1.0 - fractionalPart;

      bool wasSnapped = false;

      // Check if we're close to an integer value - either the floor or ceiling
      if (fractionalPart < snapThreshold) {
        // Close to lower integer (e.g., 1.97 → 1.0)
        newZoom = newZoom.floor().toDouble();
        wasSnapped = true;

        // Only provide haptic feedback when entering the snap zone from outside
        if (!_isInPinchSnapZone) {
          HapticFeedback.selectionClick();
          _isInPinchSnapZone = true;
        }
      } else if (distanceToNextInteger < snapThreshold) {
        // Close to upper integer (e.g., 2.03 → 2.0)
        newZoom = newZoom.ceil().toDouble();
        wasSnapped = true;

        // Only provide haptic feedback when entering the snap zone from outside
        if (!_isInPinchSnapZone) {
          HapticFeedback.selectionClick();
          _isInPinchSnapZone = true;
        }
      } else {
        // We're not in a snap zone anymore
        _isInPinchSnapZone = false;
      }

      // Only update if zoom changed significantly
      if ((_currentZoom - newZoom).abs() > 0.005) {
        // More sensitive threshold
        // Check if we're crossing a zoom level for haptic feedback
        for (final zoomLevel in _availableZoomLevels) {
          if ((_currentZoom < zoomLevel && newZoom >= zoomLevel) || (_currentZoom > zoomLevel && newZoom <= zoomLevel)) {
            HapticFeedback.lightImpact();
            break;
          }
        }

        // Show zoom ruler immediately at the start of zoom gesture - call the dedicated method
        // instead of just setting the flag to ensure proper timer handling
        _showZoomRuler();

        // IMPORTANT: First update current zoom state
        // BEFORE actually changing camera zoom level
        if (mounted) {
          setState(() {
            _currentZoom = newZoom;
            _previousZoom = newZoom; // Update previous zoom
          });
        }

        // THEN update the actual camera zoom level AFTER ui update
        _controller?.setZoomLevel(newZoom);
      }
    }
  }

  // Handle end of pinch gesture
  void _handleScaleEnd(ScaleEndDetails details) {
    // Provide haptic feedback on gesture end
    HapticFeedback.selectionClick();

    // Save current zoom as the new start zoom
    _startZoom = _currentZoom;

    // Reset snap zone tracking for next pinch gesture
    _isInPinchSnapZone = false;

    // Start timer to hide zoom ruler after delay
    _zoomRulerTimer?.cancel();
    _zoomRulerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isZoomRulerVisible = false;
        });
      }
    });

    // Notify zoom change
    if (widget.onZoomChanged != null) {
      widget.onZoomChanged!(_currentZoom);
    }
  }

  void _handleControllerChanged() {
    if (!mounted || _controller == null) return;

    // Update our state based on the controller value
    // This is especially important for camera switching
    if (_controller!.value.isInitialized) {
      // Check if the front camera status has changed
      final bool isActuallyFrontCamera = _controller!.description.lensDirection == CameraLensDirection.front;

      if (_isFrontCamera != isActuallyFrontCamera) {
        debugPrint('🎥 Detected front camera change: $_isFrontCamera -> $isActuallyFrontCamera');
        setState(() {
          _isFrontCamera = isActuallyFrontCamera;
          // Adjust flash settings for front camera (usually no flash)
          if (_isFrontCamera) {
            _flashMode = FlashMode.off;
            _torchEnabled = false;
          }
        });
      }

      // Update video mode based on camera mode setting
      final isVideoOnlyMode = _controller!.settings.cameraMode == CameraMode.videoOnly;
      if (_isVideoMode != isVideoOnlyMode && isVideoOnlyMode) {
        debugPrint('🎥 Setting video mode to true based on CameraMode.videoOnly');
        setState(() {
          _isVideoMode = true;
        });
      }

      // Check if zoom level has changed from the controller (from preview pinch gesture)
      final newZoom = _controller!.value.zoomLevel;
      if (_previousZoom != newZoom) {
        debugPrint('🎥 Detected zoom change from controller: $_previousZoom -> $newZoom');

        setState(() {
          _currentZoom = newZoom;
          _previousZoom = newZoom;
        });

        // Show zoom ruler when pinch zoom happens in the preview
        _showZoomRuler();
      }

      // Also update recording state based on controller value
      final isCurrentlyRecording = _controller!.value.isRecordingVideo;
      if (_isRecording != isCurrentlyRecording) {
        debugPrint('🎥 Syncing recording state: $_isRecording -> $isCurrentlyRecording');
        setState(() {
          _isRecording = isCurrentlyRecording;

          // Set up timers if we're recording
          if (_isRecording) {
            _startRecordingTimer();
            if (_hasVideoDurationLimit && _maxVideoDuration != null) {
              _startRecordingLimitTimer();
            }
          } else {
            _stopRecordingTimer();
            _recordingLimitTimer?.cancel();
          }

          // Notify state change
          _notifyCameraStateChanged();
        });
      }
    }
  }

  void _startRecordingTimer() {
    // Reset duration and cancel any existing timer
    _recordingDuration = Duration.zero;
    _recordingTimer?.cancel();

    // Start the timer to update duration every second
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Only update if we're still recording
      if (_isRecording) {
        setState(() {
          _recordingDuration = _recordingDuration + const Duration(seconds: 1);
        });
      } else {
        // If we're no longer recording, cancel the timer
        _stopRecordingTimer();
      }
    });

    // Start video duration limit timer if needed
    if (_hasVideoDurationLimit && _maxVideoDuration != null) {
      _startRecordingLimitTimer();
    }
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingDuration = Duration.zero;
  }

  // Format duration as MM:SS or HH:MM:SS for longer recordings
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    } else if (duration.inMinutes > 0) {
      final minutes = duration.inMinutes;
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    } else {
      return '00:${duration.inSeconds.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _cycleFlashMode() async {
    if (_isVideoMode || _isFrontCamera) return;

    final modes = [FlashMode.auto, FlashMode.always, FlashMode.off];
    final nextIndex = (modes.indexOf(_flashMode) + 1) % modes.length;
    final newMode = modes[nextIndex];

    try {
      // Provide haptic feedback when flash mode is changed
      HapticFeedback.selectionClick();

      await _controller?.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
        // Notify flash mode change
        _notifyCameraStateChanged();
      });
    } catch (e) {
      widget.onError!('flash', 'Error setting flash mode: $e');
    }
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      default:
        return Icons.flash_auto;
    }
  }

  Future<void> _switchCamera() async {
    if (_controller?.cameraController == null || !_controller!.value.isInitialized) {
      // Call error callback instead of showing snackbar
      if (widget.onError != null) {
        widget.onError!('camera_switch', 'Camera not ready yet - please try again');
      }
      return;
    }

    try {
      // Provide haptic feedback when switching camera
      HapticFeedback.mediumImpact();

      // Notify that camera is switching (this could be done with a different callback if needed)
      debugPrint('🎥 Switching camera...');

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        // Call error callback instead of showing snackbar
        if (widget.onError != null) {
          widget.onError!('camera_switch', 'No cameras detected on this device');
        }
        return;
      }

      // Log available cameras
      String cameraList = '🎥 Available cameras:\n';
      for (int i = 0; i < cameras.length; i++) {
        final camera = cameras[i];
        cameraList += '• Camera $i: ${camera.name} (${camera.lensDirection})\n';
      }
      debugPrint(cameraList);

      // Log current controller state
      debugPrint('🎥 Current controller hashcode: ${_controller.hashCode}');
      debugPrint('🎥 Current native controller: ${_controller?.cameraController?.hashCode}');
      debugPrint('🎥 Current camera direction: ${_controller?.description.lensDirection}');
      debugPrint('🎥 Current _isFrontCamera: $_isFrontCamera');
      debugPrint('🎥 Current controller.value.isFrontCamera: ${_controller?.value.isFrontCamera}');

      // Remove listener from old controller to prevent callbacks during transition
      _controller?.removeListener(_handleControllerChanged);

      // Switch to the new camera
      debugPrint('🎥 Attempting to switch camera from ${_isFrontCamera ? 'front' : 'back'} to ${_isFrontCamera ? 'back' : 'front'}');
      final newController = await _controller?.switchCamera();

      if (newController == null) {
        debugPrint('🎥 No alternative camera found');
        // Re-add listener to old controller since we're keeping it
        _controller?.addListener(_handleControllerChanged);

        // Call error callback instead of showing snackbar
        if (widget.onError != null) {
          final message = cameras.length > 1 ? 'Failed to switch camera - please try again' : 'This device only has one camera';
          widget.onError!('camera_switch', message);
        }
        return;
      }

      // Log new controller state
      debugPrint('🎥 New controller received: ${newController.hashCode}');
      debugPrint('🎥 New native controller: ${newController.cameraController?.hashCode}');
      debugPrint('🎥 New camera direction: ${newController.description.lensDirection}');

      // IMPORTANT: Immediately determine if the new camera is front-facing
      final bool isNewCameraFront = newController.description.lensDirection == CameraLensDirection.front;
      debugPrint('🎥 New camera is front-facing according to lens direction: $isNewCameraFront');
      debugPrint('🎥 New controller.value.isFrontCamera: ${newController.value.isFrontCamera}');
      debugPrint('🎥 New controller initialized: ${newController.value.isInitialized}');

      // IMPORTANT: Ensure the controller's isFrontCamera value is correct
      if (newController.value.isFrontCamera != isNewCameraFront) {
        debugPrint('🎥 WARNING: Controller value does not match lens direction. Fixing...');
        newController.value = newController.value.copyWith(isFrontCamera: isNewCameraFront);
        debugPrint('🎥 Updated controller.value.isFrontCamera to: ${newController.value.isFrontCamera}');
      }

      if (mounted) {
        // Log before notifying parent
        debugPrint('🎥 Parent notification callback exists: ${widget.onControllerChanged != null}');

        // Notify the parent widget about the controller change BEFORE updating our state
        // This ensures the parent can rebuild the preview with the new controller
        if (widget.onControllerChanged != null) {
          debugPrint('🎥 Notifying parent about controller change');
          widget.onControllerChanged!(newController);
        }

        setState(() {
          // Store previous state
          final previousFlashMode = _flashMode;
          final previousTorchEnabled = _torchEnabled;

          // Update controller
          debugPrint('🎥 Updating controller reference in overlay state');
          _controller = newController;

          // IMPORTANT: Always use lens direction for determining front camera status
          _isFrontCamera = isNewCameraFront;
          debugPrint('🎥 Camera switched to ${_isFrontCamera ? 'front' : 'back'}');

          // Reset flash and torch for front camera
          if (_isFrontCamera) {
            _flashMode = FlashMode.off;
            _torchEnabled = false;
          } else {
            // Restore previous flash settings for back camera
            _flashMode = previousFlashMode;
            _torchEnabled = previousTorchEnabled;
          }

          // Apply flash mode
          if (!_isFrontCamera) {
            _controller?.setFlashMode(_flashMode);
          }

          // Set current zoom to default 1.0 upon switching
          _currentZoom = 1.0;

          // Notify camera switch
          _notifyCameraStateChanged();
        });

        // Add listener to new controller AFTER state update
        _controller?.addListener(_handleControllerChanged);

        // Initialize zoom levels for the new camera
        debugPrint('🎥 Initializing zoom levels');
        await _initializeZoomLevels();
        await _initializeValues();

        // Reset current zoom to 1.0 for consistent behavior
        debugPrint('🎥 Setting zoom level to 1.0');
        _setZoomLevel(1.0);

        // Call the onSwitchCamera callback if provided
        if (widget.onSwitchCamera != null) {
          debugPrint('🎥 Calling onSwitchCamera callback');
          widget.onSwitchCamera!();
        }

        // Log success instead of showing snackbar
        debugPrint('🎥 Switched to ${_isFrontCamera ? 'front' : 'back'} camera');
      }
    } catch (e) {
      debugPrint('🎥 Error switching camera: $e');
      // Make sure we re-add the listener if there was an error
      // Instead of checking hasListeners directly, we'll just try to add the listener
      // The addListener method is safe to call multiple times
      if (_controller != null) {
        _controller!.addListener(_handleControllerChanged);
      }

      // Call error callback instead of showing snackbar
      if (widget.onError != null) {
        widget.onError!('camera_switch', 'Failed to switch camera: ${e.toString().split('\n').first}');
      }
    }
  }

  Future<void> _handleCapture() async {
    // Verify controller is available and initialized before proceeding
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('📹 Cannot capture: Camera controller is null or not initialized');
      if (widget.onError != null) {
        widget.onError!('capture', 'Camera not ready yet - please try again');
      }
      return;
    }

    // Provide haptic feedback when capture button is pressed
    HapticFeedback.mediumImpact();

    if (_isVideoMode) {
      await _toggleRecording();
    } else {
      await _takePicture();
    }
  }

  Future<void> _toggleRecording() async {
    // Double-check controller is available
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('📹 Cannot toggle recording: Camera controller is null or not initialized');
      if (widget.onError != null) {
        widget.onError!('recording', 'Camera not ready yet - please try again');
      }
      return;
    }

    try {
      if (_isRecording) {
        // Immediately update UI to stop the timer display
        setState(() {
          _isRecording = false;
          _recordingDuration = Duration.zero;
          _isProcessingVideo = true; // Set processing state to show loading indicator
        });

        // Let the controller handle the actual recording stop
        await _controller?.stopVideoRecording().then((file) {
          // File processing is complete
          if (mounted) {
            setState(() {
              _isProcessingVideo = false; // Clear processing state
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _isProcessingVideo = false; // Clear processing state on error too
            });
          }
          debugPrint('📹 Error stopping recording: $error');
          if (widget.onError != null) {
            widget.onError!('recording', 'Failed to stop recording: $error');
          }
        });

        // Turn off torch after stopping recording if it was enabled
        if (_torchEnabled && !_isFrontCamera) {
          debugPrint('📹 Turning off torch after stopping recording');
          await _controller?.setFlashMode(FlashMode.off);
          setState(() {
            _torchEnabled = false;
            // Notify torch state change
            _notifyCameraStateChanged();
          });
        }
      } else {
        // Ensure we maintain torch state when starting recording
        final currentTorchState = _torchEnabled;

        // Don't manually set _isRecording = true here, let the controller handle it
        // The controller will notify us through _handleControllerUpdate
        await _controller?.startVideoRecording();

        // Now start the duration limit timer if needed
        if (_hasVideoDurationLimit && _maxVideoDuration != null) {
          debugPrint('📹 Starting recording limit timer after video started');
          _startRecordingLimitTimer();
        }

        // If torch was on, make sure it stays on during recording
        if (currentTorchState && !_isFrontCamera) {
          await _controller?.setFlashMode(FlashMode.torch);
        }
      }
    } catch (e) {
      // Clear processing state on any error
      if (mounted) {
        setState(() {
          _isProcessingVideo = false;
        });
      }

      debugPrint('📹 Error toggling recording: $e');
      if (widget.onError != null) {
        widget.onError!('recording', 'Failed to ${_isRecording ? 'stop' : 'start'} recording: $e');
      }
    }
  }

  Future<void> _takePicture() async {
    // Double-check controller is available
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('📹 Cannot take picture: Camera controller is null or not initialized');
      if (widget.onError != null) {
        widget.onError!('capture', 'Camera not ready yet - please try again');
      }
      return;
    }

    try {
      // Ensure flash mode is set correctly before taking the picture
      if (!_isFrontCamera) {
        await _controller?.setFlashMode(_flashMode);
      }

      await _controller?.takePicture();
    } catch (e) {
      // Call error callback if provided
      if (widget.onError != null) {
        widget.onError!('capture', 'Error: $e');
      }
    }
  }

  /// Open the image picker to select media from the device
  Future<void> _openMediaGallery() async {
    if (widget.controller == null) return;
    if (_isRecording) {
      debugPrint('📹 Cannot open gallery while recording');
      return;
    }

    // Prevent starting if already active
    if (_isFilePickerActive) {
      debugPrint('📹 Media picker already active');
      return;
    }

    final controller = widget.controller!;
    final startTime = DateTime.now();

    // Save current orientation before opening gallery
    _savedGalleryOrientation = controller.value.deviceOrientation;
    debugPrint('📸 Saving orientation before opening system file picker: $_savedGalleryOrientation');

    // Set file picker as active before starting
    setState(() {
      _isFilePickerActive = true;
    });

    try {
      // If video-only mode, only show video picker
      if (controller.settings.cameraMode == CameraMode.videoOnly) {
        final XFile? video = await _imagePicker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: _maxVideoDuration,
        );

        // If no video selected, clear active state and return
        if (video == null) {
          if (mounted) {
            setState(() {
              _isFilePickerActive = false;
            });
          }

          // Restore orientation when returning without selection
          _restoreOrientationAfterFilePicker();
          return;
        }

        // Video selected, provide feedback
        HapticFeedback.mediumImpact();

        // Now that we're actually processing the video, show the processing indicator
        if (mounted) {
          setState(() {
            _isProcessingVideo = true; // Show processing indicator during video compression
          });
        }

        // Process the video with compression (loading state stays active)
        final processedVideo = await controller.processMediaFile(video, true);
        controller.mediaManager.addMedia(processedVideo, isVideo: true);

        // Ensure the loading state is visible for a minimum time
        final processingDuration = DateTime.now().difference(startTime);
        if (processingDuration.inMilliseconds < 1000) {
          final remainingTime = 1000 - processingDuration.inMilliseconds;
          debugPrint('📹 Adding ${remainingTime}ms delay to ensure visible loading state for video');
          await Future.delayed(Duration(milliseconds: remainingTime));
        }

        // Clear active state once processed
        if (mounted) {
          setState(() {
            _isFilePickerActive = false;
            _isProcessingVideo = false; // Clear processing indicator
          });
        }

        // Restore orientation after file picker returns
        _restoreOrientationAfterFilePicker();
        return;
      }

      // Photo-only mode - only allow photos to be selected
      if (controller.settings.cameraMode == CameraMode.photoOnly) {
        if (widget.multiImageSelect) {
          // Use pickMultiImage specifically (not pickMultipleMedia) to only allow photos
          final List<XFile> images = await _imagePicker.pickMultiImage();

          // If no images selected, clear active state and return
          if (images.isEmpty) {
            if (mounted) {
              setState(() {
                _isFilePickerActive = false;
              });
            }

            // Restore orientation when returning without selection
            _restoreOrientationAfterFilePicker();
            return;
          }

          // Images selected, provide feedback
          HapticFeedback.mediumImpact();

          // Now that we're processing files, show the processing indicator
          if (mounted) {
            setState(() {
              _isProcessingVideo = true; // Use same processing indicator for consistency
            });
          }

          // Process each image (all are guaranteed to be photos)
          for (final image in images) {
            final processedFile = await controller.processMediaFile(image, false);
            controller.mediaManager.addMedia(processedFile, isVideo: false);
          }

          // Ensure a consistent minimum loading time
          final processingDuration = DateTime.now().difference(startTime);
          if (processingDuration.inMilliseconds < 800) {
            final remainingTime = 800 - processingDuration.inMilliseconds;
            debugPrint('📸 Adding ${remainingTime}ms delay to ensure visible loading state for multiple images');
            await Future.delayed(Duration(milliseconds: remainingTime));
          }
        } else {
          // Single image selection
          final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);

          // If no image selected, clear active state and return
          if (image == null) {
            if (mounted) {
              setState(() {
                _isFilePickerActive = false;
              });
            }

            // Restore orientation when returning without selection
            _restoreOrientationAfterFilePicker();
            return;
          }

          // Image selected, provide feedback
          HapticFeedback.mediumImpact();

          // Now that we're processing the image, switch to processing indicator
          if (mounted) {
            setState(() {
              _isProcessingVideo = true; // Use same processing indicator for images
            });
          }

          // Process the image with compression
          final processedImage = await controller.processMediaFile(image, false);
          controller.mediaManager.addMedia(processedImage, isVideo: false);

          // Ensure the loading state is visible for a minimum time
          final processingDuration = DateTime.now().difference(startTime);
          if (processingDuration.inMilliseconds < 800) {
            final remainingTime = 800 - processingDuration.inMilliseconds;
            debugPrint('📸 Adding ${remainingTime}ms delay to ensure visible loading state for image');
            await Future.delayed(Duration(milliseconds: remainingTime));
          }
        }
      }
      // Combined photo and video mode - allow both media types
      else {
        if (widget.multiImageSelect) {
          final List<XFile> media = await _imagePicker.pickMultipleMedia();

          // If no media selected, clear active state and return
          if (media.isEmpty) {
            if (mounted) {
              setState(() {
                _isFilePickerActive = false;
              });
            }

            // Restore orientation when returning without selection
            _restoreOrientationAfterFilePicker();
            return;
          }

          // Media selected, provide feedback
          HapticFeedback.mediumImpact();

          // Now that we're processing files, show the processing indicator
          if (mounted) {
            setState(() {
              _isProcessingVideo = true; // Use same processing indicator for consistency
            });
          }

          // Process each media file with appropriate handling
          for (final file in media) {
            // Determine if this is a video based on file extension
            final isVideo = file.path.toLowerCase().endsWith('.mp4') || file.path.toLowerCase().endsWith('.mov') || file.path.toLowerCase().endsWith('.avi');

            // Process the media file with appropriate compression
            final processedFile = await controller.processMediaFile(file, isVideo);
            controller.mediaManager.addMedia(processedFile, isVideo: isVideo);
          }

          // Ensure a consistent minimum loading time
          final processingDuration = DateTime.now().difference(startTime);
          if (processingDuration.inMilliseconds < 800) {
            final remainingTime = 800 - processingDuration.inMilliseconds;
            debugPrint('📹 Adding ${remainingTime}ms delay to ensure visible loading state for multiple files');
            await Future.delayed(Duration(milliseconds: remainingTime));
          }
        } else {
          // Single media selection - ask user what they want to pick
          final mediaType = await _showMediaPickerDialog();
          if (mediaType == null) {
            if (mounted) {
              setState(() {
                _isFilePickerActive = false;
              });
            }

            // Restore orientation when returning without selection
            _restoreOrientationAfterFilePicker();
            return;
          }

          XFile? selectedFile;
          bool isVideo = false;

          if (mediaType == 'photo') {
            selectedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
            isVideo = false;
          } else {
            // video
            selectedFile = await _imagePicker.pickVideo(source: ImageSource.gallery);
            isVideo = true;
          }

          // If no file selected, clear active state and return
          if (selectedFile == null) {
            if (mounted) {
              setState(() {
                _isFilePickerActive = false;
              });
            }

            // Restore orientation when returning without selection
            _restoreOrientationAfterFilePicker();
            return;
          }

          // File selected, provide feedback
          HapticFeedback.mediumImpact();

          // Now that we're processing the file, show processing indicator
          if (mounted) {
            setState(() {
              _isProcessingVideo = true;
            });
          }

          // Process the file with appropriate compression
          final processedFile = await controller.processMediaFile(selectedFile, isVideo);
          controller.mediaManager.addMedia(processedFile, isVideo: isVideo);

          // Ensure the loading state is visible for a minimum time
          final processingDuration = DateTime.now().difference(startTime);
          final minDuration = isVideo ? 1000 : 800;
          if (processingDuration.inMilliseconds < minDuration) {
            final remainingTime = minDuration - processingDuration.inMilliseconds;
            debugPrint('📹 Adding ${remainingTime}ms delay to ensure visible loading state');
            await Future.delayed(Duration(milliseconds: remainingTime));
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking or processing media: $e');

      // Report error if callback exists
      if (widget.onError != null) {
        widget.onError!('media_picker', 'Failed to import media: $e');
      }
    } finally {
      // Always ensure we reset the active state when done
      if (mounted) {
        setState(() {
          _isFilePickerActive = false;
          _isProcessingVideo = false; // Always clear processing state
        });
      }

      // Restore orientation after file picker returns
      _restoreOrientationAfterFilePicker();
    }
  }

  /// Show a dialog asking the user whether to pick a photo or video
  Future<String?> _showMediaPickerDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Media Type'),
          content: const Text('Would you like to select a photo or video?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'photo'),
              child: const Text('Photo'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'video'),
              child: const Text('Video'),
            ),
          ],
        );
      },
    );
  }

  /// Helper method to restore orientation after returning from file picker
  Future<void> _restoreOrientationAfterFilePicker() async {
    if (_controller == null || !_controller!.value.isInitialized || _savedGalleryOrientation == null) {
      return;
    }

    debugPrint('📸 Restoring orientation after system file picker: $_savedGalleryOrientation');

    try {
      // Using the lifecycle machine is the most reliable approach
      if (_controller!.lifecycleMachine != null) {
        debugPrint('📸 Using lifecycle machine for orientation fix after file picker');
        await _controller!.lifecycleMachine!.handleOrientationChange(_savedGalleryOrientation!, priority: true);
        debugPrint('📸 Lifecycle orientation fix completed after file picker');
        return;
      }

      // Fallback to direct orientation setting if lifecycle machine not available
      await _controller!.setDeviceOrientation(_savedGalleryOrientation!);

      // Add a delayed check with a different approach for stubborn cases
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (_controller != null && _controller!.value.isInitialized && mounted) {
          try {
            // Check if orientation is still incorrect after the first fix
            if (_controller!.value.deviceOrientation != _savedGalleryOrientation) {
              debugPrint('📸 Orientation still incorrect after file picker, trying alternative fix');

              // Try to "jolt" the camera orientation with two quick changes
              if (Platform.isAndroid && _controller!.cameraController != null) {
                // First set the opposite orientation momentarily
                final oppositeOrientation = _getOppositeOrientation(_savedGalleryOrientation!);
                await _controller!.cameraController!.lockCaptureOrientation(oppositeOrientation);
                await Future.delayed(const Duration(milliseconds: 100));

                // Then set back to the desired orientation
                await _controller!.cameraController!.lockCaptureOrientation(_savedGalleryOrientation!);
                debugPrint('📸 Applied orientation jolt fix after file picker');
              }
            }
          } catch (e) {
            debugPrint('📸 Error in delayed orientation fix: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('📸 Error restoring orientation after file picker: $e');
    }
  }

  /// Helper to get the opposite orientation
  DeviceOrientation _getOppositeOrientation(DeviceOrientation orientation) {
    switch (orientation) {
      case DeviceOrientation.portraitUp:
        return DeviceOrientation.portraitDown;
      case DeviceOrientation.portraitDown:
        return DeviceOrientation.portraitUp;
      case DeviceOrientation.landscapeLeft:
        return DeviceOrientation.landscapeRight;
      case DeviceOrientation.landscapeRight:
        return DeviceOrientation.landscapeLeft;
    }
  }

  /// Open the custom gallery to view captured media
  Future<void> _openCustomGallery() async {
    // Don't open gallery when recording
    if (_isRecording) {
      debugPrint('📹 Cannot open gallery while recording');
      return;
    }

    final mediaManager = widget.controller?.mediaManager;
    if (mediaManager == null || mediaManager.count == 0) {
      debugPrint('📸 No media available to show in gallery');
      return;
    }

    // Track when gallery is active to prevent double-taps
    setState(() {
      _isFilePickerActive = true;
    });

    try {
      // Make sure we're saving the current device orientation before pausing
      if (_controller != null && _controller!.value.isInitialized) {
        _savedGalleryOrientation = _controller!.value.deviceOrientation;
        debugPrint('📸 Saving orientation before gallery: $_savedGalleryOrientation');
      }

      // Pause camera before showing gallery
      debugPrint('🎥 Pausing camera before opening gallery');
      _pauseCamera();

      // Use Navigator.push to get a Future we can act on when gallery is closed
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CameralyGalleryView(
            mediaManager: mediaManager,
            onDelete: (file) => mediaManager.removeMedia(file),
            backgroundColor: Colors.black,
            appBarColor: Colors.black,
          ),
        ),
      );

      // Important: Resume camera immediately after returning from gallery
      debugPrint('🎥 Returning from gallery - resuming camera');
      _returningFromGallery = true;
      await _resumeCamera();
    } catch (e) {
      debugPrint('📸 Error during gallery navigation: $e');
    } finally {
      // Always reset the flag when done with gallery
      if (mounted) {
        setState(() {
          _isFilePickerActive = false;
        });
      }
    }
  }

  Widget buildCenterArea({required bool isLandscape, required CameralyOverlayTheme theme}) {
    Widget buildMediaStack() {
      final mediaManager = widget.controller?.mediaManager;
      if (mediaManager == null) {
        return const SizedBox.shrink();
      }
      return Opacity(
        opacity: _isRecording ? 0.5 : 1.0, // Reduce opacity when recording
        child: CameralyMediaStack(
          mediaManager: mediaManager,
          onTap: _isRecording ? null : _openCustomGallery, // Disable tap when recording
          itemSize: 60,
          maxDisplayItems: 5,
        ),
      );
    }

    Widget buildPlaceholder() {
      return Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, 0.7), borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text('Center Left', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Only show media stack if not recording or explicitly force-showing placehoders
        if ((widget.centerLeftWidget != null) || (widget.showMediaStack && !_isRecording) || widget.showPlaceholders)
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Container(
              child: widget.centerLeftWidget != null
                  ? widget.centerLeftWidget!
                  : widget.showMediaStack && widget.controller?.mediaManager != null
                      ? AnimatedBuilder(animation: widget.controller!.mediaManager, builder: (context, _) => buildMediaStack())
                      : buildPlaceholder(),
            ),
          ),
      ],
    );
  }

  /// Notifies the parent widget about camera state changes.
  void _notifyCameraStateChanged() {
    if (widget.onCameraStateChanged != null) {
      final state = CameralyOverlayState(
        isRecording: _isRecording,
        isVideoMode: _isVideoMode,
        isFrontCamera: _isFrontCamera,
        flashMode: _flashMode,
        torchEnabled: _torchEnabled,
        recordingDuration: _recordingDuration,
        isFilePickerActive: _isFilePickerActive,
      );
      widget.onCameraStateChanged!(state);
    }
  }

  void _startRecordingLimitTimer() {
    if (!_hasVideoDurationLimit || _maxVideoDuration == null) {
      debugPrint('📹 No video duration limit set, not starting timer');
      return;
    }

    debugPrint('📹 Starting recording limit timer: $_maxVideoDuration');

    _recordingLimitTimer?.cancel();
    _recordingLimitTimer = Timer(_maxVideoDuration!, () async {
      debugPrint('📹 Max recording duration reached, stopping recording');

      // Provide haptic feedback when max duration is reached
      HapticFeedback.heavyImpact();

      // Immediately update the UI state to show recording has stopped
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
        _isProcessingVideo = true; // Show processing state
      });

      try {
        // Make sure we have a controller
        if (_controller != null) {
          final videoFile = await _controller!.stopVideoRecording();
          debugPrint('📹 Recording stopped successfully after reaching duration limit');

          // Make sure orientation is unlocked
          _controller?.lifecycleMachine?.unlockOrientationAfterRecording();

          // Call onCapture callback if provided
          if (widget.onCapture != null) {
            widget.onCapture!(videoFile);
          }

          // Also call onMaxDurationReached if provided
          if (widget.onMaxDurationReached != null) {
            widget.onMaxDurationReached!();
          }

          // Clear processing state
          if (mounted) {
            setState(() {
              _isProcessingVideo = false;
            });
          }
        }
      } catch (e) {
        debugPrint('📹 Error stopping recording on duration limit: $e');

        // Make sure orientation is unlocked even if there was an error
        _controller?.lifecycleMachine?.unlockOrientationAfterRecording();

        // If error handler is provided, call it
        if (widget.onError != null) {
          widget.onError!('recording_limit', 'Failed to stop recording after reaching duration limit', error: e);
        }

        // Clear processing state on error too
        if (mounted) {
          setState(() {
            _isProcessingVideo = false;
          });
        }
      } finally {
        // Cancel any active recording timers
        _recordingTimer?.cancel();
        _recordingTimer = null;
        _recordingLimitTimer?.cancel();
        _recordingLimitTimer = null;
      }
    });
  }

  /// Updates the state of UI buttons based on current camera state
  void _updateButtonStates() {
    if (_controller == null || !mounted) return;

    // Update flash button state
    _updateFlashButtonState();

    // Update recording indicator if needed
    if (_controller!.value.isRecordingVideo != _isRecording) {
      setState(() {
        _isRecording = _controller!.value.isRecordingVideo;
      });
    }

    // Update video mode state if needed
    final bool cameraReady = _controller!.value.isInitialized && !_controller!.value.isRecordingVideo;

    // Refresh UI state if camera is ready
    if (cameraReady) {
      // No need to check any specific condition - just ensure UI state is fresh
      setState(() {
        // This empty setState forces a UI rebuild

        // Ensure the file picker active flag is reset when camera is ready
        // This helps recover from any state where the flag might be stuck
        if (_isFilePickerActive && !_isRecording && !_isProcessingVideo) {
          _isFilePickerActive = false;
        }
      });
    }
  }

  /// Updates the flash button state based on current flash mode
  void _updateFlashButtonState() {
    if (_controller == null || !mounted) return;

    // Update flash mode from controller if needed
    if (_controller!.value.flashMode != _flashMode) {
      setState(() {
        _flashMode = _controller!.value.flashMode;
        _torchEnabled = _flashMode == FlashMode.torch;
      });
    }
  }

  /// Shows the zoom ruler temporarily and schedules it to hide after a delay
  void _showZoomRuler() {
    if (mounted) {
      setState(() {
        _isZoomRulerVisible = true;
      });

      // Cancel any existing timer
      _zoomRulerTimer?.cancel();

      // Schedule auto-hide after 3 seconds
      _zoomRulerTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isZoomRulerVisible = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? CameralyOverlayTheme.fromContext(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Get the current overlay state for back button builder
    final overlayState = CameralyOverlayState(
      isRecording: _isRecording,
      isVideoMode: _isVideoMode,
      isFrontCamera: _isFrontCamera,
      flashMode: _flashMode,
      torchEnabled: _torchEnabled,
      recordingDuration: _recordingDuration,
      isFilePickerActive: _isFilePickerActive,
    );

    // Wrap the result with DefaultCameralyOverlayScope to expose the state
    return DefaultCameralyOverlayScope(
      state: this,
      child: Stack(
        fit: StackFit.expand,
        key: ValueKey<Orientation>(MediaQuery.of(context).orientation),
        children: [
          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: widget.backButtonBuilder != null
                    ? widget.backButtonBuilder!(context, overlayState)
                    : widget.customBackButton ??
                        CameralyOverlayButton(
                          size: 40,
                          backgroundColor: const Color.fromARGB(77, 0, 0, 0),
                          borderColor: const Color.fromARGB(179, 255, 255, 255),
                          borderWidth: 1.0,
                          margin: EdgeInsets.zero,
                          onTap: _isFilePickerActive ? null : () => Navigator.pop(context),
                          child: Icon(Icons.arrow_back, color: _isFilePickerActive ? Colors.white60 : Colors.white),
                        ),
              ),
            ),
          ),

          // Main layout container
          isLandscape ? buildLandscapeLayout(theme, size, padding) : buildPortraitLayout(theme, size, padding),

          // Floating recording pill at bottom
          if (_isRecording)
            Positioned(
              bottom: isLandscape ? 16 : (getBottomAreaHeight(false) + 90), // Position above the capture button in portrait
              left: 0,
              right: 0,
              child: Center(
                child: buildRecordingPill(),
              ),
            ),

          // Zoom ruler - positioned appropriately for portrait/landscape
          if (_isZoomRulerVisible && !_isRecording && widget.showZoomControls)
            Positioned(
              // In portrait: centered horizontally, above bottom controls
              // In landscape: centered horizontally, below top controls
              left: 0,
              right: 0,
              top: isLandscape ? MediaQuery.of(context).padding.top + 80 : null,
              bottom: isLandscape ? null : getBottomAreaHeight(false) + 140,
              child: Center(
                child: ZoomRulerWidget(
                  currentZoom: _currentZoom,
                  minZoom: _minZoom,
                  maxZoom: _maxZoom,
                  availableZoomLevels: _availableZoomLevels,
                  onZoomChanged: (zoom) {
                    _setZoomLevel(zoom);
                    if (widget.onZoomChanged != null) {
                      widget.onZoomChanged!(zoom);
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // New floating pill indicator for recording
  Widget buildRecordingPill() {
    final isNearEnd = _hasVideoDurationLimit && _maxVideoDuration != null && _recordingDuration.inMilliseconds / _maxVideoDuration!.inMilliseconds > 0.8;

    // Calculate remaining time as a formatted string
    final String remainingTime = _hasVideoDurationLimit && _maxVideoDuration != null ? _formatDuration(_maxVideoDuration! - _recordingDuration) : '';

    // Different colors/effects based on how close to the limit we are
    Color pillColor = Colors.black.withAlpha(179);
    Color borderColor = Colors.white.withAlpha(51);
    Color textColor = Colors.white;

    if (_hasVideoDurationLimit && _maxVideoDuration != null) {
      final progress = _recordingDuration.inMilliseconds / _maxVideoDuration!.inMilliseconds;
      if (progress > 0.9) {
        pillColor = Colors.red.withAlpha(204); // equivalent to opacity 0.8
        borderColor = Colors.red;
        textColor = Colors.white;
      } else if (progress > 0.75) {
        pillColor = Colors.orange.withAlpha(179);
        borderColor = Colors.orange.withAlpha(204); // equivalent to opacity 0.8
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: isNearEnd ? Colors.red.withAlpha(77) : Colors.black.withAlpha(77),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated recording indicator
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.8, end: 1.3),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isNearEnd ? Colors.white : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isNearEnd ? Colors.white : Colors.red).withAlpha(153),
                      blurRadius: value * 4,
                      spreadRadius: value,
                    ),
                  ],
                ),
              );
            },
            onEnd: () {
              setState(() {}); // Restart animation
            },
          ),
          const SizedBox(width: 8),

          // Time display
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current time
              Text(
                _formatDuration(_recordingDuration),
                style: TextStyle(
                  color: textColor.withAlpha(204), // equivalent to opacity 0.8
                  fontSize: 14,
                  fontFamily: 'monospace',
                  letterSpacing: isNearEnd ? 0.8 : 0.5,
                ),
              ),

              // Max duration
              if (_hasVideoDurationLimit && _maxVideoDuration != null)
                Text(
                  ' / ${_formatDuration(_maxVideoDuration!)}',
                  style: TextStyle(
                    color: textColor.withAlpha(153), // equivalent to opacity 0.6
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),

          // Show remaining time prominently when near end
          if (isNearEnd && _hasVideoDurationLimit)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                remainingTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Show tap to stop hint
          const SizedBox(width: 8),
          const Icon(
            Icons.stop_circle_outlined,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }

  // New animated capture button
  Widget buildAnimatedCaptureButton({bool isLandscape = false, bool isWideScreen = false}) {
    final double size = isLandscape ? (isWideScreen ? 100 : 80) : 90;
    final double innerSize = isLandscape ? (isWideScreen ? 80 : 64) : 70;

    // Get theme-appropriate colors
    final ThemeData theme = Theme.of(context);
    final Color processingColor = theme.colorScheme.primary; // Use primary color for processing
    const Color importingColor = Colors.white; // Keep white for importing/file picking

    // Show a loading indicator when file picker is active or video is processing
    if (_isFilePickerActive || _isProcessingVideo) {
      return Stack(
        children: [
          // Pulsing loading indicator
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  height: size,
                  width: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isProcessingVideo
                          ? processingColor.withAlpha((0.5 * value * 255).round()) // Theme color for processing
                          : importingColor.withAlpha((0.5 * value * 255).round()), // White for file picker
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isProcessingVideo
                            ? processingColor.withAlpha((0.2 * value * 255).round()) // Theme color for processing
                            : importingColor.withAlpha((0.2 * value * 255).round()), // White for file picker
                        blurRadius: 8 * value,
                        spreadRadius: 2 * value,
                      ),
                    ],
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: innerSize * 0.7,
                      height: innerSize * 0.7,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_isProcessingVideo ? processingColor : importingColor),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
              );
            },
            onEnd: () {
              if (mounted) setState(() {}); // Restart animation
            },
          ),

          // Status text
          Positioned(
            bottom: -20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isProcessingVideo ? 'Saving...' : '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Ensure the button is always responsive even during camera transitions
    return GestureDetector(
      onTap: () {
        // Verify controller is available before proceeding
        if (_controller == null || !_controller!.value.isInitialized) {
          debugPrint('📹 Cannot capture: Camera controller is null or not initialized');
          if (widget.onError != null) {
            widget.onError!('capture', 'Camera not ready yet - please try again');
          }
          return;
        }
        _handleCapture();
      },
      child: _isRecording
          ? buildRecordingCaptureButton(size: size)
          : Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
                color: Colors.transparent,
              ),
              child: Center(
                child: Container(
                  width: innerSize,
                  height: innerSize,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
    );
  }

  // Recording state capture button with pulse effect
  Widget buildRecordingCaptureButton({required double size}) {
    // For recording state, show square stop button with pulsing effect
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 1.08),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        // Use scale effect only for the outer ring
        return Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.red.withAlpha((value * 0.8 * 255).round()), // Pulsing opacity - dynamic value
              width: 5 * value, // Pulsing width
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withAlpha(77),
                blurRadius: 15 * value,
                spreadRadius: 2 * value,
              ),
            ],
            color: Colors.red,
          ),
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation
        setState(() {});
      },
    );
  }

  Future<void> toggleTorch() async {
    try {
      // Provide haptic feedback when torch is toggled
      HapticFeedback.selectionClick();

      final newTorchState = !_torchEnabled;
      await _controller?.setFlashMode(newTorchState ? FlashMode.torch : FlashMode.off);
      setState(() {
        _torchEnabled = newTorchState;
        // Notify torch state change
        _notifyCameraStateChanged();
      });
    } catch (e) {
      // Call error callback instead of showing snackbar
      if (widget.onError != null) {
        widget.onError!('torch', 'Error toggling torch: $e');
      }
    }
  }

  Widget buildPortraitLayout(CameralyOverlayTheme theme, Size size, EdgeInsets padding) {
    return Stack(
      children: [
        // Top area
        buildTopArea(isLandscape: false),

        // Center area with proper positioning
        Positioned(top: 0, left: 0, right: 0, bottom: widget.bottomOverlayWidget != null ? 100 : 0, child: buildCenterArea(isLandscape: false, theme: theme)),

        // Bottom overlay widget - positioned above the gradient
        if (widget.bottomOverlayWidget != null || widget.showPlaceholders)
          Positioned(
            left: 20,
            right: 20,
            bottom: getBottomAreaHeight(false) + 20,
            child: widget.bottomOverlayWidget ??
                Container(
                  width: 200,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(156, 39, 176, 0.7), // Purple
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('Bottom Overlay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ),
          ),

        // Bottom area with gradient
        Positioned(left: 0, right: 0, bottom: 0, child: buildBottomArea(isLandscape: false, theme: theme)),
      ],
    );
  }

  Widget buildLandscapeLayout(CameralyOverlayTheme theme, Size size, EdgeInsets padding) {
    const leftAreaWidth = 80.0; // Width of the left area
    const rightAreaWidth = 120.0; // Width of the right area

    return Stack(
      children: [
        // Left area (top area in portrait)
        Positioned(top: 0, left: 80, bottom: 0, width: leftAreaWidth, child: buildTopArea(isLandscape: true)),

        // Center area with proper positioning
        Positioned(top: 0, left: leftAreaWidth + 80, right: rightAreaWidth, bottom: 0, child: buildCenterArea(isLandscape: true, theme: theme)),

        // Right area with controls (equivalent to bottom in portrait)
        Positioned(top: 0, right: 0, bottom: 0, width: rightAreaWidth, child: buildBottomArea(isLandscape: true, theme: theme)),

        // Zoom level buttons - Positioned at the top with proper padding and hit testing area
        if (widget.showZoomControls && _availableZoomLevels.length > 1)
          Positioned(top: MediaQuery.of(context).padding.top + 16, left: leftAreaWidth + 80, right: rightAreaWidth, child: Center(child: Material(color: Colors.transparent, child: _buildZoomLevelButtons()))),

        // Bottom overlay widget - positioned at the bottom of center area in landscape
        if (widget.bottomOverlayWidget != null || widget.showPlaceholders)
          Positioned(
            left: leftAreaWidth + 20,
            right: rightAreaWidth + 20,
            bottom: 20,
            child: widget.bottomOverlayWidget ??
                Container(
                  width: 200,
                  height: 60,
                  decoration: BoxDecoration(color: const Color.fromRGBO(33, 150, 243, 0.7), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('Bottom Overlay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                ),
          ),
      ],
    );
  }

  // Helper method to calculate the height of the bottom area
  double getBottomAreaHeight(bool isLandscape) {
    if (isLandscape) {
      return 0; // Not needed for landscape
    } else {
      // Calculate based on content
      double height = 90; // Base height for capture button
      if (!_isRecording && _controller?.settings.cameraMode == CameraMode.both) {
        height += 60; // Add height for mode toggle
      }
      return height + MediaQuery.of(context).padding.bottom + 40; // Add padding and extra space
    }
  }

  Widget buildTopArea({required bool isLandscape}) {
    // Note: We removed the unused state object

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(top: isLandscape ? 0 : MediaQuery.of(context).padding.top, left: 16, right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: isLandscape ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            SizedBox(height: isLandscape ? 16 : MediaQuery.of(context).padding.top + 16),

            // Top left widget
            if (!isLandscape && (widget.topLeftWidget != null || widget.showPlaceholders))
              Align(
                alignment: Alignment.topLeft,
                child: widget.topLeftWidget ??
                    Container(
                      width: 120,
                      height: 60,
                      decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, 0.7), borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('Top Left', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
              ),

            // Flash button (for photo mode)
            if (widget.showFlashButton && !_isVideoMode && !_isFrontCamera && _controller?.value.hasFlashCapability == true)
              Align(alignment: isLandscape ? Alignment.centerLeft : Alignment.topRight, child: CameralyOverlayButton(onTap: _cycleFlashMode, child: Icon(_getFlashIcon(), color: _flashMode == FlashMode.off ? Colors.white60 : Colors.white))),

            // Torch button (for video mode)
            if (widget.showFlashButton && _isVideoMode && !_isFrontCamera && _controller?.value.hasFlashCapability == true)
              Align(
                alignment: isLandscape ? Alignment.centerLeft : Alignment.topRight,
                child: CameralyOverlayButton(onTap: toggleTorch, child: Icon(_torchEnabled ? Icons.flashlight_on : Icons.flashlight_off, color: _torchEnabled ? Colors.white : Colors.white60)),
              ),

            // Gallery button (shown in top area when customLeftButton or customLeftButtonBuilder is provided)
            if (widget.showGalleryButton && (widget.customLeftButton != null || widget.customLeftButtonBuilder != null))
              Align(
                alignment: isLandscape ? Alignment.centerLeft : Alignment.topRight,
                child: CameralyOverlayButton(onTap: (_isRecording || _isFilePickerActive) ? null : _openMediaGallery, child: Icon(Icons.photo_library, color: (_isRecording || _isFilePickerActive) ? Colors.white60 : Colors.white, size: 28)),
              ),

            // Camera switch button (shown in top area when customRightButton or customRightButtonBuilder is provided)
            if (widget.showSwitchCameraButton && (widget.customRightButton != null || widget.customRightButtonBuilder != null) && !_isRecording)
              Align(
                  alignment: isLandscape ? Alignment.centerLeft : Alignment.topRight,
                  child: CameralyOverlayButton(onTap: _isFilePickerActive ? null : _switchCamera, child: Icon(Icons.switch_camera, color: _isFilePickerActive ? Colors.white60 : Colors.white, size: 28))),
          ],
        ),
      ),
    );
  }

  Widget buildBottomArea({required bool isLandscape, required CameralyOverlayTheme theme}) {
    // This is the area with the gradient background
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    return Container(
      width: isLandscape ? 120 : double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color.fromRGBO(0, 0, 0, 0.95), Color.fromRGBO(0, 0, 0, 0.8), Color.fromRGBO(0, 0, 0, 0.5), Colors.transparent]),
        // Add a solid background color to ensure visibility
        color: Colors.black.withAlpha(77),
      ),
      child: isLandscape ? buildLandscapeControls(isWideScreen) : buildPortraitControls(),
    );
  }

  Widget buildPortraitControls() {
    // Get the current overlay state for button builders
    final overlayState = CameralyOverlayState(
      isRecording: _isRecording,
      isVideoMode: _isVideoMode,
      isFrontCamera: _isFrontCamera,
      flashMode: _flashMode,
      torchEnabled: _torchEnabled,
      recordingDuration: _recordingDuration,
      isFilePickerActive: _isFilePickerActive,
    );

    // Determine if buttons should be hidden (during file picking or media processing)
    final bool hideButtons = _isFilePickerActive || _isProcessingVideo;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom level buttons - Added here above the capture controls
          if (widget.showZoomControls && _availableZoomLevels.length > 1) _buildZoomLevelButtons(),

          const SizedBox(height: 16),

          // Photo/Video toggle
          if (!_isRecording && _controller?.settings.cameraMode == CameraMode.both) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: const Color.fromRGBO(0, 0, 0, 0.4), borderRadius: BorderRadius.circular(30)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: hideButtons
                          ? null
                          : () => setState(() {
                                // Provide haptic feedback when switching to photo mode
                                HapticFeedback.lightImpact();

                                _isVideoMode = false;
                                if (!_isFrontCamera) {
                                  _controller?.setFlashMode(_flashMode);
                                }
                                _torchEnabled = false;
                                _notifyCameraStateChanged();
                              }),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: !_isVideoMode ? const Color.fromRGBO(255, 255, 255, 0.3) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera, color: (hideButtons || !_isVideoMode) ? Colors.white60 : Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Photo', style: TextStyle(color: (hideButtons || !_isVideoMode) ? Colors.white60 : Colors.white, fontWeight: !_isVideoMode ? FontWeight.bold : FontWeight.normal)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: hideButtons
                          ? null
                          : () => setState(() {
                                // Provide haptic feedback when switching to video mode
                                HapticFeedback.lightImpact();

                                _isVideoMode = true;
                                _controller?.setFlashMode(FlashMode.off);
                                _torchEnabled = false;
                                _notifyCameraStateChanged();
                              }),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: _isVideoMode ? const Color.fromRGBO(255, 255, 255, 0.3) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam, color: (hideButtons || _isVideoMode) ? Colors.white60 : Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Video', style: TextStyle(color: (hideButtons || _isVideoMode) ? Colors.white60 : Colors.white, fontWeight: _isVideoMode ? FontWeight.bold : FontWeight.normal)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Camera controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center, // Ensure vertical centering
            children: [
              // Left button (Gallery or custom)
              SizedBox(
                width: 56,
                height: 56, // Match height with button size without extra padding
                child: Center(
                  // Center the button content
                  child: _isProcessingVideo || _isRecording
                      ? const SizedBox.shrink()
                      // Use the customLeftButtonBuilder if provided, otherwise fallback to customLeftButton
                      : widget.customLeftButtonBuilder != null
                          ? _isFilePickerActive
                              // If file picker is active, render a disabled version of the button
                              ? Opacity(
                                  opacity: 0.5,
                                  child: IgnorePointer(
                                    child: widget.customLeftButtonBuilder!(context, overlayState),
                                  ),
                                )
                              : widget.customLeftButtonBuilder!(context, overlayState)
                          : widget.customLeftButton != null
                              ? _isFilePickerActive
                                  ? Opacity(
                                      opacity: 0.5,
                                      child: IgnorePointer(
                                        child: widget.customLeftButton!,
                                      ),
                                    )
                                  : widget.customLeftButton!
                              : widget.showGalleryButton && widget.customLeftButton == null
                                  ? CameralyOverlayButton(
                                      onTap: (_isRecording || _isFilePickerActive) ? null : _openMediaGallery,
                                      backgroundColor: (_isRecording || _isFilePickerActive) ? const Color.fromRGBO(158, 158, 158, 0.3) : const Color.fromRGBO(0, 0, 0, 0.4),
                                      size: 56,
                                      margin: EdgeInsets.zero, // Remove the default top margin
                                      useHapticFeedback: widget.useHapticFeedbackOnCustomButtons,
                                      hapticFeedbackType: widget.customButtonHapticFeedbackType,
                                      child: Icon(Icons.photo_library, color: (_isRecording || _isFilePickerActive) ? Colors.white60 : Colors.white, size: 30),
                                    )
                                  : const SizedBox.shrink(),
                ),
              ),

              // Capture button - Enhanced with animation when recording
              if (widget.showCaptureButton) buildAnimatedCaptureButton(),

              // Right button (Camera switch or custom)
              SizedBox(
                width: 56,
                height: 56, // Match height with button size without extra padding
                child: Center(
                  // Center the button content
                  child: _isProcessingVideo || _isRecording
                      ? const SizedBox.shrink()
                      // Use the customRightButtonBuilder if provided, otherwise fallback to customRightButton
                      : widget.customRightButtonBuilder != null
                          ? _isFilePickerActive
                              ? Opacity(
                                  opacity: 0.5,
                                  child: IgnorePointer(
                                    child: widget.customRightButtonBuilder!(context, overlayState),
                                  ),
                                )
                              : widget.customRightButtonBuilder!(context, overlayState)
                          : widget.customRightButton != null
                              ? _isFilePickerActive
                                  ? Opacity(
                                      opacity: 0.5,
                                      child: IgnorePointer(
                                        child: widget.customRightButton!,
                                      ),
                                    )
                                  : widget.customRightButton!
                              : widget.showSwitchCameraButton
                                  ? Container(
                                      decoration: const BoxDecoration(color: Color.fromRGBO(0, 0, 0, 0.4), shape: BoxShape.circle),
                                      child: IconButton.filled(
                                        onPressed: _isFilePickerActive ? null : _switchCamera,
                                        icon: const Icon(Icons.switch_camera),
                                        iconSize: 30,
                                        style: IconButton.styleFrom(
                                            backgroundColor: _isFilePickerActive ? Colors.grey.withAlpha(77) : Colors.white24, foregroundColor: _isFilePickerActive ? Colors.white60 : Colors.white, padding: const EdgeInsets.all(12)),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildLandscapeControls(bool isWideScreen) {
    // Get the current overlay state for button builders
    final overlayState = CameralyOverlayState(
      isRecording: _isRecording,
      isVideoMode: _isVideoMode,
      isFrontCamera: _isFrontCamera,
      flashMode: _flashMode,
      torchEnabled: _torchEnabled,
      recordingDuration: _recordingDuration,
      isFilePickerActive: _isFilePickerActive,
    );

    // Determine if buttons should be hidden (during file picking, media processing or recording)
    final bool hideButtons = _isFilePickerActive || _isProcessingVideo || _isRecording;

    // Size for the container that will center the button content
    final double buttonSize = isWideScreen ? 64 : 56;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center, // Ensure horizontal centering
        children: [
          // Photo/Video toggle
          if (!_isRecording && _controller?.settings.cameraMode == CameraMode.both)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.black.withAlpha(102), borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: hideButtons
                        ? null
                        : () => setState(() {
                              // Provide haptic feedback when switching to photo mode
                              HapticFeedback.lightImpact();

                              _isVideoMode = false;
                              if (!_isFrontCamera) {
                                _controller?.setFlashMode(_flashMode);
                              }
                              _torchEnabled = false;
                              _notifyCameraStateChanged();
                            }),
                    style: TextButton.styleFrom(
                      foregroundColor: !_isVideoMode ? Colors.white : Colors.white60,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      disabledForegroundColor: Colors.white38,
                    ),
                    child: Text('Photo', style: TextStyle(fontSize: 12, color: hideButtons ? Colors.white38 : (!_isVideoMode ? Colors.white : Colors.white60))),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: hideButtons
                        ? null
                        : () => setState(() {
                              // Provide haptic feedback when switching to video mode
                              HapticFeedback.lightImpact();

                              _isVideoMode = true;
                              _controller?.setFlashMode(FlashMode.off);
                              _torchEnabled = false;
                              _notifyCameraStateChanged();
                            }),
                    style: TextButton.styleFrom(
                      foregroundColor: _isVideoMode ? Colors.white : Colors.white60,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      disabledForegroundColor: Colors.white38,
                    ),
                    child: Text('Video', style: TextStyle(fontSize: 12, color: hideButtons ? Colors.white38 : (_isVideoMode ? Colors.white : Colors.white60))),
                  ),
                ],
              ),
            ),

          // Capture button - Use animated version
          if (widget.showCaptureButton) buildAnimatedCaptureButton(isLandscape: true, isWideScreen: isWideScreen),

          // Spacing after capture button
          SizedBox(height: isWideScreen ? 24 : 16),

          // Left button (Gallery or custom) - Hide completely when processing or recording
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: !_isProcessingVideo && !_isRecording
                ? (widget.customLeftButtonBuilder != null
                    ? _isFilePickerActive
                        ? Opacity(
                            opacity: 0.5,
                            child: IgnorePointer(
                              child: widget.customLeftButtonBuilder!(context, overlayState),
                            ),
                          )
                        : widget.customLeftButtonBuilder!(context, overlayState)
                    : widget.customLeftButton != null
                        ? _isFilePickerActive
                            ? Opacity(
                                opacity: 0.5,
                                child: IgnorePointer(
                                  child: widget.customLeftButton!,
                                ),
                              )
                            : widget.customLeftButton!
                        : (widget.showGalleryButton
                            ? CameralyOverlayButton(
                                onTap: (_isRecording || _isFilePickerActive)
                                    ? null
                                    : () {
                                        if (!_isRecording && widget.useHapticFeedbackOnCustomButtons) {
                                          // Apply the appropriate haptic feedback type
                                          switch (widget.customButtonHapticFeedbackType) {
                                            case HapticFeedbackType.light:
                                              HapticFeedback.lightImpact();
                                              break;
                                            case HapticFeedbackType.medium:
                                              HapticFeedback.mediumImpact();
                                              break;
                                            case HapticFeedbackType.heavy:
                                              HapticFeedback.heavyImpact();
                                              break;
                                            case HapticFeedbackType.selection:
                                              HapticFeedback.selectionClick();
                                              break;
                                            case HapticFeedbackType.vibrate:
                                              HapticFeedback.vibrate();
                                              break;
                                          }
                                        }
                                        _openMediaGallery();
                                      },
                                backgroundColor: (_isRecording || _isFilePickerActive) ? const Color.fromRGBO(158, 158, 158, 0.3) : const Color.fromRGBO(0, 0, 0, 0.4),
                                size: buttonSize,
                                useHapticFeedback: widget.useHapticFeedbackOnCustomButtons,
                                hapticFeedbackType: widget.customButtonHapticFeedbackType,
                                child: Icon(Icons.photo_library, color: (_isRecording || _isFilePickerActive) ? Colors.white60 : Colors.white, size: isWideScreen ? 32 : 24),
                              )
                            : const SizedBox.shrink()))
                : const SizedBox.shrink(),
          ),

          // Spacing between buttons
          SizedBox(height: isWideScreen ? 24 : 16),

          // Right button (Camera switch or custom) - Hide completely when processing or recording
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: !_isProcessingVideo && !_isRecording
                ? (widget.customRightButtonBuilder != null
                    ? _isFilePickerActive
                        ? Opacity(
                            opacity: 0.5,
                            child: IgnorePointer(
                              child: widget.customRightButtonBuilder!(context, overlayState),
                            ),
                          )
                        : widget.customRightButtonBuilder!(context, overlayState)
                    : widget.customRightButton != null
                        ? _isFilePickerActive
                            ? Opacity(
                                opacity: 0.5,
                                child: IgnorePointer(
                                  child: widget.customRightButton!,
                                ),
                              )
                            : widget.customRightButton!
                        : (widget.showSwitchCameraButton
                            ? CameralyOverlayButton(
                                onTap: _isFilePickerActive ? null : _switchCamera,
                                backgroundColor: _isFilePickerActive ? Colors.grey.withAlpha(77) : const Color.fromRGBO(0, 0, 0, 0.4),
                                size: buttonSize,
                                useHapticFeedback: widget.useHapticFeedbackOnCustomButtons,
                                hapticFeedbackType: widget.customButtonHapticFeedbackType,
                                child: Icon(
                                  Icons.switch_camera,
                                  color: _isFilePickerActive ? Colors.white60 : Colors.white,
                                  size: isWideScreen ? 32 : 24,
                                ),
                              )
                            : const SizedBox.shrink()))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
