import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cameraly_controller.dart';
import 'cameraly_preview.dart';
import 'overlays/cameraly_overlay_theme.dart';
import 'overlays/default_cameraly_overlay.dart';
import 'types/camera_mode.dart';
import 'types/capture_settings.dart';
import 'utils/cameraly_controller_provider.dart';
import 'utils/media_manager.dart';

/// Settings for configuring the appearance, behavior, and functionality of the CameralyCamera.
///
/// This class extends the capabilities of [CaptureSettings] by adding UI configuration options.
/// It includes both camera hardware settings (like resolution, flash mode) and UI settings
/// (like button visibility, theme customization).
///
/// While [CaptureSettings] is focused on the technical aspects of camera operation,
/// [CameraPreviewSettings] provides a comprehensive configuration for both camera
/// functionality and the user interface.
class CameraPreviewSettings {
  /// Creates a comprehensive settings object for [CameralyCamera].
  ///
  /// Note: When [cameraMode] is set to [CameraMode.photoOnly], [enableAudio] will
  /// automatically be set to false regardless of the value provided.
  const CameraPreviewSettings({
    // Camera hardware/capture settings
    this.cameraMode = CameraMode.both,
    this.resolution = ResolutionPreset.high,
    this.flashMode = FlashMode.auto,
    bool enableAudio = true,

    // Overlay visibility settings
    this.showOverlay = true,
    this.showFlashButton = true,
    this.showSwitchCameraButton = true,
    this.showCaptureButton = true,
    this.showGalleryButton = true,
    this.showMediaStack = false,
    this.showZoomControls = true,

    // Theme and appearance
    this.theme,
    this.loadingBackgroundColor = Colors.black,
    this.loadingIndicatorColor = Colors.white,
    this.loadingTextColor = Colors.white,
    this.loadingText = 'Initializing camera...',

    // Custom position widgets
    this.customRightButton,
    this.customLeftButton,
    this.customRightButtonBuilder,
    this.customLeftButtonBuilder,
    this.topLeftWidget,
    this.centerLeftWidget,
    this.bottomOverlayWidget,
    this.customBackButton,
    this.backButtonBuilder,

    // Custom overlay
    this.customOverlay,
    this.overlayPreset = OverlayPreset.standard,

    // Media handling
    this.maxMediaItems = 30,
    this.videoDurationLimit,

    // Callbacks
    this.onCapture,
    this.onInitialized,
    this.onError,
    this.onClose,
    this.onComplete,

    // Additional settings
    this.exposureMode = ExposureMode.auto,
    this.focusMode = FocusMode.auto,
    this.deviceOrientation = DeviceOrientation.portraitUp,
    this.multiImageSelect = true,

    // Haptic feedback settings
    this.useHapticFeedbackOnCustomButtons = true,
    this.customButtonHapticFeedbackType = HapticFeedbackType.light,
  }) :
        // Force enableAudio to false when in photoOnly mode
        enableAudio = cameraMode == CameraMode.photoOnly ? false : enableAudio;

  /// Camera mode setting (photo only, video only, or both).
  final CameraMode cameraMode;

  /// Camera resolution preset.
  final ResolutionPreset resolution;

  /// Initial flash mode setting.
  final FlashMode flashMode;

  /// Whether to enable audio during video recording.
  ///
  /// This is always false when [cameraMode] is [CameraMode.photoOnly].
  final bool enableAudio;

  /// Whether to show any overlay on top of the camera preview.
  final bool showOverlay;

  /// Whether to show the flash mode toggle button.
  final bool showFlashButton;

  /// Whether to show the switch camera button.
  final bool showSwitchCameraButton;

  /// Whether to show the capture button.
  final bool showCaptureButton;

  /// Whether to show the gallery button.
  final bool showGalleryButton;

  /// Whether to show the media stack for recently captured items.
  final bool showMediaStack;

  /// Whether to show zoom controls.
  final bool showZoomControls;

  /// Theme for customizing the appearance of the overlay.
  final CameralyOverlayTheme? theme;

