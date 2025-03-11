import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../cameraly_controller.dart';
import '../types/camera_mode.dart';
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
  /// Creates a default camera overlay.
  const DefaultCameralyOverlay({
    required this.controller,
    this.theme,
    this.showCaptureButton = true,
    this.showFlashButton = true,
    this.showSwitchCameraButton = true,
    this.showGalleryButton = true,
    this.showZoomControls = true,
    this.showFocusCircle = true,
    this.showMediaStack = true,
    this.onGalleryTap,
    this.onPictureTaken,
    this.onMediaSelected,
    this.allowMultipleSelection = true,
    this.topLeftWidget,
    this.centerLeftWidget,
    this.bottomOverlayWidget,
    this.customRightButton,
    this.customLeftButton,
    this.customBackButton,
    this.showPlaceholders = false,
    this.onCameraStateChanged,
    this.maxVideoDuration,
    this.onMaxDurationReached,
    super.key,
  });

  /// The controller for the camera.
  final CameralyController controller;

  /// The theme for the overlay.
  final CameralyOverlayTheme? theme;

  /// Whether to show the capture button.
  final bool showCaptureButton;

  /// Whether to show the flash button.
  final bool showFlashButton;

  /// Whether to show the camera switch button.
  final bool showSwitchCameraButton;

  /// Whether to show the gallery button.
  final bool showGalleryButton;

  /// Whether to show the zoom controls.
  final bool showZoomControls;

  /// Whether to show the focus circle.
  final bool showFocusCircle;

  /// Whether to show the media stack.
  final bool showMediaStack;

  /// Callback when the gallery button is tapped.
  final VoidCallback? onGalleryTap;

  /// Callback when a picture is taken. The image is added to the media manager. Access the media manager via [controller.mediaManager].
  final Function()? onPictureTaken;

  /// Callback when media is selected from the gallery. The images are added to the media manager. Access the media manager via [controller.mediaManager].
  final Function()? onMediaSelected;

  /// Whether to allow multiple selection in the gallery.
  final bool allowMultipleSelection;

  /// Widget to display in the top-left corner.
  final Widget? topLeftWidget;

  /// Widget to display in the center-left area.
  final Widget? centerLeftWidget;

  /// Widget to display in the bottom overlay area.
  final Widget? bottomOverlayWidget;

  /// Custom button to display on the right side.
  final Widget? customRightButton;

  /// Custom button to display on the left side.
  final Widget? customLeftButton;

  /// Custom back button to display.
  final Widget? customBackButton;

  /// Whether to show placeholders for customizable widgets.
  final bool showPlaceholders;

  /// Callback when the camera state changes.
  final Function(CameralyOverlayState)? onCameraStateChanged;

  /// Maximum duration for video recording.
  final Duration? maxVideoDuration;

  /// Callback when the maximum video duration is reached.
  final VoidCallback? onMaxDurationReached;

  /// Whether to show the media stack in the center-left position.
  /// This will be automatically disabled if [centerLeftWidget] is provided.
  bool get effectiveShowMediaStack => showMediaStack;

  /// Returns the DefaultCameralyOverlay instance from the given context.
  // ignore: library_private_types_in_public_api
  static _DefaultCameralyOverlayState? of(BuildContext context) {
    final state = context.findAncestorStateOfType<_DefaultCameralyOverlayState>();
    return state;
  }

  @override
  State<DefaultCameralyOverlay> createState() => _DefaultCameralyOverlayState();
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

class _DefaultCameralyOverlayState extends State<DefaultCameralyOverlay> with WidgetsBindingObserver {
  late CameralyController _controller;
  bool _isFrontCamera = false;
  bool _isVideoMode = false;
  bool _isRecording = false;
  FlashMode _flashMode = FlashMode.auto;
  bool _torchEnabled = false;
  Offset? _focusPoint;
  bool _showFocusCircle = false;
  double _currentZoom = 1.0;
  bool _showZoomSlider = false;
  Timer? _focusTimer;
  Timer? _zoomSliderTimer;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _recordingLimitTimer;
  bool _hasVideoDurationLimit = false;
  Duration? _maxVideoDuration;

  /// Whether to show the mode toggle button.
  /// This is determined by the camera mode - only shown when mode is [CameraMode.both].
  bool get effectiveShowModeToggle => widget.controller.settings.cameraMode == CameraMode.both;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _flashMode = _controller.settings.flashMode;
    _isFrontCamera = _controller.description.lensDirection == CameraLensDirection.front;
    _torchEnabled = false;
    _hasVideoDurationLimit = widget.maxVideoDuration != null;
    _maxVideoDuration = widget.maxVideoDuration;

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
    WidgetsBinding.instance.addObserver(this);
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
    _focusTimer?.cancel();
    _zoomSliderTimer?.cancel();
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

        // Show zoom slider when zoom changes (e.g., from pinch gesture)
        if (!_showZoomSlider) {
          _showZoomSlider = true;
        }

