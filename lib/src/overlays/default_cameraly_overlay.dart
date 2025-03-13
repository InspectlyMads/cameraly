import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../cameraly_controller.dart';
import '../types/camera_mode.dart';
import '../utils/cameraly_controller_provider.dart';
import '../utils/media_manager.dart';
import 'cameraly_overlay_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(margin: margin, width: size, height: size, decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle, border: Border.all(color: borderColor, width: borderWidth)), child: child),
    );
  }
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
    this.centerLeftWidget,
    this.showCaptureButton = true,
    this.onError,
    this.multiImageSelect = true,
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

  @override
  State<DefaultCameralyOverlay> createState() => _DefaultCameralyOverlayState();

  /// Returns the [_DefaultCameralyOverlayState] from the closest [DefaultCameralyOverlay]
  /// ancestor, or null if none exists.
  ///
  /// This allows other widgets to interact with the overlay's state.
  static _DefaultCameralyOverlayState? of(BuildContext context) {
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
  ///   backgroundColor: Colors.red.withOpacity(0.7),
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
  const CameralyOverlayState({required this.isRecording, required this.isVideoMode, required this.isFrontCamera, required this.flashMode, required this.torchEnabled, required this.recordingDuration});

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

  /// Creates a copy of this state with the specified fields replaced.
  CameralyOverlayState copyWith({bool? isRecording, bool? isVideoMode, bool? isFrontCamera, FlashMode? flashMode, bool? torchEnabled, Duration? recordingDuration}) {
    return CameralyOverlayState(
      isRecording: isRecording ?? this.isRecording,
      isVideoMode: isVideoMode ?? this.isVideoMode,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      flashMode: flashMode ?? this.flashMode,
      torchEnabled: torchEnabled ?? this.torchEnabled,
      recordingDuration: recordingDuration ?? this.recordingDuration,
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
  final _DefaultCameralyOverlayState state;

  @override
  bool updateShouldNotify(DefaultCameralyOverlayScope oldWidget) {
    return state != oldWidget.state;
  }
}

class _DefaultCameralyOverlayState extends State<DefaultCameralyOverlay> with WidgetsBindingObserver {
  // Changed from late to nullable
  CameralyController? _controller;
  bool _isFrontCamera = false;
  bool _isVideoMode = false;
  bool _isRecording = false;
  FlashMode _flashMode = FlashMode.auto;
  bool _torchEnabled = false;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  List<double> _availableZoomLevels = [1.0];
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _recordingLimitTimer;
  bool _hasVideoDurationLimit = false;
  Duration? _maxVideoDuration;
  bool _hasControllerFromProvider = false;

  /// Whether to show the mode toggle button.
  /// This is determined by the camera mode - only shown when mode is [CameraMode.both].
  bool get effectiveShowModeToggle => _controller?.settings.cameraMode == CameraMode.both;

  @override
  void initState() {
    super.initState();

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // If we don't have a controller yet, try to get one from the provider
    if (_controller == null) {
      final controller = CameralyControllerProvider.of(context);
      if (controller != null) {
        _controller = controller;
        _hasControllerFromProvider = true;

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
  void dispose() {
    _controller?.removeListener(_handleControllerChanged);
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _recordingLimitTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // This will be called when the screen rotates
    if (mounted) {
      setState(() {
        // This empty setState will trigger a rebuild when the orientation changes
      });
    }
    super.didChangeMetrics();
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

  Future<void> _setZoomLevel(double zoom) async {
    try {
      await _controller?.setZoomLevel(zoom);
      setState(() {
        _currentZoom = zoom;
      });
    } catch (e) {
      debugPrint('Error setting zoom level: $e');
    }
  }

  Widget _buildZoomLevelButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _availableZoomLevels.map((zoom) {
          final isSelected = (_currentZoom - zoom).abs() < 0.1;
          final zoomText = zoom == 1.0 ? '1x' : '${zoom}x';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _setZoomLevel(zoom),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                child: Text(zoomText, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
              ),
            ),
          );
        }).toList(),
      ),
    );
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

  void _handleControllerUpdate() {
    final value = _controller?.value;

    // Update recording state based on controller's value
    if (value?.isRecordingVideo != _isRecording) {
      debugPrint('📹 Recording state changed from controller: ${value?.isRecordingVideo}');
      setState(() {
        _isRecording = value?.isRecordingVideo ?? false;

        if (_isRecording) {
          debugPrint('📹 Starting recording timer from controller update');
          _startRecordingTimer();
          // Don't start recording limit timer here, it's started in _toggleRecording()
        } else {
          debugPrint('📹 Stopping recording timer from controller update');
          _stopRecordingTimer();
          _recordingLimitTimer?.cancel();
        }

        // Notify state change
        _notifyCameraStateChanged();
      });
    }

    // Update zoom level
    if (value?.zoomLevel != _currentZoom) {
      setState(() {
        _currentZoom = value?.zoomLevel ?? 1.0;
      });
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
    }
    else if (duration.inMinutes > 0) {
      final minutes = duration.inMinutes;
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
    else {
      return '00:${duration.inSeconds.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _cycleFlashMode() async {
    if (_isVideoMode || _isFrontCamera) return;

    final modes = [FlashMode.auto, FlashMode.always, FlashMode.off];
    final nextIndex = (modes.indexOf(_flashMode) + 1) % modes.length;
    final newMode = modes[nextIndex];

    try {
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

      // Switch to the new camera
      debugPrint('🎥 Attempting to switch camera from ${_isFrontCamera ? 'front' : 'back'} to ${_isFrontCamera ? 'back' : 'front'}');
      final newController = await _controller?.switchCamera();

      if (newController == null) {
        debugPrint('🎥 No alternative camera found');
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
      // Call error callback instead of showing snackbar
      if (widget.onError != null) {
        widget.onError!('camera_switch', 'Failed to switch camera: ${e.toString().split('\n').first}');
      }
    }
  }

  Future<void> _handleCapture() async {
    if (_isVideoMode) {
      await _toggleRecording();
    } else {
      await _takePicture();
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        // Let the controller update our recording state through its value listener
        // Don't manually set _isRecording = false here
        final file = await _controller?.stopVideoRecording();

        // Only process the file if it's not null
        if (file != null) {
          // Add to the controller's media manager
          _controller?.mediaManager.addMedia(file);

          // Call the callback if provided
          if (widget.onCapture != null) {
            widget.onCapture!(file);
          }
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
      // Since we rely on the controller to update our state,
      // we need to make sure we handle errors properly
      debugPrint('📹 Recording error: $e');

      // Call error callback if provided
      if (widget.onError != null) {
        widget.onError!('capture', 'Error: $e');
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      // Ensure flash mode is set correctly before taking the picture
      if (!_isFrontCamera) {
        await _controller?.setFlashMode(_flashMode);
      }

      final file = await _controller?.takePicture();

      // Only process the file if it's not null
      if (file != null) {
        // Add to the controller's media manager
        _controller?.mediaManager.addMedia(file);

        // Call the callback if provided
        if (widget.onCapture != null) {
          widget.onCapture!(file);
        }
      }
    } catch (e) {
      // Call error callback if provided
      if (widget.onError != null) {
        widget.onError!('capture', 'Error: $e');
      }
    }
  }

  Future<void> _openMediaGallery() async {
    try {
      if (widget.multiImageSelect) {
        // Pick multiple images from device gallery
        final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();

        // Add each image to the media manager
        if (pickedFiles.isNotEmpty && widget.controller?.mediaManager != null) {
          for (final file in pickedFiles) {
            widget.controller!.mediaManager.addMedia(file);

            // Call the onCapture callback for each file if provided
            if (widget.onCapture != null) {
              widget.onCapture!(file);
            }
          }
        }
      } else {
        // Pick a single image from device gallery
        final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null && widget.controller?.mediaManager != null) {
          // Add the image to the media manager
          widget.controller!.mediaManager.addMedia(pickedFile);

          // Call the onCapture callback if provided
          if (widget.onCapture != null) {
            widget.onCapture!(pickedFile);
          }
        }
      }

      // Call the gallery tap callback if provided
      if (widget.onGalleryTap != null) {
        widget.onGalleryTap!();
      }
    } catch (e) {
      // Call error callback if provided
      if (widget.onError != null) {
        widget.onError!('gallery', 'Error opening gallery: $e', error: e, isRecoverable: true);
      }
    }
  }

  Future<void> _openCustomGallery() async {
    final mediaManager = widget.controller?.mediaManager;
    if (mediaManager == null || mediaManager.count == 0) {
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (context) => CameralyGalleryView(mediaManager: mediaManager, onDelete: (file) => mediaManager.removeMedia(file), backgroundColor: Colors.black, appBarColor: Colors.black)));
  }

  Widget _buildCenterArea({required bool isLandscape, required CameralyOverlayTheme theme}) {
    Widget buildMediaStack() {
      final mediaManager = widget.controller?.mediaManager;
      if (mediaManager == null) {
        return const SizedBox.shrink();
      }
      return CameralyMediaStack(mediaManager: mediaManager, onTap: _openCustomGallery, itemSize: 60, maxDisplayItems: 5);
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
        if (widget.centerLeftWidget != null || widget.showMediaStack || widget.showPlaceholders)
          Positioned(
            left: 16,
            top: MediaQuery.of(context).size.height / 2 - 40,
            child: widget.centerLeftWidget != null
                ? widget.centerLeftWidget!
                : widget.showMediaStack && widget.controller?.mediaManager != null
                    ? AnimatedBuilder(animation: widget.controller!.mediaManager, builder: (context, _) => buildMediaStack())
                    : buildPlaceholder(),
          ),
      ],
    );
  }

  /// Notifies the parent widget about camera state changes.
  void _notifyCameraStateChanged() {
    if (widget.onCameraStateChanged != null) {
      final state = CameralyOverlayState(isRecording: _isRecording, isVideoMode: _isVideoMode, isFrontCamera: _isFrontCamera, flashMode: _flashMode, torchEnabled: _torchEnabled, recordingDuration: _recordingDuration);
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
    _recordingLimitTimer = Timer(_maxVideoDuration!, () {
      debugPrint('📹 Max recording duration reached, stopping recording');
      if (_isRecording) {
        // Use the controller to stop recording
        // Don't manually update _isRecording here
        _controller?.stopVideoRecording().then((file) {
          debugPrint('📹 Recording stopped successfully');
          // Add to the controller's media manager
          _controller?.mediaManager.addMedia(file);

          // Call the callback if provided
          if (widget.onCapture != null) {
            widget.onCapture!(file);
          }

          if (widget.onMaxDurationReached != null) {
            widget.onMaxDurationReached!();
          }
        }).catchError((error) {
          debugPrint('📹 Error stopping recording: $error');
          if (widget.onError != null) {
            widget.onError!('capture', 'Error stopping recording: $error');
          }
        });

        // No need to manually update _isRecording
        // The controller's value change will trigger _handleControllerUpdate
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? CameralyOverlayTheme.fromContext(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

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
                    ? widget.backButtonBuilder!(
                        context, CameralyOverlayState(isRecording: _isRecording, isVideoMode: _isVideoMode, isFrontCamera: _isFrontCamera, flashMode: _flashMode, torchEnabled: _torchEnabled, recordingDuration: _recordingDuration))
                    : widget.customBackButton ??
                        CameralyOverlayButton(
                          size: 40,
                          backgroundColor: const Color.fromARGB(77, 0, 0, 0),
                          borderColor: const Color.fromARGB(179, 255, 255, 255),
                          borderWidth: 1.0,
                          margin: EdgeInsets.zero,
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
              ),
            ),
          ),

          // Main layout container
          isLandscape ? _buildLandscapeLayout(theme, size, padding) : _buildPortraitLayout(theme, size, padding),

          // Floating recording pill at bottom
          if (_isRecording)
            Positioned(
              bottom: isLandscape ? 16 : (_getBottomAreaHeight(false) + 90), // Position above the capture button in portrait
              left: 0,
              right: 0,
              child: Center(
                child: _buildRecordingPill(),
              ),
            ),
        ],
      ),
    );
  }

  // New floating pill indicator for recording
  Widget _buildRecordingPill() {
    final isNearEnd = _hasVideoDurationLimit && _maxVideoDuration != null && _recordingDuration.inMilliseconds / _maxVideoDuration!.inMilliseconds > 0.8;

    // Calculate remaining time as a formatted string
    final String remainingTime = _hasVideoDurationLimit && _maxVideoDuration != null ? _formatDuration(_maxVideoDuration! - _recordingDuration) : '';

    // Different colors/effects based on how close to the limit we are
    Color pillColor = Colors.black.withOpacity(0.7);
    Color borderColor = Colors.white.withOpacity(0.2);
    Color textColor = Colors.white;

    if (_hasVideoDurationLimit && _maxVideoDuration != null) {
      final progress = _recordingDuration.inMilliseconds / _maxVideoDuration!.inMilliseconds;
      if (progress > 0.9) {
        pillColor = Colors.red.withOpacity(0.8);
        borderColor = Colors.red;
        textColor = Colors.white;
      } else if (progress > 0.75) {
        pillColor = Colors.orange.withOpacity(0.7);
        borderColor = Colors.orange.withOpacity(0.8);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: isNearEnd ? Colors.red.withOpacity(0.3) : Colors.black.withOpacity(0.3),
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
                      color: (isNearEnd ? Colors.white : Colors.red).withOpacity(0.6),
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
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: isNearEnd ? 0.8 : 0.5,
                ),
              ),

              // Max duration
              if (_hasVideoDurationLimit && _maxVideoDuration != null)
                Text(
                  ' / ${_formatDuration(_maxVideoDuration!)}',
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
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
                color: Colors.white.withOpacity(0.2),
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
  Widget _buildAnimatedCaptureButton({bool isLandscape = false, bool isWideScreen = false}) {
    final double size = isLandscape ? (isWideScreen ? 100 : 80) : 90;
    final double innerSize = isLandscape ? (isWideScreen ? 80 : 64) : 70;

    return GestureDetector(
      onTap: _handleCapture,
      child: _isRecording
          ? _buildRecordingCaptureButton(size: size)
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
    );
  }

  // Recording state capture button with pulse effect
  Widget _buildRecordingCaptureButton({required double size}) {
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
              color: Colors.red.withOpacity(value * 0.8), // Pulsing opacity
              width: 5 * value, // Pulsing width
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
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

  Future<void> _toggleTorch() async {
    try {
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

  Widget _buildPortraitLayout(CameralyOverlayTheme theme, Size size, EdgeInsets padding) {
    return Stack(
      children: [
        // Top area
        _buildTopArea(isLandscape: false),

        // Center area with proper positioning
        Positioned(top: 0, left: 0, right: 0, bottom: widget.bottomOverlayWidget != null ? 100 : 0, child: _buildCenterArea(isLandscape: false, theme: theme)),

        // Bottom overlay widget - positioned above the gradient
        if (widget.bottomOverlayWidget != null || widget.showPlaceholders)
          Positioned(
            left: 20,
            right: 20,
            bottom: _getBottomAreaHeight(false) + 20,
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
        Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomArea(isLandscape: false, theme: theme)),
      ],
    );
  }

  Widget _buildLandscapeLayout(CameralyOverlayTheme theme, Size size, EdgeInsets padding) {
    const leftAreaWidth = 80.0; // Width of the left area
    const rightAreaWidth = 120.0; // Width of the right area

    return Stack(
      children: [
        // Left area (top area in portrait)
        Positioned(top: 0, left: 80, bottom: 0, width: leftAreaWidth, child: _buildTopArea(isLandscape: true)),

        // Center area with proper positioning
        Positioned(top: 0, left: leftAreaWidth + 80, right: rightAreaWidth, bottom: 0, child: _buildCenterArea(isLandscape: true, theme: theme)),

        // Right area with controls (equivalent to bottom in portrait)
        Positioned(top: 0, right: 0, bottom: 0, width: rightAreaWidth, child: _buildBottomArea(isLandscape: true, theme: theme)),

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
  double _getBottomAreaHeight(bool isLandscape) {
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

  Widget _buildTopArea({required bool isLandscape}) {
    return SizedBox(
      width: isLandscape ? 80 : double.infinity,
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
                child: CameralyOverlayButton(onTap: _toggleTorch, child: Icon(_torchEnabled ? Icons.flashlight_on : Icons.flashlight_off, color: _torchEnabled ? Colors.white : Colors.white60)),
              ),

            // Gallery button (shown in top area when customLeftButton is provided)
            if (widget.showGalleryButton && widget.customLeftButton != null)
              Align(
                alignment: isLandscape ? Alignment.centerLeft : Alignment.topRight,
                child: CameralyOverlayButton(onTap: _isRecording ? null : _openMediaGallery, child: Icon(Icons.photo_library, color: _isRecording ? Colors.white60 : Colors.white, size: 28)),
              ),

            // Camera switch button (shown in top area when customRightButton is provided)
            if (widget.showSwitchCameraButton && widget.customRightButton != null)
              Align(alignment: isLandscape ? Alignment.centerLeft : Alignment.topRight, child: CameralyOverlayButton(onTap: _switchCamera, child: const Icon(Icons.switch_camera, color: Colors.white, size: 28))),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomArea({required bool isLandscape, required CameralyOverlayTheme theme}) {
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
      child: isLandscape ? _buildLandscapeControls(isWideScreen) : _buildPortraitControls(),
    );
  }

  Widget _buildPortraitControls() {
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() {
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
                            Icon(Icons.photo_camera, color: !_isVideoMode ? Colors.white : Colors.white60, size: 20),
                            const SizedBox(width: 8),
                            Text('Photo', style: TextStyle(color: !_isVideoMode ? Colors.white : Colors.white60, fontWeight: !_isVideoMode ? FontWeight.bold : FontWeight.normal)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() {
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
                            Icon(Icons.videocam, color: _isVideoMode ? Colors.white : Colors.white60, size: 20),
                            const SizedBox(width: 8),
                            Text('Video', style: TextStyle(color: _isVideoMode ? Colors.white : Colors.white60, fontWeight: _isVideoMode ? FontWeight.bold : FontWeight.normal)),
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
            children: [
              // Left button (Gallery or custom)
              SizedBox(
                width: 56,
                height: 73, // 56 + 17 padding for consistent height
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, // Align to top
                  children: [
                    widget.customLeftButton != null
                        ? widget.customLeftButton!
                        : widget.showGalleryButton && widget.customLeftButton == null
                            ? CameralyOverlayButton(
                                onTap: _isRecording ? null : _openMediaGallery,
                                backgroundColor: _isRecording ? const Color.fromRGBO(158, 158, 158, 0.3) : const Color.fromRGBO(0, 0, 0, 0.4),
                                size: 56,
                                margin: EdgeInsets.zero, // Remove the default top margin
                                child: Icon(Icons.photo_library, color: _isRecording ? Colors.white60 : Colors.white, size: 30),
                              )
                            : const SizedBox.shrink(),
                  ],
                ),
              ),

              // Capture button - Enhanced with animation when recording
              if (widget.showCaptureButton) _buildAnimatedCaptureButton(),

              // Right button (Camera switch or custom)
              SizedBox(
                width: 56,
                height: 73, // 56 + 17 padding for consistent height
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, // Align to top
                  children: [
                    widget.customRightButton != null
                        ? widget.customRightButton!
                        : widget.showSwitchCameraButton
                            ? Container(
                                decoration: const BoxDecoration(color: Color.fromRGBO(0, 0, 0, 0.4), shape: BoxShape.circle),
                                child: IconButton.filled(
                                  onPressed: _switchCamera,
                                  icon: const Icon(Icons.switch_camera),
                                  iconSize: 30,
                                  style: IconButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white, padding: const EdgeInsets.all(12)),
                                ),
                              )
                            : const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLandscapeControls(bool isWideScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
                    onPressed: () => setState(() {
                      _isVideoMode = false;
                      if (!_isFrontCamera) {
                        _controller?.setFlashMode(_flashMode);
                      }
                      _torchEnabled = false;
                      _notifyCameraStateChanged();
                    }),
                    style: TextButton.styleFrom(foregroundColor: !_isVideoMode ? Colors.white : Colors.white60, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Photo', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => setState(() {
                      _isVideoMode = true;
                      _controller?.setFlashMode(FlashMode.off);
                      _torchEnabled = false;
                      _notifyCameraStateChanged();
                    }),
                    style: TextButton.styleFrom(foregroundColor: _isVideoMode ? Colors.white : Colors.white60, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Video', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Capture button - Use animated version
          if (widget.showCaptureButton) _buildAnimatedCaptureButton(isLandscape: true, isWideScreen: isWideScreen),

          // Spacing after capture button
          SizedBox(height: isWideScreen ? 24 : 16),

          // Left button (Gallery or custom)
          SizedBox(
            width: isWideScreen ? 64 : 56,
            height: isWideScreen ? 64 : 56,
            child: widget.customLeftButton != null
                ? widget.customLeftButton!
                : widget.showGalleryButton && widget.customLeftButton == null
                    ? Container(
                        decoration: BoxDecoration(color: Colors.black.withAlpha(102), shape: BoxShape.circle),
                        child: IconButton.filled(
                          onPressed: _isRecording ? null : _openMediaGallery, // Disable during recording
                          icon: Icon(Icons.photo_library, size: isWideScreen ? 32 : 24),
                          style: IconButton.styleFrom(
                            backgroundColor: _isRecording ? const Color.fromRGBO(158, 158, 158, 0.3) : Colors.white24,
                            foregroundColor: _isRecording ? Colors.white60 : Colors.white,
                            minimumSize: isWideScreen ? const Size(64, 64) : const Size(48, 48),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
          ),

          // Spacing between buttons
          SizedBox(height: isWideScreen ? 24 : 16),

          // Right button (Camera switch or custom)
          SizedBox(
            width: isWideScreen ? 64 : 56,
            height: isWideScreen ? 64 : 56,
            child: widget.customRightButton != null
                ? widget.customRightButton!
                : widget.showSwitchCameraButton
                    ? Container(
                        decoration: BoxDecoration(color: Colors.black.withAlpha(102), shape: BoxShape.circle),
                        child: IconButton.filled(
                          onPressed: _switchCamera,
                          icon: Icon(Icons.switch_camera, size: isWideScreen ? 32 : 24),
                          style: IconButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white, minimumSize: isWideScreen ? const Size(64, 64) : const Size(48, 48)),
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