  /// Background color for the loading screen.
  final Color loadingBackgroundColor;

  /// Color for the loading indicator.
  final Color loadingIndicatorColor;

  /// Color for the loading text.
  final Color loadingTextColor;

  /// Text to display while the camera is initializing.
  final String loadingText;

  /// Custom widget to display in the right button position.
  ///
  /// Note: If [customRightButtonBuilder] is provided, it takes precedence over this.
  final Widget? customRightButton;

  /// Custom widget to display in the left button position.
  ///
  /// Note: If [customLeftButtonBuilder] is provided, it takes precedence over this.
  final Widget? customLeftButton;

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

  /// Widget to display in the top-left corner of the overlay.
  final Widget? topLeftWidget;

  /// Widget to display in the center-left position of the overlay.
  final Widget? centerLeftWidget;

  /// Widget to display in the bottom overlay area.
  final Widget? bottomOverlayWidget;

  /// Custom back button to display.
  ///
  /// Note: Consider using [backButtonBuilder] for more flexibility.
  final Widget? customBackButton;

  /// Builder for a fully customizable back button.
  ///
  /// This provides access to the context and the current overlay state,
  /// allowing for more dynamic customization based on camera state.
  ///
  /// Example:
  /// ```dart
  /// backButtonBuilder: (context, state) {
  ///   return GestureDetector(
  ///     onTap: () {
  ///       // Custom back action
  ///       if (state.isRecording) {
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
  /// ```
  final Widget Function(BuildContext context, CameralyOverlayState state)? backButtonBuilder;

  /// Custom overlay widget builder. If provided, this takes precedence
  /// over the default overlay and its customization options.
  ///
  /// The builder provides access to the controller and the BuildContext.
  final Widget Function(BuildContext context, CameralyController controller)? customOverlay;

  /// Predefined overlay style preset.
  final OverlayPreset overlayPreset;

  /// Maximum number of media items to keep in history.
  final int maxMediaItems;

  /// Maximum duration for video recording.
  final Duration? videoDurationLimit;

  /// Callback when a photo is captured or video recording is stopped.
  final Function(XFile)? onCapture;

  /// Callback when the camera controller is fully initialized.
  final Function(CameralyController)? onInitialized;

  /// Callback for any camera error that occurs.
  ///
  /// The callback includes:
  /// - source: The source of the error (e.g., 'initialization', 'capture', etc.)
  /// - message: A human-readable error message
  /// - error: The original error object (if available)
  /// - isRecoverable: Whether the error is potentially recoverable
  final Function(String source, String message, {Object? error, bool isRecoverable})? onError;

  /// Callback when the camera is closed.
  final VoidCallback? onClose;

  /// Callback when the camera session is completed with media.
  ///
  /// This is typically used when the user finishes the camera session
  /// and wants to return the captured media to the calling screen.
  final Function(List<XFile>)? onComplete;

  /// The initial exposure mode.
  final ExposureMode exposureMode;

  /// The initial focus mode.
  final FocusMode focusMode;

  /// The device orientation to use.
  final DeviceOrientation deviceOrientation;

  /// Whether to allow multiple image selection in the gallery picker.
  final bool multiImageSelect;

  /// Whether to use haptic feedback when standard buttons are tapped.
  /// This applies to the built-in buttons like gallery, camera switch, flash, etc.
  final bool useHapticFeedbackOnCustomButtons;

  /// The type of haptic feedback to provide for buttons.
  ///
  /// Available types:
  /// - light: Light impact feedback
  /// - medium: Medium impact feedback
  /// - heavy: Heavy impact feedback
  /// - selection: Selection click feedback
  /// - vibrate: Vibration feedback
  final HapticFeedbackType customButtonHapticFeedbackType;

  /// Converts this settings object to a [CaptureSettings] object.
  ///
  /// This is used internally by [CameralyCamera] to configure the [CameralyController].
  CaptureSettings toCaptureSettings() {
    return CaptureSettings(
      cameraMode: cameraMode,
      enableAudio: enableAudio,
      flashMode: flashMode,
      resolution: resolution,
      maxVideoDuration: videoDurationLimit,
    );
  }

