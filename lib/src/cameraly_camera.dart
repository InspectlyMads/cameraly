import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'cameraly_controller.dart';
import 'cameraly_preview.dart';
import 'overlays/cameraly_overlay_theme.dart';
import 'overlays/default_cameraly_overlay.dart';
import 'types/camera_mode.dart';
import 'types/capture_settings.dart';
import 'utils/camera_lifecycle_machine.dart';
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
    this.compressionQuality = CompressionQuality.auto,
    this.imageQuality = 90,
    this.videoQuality = 85,
    this.addLocationMetadata = false,
    this.locationAccuracy = LocationAccuracy.high,

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

    // Error texts (for localization)
    this.errorCameraPermissionTitle = 'Camera Permission Required',
    this.errorCameraPermissionMessage = 'The app needs camera access to function properly. Please grant camera permission to continue.',
    this.errorMicrophonePermissionTitle = 'Microphone Permission Denied',
    this.errorMicrophonePermissionMessage = 'Microphone access was denied. You can continue using the camera without audio recording, or enable microphone access in settings.',
    this.errorCameraInitFailedTitle = 'Camera Initialization Failed',
    this.errorCameraInitFailedMessage = 'Unable to initialize the camera. This could be due to a hardware issue or the camera is in use by another app.',
    this.errorSettingsButtonText = 'Open Settings',
    this.errorRetryButtonText = 'Retry',
    this.errorContinueWithoutAudioText = 'Continue Without Audio',
    this.errorBackButtonText = 'Back',
    this.errorHowToEnableText = 'How to enable:',
    this.appName = 'App',

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
    this.customStoragePath,

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

  /// Title text for camera permission error
  final String errorCameraPermissionTitle;

  /// Message text for camera permission error
  final String errorCameraPermissionMessage;

  /// Title text for microphone permission error
  final String errorMicrophonePermissionTitle;

  /// Message text for microphone permission error
  final String errorMicrophonePermissionMessage;

  /// Title text for camera initialization failure
  final String errorCameraInitFailedTitle;

  /// Message text for camera initialization failure
  final String errorCameraInitFailedMessage;

  /// Text for the settings button on error screens
  final String errorSettingsButtonText;

  /// Text for the retry button on error screens
  final String errorRetryButtonText;

  /// Text for the continue without audio button
  final String errorContinueWithoutAudioText;

  /// Text for the back button on error screens
  final String errorBackButtonText;

  /// Text for the "How to enable" header in permission instructions
  final String errorHowToEnableText;

  /// App name to use in permission instructions (replaces '[App Name]' placeholder)
  final String appName;

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

  /// Custom directory path where captured media will be stored.
  ///
  /// If not provided, media will be stored in the app's temporary directory.
  /// This should be an absolute path to a directory where the app has write permissions.
  ///
  /// Example:
  /// ```dart
  /// final directory = await getApplicationDocumentsDirectory();
  /// final path = '${directory.path}/my_camera_app';
  /// ```
  final String? customStoragePath;

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

  /// The compression quality level for captured media.
  /// Affects both images and videos.
  ///
  /// Default is [CompressionQuality.auto], which automatically sets compression
  /// based on the resolution.
  final CompressionQuality compressionQuality;

  /// Image quality percentage (0-100) when compression is enabled.
  ///
  /// Only used when [compressionQuality] is not [CompressionQuality.none].
  /// Higher values mean better quality but larger file sizes.
  /// Default is 90, which provides good quality with reasonable compression.
  final int imageQuality;

  /// Video quality percentage (0-100) when compression is enabled.
  ///
  /// Only used when [compressionQuality] is not [CompressionQuality.none].
  /// Higher values mean better quality but larger file sizes.
  /// Default is 85, which provides good quality with reasonable compression.
  final int videoQuality;

  /// Whether to add location metadata to captured media.
  final bool addLocationMetadata;

  /// Location accuracy for capturing location metadata.
  final LocationAccuracy locationAccuracy;

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
      compressionQuality: compressionQuality,
      imageQuality: imageQuality,
      videoQuality: videoQuality,
      addLocationMetadata: addLocationMetadata,
      locationAccuracy: locationAccuracy,
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
    String? errorCameraPermissionTitle,
    String? errorCameraPermissionMessage,
    String? errorMicrophonePermissionTitle,
    String? errorMicrophonePermissionMessage,
    String? errorCameraInitFailedTitle,
    String? errorCameraInitFailedMessage,
    String? errorSettingsButtonText,
    String? errorRetryButtonText,
    String? errorContinueWithoutAudioText,
    String? errorBackButtonText,
    String? errorHowToEnableText,
    String? appName,
    Widget? customRightButton,
    Widget? customLeftButton,
    Widget? topLeftWidget,
    Widget? centerLeftWidget,
    Widget? bottomOverlayWidget,
    Widget Function(BuildContext, CameralyController)? customOverlay,
    OverlayPreset? overlayPreset,
    int? maxMediaItems,
    Duration? videoDurationLimit,
    String? customStoragePath,
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
    CompressionQuality? compressionQuality,
    int? imageQuality,
    int? videoQuality,
    bool? addLocationMetadata,
    LocationAccuracy? locationAccuracy,
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
      errorCameraPermissionTitle: errorCameraPermissionTitle ?? this.errorCameraPermissionTitle,
      errorCameraPermissionMessage: errorCameraPermissionMessage ?? this.errorCameraPermissionMessage,
      errorMicrophonePermissionTitle: errorMicrophonePermissionTitle ?? this.errorMicrophonePermissionTitle,
      errorMicrophonePermissionMessage: errorMicrophonePermissionMessage ?? this.errorMicrophonePermissionMessage,
      errorCameraInitFailedTitle: errorCameraInitFailedTitle ?? this.errorCameraInitFailedTitle,
      errorCameraInitFailedMessage: errorCameraInitFailedMessage ?? this.errorCameraInitFailedMessage,
      errorSettingsButtonText: errorSettingsButtonText ?? this.errorSettingsButtonText,
      errorRetryButtonText: errorRetryButtonText ?? this.errorRetryButtonText,
      errorContinueWithoutAudioText: errorContinueWithoutAudioText ?? this.errorContinueWithoutAudioText,
      errorBackButtonText: errorBackButtonText ?? this.errorBackButtonText,
      errorHowToEnableText: errorHowToEnableText ?? this.errorHowToEnableText,
      appName: appName ?? this.appName,
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
      customStoragePath: customStoragePath ?? this.customStoragePath,
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
      compressionQuality: compressionQuality ?? this.compressionQuality,
      imageQuality: imageQuality ?? this.imageQuality,
      videoQuality: videoQuality ?? this.videoQuality,
      addLocationMetadata: addLocationMetadata ?? this.addLocationMetadata,
      locationAccuracy: locationAccuracy ?? this.locationAccuracy,
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
///
/// **Important Permission Notes:**
///
/// For proper camera functionality, your app must include proper permission declarations
/// in the platform-specific manifest files:
///
/// * On Android, add the following to your AndroidManifest.xml file inside the <manifest> tag:
/// ```xml
/// <uses-permission android:name="android.permission.CAMERA" />
/// <uses-feature android:name="android.hardware.camera" />
/// <uses-feature android:name="android.hardware.camera.autofocus" />
/// ```
///
/// For audio recording in videos, also add:
/// ```xml
/// <uses-permission android:name="android.permission.RECORD_AUDIO" />
/// <uses-permission android:name="android.permission.MICROPHONE" />
/// ```
///
/// * On iOS, add the following to your Info.plist file:
/// ```xml
/// <key>NSCameraUsageDescription</key>
/// <string>This app needs camera access to take photos and record videos</string>
/// <key>NSMicrophoneUsageDescription</key>
/// <string>This app needs microphone access to record videos with audio</string>
/// ```
///
/// The package will automatically handle permission requests at runtime, but these
/// manifest declarations are required for the permission system to work properly.
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

