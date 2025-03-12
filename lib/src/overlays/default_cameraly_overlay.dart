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
      child: Container(
        margin: margin,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        child: child,
      ),
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
    this.onCaptureError,
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
    this.showZoomSlider = true,
    this.showZoomControls = true,
    this.maxVideoDuration,
    this.captureButtonBuilder,
    this.flashButtonBuilder,
    this.galleryButtonBuilder,
    this.switchCameraButtonBuilder,
    this.zoomSliderBuilder,
    this.mediaManager,
    this.allowMultipleSelection = true,
    this.onMediaSelected,
    this.onCameraStateChanged,
    this.onMaxDurationReached,
    this.customBackButton,
    this.bottomOverlayWidget,
    this.showPlaceholders = false,
    this.topLeftWidget,
    this.showMediaStack = true,
    this.customLeftButton,
    this.customRightButton,
    this.centerLeftWidget,
    this.showCaptureButton = true,
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

  /// Callback when an error occurs during capture.
  final Function(String)? onCaptureError;

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

  /// Whether to show the zoom slider.
  final bool showZoomSlider;

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

  /// Whether to allow multiple selection in the gallery.
  final bool allowMultipleSelection;

  /// Callback when media is selected from the gallery.
  final VoidCallback? onMediaSelected;

  /// Callback when the camera state changes.
  final Function(CameralyOverlayState)? onCameraStateChanged;

  /// Callback when the maximum video duration is reached.
  final VoidCallback? onMaxDurationReached;

  /// Custom back button to display.
  final Widget? customBackButton;

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

  /// Creates a copy of this state with the specified fields replaced.
  CameralyOverlayState copyWith({
    bool? isRecording,
    bool? isVideoMode,
    bool? isFrontCamera,
    FlashMode? flashMode,
    bool? torchEnabled,
    Duration? recordingDuration,
  }) {
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
  const DefaultCameralyOverlayScope({
    required this.state,
    required super.child,
    super.key,
  });

  /// The state of the [DefaultCameralyOverlay] widget.
  final _DefaultCameralyOverlayState state;

  @override
  bool updateShouldNotify(DefaultCameralyOverlayScope oldWidget) {
    return state != oldWidget.state;
  }
}

class _DefaultCameralyOverlayState extends State<DefaultCameralyOverlay> with WidgetsBindingObserver {
  late CameralyController _controller;
  bool _hasControllerFromProvider = false;
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

  /// Whether to show the mode toggle button.
  /// This is determined by the camera mode - only shown when mode is [CameraMode.both].
  bool get effectiveShowModeToggle => widget.controller?.settings.cameraMode == CameraMode.both;

  @override
  void initState() {
    super.initState();
    // Controller will be initialized in didChangeDependencies
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the controller - either from the widget or from the provider
    if (widget.controller != null) {
      _controller = widget.controller!;
      _hasControllerFromProvider = false;
    } else {
      // Try to get controller from provider
      final providerController = CameralyControllerProvider.of(context);
      if (providerController == null) {
        throw FlutterError(
          'DefaultCameralyOverlay requires a controller. Either provide a controller '
          'directly using the controller parameter, or ensure the widget is a descendant '
          'of a CameralyControllerProvider.',
        );
      }
      _controller = providerController;
      _hasControllerFromProvider = true;
    }

    // Finish initialization now that we have a controller
    _flashMode = _controller.settings.flashMode;
    _isFrontCamera = _controller.description.lensDirection == CameraLensDirection.front;
    _torchEnabled = false;
    _hasVideoDurationLimit = widget.maxVideoDuration != null;
    _maxVideoDuration = widget.maxVideoDuration;

    // Initialize zoom levels
    _initializeZoomLevels();

    // Set initial video mode based on camera mode setting
    switch (_controller.settings.cameraMode) {
      case CameraMode.photoOnly:
        _isVideoMode = false;
        break;
      case CameraMode.videoOnly:
        _isVideoMode = true;
        break;
      case CameraMode.both:
        // Default behavior, keep as is
        break;
    }

    // Listen for changes to the controller
    _controller.addListener(_handleControllerUpdate);
    _initializeValues();

    // Notify initial state
    Future.microtask(() => _notifyCameraStateChanged());
  }