  /// Creates a copy of this settings object with the given fields replaced.
  CameraPreviewSettings copyWith({
    CameraMode? cameraMode,
    ResolutionPreset? resolution,
    FlashMode? flashMode,
    bool? enableAudio,
    bool? showOverlay,
    bool? showFlashButton,
    bool? showSwitchCameraButton,
    bool? showCaptureButton,
    bool? showGalleryButton,
    bool? showMediaStack,
    bool? showZoomControls,
    bool? showZoomSlider,
    CameralyOverlayTheme? theme,
    Color? loadingBackgroundColor,
    Color? loadingIndicatorColor,
    Color? loadingTextColor,
    String? loadingText,
    Widget? customRightButton,
    Widget? customLeftButton,
    Widget? topLeftWidget,
    Widget? centerLeftWidget,
    Widget? bottomOverlayWidget,
    Widget Function(BuildContext, CameralyController)? customOverlay,
    OverlayPreset? overlayPreset,
    int? maxMediaItems,
    Duration? videoDurationLimit,
    Function(XFile)? onCapture,
    Function(CameralyController)? onInitialized,
    Function(String, String, {Object? error, bool isRecoverable})? onError,
    VoidCallback? onClose,
    Function(List<XFile>)? onComplete,
    ExposureMode? exposureMode,
    FocusMode? focusMode,
    DeviceOrientation? deviceOrientation,
    bool? multiImageSelect,
    Widget? customBackButton,
    Widget Function(BuildContext, CameralyOverlayState)? backButtonBuilder,
    bool? useHapticFeedbackOnCustomButtons,
    HapticFeedbackType? customButtonHapticFeedbackType,
  }) {
    final newCameraMode = cameraMode ?? this.cameraMode;
    // If new camera mode is photoOnly, force enableAudio to false
    final newEnableAudio = newCameraMode == CameraMode.photoOnly ? false : (enableAudio ?? this.enableAudio);

    return CameraPreviewSettings(
      cameraMode: newCameraMode,
      resolution: resolution ?? this.resolution,
      flashMode: flashMode ?? this.flashMode,
      enableAudio: newEnableAudio,
      showOverlay: showOverlay ?? this.showOverlay,
      showFlashButton: showFlashButton ?? this.showFlashButton,
      showSwitchCameraButton: showSwitchCameraButton ?? this.showSwitchCameraButton,
      showCaptureButton: showCaptureButton ?? this.showCaptureButton,
      showGalleryButton: showGalleryButton ?? this.showGalleryButton,
      showMediaStack: showMediaStack ?? this.showMediaStack,
      showZoomControls: showZoomControls ?? this.showZoomControls,
      theme: theme ?? this.theme,
      loadingBackgroundColor: loadingBackgroundColor ?? this.loadingBackgroundColor,
      loadingIndicatorColor: loadingIndicatorColor ?? this.loadingIndicatorColor,
      loadingTextColor: loadingTextColor ?? this.loadingTextColor,
      loadingText: loadingText ?? this.loadingText,
      customRightButton: customRightButton ?? this.customRightButton,
      customLeftButton: customLeftButton ?? this.customLeftButton,
      customRightButtonBuilder: customRightButtonBuilder ?? customRightButtonBuilder,
      customLeftButtonBuilder: customLeftButtonBuilder ?? customLeftButtonBuilder,
      topLeftWidget: topLeftWidget ?? this.topLeftWidget,
      centerLeftWidget: centerLeftWidget ?? this.centerLeftWidget,
      bottomOverlayWidget: bottomOverlayWidget ?? this.bottomOverlayWidget,
      customBackButton: customBackButton ?? this.customBackButton,
      backButtonBuilder: backButtonBuilder ?? this.backButtonBuilder,
      customOverlay: customOverlay ?? this.customOverlay,
      overlayPreset: overlayPreset ?? this.overlayPreset,
      maxMediaItems: maxMediaItems ?? this.maxMediaItems,
      videoDurationLimit: videoDurationLimit ?? this.videoDurationLimit,
      onCapture: onCapture ?? this.onCapture,
      onInitialized: onInitialized ?? this.onInitialized,
      onError: onError ?? this.onError,
      onClose: onClose ?? this.onClose,
      onComplete: onComplete ?? this.onComplete,
      exposureMode: exposureMode ?? this.exposureMode,
      focusMode: focusMode ?? this.focusMode,
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
      multiImageSelect: multiImageSelect ?? this.multiImageSelect,
      useHapticFeedbackOnCustomButtons: useHapticFeedbackOnCustomButtons ?? this.useHapticFeedbackOnCustomButtons,
      customButtonHapticFeedbackType: customButtonHapticFeedbackType ?? this.customButtonHapticFeedbackType,
    );
  }
}

