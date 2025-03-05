import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';

import '../cameraly_controller.dart';
import 'cameraly_overlay_theme.dart';
import 'default_cameraly_overlay.dart';

/// A custom overlay that extends the default overlay to add a time limit for video recording.
class VideoLimiterOverlay extends StatefulWidget {
  /// Creates a new [VideoLimiterOverlay] instance.
  const VideoLimiterOverlay({
    super.key,
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
    this.maxDuration = const Duration(seconds: 30),
    this.onMaxDurationReached,
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

  /// The maximum duration for video recording.
  final Duration maxDuration;

  /// Callback when the maximum duration is reached.
  final void Function(XFile videoFile)? onMaxDurationReached;

  @override
  State<VideoLimiterOverlay> createState() => _VideoLimiterOverlayState();
}

class _VideoLimiterOverlayState extends State<VideoLimiterOverlay> {
  late CameralyController _controller;
  bool _isRecording = false;
  Timer? _recordingLimitTimer;
  Duration _recordingDuration = Duration.zero;
  Duration _maxDuration = const Duration(seconds: 30);
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _maxDuration = widget.maxDuration;

    // Listen for changes to the controller
    _controller.addListener(_handleControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    _recordingLimitTimer?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoLimiterOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maxDuration != widget.maxDuration) {
      _maxDuration = widget.maxDuration;
    }
  }

  void _handleControllerUpdate() {
    final value = _controller.value;

    // Update recording state
    if (value.isRecordingVideo != _isRecording) {
      setState(() {
        _isRecording = value.isRecordingVideo;

        if (_isRecording) {
          _startRecordingTimer();
          _startRecordingLimitTimer();
        } else {
          _stopRecordingTimer();
          _recordingLimitTimer?.cancel();
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

  void _startRecordingLimitTimer() {
    _recordingLimitTimer = Timer(widget.maxDuration, () {
      if (_isRecording) {
        _controller.stopVideoRecording().then((file) {
          if (widget.onMaxDurationReached != null) {
            widget.onMaxDurationReached!(file);
          }
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Use the default overlay for most functionality
        DefaultCameralyOverlay(
          controller: widget.controller,
          theme: widget.theme,
          showCaptureButton: widget.showCaptureButton,
          showFlashButton: widget.showFlashButton,
          showSwitchCameraButton: widget.showSwitchCameraButton,
          showGalleryButton: widget.showGalleryButton,
          showZoomControls: widget.showZoomControls,
          showModeToggle: widget.showModeToggle,
          showFocusCircle: widget.showFocusCircle,
          onGalleryTap: widget.onGalleryTap,
        ),

        // Custom recording timer with progress indicator
        if (_isRecording)
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
                          '${_formatDuration(_recordingDuration)} / ${_formatDuration(_maxDuration)}',
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
                      widthFactor: _recordingDuration.inMilliseconds / _maxDuration.inMilliseconds,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _recordingDuration.inSeconds > (_maxDuration.inSeconds * 0.8) ? Colors.red : Colors.white,
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
}
