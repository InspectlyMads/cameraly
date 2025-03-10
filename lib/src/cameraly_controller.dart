import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cameraly_value.dart';
import 'types/camera_mode.dart';
import 'types/capture_settings.dart';
import 'types/photo_settings.dart';
import 'types/video_settings.dart';
import 'utils/media_manager.dart';
import 'utils/permission_handler.dart';

/// Controller for the Cameraly camera interface.
class CameralyController extends ValueNotifier<CameralyValue> with WidgetsBindingObserver {
  /// Creates a new controller instance.
  CameralyController({
    required CameraDescription description,
    CaptureSettings? settings,
    CameralyMediaManager? mediaManager,
  })  : _description = description,
        _settings = settings ?? const CaptureSettings(),
        _permissionHandler = const CameralyPermissionHandler(),
        _mediaManager = mediaManager ?? CameralyMediaManager(),
        _isProcessingOrientation = false,
        super(const CameralyValue.uninitialized()) {
    // Register as an observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  final CameraDescription _description;
  final CaptureSettings _settings;
  final CameralyPermissionHandler _permissionHandler;
  final CameralyMediaManager _mediaManager;
  CameraController? _controller;
  bool _isProcessingOrientation;

  /// The camera description this controller is using
  CameraDescription get description => _description;

  /// The current settings being used
  CaptureSettings get settings => _settings;

  /// Whether the controller has been initialized
  bool get isInitialized => value.isInitialized;

  /// The underlying camera controller
  CameraController? get cameraController => _controller;

  /// The media manager for handling captured photos and videos
  CameralyMediaManager get mediaManager => _mediaManager;

  /// Gets a list of available cameras on the device.
  ///
  /// This is a convenience method to avoid importing the camera package directly.
  static Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      return await availableCameras();
    } catch (e) {
      debugPrint('Error getting available cameras: $e');
      return [];
    }
  }

  /// Creates and initializes a CameralyController with the first available camera.
  ///
  /// This is a convenience method that:
  /// 1. Gets available cameras
  /// 2. Creates a controller with the first camera (or specified cameraIndex)
  /// 3. Initializes the controller
  ///
  /// Returns null if no cameras are available or initialization fails.
  ///
  /// Example usage:
  /// ```dart
  /// final controller = await CameralyController.initializeCamera();
  /// if (controller != null) {
  ///   // Camera initialized successfully
  /// }
  /// ```
  static Future<CameralyController?> initializeCamera({
    int cameraIndex = 0,
    CaptureSettings? settings,
    bool enableFallback = true,
  }) async {
    try {
      // Get available cameras
      final cameras = await getAvailableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        return null;
      }

      // Make sure the camera index is valid
      if (cameraIndex >= cameras.length) {
        debugPrint('Camera index out of range, using first camera');
        cameraIndex = 0;
      }

      // Create controller with the selected camera
      final controller = CameralyController(
        description: cameras[cameraIndex],
        settings: settings,
      );

      // Initialize the controller with fallback if enabled
      if (enableFallback) {
        await controller.initializeWithFallback();
      } else {
        await controller.initialize();
      }

      return controller;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      return null;
    }
  }

  /// Creates and initializes a CameralyController optimized for photo capture.
  ///
  /// This is a convenience method that:
  /// 1. Gets available cameras
  /// 2. Creates a controller with the first camera (or specified cameraIndex)
  /// 3. Initializes the controller with photo-specific settings
  ///
  /// Returns null if no cameras are available or initialization fails.
  ///
  /// Example usage:
  /// ```dart
  /// final controller = await CameralyController.initializeForPhotos();
  /// if (controller != null) {
  ///   // Camera initialized successfully for photos
  /// }
  /// ```
  ///
  /// @deprecated Use [initializeCamera] with CameraMode.photoOnly instead.
  /// Example: `CameralyController.initializeCamera(settings: CaptureSettings(cameraMode: CameraMode.photoOnly))`
  static Future<CameralyController?> initializeForPhotos({
    int cameraIndex = 0,
    PhotoSettings? settings,
    bool enableFallback = true,
  }) async {
    debugPrint('Warning: initializeForPhotos is deprecated. '
        'Use initializeCamera with CameraMode.photoOnly instead.');

    // Convert PhotoSettings to CaptureSettings
    final captureSettings = settings != null
        ? CaptureSettings(
            resolution: settings.resolution,
            flashMode: settings.flashMode,
            enableAudio: false, // Audio disabled for photos
            cameraMode: CameraMode.photoOnly,
          )
        : const CaptureSettings(
            cameraMode: CameraMode.photoOnly,
          );

    return initializeCamera(
      cameraIndex: cameraIndex,
      settings: captureSettings,
      enableFallback: enableFallback,
    );
  }

  /// Creates and initializes a CameralyController optimized for video recording.
  ///
  /// This is a convenience method that:
  /// 1. Gets available cameras
  /// 2. Creates a controller with the first camera (or specified cameraIndex)
  /// 3. Initializes the controller with video-specific settings
  ///
  /// Returns null if no cameras are available or initialization fails.
  ///
  /// Example usage:
  /// ```dart
  /// final controller = await CameralyController.initializeForVideos();
  /// if (controller != null) {
  ///   // Camera initialized successfully for videos
  /// }
  /// ```
  ///
  /// @deprecated Use [initializeCamera] with CameraMode.videoOnly instead.
  /// Example: `CameralyController.initializeCamera(settings: CaptureSettings(cameraMode: CameraMode.videoOnly))`
  static Future<CameralyController?> initializeForVideos({
    int cameraIndex = 0,
    VideoSettings? settings,
    bool enableFallback = true,
  }) async {
    debugPrint('Warning: initializeForVideos is deprecated. '
        'Use initializeCamera with CameraMode.videoOnly instead.');

    // Convert VideoSettings to CaptureSettings
    final captureSettings = settings != null
        ? CaptureSettings(
            resolution: settings.resolution,
            flashMode: FlashMode.off, // Flash is typically off for videos
            enableAudio: settings.enableAudio,
            cameraMode: CameraMode.videoOnly,
            // Note: maxDuration is specific to VideoSettings and not available in CaptureSettings
          )
        : const CaptureSettings(
            cameraMode: CameraMode.videoOnly,
            enableAudio: true,
          );

    return initializeCamera(
      cameraIndex: cameraIndex,
      settings: captureSettings,
      enableFallback: enableFallback,
    );
  }

  /// Initializes the camera controller.
  Future<void> initialize() async {
    try {
      // Check if we're already in a deniedButContinued state
      if (value.permissionState == CameraPermissionState.deniedButContinued) {
        // User has chosen to continue without camera, so we don't try to initialize
        return;
      }

      final hasPermission = await _permissionHandler.requestPermissions(
        requireAudio: _settings.enableAudio,
      );

      if (!hasPermission) {
        value = value.copyWith(
          permissionState: CameraPermissionState.denied,
          error: 'Camera permission denied',
        );
        return;
      }

      _controller = CameraController(
        _description,
        _settings.resolution,
        enableAudio: _settings.enableAudio,
      );

      await _controller!.initialize();

      // Listen for camera value changes to update our value
      _controller!.addListener(_updateValueFromController);

      // Set initial orientation for Android
      if (Platform.isAndroid) {
        await _handleInitialOrientation();
      }

      // Default to assuming flash is available, we'll update this if we detect otherwise
      bool hasFlashCapability = true;

      // Get the current device orientation - we'll update this after initialization
      // but we need a default value for now
      final deviceOrientation = _settings.deviceOrientation;

      value = CameralyValue(
        isInitialized: true,
        flashMode: _settings.flashMode,
        exposureMode: _settings.exposureMode,
        focusMode: _settings.focusMode,
        deviceOrientation: deviceOrientation,
        permissionState: CameraPermissionState.granted,
        isFrontCamera: _description.lensDirection == CameraLensDirection.front,
        zoomLevel: 1.0,
        hasFlashCapability: hasFlashCapability,
      );

      // Apply initial settings
      // Try to set flash mode, but handle gracefully if it fails
      try {
        await setFlashMode(_settings.flashMode);
      } catch (e) {
        debugPrint('Failed to set initial flash mode: $e');
        // If we get an error setting flash mode, update our state to indicate no flash capability
        if (e.toString().toLowerCase().contains('flash') || e.toString().toLowerCase().contains('torch')) {
          value = value.copyWith(hasFlashCapability: false);
        }
      }

      await setExposureMode(_settings.exposureMode);
      await setFocusMode(_settings.focusMode);

      // Get the actual zoom level after initialization
      try {
        final zoom = await _controller!.getMaxZoomLevel();
        if (zoom > 1.0) {
          // Only update if we got a valid zoom level
          value = value.copyWith(zoomLevel: 1.0);
        }
      } catch (e) {
        // Ignore zoom errors during initialization
      }
    } on CameraException catch (e) {
      value = value.copyWith(
        error: 'Failed to initialize camera: ${e.description}',
        permissionState: CameraPermissionState.denied,
      );
      rethrow;
    }
  }

  /// Handles the initial orientation setup for Android devices
  Future<void> _handleInitialOrientation() async {
    try {
      // Get the current device orientation from the platform
      final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
      final view = platformDispatcher.views.first;
      final size = view.physicalSize;

      // Determine if we're in landscape mode
      final isLandscape = size.width > size.height;

      // Get the view padding to determine if it's landscape left or right
      final viewPadding = view.padding;

      // Determine the orientation
      DeviceOrientation orientation;

      if (isLandscape) {
        // In landscape, check if it's left or right based on padding
        final isLandscapeLeft = viewPadding.left > viewPadding.right;
        orientation = isLandscapeLeft ? DeviceOrientation.landscapeLeft : DeviceOrientation.landscapeRight;
        debugPrint('📱 Initial orientation: Landscape ${isLandscapeLeft ? "LEFT" : "RIGHT"} (Android)');
      } else {
        orientation = DeviceOrientation.portraitUp;
        debugPrint('📱 Initial orientation: Portrait Up (Android)');
      }

      debugPrint('📱 Initial view padding: $viewPadding');
      debugPrint('📱 Initial physical size: $size');
      debugPrint('🧭 Setting initial orientation to: $orientation');

      // Set the device orientation in the value
      value = value.copyWith(deviceOrientation: orientation);

      // Set the capture orientation for Android
      await _controller?.lockCaptureOrientation(orientation);
    } catch (e) {
      debugPrint('Error setting initial orientation: $e');
    }
  }

  /// Handles orientation changes
  Future<void> handleOrientationChange(BuildContext context) async {
    if (_isProcessingOrientation || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    // Skip orientation handling for iOS - it handles orientation correctly by itself
    if (!Platform.isAndroid) {
      debugPrint('📱 Skipping orientation handling on iOS - handled natively');
      return;
    }

    _isProcessingOrientation = true;

    try {
      // Get current orientation
      final orientation = MediaQuery.of(context).orientation;
      DeviceOrientation targetOrientation;

      if (orientation == Orientation.landscape) {
        // Use the window padding to determine if it's landscape left or right
        // This works on Android
        final windowPadding = MediaQuery.of(context).viewPadding;
        final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

        // If the left padding is greater than the right padding, it's likely landscape left
        final isLandscapeLeft = windowPadding.left > windowPadding.right;

        targetOrientation = isLandscapeLeft ? DeviceOrientation.landscapeLeft : DeviceOrientation.landscapeRight;

        // Print orientation information
        debugPrint('🔄 ORIENTATION CHANGED: Landscape ${isLandscapeLeft ? "LEFT" : "RIGHT"} (Android)');
        debugPrint('📱 Window Padding: $windowPadding');
        debugPrint('📱 Device Pixel Ratio: $devicePixelRatio');
        debugPrint('🧭 Target Orientation: $targetOrientation');
      } else {
        targetOrientation = DeviceOrientation.portraitUp;

        // Print orientation information
        debugPrint('🔄 ORIENTATION CHANGED: Portrait Up (Android)');
        debugPrint('📱 Device Size: ${WidgetsBinding.instance.platformDispatcher.views.first.physicalSize}');
        debugPrint('🧭 Target Orientation: $targetOrientation');
      }

      // Set the orientation for Android
      try {
        // Set the capture orientation
        await _controller!.lockCaptureOrientation(targetOrientation);

        // Force a value update to trigger UI rebuild
        value = value.copyWith(
          deviceOrientation: targetOrientation,
          // Just update with current value to trigger notification
          isInitialized: value.isInitialized,
        );
      } catch (e) {
        debugPrint('Error updating camera orientation: $e');
      }
    } finally {
      _isProcessingOrientation = false;
    }
  }

  /// Returns the appropriate transform for the camera preview based on orientation
  Transform getPreviewTransform(BuildContext context, Widget child) {
    // We don't need to transform the preview anymore since it was correct before
    return Transform.rotate(
      angle: 0,
      child: child,
    );
  }

  /// Builds a camera preview widget with proper orientation handling
  Widget buildOrientationAwarePreview(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(color: Colors.black);
    }

    // Get the current orientation from MediaQuery
    final mediaQueryOrientation = MediaQuery.of(context).orientation;

    // Get the device orientation from our controller value
    // This is more reliable, especially for the initial orientation
    final deviceOrientation = value.deviceOrientation;

    // Determine if we're in landscape mode
    final isLandscape = mediaQueryOrientation == Orientation.landscape || deviceOrientation == DeviceOrientation.landscapeLeft || deviceOrientation == DeviceOrientation.landscapeRight;

    // Get the camera's natural aspect ratio
    final cameraAspectRatio = _controller!.value.aspectRatio;

    // In portrait mode, we need to invert the aspect ratio
    // This is because the camera sensor is naturally in landscape orientation
    final previewRatio = isLandscape ? cameraAspectRatio : 1.0 / cameraAspectRatio;

    // Check if we need to apply rotation for landscape left
    final isLandscapeLeft = deviceOrientation == DeviceOrientation.landscapeLeft;

    // Only apply rotation on Android - iOS handles orientation correctly by itself
    if (Platform.isAndroid && isLandscapeLeft) {
      // For landscape left on Android, we need to rotate 180 degrees to fix upside-down preview
      debugPrint('📱 Applying rotation for Landscape LEFT in preview (Android)');
      return AspectRatio(
        aspectRatio: previewRatio,
        child: Transform.rotate(
          angle: 3.14159, // 180 degrees (π) rotation for landscape left
          child: CameraPreview(_controller!),
        ),
      );
    } else {
      // For iOS or non-landscape-left on Android, no rotation needed
      debugPrint('📱 No rotation needed for ${deviceOrientation.toString()} in preview (${Platform.isAndroid ? "Android" : "iOS"})');
      return AspectRatio(
        aspectRatio: previewRatio,
        child: CameraPreview(_controller!),
      );
    }
  }

  /// Updates the value from the camera controller.
  void _updateValueFromController() {
    if (_controller == null) return;

    // Update our value with the latest from the camera controller
    value = value.copyWith(
      isRecordingVideo: _controller!.value.isRecordingVideo,
      // We don't update zoom level here as it's updated in setZoomLevel
    );
  }

  /// Takes a picture using the current settings.
  Future<XFile> takePicture() async {
    if (!value.isInitialized) {
      throw CameraException(
        'notInitialized',
        'Camera has not been initialized',
      );
    }

    if (value.isTakingPicture) {
      throw CameraException(
        'captureInProgress',
        'A capture operation is already in progress',
      );
    }

    try {
      value = value.copyWith(isTakingPicture: true);

      // Ensure the orientation is set correctly before taking the picture
      // Only needed for Android - iOS handles orientation correctly by itself
      if (Platform.isAndroid) {
        // Use the current device orientation from our value
        // This is more reliable than trying to detect it here
        final deviceOrientation = value.deviceOrientation;

        debugPrint('📸 Taking picture with orientation: $deviceOrientation (Android)');

        // Lock the capture orientation to ensure the image is captured correctly
        await _controller!.lockCaptureOrientation(deviceOrientation);
      }

      // Take the picture
      final file = await _controller!.takePicture();

      value = value.copyWith(
        isTakingPicture: false,
        lastCapturedPhoto: file,
      );

      return file;
    } catch (e) {
      value = value.copyWith(
        isTakingPicture: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Sets the flash mode.
  Future<void> setFlashMode(FlashMode mode) async {
    if (!value.isInitialized) return;

    // If the camera doesn't have flash capability, don't try to set the flash mode
    if (!value.hasFlashCapability) {
      debugPrint('Camera does not have flash capabilities, ignoring flash mode change');
      return;
    }

    try {
      // Try to set the flash mode, but catch any exceptions related to flash capabilities
      await _controller!.setFlashMode(mode);
      value = value.copyWith(flashMode: mode);
    } on CameraException catch (e) {
      debugPrint('Error setting flash mode: ${e.description}');

      // Check if the error is related to flash capabilities
      if (e.description?.toLowerCase().contains('flash') == true || e.description?.toLowerCase().contains('torch') == true) {
        // If it's a flash-related error, update the value to indicate no flash capability
        debugPrint('Camera does not have flash capabilities, updating state');
        value = value.copyWith(flashMode: FlashMode.off, hasFlashCapability: false);
      } else {
        // For other types of errors, update the error state
        value = value.copyWith(error: e.description);
      }
    }
  }

  /// Sets the exposure mode.
  Future<void> setExposureMode(ExposureMode mode) async {
    if (!value.isInitialized) return;
    try {
      await _controller!.setExposureMode(mode);
      value = value.copyWith(exposureMode: mode);
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
    }
  }

  /// Sets the focus mode.
  Future<void> setFocusMode(FocusMode mode) async {
    if (!value.isInitialized) return;
    try {
      await _controller!.setFocusMode(mode);
      value = value.copyWith(focusMode: mode);
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
    }
  }

  /// Starts video recording.
  Future<void> startVideoRecording() async {
    if (!value.isInitialized) {
      throw CameraException(
        'notInitialized',
        'Camera has not been initialized',
      );
    }

    if (value.isRecordingVideo) {
      throw CameraException(
        'captureInProgress',
        'A video recording is already in progress',
      );
    }

    try {
      // Ensure the orientation is set correctly before starting recording
      // Only needed for Android - iOS handles orientation correctly by itself
      if (Platform.isAndroid) {
        // Use the current device orientation from our value
        // This is more reliable than trying to detect it here
        final deviceOrientation = value.deviceOrientation;

        debugPrint('🎥 Starting video recording with orientation: $deviceOrientation (Android)');

        // Lock the capture orientation to ensure the video is recorded correctly
        await _controller!.lockCaptureOrientation(deviceOrientation);
      }

      await _controller!.startVideoRecording();
      value = value.copyWith(isRecordingVideo: true);
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
    }
  }

  /// Stops video recording and returns the file.
  Future<XFile> stopVideoRecording() async {
    if (!value.isInitialized) {
      throw CameraException(
        'notInitialized',
        'Camera has not been initialized',
      );
    }

    if (!value.isRecordingVideo) {
      throw CameraException(
        'notRecording',
        'No video recording in progress',
      );
    }

    try {
      final file = await _controller!.stopVideoRecording();
      value = value.copyWith(
        isRecordingVideo: false,
        lastRecordedVideo: file,
      );
      // Add the recorded video to the media manager
      _mediaManager.addMedia(file);
      return file;
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
    } catch (e) {
      value = value.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Pauses video recording.
  Future<void> pauseVideoRecording() async {
    if (!value.isInitialized || !value.isRecordingVideo) return;
    try {
      await _controller!.pauseVideoRecording();
      value = value.copyWith(isRecordingPaused: true);
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
    }
  }

  /// Resumes video recording.
  Future<void> resumeVideoRecording() async {
    if (!value.isInitialized || !value.isRecordingVideo) return;
    try {
      await _controller!.resumeVideoRecording();
      value = value.copyWith(isRecordingPaused: false);
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
    }
  }

  /// Gets the maximum zoom level.
  Future<double> getMaxZoomLevel() async {
    if (!value.isInitialized) return 1.0;
    try {
      return await _controller!.getMaxZoomLevel();
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      return 1.0;
    }
  }

  /// Gets the minimum zoom level.
  Future<double> getMinZoomLevel() async {
    if (!value.isInitialized) return 1.0;
    try {
      return await _controller!.getMinZoomLevel();
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      return 1.0;
    }
  }

  /// Sets the zoom level.
  Future<void> setZoomLevel(double zoom) async {
    if (!value.isInitialized) return;
    try {
      await _controller!.setZoomLevel(zoom);
      value = value.copyWith(zoomLevel: zoom);
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
    }
  }

  /// Handles pinch-to-zoom gestures with sensitivity adjustment.
  ///
  /// This method takes the raw scale value from a scale gesture and applies
  /// sensitivity adjustment to make zooming more controlled.
  ///
  /// Parameters:
  /// - [scale]: The raw scale value from the gesture detector
  /// - [sensitivity]: Optional sensitivity factor (0.0-1.0), defaults to 0.3 (30%)
  /// - [minZoom]: Optional minimum zoom level, defaults to 1.0
  /// - [maxZoom]: Optional maximum zoom level, defaults to 5.0
  ///
  /// Returns a Future that completes when the zoom is applied.
  Future<void> handleScale(
    double scale, {
    double sensitivity = 0.3,
    double? minZoom,
    double? maxZoom,
  }) async {
    if (!value.isInitialized) return;

    try {
      // Get current zoom level and initial zoom level (if set)
      final baseZoom = value.initialZoomLevel ?? value.zoomLevel;

      // Get min/max zoom levels if not provided
      final effectiveMinZoom = minZoom ?? await getMinZoomLevel();
      final effectiveMaxZoom = maxZoom ?? await getMaxZoomLevel();

      // Apply sensitivity adjustment to make zooming more controlled
      // Use the initial zoom level as the base for calculations to prevent jumps
      final newZoom = (baseZoom * scale).clamp(
        effectiveMinZoom,
        effectiveMaxZoom,
      );

      // Apply the new zoom level
      await setZoomLevel(newZoom);
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
    }
  }

  /// Toggles the flash mode between off and auto.
  Future<void> toggleFlash() async {
    if (!value.isInitialized) return;

    final FlashMode newMode;
    switch (value.flashMode) {
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        newMode = FlashMode.off;
        break;
    }

    await setFlashMode(newMode);
  }

  /// Switches between front and back cameras.
  Future<CameralyController?> switchCamera() async {
    if (!value.isInitialized) return null;

    try {
      // Get available cameras
      final cameras = await getAvailableCameras();

      // Find a camera facing the opposite direction
      final lensDirection = _description.lensDirection;
      final newDirection = lensDirection == CameraLensDirection.front ? CameraLensDirection.back : CameraLensDirection.front;

      final newCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == newDirection,
        orElse: () => _description,
      );

      // If we found a different camera, dispose the current one and initialize the new one
      if (newCamera.name != _description.name) {
        final previousSettings = _settings;
        final wasRecording = value.isRecordingVideo;

        // Stop recording if needed
        if (wasRecording) {
          await stopVideoRecording();
        }

        // Dispose current controller
        await _controller?.dispose();
        _controller = null;

        // Create a new controller with the new camera
        final newController = CameralyController(
          description: newCamera,
          settings: previousSettings,
        );

        // Initialize the new controller with fallback options
        await newController.initializeWithFallback();

        // Restore previous state
        if (wasRecording) {
          await newController.startVideoRecording();
        }

        // Return the new controller
        return newController;
      }

      return null;
    } catch (e) {
      value = value.copyWith(
        error: 'Failed to switch camera: $e',
      );
      rethrow;
    }
  }

  /// Captures a photo or toggles video recording based on the current state.
  Future<XFile?> captureMedia() async {
    if (!value.isInitialized) return null;

    try {
      if (value.isRecordingVideo) {
        // If recording, stop recording and return the video file
        return await stopVideoRecording();
      } else {
        // Otherwise take a picture
        return await takePicture();
      }
    } catch (e) {
      value = value.copyWith(
        error: 'Failed to capture media: $e',
      );
      return null;
    }
  }

  /// Toggles video recording (starts or stops).
  Future<XFile?> toggleVideoRecording() async {
    if (!value.isInitialized) return null;

    try {
      if (value.isRecordingVideo) {
        // If recording, stop recording and return the video file
        return await stopVideoRecording();
      } else {
        // Otherwise start recording
        await startVideoRecording();
        return null;
      }
    } catch (e) {
      value = value.copyWith(
        error: 'Failed to toggle video recording: $e',
      );
      return null;
    }
  }

  /// Sets the focus and exposure point.
  Future<void> setFocusAndExposurePoint(Offset point) async {
    if (!value.isInitialized) return;

    try {
      // The point is already normalized (0.0 to 1.0) from the CameralyPreview
      // Make sure it's within valid bounds
      final normalizedPoint = Offset(
        point.dx.clamp(0.0, 1.0),
        point.dy.clamp(0.0, 1.0),
      );

      // Set focus and exposure modes to auto first
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);

      // Create a temporary value with the new focus point
      // This ensures we don't update the UI state until all operations succeed
      CameralyValue newValue = value.copyWith(
        focusMode: FocusMode.auto,
        exposureMode: ExposureMode.auto,
      );

      // Set focus point first and wait for it to complete
      await _controller!.setFocusPoint(normalizedPoint);
      newValue = newValue.copyWith(focusPoint: normalizedPoint);

      // Then set exposure point and wait for it to complete
      await _controller!.setExposurePoint(normalizedPoint);
      newValue = newValue.copyWith(exposurePoint: normalizedPoint);

      // Only update the value once all operations have succeeded
      value = newValue;
    } catch (e) {
      debugPrint('Error setting focus and exposure: $e');
      // Don't update the focus point if there was an error
      value = value.copyWith(
        error: 'Failed to set focus and exposure point: $e',
      );
    }
  }

  /// Initializes the camera with fallback options if the initial initialization fails.
  ///
  /// This method attempts to initialize the camera with the current settings.
  /// If that fails, it tries alternative settings in the following order:
  /// 1. Disable flash if it's enabled
  /// 2. Lower resolution if it's high
  /// 3. Try video-only mode if photo mode fails
  ///
  /// Returns true if initialization succeeds with any settings, false otherwise.
  Future<bool> initializeWithFallback() async {
    try {
      // First try with current settings
      debugPrint('Attempting to initialize camera with current settings');
      await initialize();
      debugPrint('Camera initialized successfully with current settings');
      return true;
    } catch (e) {
      debugPrint('Error initializing camera with current settings: $e');

      // Try with flash disabled if the error is related to flash
      if (e.toString().contains('flash') || e.toString().contains('Flash')) {
        debugPrint('Flash capability error detected, retrying with flash disabled');
        try {
          // Create new settings with flash disabled
          CaptureSettings newSettings;
          if (_settings is PhotoSettings) {
            newSettings = (_settings).copyWith(flashMode: FlashMode.off);
          } else {
            newSettings = _settings;
          }

          // Create a new controller with the new settings
          final newController = CameralyController(
            description: _description,
            settings: newSettings,
          );

          // Initialize the new controller
          await newController.initialize();

          // Update this controller with the new controller's values
          _controller = newController._controller;
          value = newController.value.copyWith(
            hasFlashCapability: false,
          );

          debugPrint('Camera initialized successfully with flash disabled');
          return true;
        } catch (retryError) {
          debugPrint('Retry with flash disabled also failed: $retryError');
        }
      }

      // Try with lower resolution if current resolution is high
      if (_settings.resolution == ResolutionPreset.high || _settings.resolution == ResolutionPreset.veryHigh || _settings.resolution == ResolutionPreset.ultraHigh || _settings.resolution == ResolutionPreset.max) {
        debugPrint('Trying with lower resolution');
        try {
          // Create new settings with lower resolution
          CaptureSettings newSettings;
          if (_settings is PhotoSettings) {
            newSettings = (_settings).copyWith(
              resolution: ResolutionPreset.medium,
              flashMode: FlashMode.off,
            );
          } else if (_settings is VideoSettings) {
            newSettings = (_settings).copyWith(
              resolution: ResolutionPreset.medium,
            );
          } else {
            newSettings = const CaptureSettings(resolution: ResolutionPreset.medium);
          }

          // Create a new controller with the new settings
          final newController = CameralyController(
            description: _description,
            settings: newSettings,
          );

          // Initialize the new controller
          await newController.initialize();

          // Update this controller with the new controller's values
          _controller = newController._controller;
          value = newController.value.copyWith(
            hasFlashCapability: false,
          );

          debugPrint('Camera initialized successfully with lower resolution');
          return true;
        } catch (resolutionError) {
          debugPrint('Retry with lower resolution also failed: $resolutionError');
        }
      }

      // As a last resort, try video-only mode with audio disabled
      debugPrint('Attempting video-only initialization as last resort');
      try {
        // Create new settings for video-only mode
        const videoSettings = VideoSettings(
          resolution: ResolutionPreset.medium,
          enableAudio: false,
        );

        // Create a new controller with video settings
        final newController = CameralyController(
          description: _description,
          settings: videoSettings,
        );

        // Initialize the new controller
        await newController.initialize();

        // Update this controller with the new controller's values
        _controller = newController._controller;
        value = newController.value.copyWith(
          hasFlashCapability: false,
        );

        debugPrint('Video-only initialization successful');
        return true;
      } catch (videoError) {
        debugPrint('Video-only initialization also failed: $videoError');
      }

      // If all attempts fail, update the value with an error
      value = value.copyWith(
        error: 'Failed to initialize camera after multiple attempts',
      );

      return false;
    }
  }

  /// Initializes the camera with platform-specific optimizations.
  ///
  /// This method handles platform-specific camera initialization:
  /// - On Android, it ensures proper orientation handling with CameraX
  /// - On iOS, it handles specific iOS camera quirks
  ///
  /// Returns true if initialization succeeds, false otherwise.
  Future<bool> initializeWithPlatformOptimizations() async {
    try {
      // First, initialize the camera
      await initialize();

      // Then apply platform-specific optimizations
      if (Platform.isAndroid) {
        // For Android with CameraX, we need to set the target rotation
        if (_controller != null) {
          try {
            // This is a dummy call to ensure controller is initialized
            await _controller!.setExposureOffset(0.0);
            debugPrint('Using CameraX on Android with explicit orientation handling');
          } catch (e) {
            debugPrint('Error setting camera orientation: $e');
          }
        }
      } else if (Platform.isIOS) {
        // iOS-specific optimizations if needed
        debugPrint('Applying iOS-specific camera optimizations');
      }

      return true;
    } catch (e) {
      debugPrint('Error in platform-optimized initialization: $e');
      return false;
    }
  }

  /// Sets the device orientation for the camera.
  ///
  /// This method sets the device orientation for the camera without pausing/resuming
  /// the preview, which can cause locking issues.
  Future<void> setDeviceOrientation(DeviceOrientation orientation) async {
    if (!value.isInitialized || _controller == null) return;

    // Skip orientation handling for iOS - it handles orientation correctly by itself
    if (!Platform.isAndroid) {
      debugPrint('📱 Skipping setDeviceOrientation on iOS - handled natively');
      return;
    }

    try {
      // Update the value first to trigger UI updates
      value = value.copyWith(deviceOrientation: orientation);

      // Then set the orientation on the camera controller
      await _controller!.lockCaptureOrientation(orientation);
    } catch (e) {
      debugPrint('Error setting device orientation: $e');
    }
  }

  /// Handles orientation changes based on device sensor data rather than UI orientation.
  /// This can provide smoother transitions when rotating the device.
  void handleDeviceOrientationChange() {
    if (!value.isInitialized || _controller == null) return;

    // Skip orientation handling for iOS - it handles orientation correctly by itself
    if (!Platform.isAndroid) {
      debugPrint('📱 Skipping device orientation handling on iOS - handled natively');
      return;
    }

    // Get the current device orientation from the platform
    final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
    final size = platformDispatcher.views.first.physicalSize;
    final view = platformDispatcher.views.first;

    // Determine orientation based on physical dimensions
    final isLandscape = size.width > size.height;

    // Print orientation information
    debugPrint('📱 DEVICE ORIENTATION CHANGED (Android):');
    debugPrint('📐 Physical Size: $size');
    debugPrint('📱 Is Landscape: $isLandscape');
    debugPrint('🧭 Previous Orientation: ${value.deviceOrientation}');
    debugPrint('📷 Camera Sensor Orientation: ${_description.sensorOrientation}°');

    // Set the appropriate orientation
    DeviceOrientation newOrientation;
    if (isLandscape) {
      // Get the view padding - on most devices, the side with the notch or buttons
      // will have larger padding
      final viewPadding = view.padding;
      final isLandscapeLeft = viewPadding.left > viewPadding.right;

      if (isLandscapeLeft) {
        newOrientation = DeviceOrientation.landscapeLeft;
        debugPrint('🧭 Detected Landscape LEFT orientation (by padding)');
      } else {
        newOrientation = DeviceOrientation.landscapeRight;
        debugPrint('🧭 Detected Landscape RIGHT orientation (by padding)');
      }

      debugPrint('📱 View Padding: $viewPadding');
      debugPrint('🧭 New Orientation: $newOrientation');
    } else {
      newOrientation = DeviceOrientation.portraitUp;
      debugPrint('🧭 New Orientation: $newOrientation');
    }

    setDeviceOrientation(newOrientation);
  }

  @override
  void didChangeMetrics() {
    // This method is called whenever the device orientation changes
    super.didChangeMetrics();

    debugPrint('📊 METRICS CHANGED - Device orientation might have changed');

    // Handle orientation changes directly in the controller
    if (value.isInitialized) {
      handleDeviceOrientationChange();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  /// Manually detects and prints the current device orientation.
  /// This method can be called from outside to debug orientation issues.
  void printCurrentOrientation(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
    final size = platformDispatcher.views.first.physicalSize;
    final isLandscape = size.width > size.height;
    final orientation = mediaQuery.orientation;
    final windowPadding = mediaQuery.viewPadding;
    final devicePixelRatio = mediaQuery.devicePixelRatio;

    debugPrint('📊 ORIENTATION DEBUG INFO:');
    debugPrint('📱 Device Physical Size: $size');
    debugPrint('📱 MediaQuery Orientation: $orientation');
    debugPrint('📱 Is Landscape (by size): $isLandscape');
    debugPrint('📱 Window Padding: $windowPadding');
    debugPrint('📱 Device Pixel Ratio: $devicePixelRatio');
    debugPrint('🧭 Current Controller Orientation: ${value.deviceOrientation}');
    debugPrint('📷 Camera Description: ${_description.name}');
    debugPrint('📷 Camera Lens Direction: ${_description.lensDirection}');
    debugPrint('📷 Camera Sensor Orientation: ${_description.sensorOrientation}°');

    // Try to determine if we're in landscape left or right
    if (orientation == Orientation.landscape) {
      // If the left padding is greater than the right padding, it's likely landscape left
      final isLandscapeLeft = windowPadding.left > windowPadding.right;
      debugPrint('📱 Is Landscape Left (by padding): $isLandscapeLeft');
      debugPrint('📱 Detected Orientation: ${isLandscapeLeft ? "Landscape LEFT" : "Landscape RIGHT"}');
    }
  }
}