        // Reset the auto-hide timer whenever zoom changes
        _zoomSliderTimer?.cancel();
        _zoomSliderTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showZoomSlider = false;
            });
          }
        });
      });
    }

    // Update focus point - process immediately when it changes
    if (value.focusPoint != null && (value.focusPoint != _focusPoint || !_showFocusCircle)) {
      // Use microtask to ensure UI updates quickly
      Future.microtask(() {
        if (mounted) {
          setState(() {
            // Convert normalized focus point to screen coordinates
            final size = MediaQuery.of(context).size;
            final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

            // Get the camera preview's aspect ratio
            final previewRatio = _controller.cameraController!.value.aspectRatio;

            // Calculate preview dimensions
            final previewAspectRatio = isLandscape ? previewRatio : 1.0 / previewRatio;
            final previewWidth = isLandscape ? size.width : size.height * previewAspectRatio;
            final previewHeight = isLandscape ? size.width / previewAspectRatio : size.height;

            // Calculate preview position
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
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Switching camera...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Switch to the new camera
      final newController = await _controller.switchCamera();
      if (newController != null && mounted) {
        setState(() {
          // Store previous state
          final previousFlashMode = _flashMode;
          final previousTorchEnabled = _torchEnabled;

          // Update controller
          _controller = newController;
          _isFrontCamera = newController.description.lensDirection == CameraLensDirection.front;

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

          // Notify camera switch
          _notifyCameraStateChanged();
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Switched to ${_isFrontCamera ? 'front' : 'back'} camera'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
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

  Future<void> _takePicture() async {
    try {
      // Ensure flash mode is set correctly before taking the picture
      if (!_isFrontCamera) {
        await _controller.setFlashMode(_flashMode);
      }

      final file = await _controller.takePicture();
      _controller.mediaManager.addMedia(file);

      // Call the callback if provided
      if (widget.onPictureTaken != null) {
        // Schedule the callback in a microtask to ensure proper state update
        widget.onPictureTaken!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final file = await _controller.stopVideoRecording();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openCustomGallery() async {
    // If media stack is enabled and has media, show our custom gallery view
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CameralyGalleryView(
            mediaManager: widget.controller.mediaManager,
            onDelete: (file) => widget.controller.mediaManager.removeMedia(file),
            backgroundColor: Colors.black,
            appBarColor: Colors.black,
            appBarTextColor: Colors.white,
            gridSpacing: 2,
            gridCrossAxisCount: 3,
            emptyStateWidget: const Center(
              child: Text('No photos yet', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      );
    }
    return;
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

    return Stack(
      fit: StackFit.expand,
      key: ValueKey<Orientation>(MediaQuery.of(context).orientation),
      children: [
        // Focus circle
        if (_showFocusCircle && _focusPoint != null && widget.showFocusCircle)
          Positioned(
            left: _focusPoint!.dx - 20,
            top: _focusPoint!.dy - 20,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 200),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) => Transform.scale(
                scale: 2 - value,
                child: Opacity(
                  opacity: value,
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha((0.3 * 255).round()),
                    ),
                  ),
                ),
              ),
            ),
          ),

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
    // In landscape, this becomes the left area
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

            // Recording timer - only show if not using video duration limit
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

            // Zoom button
            if (widget.showZoomControls)
              Align(
                alignment: isLandscape ? Alignment.centerLeft : Alignment.topRight,
                child: CameralyOverlayButton(
                  onTap: () {
                    setState(() {
                      _showZoomSlider = !_showZoomSlider;
                    });
                    // Hide zoom slider after 3 seconds
                    if (_showZoomSlider) {
                      _zoomSliderTimer?.cancel();
                      _zoomSliderTimer = Timer(const Duration(seconds: 3), () {
                        if (mounted) {
                          setState(() {
                            _showZoomSlider = false;
                          });
                        }
                      });
                    }
                  },
                  child: Icon(
                    Icons.zoom_in,
                    color: _showZoomSlider ? Colors.white : Colors.white60,
                    size: 28,
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
      return CameralyMediaStack(
        mediaManager: widget.controller.mediaManager,
        onTap: _openCustomGallery,
        itemSize: 60,
        maxDisplayItems: 3,
        borderColor: Colors.white,
        borderWidth: 2,
        borderRadius: 8,
        showCountBadge: true,
        countBadgeColor: theme.primaryColor,
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
        if (widget.centerLeftWidget != null || widget.effectiveShowMediaStack || widget.showPlaceholders)
          Positioned(
            left: 16,
            top: MediaQuery.of(context).size.height / 2 - 40,
            child: widget.centerLeftWidget ??
                (widget.effectiveShowMediaStack
                    ? AnimatedBuilder(
                        animation: widget.controller.mediaManager,
                        builder: (context, _) => buildMediaStack(),
                      )
                    : buildPlaceholder()),
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
        top: 20, // Add top padding since bottom overlay is now outside
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