/// Predefined overlay styles that can be used with the [CameralyCamera].
enum OverlayPreset {
  /// Standard overlay with all default controls.
  standard,

  /// Minimal overlay with just essential controls.
  minimal,

  /// Photo-focused overlay optimized for still photography.
  photoFocused,

  /// Video-focused overlay optimized for video recording.
  videoFocused,

  /// Document scanning overlay with corner markers.
  documentScan,
}

/// A comprehensive widget that handles the camera preview, overlay, and functionality.
///
/// This widget encapsulates the entire camera experience, including:
/// - Creating and managing the camera controller
/// - Handling camera initialization and lifecycle
/// - Providing the camera preview
/// - Managing the overlay UI
/// - Handling media capture and storage
///
/// Unlike the more low-level [CameralyPreview], this widget doesn't require you to
/// create and manage a controller - it handles everything internally based on the
/// provided [settings].
class CameralyCamera extends StatefulWidget {
  /// Creates a [CameralyCamera] with the specified settings.
  const CameralyCamera({
    required this.settings,
    super.key,
  });

  /// Settings that define the appearance, behavior, and functionality.
  final CameraPreviewSettings settings;

  @override
  State<CameralyCamera> createState() => _CameralyCameraState();
}

class _CameralyCameraState extends State<CameralyCamera> {
  CameralyController? _controller;
  late CameralyMediaManager _mediaManager;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CameralyCamera oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle settings changes that require controller re-initialization
    if (widget.settings.cameraMode != oldWidget.settings.cameraMode || widget.settings.resolution != oldWidget.settings.resolution || widget.settings.enableAudio != oldWidget.settings.enableAudio) {
      _controller?.dispose();
      _initializeCamera();
    } else if (widget.settings.flashMode != oldWidget.settings.flashMode && _controller != null) {
      _controller!.setFlashMode(widget.settings.flashMode);
    }
  }

  Future<void> _initializeCamera() async {
    // Set initial state without triggering a rebuild yet
    _isInitializing = true;
    _errorMessage = null;

    // Initialize media manager
    _mediaManager = CameralyMediaManager(
      maxItems: widget.settings.maxMediaItems,
      onMediaAdded: (file) {
        widget.settings.onCapture?.call(file);
      },
    );

    try {
      // Get available cameras
      final cameras = await CameralyController.getAvailableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'No cameras available on this device';

        // Now trigger the rebuild with error state
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
        }

        // Call the error callback
        widget.settings.onError?.call('initialization', 'No cameras available on this device', isRecoverable: false);
        return;
      }

      // Convert to capture settings and create the controller
      final captureSettings = widget.settings.toCaptureSettings();
      final controller = CameralyController(
        description: cameras.first,
        settings: captureSettings,
        mediaManager: _mediaManager,
      );

      // Set controller immediately without rebuild
      _controller = controller;

      try {
        // Platform-specific initialization approach
        if (Platform.isAndroid) {
          // On Android, avoid showing loading screen when possible
          // Initialize in background then directly show camera
          setState(() {
            // Set initializing to false immediately to show the camera preview
            // This prevents the black loading screen flash
            _isInitializing = false;
          });

          // Now initialize the controller after showing the UI
          await controller.initialize();

          // Additional brief stabilization delay without showing loading screen
          await Future.delayed(const Duration(milliseconds: 100));
        } else {
          // For iOS, use the traditional approach - initialize first, then show
          await controller.initialize();

          // Small delay for UI stability
          await Future.delayed(const Duration(milliseconds: 100));

          // Update state only after initialization completes
          if (mounted) {
            setState(() {
              _isInitializing = false;
            });
          }
        }

        // Call the onInitialized callback if provided
        if (mounted) {
          widget.settings.onInitialized?.call(controller);
        }
      } catch (e) {
        // Handle initialization error
        final errorMsg = 'Failed to initialize camera: ${e.toString()}';

        // Only update state if still mounted
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _errorMessage = errorMsg;
          });

          widget.settings.onError?.call('initialization', errorMsg, error: e, isRecoverable: true);
        }

        // Clean up the controller
        controller.dispose();
      }
    } catch (e) {
      // Handle general error
      final errorMsg = 'Camera error: ${e.toString()}';

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = errorMsg;
        });

        widget.settings.onError?.call('system', errorMsg, error: e, isRecoverable: false);
      }
    }
  }

  Widget _buildLoadingUI() {
    return Container(
      color: widget.settings.loadingBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: widget.settings.loadingIndicatorColor,
              strokeWidth: 4.0,
            ),
            const SizedBox(height: 20),
            Text(
              widget.settings.loadingText,
              style: TextStyle(
                color: widget.settings.loadingTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorUI() {
    return Container(
      color: widget.settings.loadingBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: widget.settings.loadingIndicatorColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown camera error',
              style: TextStyle(
                color: widget.settings.loadingTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(CameralyController controller) {
    // If a custom overlay is provided, use it
    if (widget.settings.customOverlay != null) {
      return widget.settings.customOverlay!(context, controller);
    }

    // If overlay is disabled, return an empty container
    if (!widget.settings.showOverlay) {
      return const SizedBox.shrink();
    }

    // Otherwise, create a default overlay based on settings
    return DefaultCameralyOverlay(
      controller: controller,
      showCaptureButton: widget.settings.showCaptureButton,
      showFlashButton: widget.settings.showFlashButton,
      showSwitchCameraButton: widget.settings.showSwitchCameraButton,
      showGalleryButton: widget.settings.showGalleryButton,
      showMediaStack: widget.settings.showMediaStack,
      showZoomControls: widget.settings.showZoomControls,
      theme: widget.settings.theme,
      maxVideoDuration: widget.settings.videoDurationLimit,
      customLeftButton: widget.settings.customLeftButton,
      customRightButton: widget.settings.customRightButton,
      customRightButtonBuilder: widget.settings.customRightButtonBuilder,
      customLeftButtonBuilder: widget.settings.customLeftButtonBuilder,
      topLeftWidget: widget.settings.topLeftWidget,
      centerLeftWidget: widget.settings.centerLeftWidget,
      bottomOverlayWidget: widget.settings.bottomOverlayWidget,
      onCapture: widget.settings.onCapture,
      onClose: widget.settings.onClose,
      multiImageSelect: widget.settings.multiImageSelect,
      useHapticFeedbackOnCustomButtons: widget.settings.useHapticFeedbackOnCustomButtons,
      customButtonHapticFeedbackType: widget.settings.customButtonHapticFeedbackType,

      // Handle controller changed event by re-initializing our controller
      onControllerChanged: (newController) {
        setState(() {
          _controller = newController;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isInitializing) {
      return _buildLoadingUI();
    }

    // Error state
    if (_errorMessage != null || _controller == null) {
      return _buildErrorUI();
    }

    // Camera initialized, show preview with overlay
    return CameralyControllerProvider(
      controller: _controller!,
      child: CameralyPreview(
        controller: _controller!,
        overlay: _buildOverlay(_controller!),
        loadingBuilder: (context, value) => _buildLoadingUI(),
      ),
    );
  }
}