  @override
  void didUpdateWidget(DefaultCameralyOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.maxVideoDuration != widget.maxVideoDuration) {
      _hasVideoDurationLimit = widget.maxVideoDuration != null;
      _maxVideoDuration = widget.maxVideoDuration;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
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
    final value = _controller.value;

    // Initialize zoom levels
    _currentZoom = value.zoomLevel;
  }

  Future<void> _initializeZoomLevels() async {
    try {
      _minZoom = await _controller.getMinZoomLevel();
      _maxZoom = await _controller.getMaxZoomLevel();

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
      await _controller.setZoomLevel(zoom);
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
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
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
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  zoomText,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleControllerUpdate() {
    final value = _controller.value;

    // Update recording state
    if (value.isRecordingVideo != _isRecording) {
      setState(() {
        _isRecording = value.isRecordingVideo;

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

    // Update zoom level
    if (value.zoomLevel != _currentZoom) {
      setState(() {
        _currentZoom = value.zoomLevel;
      });
    }
  }

  void _startRecordingTimer() {
    _recordingDuration = Duration.zero;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
          // Notify recording duration update
          _notifyCameraStateChanged();
        });
      }
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingDuration = Duration.zero;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _cycleFlashMode() async {
    if (_isVideoMode || _isFrontCamera) return;

    final modes = [FlashMode.auto, FlashMode.always, FlashMode.off];
    final nextIndex = (modes.indexOf(_flashMode) + 1) % modes.length;
    final newMode = modes[nextIndex];

    try {
      await _controller.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
        // Notify flash mode change
        _notifyCameraStateChanged();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting flash mode: $e')),
        );
      }
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
    if (!_controller.value.isInitialized) {
      debugPrint('Camera is not initialized, cannot switch');
      return;
    }

    try {
      // Log current controller state
      debugPrint('🎥 Current controller hashcode: ${_controller.hashCode}');
      debugPrint('🎥 Current native controller: ${_controller.cameraController?.hashCode}');
      debugPrint('🎥 Current camera direction: ${_controller.description.lensDirection}');

      // Switch to the new camera
      debugPrint('🎥 Attempting to switch camera from ${_isFrontCamera ? 'front' : 'back'} to ${_isFrontCamera ? 'back' : 'front'}');
      final newController = await _controller.switchCamera();

      if (newController == null) {
        debugPrint('🎥 No alternative camera found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find another camera'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Log new controller state
      debugPrint('🎥 New controller received: ${newController.hashCode}');
      debugPrint('🎥 New native controller: ${newController.cameraController?.hashCode}');
      debugPrint('🎥 New camera direction: ${newController.description.lensDirection}');
      debugPrint('🎥 New controller initialized: ${newController.value.isInitialized}');

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
          _isFrontCamera = newController.description.lensDirection == CameraLensDirection.front;
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
            _controller.setFlashMode(_flashMode);
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
      }
    } catch (e) {
      debugPrint('🎥 Error switching camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch camera: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
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
        final file = await _controller.stopVideoRecording();

        // Add to the controller's media manager
        _controller.mediaManager.addMedia(file);

        // Call the callback if provided
        if (widget.onCapture != null) {
          widget.onCapture!(file);
        }
      } else {
        // Ensure we maintain torch state when starting recording
        final currentTorchState = _torchEnabled;
        await _controller.startVideoRecording();

        // If torch was on, make sure it stays on during recording
        if (currentTorchState && !_isFrontCamera) {
          await _controller.setFlashMode(FlashMode.torch);
        }
      }
    } catch (e) {
      // Call error callback if provided
      if (widget.onCaptureError != null) {
        widget.onCaptureError!(e.toString());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      // Ensure flash mode is set correctly before taking the picture
      if (!_isFrontCamera) {
        await _controller.setFlashMode(_flashMode);
      }

      final file = await _controller.takePicture();

      // Add to the controller's media manager
      _controller.mediaManager.addMedia(file);

      // Call the callback if provided
      if (widget.onCapture != null) {
        // Schedule the callback in a microtask to ensure proper state update
        widget.onCapture!(file);
      }
    } catch (e) {
      // Call error callback if provided
      if (widget.onCaptureError != null) {
        widget.onCaptureError!(e.toString());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openCustomGallery() async {
    final mediaManager = widget.controller?.mediaManager;
    if (mediaManager == null || mediaManager.count == 0) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameralyGalleryView(
          mediaManager: mediaManager,
          onDelete: (file) => mediaManager.removeMedia(file),
          backgroundColor: Colors.black,
          appBarColor: Colors.black,
          // The following parameters don't exist in CameralyGalleryView
          // allowMultipleSelection: widget.allowMultipleSelection,
          // onMediaSelected: widget.onMediaSelected,
        ),
      ),
    );
  }

  Future<void> _openGallery() async {
    if (widget.onGalleryTap != null) {
      widget.onGalleryTap!();
      return;
    }

    // Otherwise, use the system gallery picker
    try {
      List<XFile> selectedMedia = [];

      // Determine which media types to allow based on camera mode
      switch (_controller.settings.cameraMode) {
        case CameraMode.photoOnly:
          if (widget.allowMultipleSelection) {
            selectedMedia = await _imagePicker.pickMultiImage();
          } else {
            final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              selectedMedia = [image];
            }
          }
          break;

        case CameraMode.videoOnly:
          final XFile? video = await _imagePicker.pickVideo(source: ImageSource.gallery);
          if (video != null) {
            selectedMedia = [video];
          }
          break;

        case CameraMode.both:
          if (widget.allowMultipleSelection) {
            selectedMedia = await _imagePicker.pickMultipleMedia();
          } else {
            final XFile? media = await _imagePicker.pickMedia();
            if (media != null) {
              selectedMedia = [media];
            }
          }
          break;
      }

      if (selectedMedia.isNotEmpty) {
        for (final file in selectedMedia) {
          _controller.mediaManager.addMedia(file);
        }

        if (widget.onMediaSelected != null) {
          widget.onMediaSelected!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking media: $e')),
        );
      }
    }
  }

  Future<void> _toggleTorch() async {
    try {
      final newTorchState = !_torchEnabled;
      await _controller.setFlashMode(newTorchState ? FlashMode.torch : FlashMode.off);
      setState(() {
        _torchEnabled = newTorchState;
        // Notify torch state change
        _notifyCameraStateChanged();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling torch: $e')),
        );
      }
    }
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
      );
      widget.onCameraStateChanged!(state);
    }
  }

  void _startRecordingLimitTimer() {
    _recordingLimitTimer?.cancel();
    _recordingLimitTimer = Timer(_maxVideoDuration!, () {
      if (_isRecording) {
        _controller.stopVideoRecording().then((file) {
          if (widget.onMaxDurationReached != null) {
            widget.onMaxDurationReached!();
          }
        });
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
                child: widget.customBackButton ??
                    CircleAvatar(
                      backgroundColor: Colors.black.withAlpha(102),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
              ),
            ),
          ),

          // Main layout container
          isLandscape ? _buildLandscapeLayout(theme, size, padding) : _buildPortraitLayout(theme, size, padding),

          // Video duration limit UI
          if (_isRecording && _hasVideoDurationLimit && _maxVideoDuration != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Timer display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.4 * 255).round()),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatDuration(_recordingDuration)} / ${_formatDuration(_maxVideoDuration!)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Progress bar
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.4 * 255).round()),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _recordingDuration.inMilliseconds / _maxVideoDuration!.inMilliseconds,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _recordingDuration.inSeconds > (_maxVideoDuration!.inSeconds * 0.8) ? Colors.red : Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(CameralyOverlayTheme theme, Size size, EdgeInsets padding) {
    return Stack(
      children: [
        // Top area
        _buildTopArea(isLandscape: false),

        // Center area with proper positioning
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: widget.bottomOverlayWidget != null ? 100 : 0,
          child: _buildCenterArea(isLandscape: false, theme: theme),
        ),

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
                  child: const Center(
                    child: Text(
                      'Bottom Overlay',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
          ),

        // Bottom area with gradient
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomArea(isLandscape: false, theme: theme),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(CameralyOverlayTheme theme, Size size, EdgeInsets padding) {
    const leftAreaWidth = 80.0; // Width of the left area
    const rightAreaWidth = 120.0; // Width of the right area

    return Stack(
      children: [
        // Left area (top area in portrait)
        Positioned(
          top: 0,
          left: 80,
          bottom: 0,
          width: leftAreaWidth,
          child: _buildTopArea(isLandscape: true),
        ),

        // Center area with proper positioning
        Positioned(
          top: 0,
          left: leftAreaWidth + 80,
          right: rightAreaWidth,
          bottom: 0,
          child: _buildCenterArea(isLandscape: true, theme: theme),
        ),

        // Right area with controls (equivalent to bottom in portrait)
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          width: rightAreaWidth,
          child: _buildBottomArea(isLandscape: true, theme: theme),
        ),

        // Zoom level buttons - Positioned at the top with proper padding and hit testing area
        if (widget.showZoomControls && _availableZoomLevels.length > 1)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: leftAreaWidth + 80,
            right: rightAreaWidth,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: _buildZoomLevelButtons(),
              ),
            ),
          ),

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
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(33, 150, 243, 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Bottom Overlay',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
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
      if (!_isRecording && _controller.settings.cameraMode == CameraMode.both) {
        height += 60; // Add height for mode toggle
      }
      return height + MediaQuery.of(context).padding.bottom + 40; // Add padding and extra space
    }
  }

  Widget _buildTopArea({required bool isLandscape}) {
    return SizedBox(
      width: isLandscape ? 80 : double.infinity,
      child: Padding(
        padding: EdgeInsets.only(
          top: isLandscape ? 0 : MediaQuery.of(context).padding.top,
          left: 16,
          right: 16,
        ),
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
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Top Left',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
              ),

            // Recording timer
            if (_isRecording && !_hasVideoDurationLimit)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 0, 0, 0.4),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(_recordingDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Flash button (for photo mode)
            if (widget.showFlashButton && !_isVideoMode && !_isFrontCamera && _controller.value.hasFlashCapability)
              Align(
                alignment: isLandscape ? Alignment.centerLeft : Alignment.topRight,
                child: CameralyOverlayButton(
                  onTap: _cycleFlashMode,
                  child: Icon(
                    _getFlashIcon(),
                    color: _flashMode == FlashMode.off ? Colors.white60 : Colors.white,
                  ),
                ),
              ),

            // Torch button (for video mode)
            if (widget.showFlashButton && _isVideoMode && !_isFrontCamera && _controller.value.hasFlashCapability)
              Align(
                alignment: isLandscape ? Alignment.centerLeft : Alignment.topRight,
                child: CameralyOverlayButton(
                  onTap: _toggleTorch,
                  child: Icon(
                    _torchEnabled ? Icons.flashlight_on : Icons.flashlight_off,
                    color: _torchEnabled ? Colors.white : Colors.white60,
                  ),
                ),
              ),

            // Gallery button (shown in top area when customLeftButton is provided)
            if (widget.showGalleryButton && widget.customLeftButton != null)
              Align(
                alignment: isLandscape ? Alignment.centerLeft : Alignment.topRight,
                child: CameralyOverlayButton(
                  onTap: _isRecording ? null : _openGallery,
                  child: Icon(
                    Icons.photo_library,
                    color: _isRecording ? Colors.white60 : Colors.white,
                    size: 28,
                  ),
                ),
              ),

            // Camera switch button (shown in top area when customRightButton is provided)
            if (widget.showSwitchCameraButton && widget.customRightButton != null)
              Align(
                alignment: isLandscape ? Alignment.centerLeft : Alignment.topRight,
                child: CameralyOverlayButton(
                  onTap: _switchCamera,
                  child: const Icon(
                    Icons.switch_camera,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterArea({required bool isLandscape, required CameralyOverlayTheme theme}) {
    Widget buildMediaStack() {
      final mediaManager = widget.controller?.mediaManager;
      if (mediaManager == null) {
        return const SizedBox.shrink();
      }
      return CameralyMediaStack(
        mediaManager: mediaManager,
        onTap: _openCustomGallery,
        itemSize: 60,
        maxDisplayItems: 5,
      );
    }

    Widget buildPlaceholder() {
      return Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Center Left',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
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
                    ? AnimatedBuilder(
                        animation: widget.controller!.mediaManager,
                        builder: (context, _) => buildMediaStack(),
                      )
                    : buildPlaceholder(),
          ),
      ],
    );
  }

  Widget _buildBottomArea({required bool isLandscape, required CameralyOverlayTheme theme}) {
    // This is the area with the gradient background
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    return Container(
      width: isLandscape ? 120 : double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.fromRGBO(0, 0, 0, 0.95),
            Color.fromRGBO(0, 0, 0, 0.8),
            Color.fromRGBO(0, 0, 0, 0.5),
            Colors.transparent,
          ],
        ),
        // Add a solid background color to ensure visibility
        color: Colors.black.withAlpha(77),
      ),
      child: isLandscape ? _buildLandscapeControls(isWideScreen) : _buildPortraitControls(),
    );
  }

  Widget _buildPortraitControls() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom level buttons - Added here above the capture controls
          if (widget.showZoomControls && _availableZoomLevels.length > 1) _buildZoomLevelButtons(),

          const SizedBox(height: 16),

          // Photo/Video toggle
          if (!_isRecording && _controller.settings.cameraMode == CameraMode.both) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 0, 0, 0.4),
                borderRadius: BorderRadius.circular(30),
              ),
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
                          _controller.setFlashMode(_flashMode);
                        }
                        _torchEnabled = false;
                        _notifyCameraStateChanged();
                      }),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isVideoMode ? const Color.fromRGBO(255, 255, 255, 0.3) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_camera,
                              color: !_isVideoMode ? Colors.white : Colors.white60,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Photo',
                              style: TextStyle(
                                color: !_isVideoMode ? Colors.white : Colors.white60,
                                fontWeight: !_isVideoMode ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
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
                        _controller.setFlashMode(FlashMode.off);
                        _torchEnabled = false;
                        _notifyCameraStateChanged();
                      }),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isVideoMode ? const Color.fromRGBO(255, 255, 255, 0.3) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.videocam,
                              color: _isVideoMode ? Colors.white : Colors.white60,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Video',
                              style: TextStyle(
                                color: _isVideoMode ? Colors.white : Colors.white60,
                                fontWeight: _isVideoMode ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
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
              widget.customLeftButton != null
                  ? widget.customLeftButton!
                  : widget.showGalleryButton && widget.customLeftButton == null
                      ? CameralyOverlayButton(
                          onTap: _isRecording ? null : _openGallery,
                          backgroundColor: _isRecording ? const Color.fromRGBO(158, 158, 158, 0.3) : const Color.fromRGBO(0, 0, 0, 0.4),
                          size: 56,
                          child: Icon(
                            Icons.photo_library,
                            color: _isRecording ? Colors.white60 : Colors.white,
                            size: 30,
                          ),
                        )
                      : const SizedBox.shrink(),

              // Capture button
              if (widget.showCaptureButton)
                GestureDetector(
                  onTap: _handleCapture,
                  child: Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                      color: _isRecording ? Colors.red : Colors.transparent,
                    ),
                    child: Center(
                      child: _isRecording
                          ? Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                              ),
                            )
                          : Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                ),

              // Right button (Camera switch or custom)
              widget.customRightButton != null
                  ? widget.customRightButton!
                  : widget.showSwitchCameraButton
                      ? Container(
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(0, 0, 0, 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton.filled(
                            onPressed: _switchCamera,
                            icon: const Icon(Icons.switch_camera),
                            iconSize: 30,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white24,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
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
          if (!_isRecording && _controller.settings.cameraMode == CameraMode.both)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(102),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _isVideoMode = false;
                      if (!_isFrontCamera) {
                        _controller.setFlashMode(_flashMode);
                      }
                      _torchEnabled = false;
                      _notifyCameraStateChanged();
                    }),
                    style: TextButton.styleFrom(
                      foregroundColor: !_isVideoMode ? Colors.white : Colors.white60,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Photo', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => setState(() {
                      _isVideoMode = true;
                      _controller.setFlashMode(FlashMode.off);
                      _torchEnabled = false;
                      _notifyCameraStateChanged();
                    }),
                    style: TextButton.styleFrom(
                      foregroundColor: _isVideoMode ? Colors.white : Colors.white60,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Video', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Capture button
          if (widget.showCaptureButton)
            GestureDetector(
              onTap: _handleCapture,
              child: Container(
                height: isWideScreen ? 100 : 80,
                width: isWideScreen ? 100 : 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: isWideScreen ? 5 : 4,
                  ),
                  color: _isRecording ? Colors.red : Colors.transparent,
                ),
                child: Center(
                  child: _isRecording
                      ? Container(
                          width: isWideScreen ? 36 : 28,
                          height: isWideScreen ? 36 : 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.all(Radius.circular(4)),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        )
                      : Container(
                          width: isWideScreen ? 80 : 64,
                          height: isWideScreen ? 80 : 64,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ),
            ),
          SizedBox(height: isWideScreen ? 24 : 16),

          // Left button (Gallery or custom)
          widget.customLeftButton != null
              ? Padding(
                  padding: EdgeInsets.only(top: isWideScreen ? 24 : 16),
                  child: widget.customLeftButton!,
                )
              : widget.showGalleryButton && widget.customLeftButton == null
                  ? Padding(
                      padding: EdgeInsets.only(top: isWideScreen ? 24 : 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(102),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton.filled(
                          onPressed: _isRecording ? null : _openGallery, // Disable during recording
                          icon: Icon(Icons.photo_library, size: isWideScreen ? 32 : 24),
                          style: IconButton.styleFrom(
                            backgroundColor: _isRecording ? const Color.fromRGBO(158, 158, 158, 0.3) : Colors.white24,
                            foregroundColor: _isRecording ? Colors.white60 : Colors.white,
                            minimumSize: isWideScreen ? const Size(64, 64) : const Size(48, 48),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),

          // Right button (Camera switch or custom)
          widget.customRightButton != null
              ? Padding(
                  padding: EdgeInsets.only(top: isWideScreen ? 24 : 16),
                  child: widget.customRightButton!,
                )
              : widget.showSwitchCameraButton
                  ? Padding(
                      padding: EdgeInsets.only(top: isWideScreen ? 24 : 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(102),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton.filled(
                          onPressed: _switchCamera,
                          icon: Icon(Icons.switch_camera, size: isWideScreen ? 32 : 24),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                            minimumSize: isWideScreen ? const Size(64, 64) : const Size(48, 48),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
