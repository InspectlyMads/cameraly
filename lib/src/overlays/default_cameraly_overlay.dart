import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../cameraly_controller.dart';
import 'cameraly_overlay_theme.dart';

/// A default overlay for the camera preview with standard controls.
///
/// This widget provides a customizable camera UI with controls for
/// capturing photos, recording videos, switching cameras, toggling flash,
/// and more. The UI matches the basic camera example.
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
    this.showModeToggle = true,
    this.showFocusCircle = true,
    this.onGalleryTap,
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

  /// Whether to show the switch camera button.
  final bool showSwitchCameraButton;

  /// Whether to show the gallery button.
  final bool showGalleryButton;

  /// Whether to show zoom controls.
  final bool showZoomControls;

  /// Whether to show the photo/video mode toggle.
  final bool showModeToggle;

  /// Whether to show the focus circle when focus point changes.
  final bool showFocusCircle;

  /// Callback when the gallery button is tapped.
  final VoidCallback? onGalleryTap;

  @override
  State<DefaultCameralyOverlay> createState() => _DefaultCameralyOverlayState();
}

class _DefaultCameralyOverlayState extends State<DefaultCameralyOverlay> with WidgetsBindingObserver {
  bool _isFrontCamera = false;
  bool _isVideoMode = false;
  bool _isRecording = false;
  FlashMode _flashMode = FlashMode.auto;
  Offset? _focusPoint;
  bool _showFocusCircle = false;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  bool _showZoomSlider = false;
  Timer? _focusTimer;
  Timer? _zoomSliderTimer;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_controllerListener);
    WidgetsBinding.instance.addObserver(this);
    _initializeValues();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerListener);
    WidgetsBinding.instance.removeObserver(this);
    _focusTimer?.cancel();
    _zoomSliderTimer?.cancel();
    _recordingTimer?.cancel();
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
    final value = widget.controller.value;

    // Initialize flash mode
    _flashMode = value.flashMode;

    // Initialize camera direction
    _isFrontCamera = widget.controller.description.lensDirection == CameraLensDirection.front;

    // Initialize zoom levels
    _minZoom = await widget.controller.getMinZoomLevel();
    _maxZoom = await widget.controller.getMaxZoomLevel();
    _currentZoom = value.zoomLevel;
  }

  void _controllerListener() {
    final value = widget.controller.value;

    // Update recording state
    if (value.isRecordingVideo != _isRecording) {
      setState(() {
        _isRecording = value.isRecordingVideo;

        if (_isRecording) {
          _startRecordingTimer();
        } else {
          _stopRecordingTimer();
        }
      });
    }

    // Update zoom level
    if (value.zoomLevel != _currentZoom) {
      setState(() {
        _currentZoom = value.zoomLevel;
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
            final previewRatio = widget.controller.cameraController!.value.aspectRatio;

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
      await widget.controller.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Flash mode: ${_flashMode.toString().split('.').last}'),
            duration: const Duration(seconds: 1),
          ),
        );
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
    final newController = await widget.controller.switchCamera();
    if (newController != null) {
      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });
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
        await widget.controller.setFlashMode(_flashMode);
      }

      final file = await widget.controller.takePicture();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Picture saved: ${file.path}')),
        );
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
        final file = await widget.controller.stopVideoRecording();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Video saved: ${file.path}')),
          );
        }
      } else {
        await widget.controller.startVideoRecording();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _setZoom(double zoom) async {
    try {
      await widget.controller.setZoomLevel(zoom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting zoom: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? CameralyOverlayTheme.fromContext(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Stack(
      fit: StackFit.expand,
      key: ValueKey<Orientation>(MediaQuery.of(context).orientation),
      children: [
        // Focus circle - updated implementation
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
                      color: Colors.white.withOpacity(0.3),
                    ),
                    child: const Center(
                      child: Icon(Icons.center_focus_strong, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Recording timer
        if (_isRecording)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
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
          ),

        // Flash control
        if (widget.showFlashButton && !_isVideoMode && !_isFrontCamera)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: isLandscape ? 16 : null,
            right: isLandscape ? null : 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isRecording ? 0.0 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    onPressed: _cycleFlashMode,
                    icon: Icon(
                      _getFlashIcon(),
                      color: _flashMode == FlashMode.off ? Colors.white60 : Colors.white,
                    ),
                    iconSize: 28,
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: _flashMode == FlashMode.always ? Colors.amber.withOpacity(0.3) : Colors.transparent,
                      minimumSize: const Size(56, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Zoom slider
        if (widget.showZoomControls && _showZoomSlider)
          Positioned(
            top: MediaQuery.of(context).padding.top + (isLandscape ? 80 : 120),
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_currentZoom.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      activeTrackColor: theme.primaryColor,
                      inactiveTrackColor: Colors.white30,
                      thumbColor: Colors.white,
                      overlayColor: theme.primaryColor.withOpacity(0.2),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    ),
                    child: Slider(
                      value: _currentZoom.clamp(_minZoom, _maxZoom),
                      min: _minZoom,
                      max: _maxZoom,
                      onChanged: _setZoom,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Zoom button - positioned differently based on orientation
        if (widget.showZoomControls)
          Positioned(
            // In landscape: bottom left, In portrait: top left (changed from right)
            bottom: isLandscape ? 20 + MediaQuery.of(context).padding.bottom : null,
            top: isLandscape ? null : MediaQuery.of(context).padding.top + 16,
            left: 16, // Always on the left in both orientations
            right: null, // Removed right positioning
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton.filled(
                onPressed: () {
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
                icon: const Icon(Icons.zoom_in),
                iconSize: 28,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),

        // Bottom controls with gradient background
        AnimatedPositioned(
          key: ValueKey<bool>(isLandscape),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          right: 0,
          bottom: isLandscape ? 0 : 0,
          left: isLandscape ? null : 0,
          top: isLandscape ? 0 : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: EdgeInsets.only(
              left: isLandscape ? 0 : 20,
              right: isLandscape ? 0 : 20,
              bottom: isLandscape ? 16 : 20 + MediaQuery.of(context).padding.bottom,
              top: isLandscape ? 16 : 20 + MediaQuery.of(context).padding.top,
            ),
            width: isLandscape ? 120 : MediaQuery.of(context).size.width,
            height: isLandscape ? MediaQuery.of(context).size.height : null,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isLandscape ? Alignment.centerRight : Alignment.bottomCenter,
                end: isLandscape ? Alignment.centerLeft : Alignment.topCenter,
                stops: isLandscape ? const [0.0, 0.3, 0.7, 1.0] : const [0.0, 0.15, 0.3, 0.5],
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: isLandscape ? _buildLandscapeControls() : _buildPortraitControls(),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitControls() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.showModeToggle && !_isRecording) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _isVideoMode = false;
                  // Update flash mode when switching to photo mode
                  if (!_isFrontCamera) {
                    widget.controller.setFlashMode(_flashMode);
                  }
                }),
                style: TextButton.styleFrom(
                  foregroundColor: !_isVideoMode ? Colors.white : Colors.white60,
                ),
                child: const Text('Photo'),
              ),
              const SizedBox(width: 20),
              TextButton(
                onPressed: () => setState(() {
                  _isVideoMode = true;
                  // Turn off flash in video mode
                  widget.controller.setFlashMode(FlashMode.off);
                }),
                style: TextButton.styleFrom(
                  foregroundColor: _isVideoMode ? Colors.white : Colors.white60,
                ),
                child: const Text('Video'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (widget.showSwitchCameraButton)
              IconButton.filled(
                onPressed: _switchCamera,
                icon: const Icon(Icons.switch_camera),
                iconSize: 30,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
              ),
            if (widget.showCaptureButton)
              GestureDetector(
                onTap: _handleCapture,
                child: Container(
                  // Increased size for better visibility and usability
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
            if (widget.showGalleryButton)
              IconButton.filled(
                onPressed: widget.onGalleryTap,
                icon: const Icon(Icons.photo_library),
                iconSize: 30,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLandscapeControls() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    return SizedBox(
      width: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Photo/Video toggle to the left of the capture button
          if (widget.showModeToggle && !_isRecording)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _isVideoMode = false;
                      // Update flash mode when switching to photo mode
                      if (!_isFrontCamera) {
                        widget.controller.setFlashMode(_flashMode);
                      }
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
                      // Turn off flash in video mode
                      widget.controller.setFlashMode(FlashMode.off);
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
                // Increased size for better visibility and usability
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

          // Camera switch button
          if (widget.showSwitchCameraButton)
            IconButton.filled(
              onPressed: _switchCamera,
              icon: Icon(Icons.switch_camera, size: isWideScreen ? 32 : 24),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
                minimumSize: isWideScreen ? const Size(64, 64) : const Size(48, 48),
              ),
            ),

          // Gallery button
          if (widget.showGalleryButton)
            Padding(
              padding: EdgeInsets.only(top: isWideScreen ? 24 : 16),
              child: IconButton.filled(
                onPressed: widget.onGalleryTap,
                icon: Icon(Icons.photo_library, size: isWideScreen ? 32 : 24),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  minimumSize: isWideScreen ? const Size(64, 64) : const Size(48, 48),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
