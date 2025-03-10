import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../cameraly_controller.dart';
import '../types/camera_mode.dart';
import '../utils/media_manager.dart';
import 'cameraly_overlay_theme.dart';
import 'components/camera_controls.dart';
import 'components/focus_circle.dart';
import 'components/top_controls.dart';
import 'controllers/cameraly_overlay_controller.dart';
import 'layouts/cameraly_layout_manager.dart';
import 'models/cameraly_overlay_state.dart';
import 'widgets/bottom_gradient_area.dart';

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

  /// Callback when a picture is taken.
  final Function(XFile)? onPictureTaken;

  /// Callback when media is selected from the gallery.
  final Function(List<XFile>)? onMediaSelected;

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
  bool get effectiveShowMediaStack => showMediaStack && centerLeftWidget == null;

  /// Returns the DefaultCameralyOverlay instance from the given context.
  static _DefaultCameralyOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<_DefaultCameralyOverlayState>();
  }

  @override
  State<DefaultCameralyOverlay> createState() => _DefaultCameralyOverlayState();
}

class _DefaultCameralyOverlayState extends State<DefaultCameralyOverlay> {
  late final CameralyOverlayController _overlayController;

  @override
  void initState() {
    super.initState();
    _overlayController = CameralyOverlayController(
      controller: widget.controller,
      maxVideoDuration: widget.maxVideoDuration,
      onStateChanged: widget.onCameraStateChanged,
    );
  }

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
  }

  double _getBottomAreaHeight(bool isLandscape) {
    if (isLandscape) return 0;
    double height = 90;
    if (!_overlayController.isRecording && widget.controller.settings.cameraMode == CameraMode.both) {
      height += 60;
    }
    return height + MediaQuery.of(context).padding.bottom + 40;
  }

  Future<void> _openCustomGallery() async {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CameralyCustomGalleryView(
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
  }

  Future<void> _handleMediaSelected(List<XFile> media) async {
    for (final file in media) {
      widget.controller.mediaManager.addMedia(file);
    }
    if (widget.onMediaSelected != null) {
      widget.onMediaSelected!(media);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? CameralyOverlayTheme.fromContext(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return ListenableBuilder(
      listenable: _overlayController,
      builder: (context, _) {
        return CameralyLayoutManager(
          isLandscape: isLandscape,
          theme: theme,
          topArea: TopControls(
            isVideoMode: _overlayController.isVideoMode,
            isRecording: _overlayController.isRecording,
            isFrontCamera: _overlayController.isFrontCamera,
            flashMode: _overlayController.flashMode,
            torchEnabled: _overlayController.torchEnabled,
            showFlashButton: widget.showFlashButton,
            showZoomControls: widget.showZoomControls,
            onFlashModeChanged: _overlayController.setFlashMode,
            onTorchToggled: _overlayController.toggleTorch,
            onZoomToggled: _overlayController.toggleZoomSlider,
            hasFlashCapability: widget.controller.value.hasFlashCapability,
            currentZoom: _overlayController.currentZoom,
            minZoom: _overlayController.minZoom,
            maxZoom: _overlayController.maxZoom,
            showZoomSlider: _overlayController.showZoomSlider,
            onZoomChanged: _overlayController.setZoomLevel,
            isLandscape: isLandscape,
            showRelocatedGalleryButton: widget.customLeftButton != null && widget.showGalleryButton,
            showRelocatedSwitchButton: widget.customRightButton != null && widget.showSwitchCameraButton,
            onGalleryTap: widget.customLeftButton != null
                ? () async {
                    if (widget.onGalleryTap != null) {
                      widget.onGalleryTap!();
                    } else {
                      try {
                        final media = await _overlayController.pickMedia(
                          allowMultiple: widget.allowMultipleSelection,
                        );
                        if (media.isNotEmpty) {
                          await _handleMediaSelected(media);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error picking media: $e')),
                          );
                        }
                      }
                    }
                  }
                : null,
            onSwitchCamera: widget.customRightButton != null
                ? () async {
                    try {
                      await _overlayController.switchCamera();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error switching camera: $e')),
                        );
                      }
                    }
                  }
                : null,
          ),
          centerArea: Stack(
            fit: StackFit.expand,
            children: [
              if (_overlayController.showFocusCircle && _overlayController.focusPoint != null && widget.showFocusCircle) FocusCircle(position: _overlayController.focusPoint!),
              if (widget.centerLeftWidget != null || widget.effectiveShowMediaStack || widget.showPlaceholders)
                Positioned(
                  left: 16,
                  top: MediaQuery.of(context).size.height / 2 - 40,
                  child: widget.centerLeftWidget ??
                      (widget.effectiveShowMediaStack
                          ? AnimatedBuilder(
                              animation: widget.controller.mediaManager,
                              builder: (context, _) => CameralyMediaStack(
                                mediaManager: widget.controller.mediaManager,
                                onTap: _openCustomGallery,
                                itemSize: 60,
                                maxDisplayItems: 3,
                                borderColor: Colors.white,
                                borderWidth: 2,
                                borderRadius: 8,
                                showCountBadge: true,
                                countBadgeColor: theme.primaryColor,
                              ),
                            )
                          : Container(
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
                            )),
                ),
            ],
          ),
          bottomArea: BottomGradientArea(
            isLandscape: isLandscape,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Left position
                      if (widget.customLeftButton != null)
                        widget.customLeftButton!
                      else if (widget.showGalleryButton && widget.customLeftButton == null)
                        IconButton.filled(
                          onPressed: _overlayController.isRecording
                              ? null
                              : () async {
                                  if (widget.onGalleryTap != null) {
                                    widget.onGalleryTap!();
                                  } else {
                                    try {
                                      final media = await _overlayController.pickMedia(
                                        allowMultiple: widget.allowMultipleSelection,
                                      );
                                      if (media.isNotEmpty) {
                                        await _handleMediaSelected(media);
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error picking media: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                          icon: const Icon(Icons.photo_library, size: 30),
                          style: IconButton.styleFrom(
                            backgroundColor: _overlayController.isRecording ? Colors.grey.withAlpha(77) : Colors.white24,
                            foregroundColor: _overlayController.isRecording ? Colors.white60 : Colors.white,
                            minimumSize: const Size(64, 64),
                            fixedSize: const Size(64, 64),
                            padding: EdgeInsets.zero,
                          ),
                        )
                      else
                        const SizedBox(width: 84),

                      const SizedBox(width: 16),

                      // Center position (Capture button)
                      if (widget.showCaptureButton)
                        CameraControls(
                          isVideoMode: _overlayController.isVideoMode,
                          isRecording: _overlayController.isRecording,
                          showCaptureButton: true,
                          onModeChanged: _overlayController.setVideoMode,
                          onCapture: () async {
                            try {
                              if (_overlayController.isVideoMode) {
                                await _overlayController.toggleRecording();
                              } else {
                                final file = await _overlayController.takePicture();
                                if (widget.onPictureTaken != null) {
                                  widget.onPictureTaken!(file);
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          showModeToggle: widget.controller.settings.cameraMode == CameraMode.both,
                          theme: theme,
                        )
                      else
                        const SizedBox.shrink(),

                      const SizedBox(width: 16),

                      // Right position
                      if (widget.customRightButton != null)
                        widget.customRightButton!
                      else if (widget.showSwitchCameraButton && widget.customRightButton == null)
                        IconButton.filled(
                          onPressed: () async {
                            try {
                              await _overlayController.switchCamera();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error switching camera: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.switch_camera, size: 30),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(64, 64),
                            fixedSize: const Size(64, 64),
                            padding: EdgeInsets.zero,
                          ),
                        )
                      else
                        const SizedBox(width: 84),
                    ],
                  ),
                ],
              ),
            ),
          ),
          bottomOverlayWidget: widget.bottomOverlayWidget,
          showPlaceholders: widget.showPlaceholders,
          isRecording: _overlayController.isRecording,
          hasVideoDurationLimit: _overlayController.hasVideoDurationLimit,
          recordingDuration: _overlayController.recordingDuration,
          maxVideoDuration: widget.maxVideoDuration,
          getBottomAreaHeight: _getBottomAreaHeight,
        );
      },
    );
  }
}