class _CameralyCameraState extends State<CameralyCamera> with WidgetsBindingObserver {
  CameralyController? _controller;
  late CameralyMediaManager _mediaManager;
  bool _isInitializing = true;
  String? _errorMessage;
  List<CameraDescription>? _cameras;
  bool _controllerInitialized = false;
  bool _controllerDisposed = false;
  bool _isChangingController = false;

  // Add lifecycle machine
  CameraLifecycleMachine? _lifecycleMachine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    _controllerDisposed = true;

    // Clean up lifecycle machine
    _lifecycleMachine?.dispose();

    // Dispose of controller if we initialized it
    if (_controllerInitialized && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }

    WidgetsBinding.instance.removeObserver(this);
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

  // Check camera permission status directly
  Future<Map<String, PermissionStatus>> _checkPermissionStatuses() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final microphoneStatus = await Permission.microphone.status;

      debugPrint('Camera permission status: $cameraStatus');
      debugPrint('Microphone permission status: $microphoneStatus');

      return {
        'camera': cameraStatus,
        'microphone': microphoneStatus,
      };
    } catch (e) {
      debugPrint('Error checking permission status: $e');
      return {
        'camera': PermissionStatus.denied,
        'microphone': PermissionStatus.denied,
      };
    }
  }

  Future<bool> _checkPermissionStatus() async {
    try {
      final status = await Permission.camera.status;
      debugPrint('Current camera permission status: $status');
      return status == PermissionStatus.permanentlyDenied;
    } catch (e) {
      debugPrint('Error checking permission status: $e');
      return false;
    }
  }

  Future<void> _initializeCamera({bool forceWithoutAudio = false}) async {
    try {
      setState(() {
        _isInitializing = true;
      });

      // Always request camera permission first before checking status
      // This ensures the system dialog appears at least once
      bool cameraPermissionRequested = false;

      // Check permission statuses
      final permissionStatuses = await _checkPermissionStatuses();
      final cameraStatus = permissionStatuses['camera']!;
      final microphoneStatus = permissionStatuses['microphone']!;

      // For first-time users, always request camera permission
      // This ensures the system dialog appears at least once
      if (cameraStatus != PermissionStatus.granted) {
        debugPrint('Requesting camera permission...');
        final requestResult = await Permission.camera.request();
        cameraPermissionRequested = true;

        // Re-check camera status after request
        if (requestResult == PermissionStatus.permanentlyDenied) {
          _handleError('initCamera', 'Camera permission permanently denied. Please enable in settings.', null, false);
          if (mounted) {
            _showSettingsDialog(isCamera: true);
          }
          return;
        } else if (requestResult == PermissionStatus.denied) {
          _handleError('initCamera', 'Camera permission denied.', null, false);
          return;
        }
        // If granted, continue with initialization
      }

      // Check if we need microphone permission
      final needsMicrophone = widget.settings.cameraMode != CameraMode.photoOnly && widget.settings.enableAudio && !forceWithoutAudio;

      // Handle microphone permission issues if needed
      if (needsMicrophone) {
        if (microphoneStatus == PermissionStatus.permanentlyDenied) {
          _handleError('initCamera', 'Microphone permission permanently denied.', null, false);
          if (mounted) {
            _showMicrophonePermissionDialog();
          }
          return;
        }

        if (microphoneStatus != PermissionStatus.granted) {
          // Request microphone permission
          debugPrint('Requesting microphone permission...');
          final microphoneRequestResult = await Permission.microphone.request();
          if (microphoneRequestResult == PermissionStatus.denied || microphoneRequestResult == PermissionStatus.permanentlyDenied) {
            _handleError('initCamera', 'Microphone permission denied.', null, false);
            if (mounted) {
              _showMicrophonePermissionDialog();
            }
            return;
          }
        }
      }

      // Initialize media manager
      _mediaManager = CameralyMediaManager(
        maxItems: widget.settings.maxMediaItems,
        customStoragePath: widget.settings.customStoragePath,
        onMediaAdded: (file) {
          widget.settings.onCapture?.call(file);
        },
      );

      // Get available cameras
      final cameras = await CameralyController.getAvailableCameras();
      if (cameras.isEmpty) {
        _handleError('initCamera', 'No cameras found', null, false);
        return;
      }
      _cameras = cameras;

      // Find initial camera to use
      final cameraIndex = _getCameraIndexToUse(cameras);
      final cameraDescription = cameras[cameraIndex];

      // Modify settings for better initialization in dark conditions
      final captureSettings = _createCaptureSettings(
        forceWithoutAudio: forceWithoutAudio,
        // Start with fixed focus initially to avoid getting stuck
        initialFocusMode: FocusMode.auto,
      );

      // Create controller and initialize it
      _controller = CameralyController(
        description: cameraDescription,
        settings: captureSettings,
        mediaManager: _mediaManager,
      );

      // Create lifecycle machine
      _lifecycleMachine = CameraLifecycleMachine(
        controller: _controller!,
        onStateChange: _handleLifecycleStateChange,
        onError: _handleLifecycleError,
      );

      // Initialize using lifecycle machine with a timeout
      bool initialized = false;
      try {
        initialized = await _lifecycleMachine!.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Camera initialization timed out - forcing completion');
            return true; // Force success after timeout
          },
        );
      } catch (e) {
        debugPrint('Error during camera initialization with timeout: $e');
        // Continue anyway - we'll handle UI with fallback
      }

      if (!initialized && mounted) {
        debugPrint('Camera initialization reported failure - attempting to continue anyway');
        // Don't return early, try to continue with partial initialization
      }

      _controllerInitialized = true;

      if (widget.settings.onInitialized != null && _controller != null) {
        widget.settings.onInitialized!(_controller!);
      }

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _selectedCameraIndex = cameraIndex;
          _errorMessage = null; // Clear any error messages
        });
      }
    } catch (e, stackTrace) {
      _handleError('initCamera', 'Error initializing camera', e, true, stackTrace);
    }
  }

  // Handle state transitions from lifecycle machine
  void _handleLifecycleStateChange(CameraLifecycleState oldState, CameraLifecycleState newState) {
    debugPrint('CameralyCamera: Lifecycle state changed from $oldState to $newState');

    if (mounted) {
      setState(() {
        // Update loading state based on lifecycle transitions
        _isChangingController = newState == CameraLifecycleState.initializing || newState == CameraLifecycleState.resuming || newState == CameraLifecycleState.recreating || newState == CameraLifecycleState.switching;
      });
    }
  }

  // Handle lifecycle errors
  void _handleLifecycleError(String message, Object? error) {
    _handleError('cameraLifecycle', message, error, false);
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
    // Check if this is a permission-related error
    final bool isPermissionError = _errorMessage?.toLowerCase().contains('permission') ?? false;
    final bool isMicrophoneError = _errorMessage?.toLowerCase().contains('microphone') ?? false;
    final bool isCameraError = isPermissionError && !isMicrophoneError;

    // Get the appropriate colors from theme
    final themeColor = Theme.of(context).primaryColor;
    final errorColor = Theme.of(context).colorScheme.error;

    // Color to use based on error type
    final Color accentColor = isPermissionError ? themeColor : errorColor;

    return Container(
      color: widget.settings.loadingBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add back button in header
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: widget.settings.loadingTextColor,
                onPressed: () {
                  if (widget.settings.onClose != null) {
                    widget.settings.onClose!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                tooltip: widget.settings.errorBackButtonText,
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    color: widget.settings.loadingBackgroundColor.withOpacity(0.8),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: accentColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCameraError ? Icons.no_photography : (isMicrophoneError ? Icons.mic_off : Icons.error_outline),
                                color: accentColor,
                                size: 64,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isCameraError ? widget.settings.errorCameraPermissionTitle : (isMicrophoneError ? widget.settings.errorMicrophonePermissionTitle : widget.settings.errorCameraInitFailedTitle),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: widget.settings.loadingTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isCameraError ? widget.settings.errorCameraPermissionMessage : (isMicrophoneError ? widget.settings.errorMicrophonePermissionMessage : _errorMessage ?? widget.settings.errorCameraInitFailedMessage),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: widget.settings.loadingTextColor,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            if (isPermissionError) ...[
                              const SizedBox(height: 24),
                              _buildPermissionInstructions(isCameraPermission: isCameraError),
                            ],
                            const SizedBox(height: 24),
                            FutureBuilder<Map<String, PermissionStatus>>(
                                future: _checkPermissionStatuses(),
                                builder: (context, snapshot) {
                                  final permissionStatuses = snapshot.data ?? {'camera': PermissionStatus.denied, 'microphone': PermissionStatus.denied};

                                  final cameraStatus = permissionStatuses['camera']!;
                                  final microphoneStatus = permissionStatuses['microphone']!;

                                  final bool cameraPermDenied = cameraStatus == PermissionStatus.permanentlyDenied;
                                  final bool microphonePermDenied = microphoneStatus == PermissionStatus.permanentlyDenied;

                                  // If this is a microphone error and camera is granted, show both buttons
                                  if (isMicrophoneError && cameraStatus == PermissionStatus.granted) {
                                    return Column(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: microphonePermDenied ? _openAppSettings : _initializeCamera,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: themeColor,
                                            foregroundColor: widget.settings.loadingBackgroundColor,
                                            minimumSize: const Size(double.infinity, 48),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: Icon(microphonePermDenied ? Icons.settings : Icons.refresh),
                                          label: Text(microphonePermDenied ? widget.settings.errorSettingsButtonText : widget.settings.errorRetryButtonText),
                                        ),
                                        const SizedBox(height: 12),
                                        TextButton.icon(
                                          onPressed: () => _initializeCamera(forceWithoutAudio: true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: widget.settings.loadingTextColor,
                                            minimumSize: const Size(double.infinity, 48),
                                          ),
                                          icon: const Icon(Icons.videocam_off),
                                          label: Text(widget.settings.errorContinueWithoutAudioText),
                                        ),
                                      ],
                                    );
                                  }

                                  // Otherwise, just show the primary action button
                                  return ElevatedButton.icon(
                                    onPressed: (isPermissionError && (cameraPermDenied || microphonePermDenied)) ? _openAppSettings : _initializeCamera,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPermissionError ? themeColor : Theme.of(context).colorScheme.secondary,
                                      foregroundColor: widget.settings.loadingBackgroundColor,
                                      minimumSize: const Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: Icon(isPermissionError && (cameraPermDenied || microphonePermDenied) ? Icons.settings : Icons.refresh),
                                    label: Text(isPermissionError && (cameraPermDenied || microphonePermDenied) ? widget.settings.errorSettingsButtonText : widget.settings.errorRetryButtonText),
                                  );
                                }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionInstructions({bool isCameraPermission = true}) {
    // Get the theme color
    final themeColor = Theme.of(context).primaryColor;

    String instructions;
    if (Platform.isAndroid) {
      instructions = 'To enable ${isCameraPermission ? 'camera' : 'microphone'} access:\n'
          '1. Open device Settings\n'
          '2. Go to Apps or Application Manager\n'
          '3. Find ${widget.settings.appName}\n'
          '4. Tap Permissions\n'
          '5. Enable ${isCameraPermission ? 'Camera' : 'Microphone'}';
    } else if (Platform.isIOS) {
      instructions = 'To enable ${isCameraPermission ? 'camera' : 'microphone'} access:\n'
          '1. Open device Settings\n'
          '2. Find ${widget.settings.appName} in the list\n'
          '3. Tap on the app name\n'
          '4. Enable ${isCameraPermission ? 'Camera' : 'Microphone'} access';
    } else {
      instructions = 'Please enable ${isCameraPermission ? 'camera' : 'microphone'} permissions in your device settings.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.settings.errorHowToEnableText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: widget.settings.loadingTextColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            instructions,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: widget.settings.loadingTextColor,
                ),
          ),
        ],
      ),
    );
  }

  bool _isPermanentlyDenied() {
    return _errorMessage?.toLowerCase().contains('permanent') ?? false;
  }

  Future<void> _openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
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
        loadingBuilder: (context, value) => const SizedBox.shrink(),
      ),
    );
  }

  // Add these missing helper methods

  // Convert CameraPreviewSettings to CaptureSettings with optional overrides
  CaptureSettings _createCaptureSettings({
    bool forceWithoutAudio = false,
    FocusMode? initialFocusMode,
  }) {
    return CaptureSettings(
      cameraMode: widget.settings.cameraMode,
      resolution: widget.settings.resolution,
      flashMode: widget.settings.flashMode,
      enableAudio: forceWithoutAudio ? false : widget.settings.enableAudio,
      compressionQuality: widget.settings.compressionQuality,
      imageQuality: widget.settings.imageQuality,
      videoQuality: widget.settings.videoQuality,
      addLocationMetadata: widget.settings.addLocationMetadata,
      locationAccuracy: widget.settings.locationAccuracy,
      exposureMode: widget.settings.exposureMode,
      focusMode: initialFocusMode ?? widget.settings.focusMode,
      deviceOrientation: widget.settings.deviceOrientation,
    );
  }

  // Get camera index to use (front or back)
  int _getCameraIndexToUse(List<CameraDescription> cameras) {
    // Default to first camera
    int cameraIndex = 0;

    // Try to find back camera for initial use
    for (int i = 0; i < cameras.length; i++) {
      if (cameras[i].lensDirection == CameraLensDirection.back) {
        cameraIndex = i;
        break;
      }
    }

    return cameraIndex;
  }

  // Selected camera index
  int _selectedCameraIndex = 0;

  // Handle errors consistently
  void _handleError(String source, String message, Object? error, bool isRecoverable, [StackTrace? stackTrace]) {
    final fullMessage = '$source: $message';
    debugPrint('CameralyCamera error: $fullMessage');
    if (error != null) {
      debugPrint('Error details: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }

    // Update state
    if (mounted) {
      setState(() {
        _isInitializing = false;
        _errorMessage = fullMessage;
      });
    }

    // Call error callback
    widget.settings.onError?.call(source, message, error: error, isRecoverable: isRecoverable);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only handle app lifecycle changes if controller is initialized
    if (_controller != null && _lifecycleMachine != null) {
      _lifecycleMachine!.handleAppLifecycleChange(state);
    }
  }

  // Show a dialog for microphone permission issues
  Future<void> _showMicrophonePermissionDialog() async {
    // Get the theme color
    final themeColor = Theme.of(context).primaryColor;

    final statuses = await _checkPermissionStatuses();
    final micStatus = statuses['microphone']!;
    final isPermanentlyDenied = micStatus == PermissionStatus.permanentlyDenied;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            widget.settings.errorMicrophonePermissionTitle,
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(isPermanentlyDenied ? 'Microphone permission has been permanently denied.' : 'Microphone permission is required for video recording with audio.'),
                const SizedBox(height: 8),
                const Text('You can continue without audio recording, or enable microphone access in settings.'),
                if (isPermanentlyDenied) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      Platform.isAndroid ? 'Go to: Settings → Apps → ${widget.settings.appName} → Permissions → Microphone' : 'Go to: Settings → ${widget.settings.appName} → Microphone',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(widget.settings.errorContinueWithoutAudioText),
              onPressed: () {
                Navigator.of(context).pop();
                _initializeCamera(forceWithoutAudio: true);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: themeColor,
              ),
              child: Text(isPermanentlyDenied ? widget.settings.errorSettingsButtonText : widget.settings.errorRetryButtonText),
              onPressed: () {
                Navigator.of(context).pop();
                if (isPermanentlyDenied) {
                  _openAppSettings();
                } else {
                  _initializeCamera();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Show a dialog prompting the user to go to settings
  Future<void> _showSettingsDialog({bool isCamera = true}) async {
    // Get the theme color
    final themeColor = Theme.of(context).primaryColor;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isCamera ? widget.settings.errorCameraPermissionTitle : widget.settings.errorMicrophonePermissionTitle,
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('${isCamera ? 'Camera' : 'Microphone'} permission has been permanently denied.'),
                const SizedBox(height: 8),
                Text('You need to enable it in your device settings to ${isCamera ? 'use the camera' : 'record audio'}.'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    Platform.isAndroid ? 'Go to: Settings → Apps → ${widget.settings.appName} → Permissions → ${isCamera ? 'Camera' : 'Microphone'}' : 'Go to: Settings → ${widget.settings.appName} → ${isCamera ? 'Camera' : 'Microphone'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (!isCamera) ...[
              TextButton(
                child: Text(widget.settings.errorContinueWithoutAudioText),
                onPressed: () {
                  Navigator.of(context).pop();
                  _initializeCamera(forceWithoutAudio: true);
                },
              ),
            ],
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: themeColor,
              ),
              child: Text(widget.settings.errorSettingsButtonText),
              onPressed: () {
                Navigator.of(context).pop();
                _openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Add device orientation change detection
  void _checkOrientationChange() {
    // Force UI refresh on orientation change to help camera initialization
    final currentOrientation = MediaQuery.of(context).orientation;
    if (_lastOrientation != null && _lastOrientation != currentOrientation) {
      debugPrint('Orientation changed, refreshing camera UI');
      if (_controller != null && !_isInitializing) {
        // Refresh the camera by applying current settings
        _controller!.setFlashMode(_controller!.value.flashMode);
        _controller!.setFocusMode(_controller!.value.focusMode);
        _controller!.setExposureMode(_controller!.value.exposureMode);
      }
    }
    _lastOrientation = currentOrientation;
  }

  Orientation? _lastOrientation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkOrientationChange();
  }
}
