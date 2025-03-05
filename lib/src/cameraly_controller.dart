import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'cameraly_value.dart';
import 'types/capture_settings.dart';
import 'utils/permission_handler.dart';

/// Controller for the Cameraly camera interface.
class CameralyController extends ValueNotifier<CameralyValue> {
  /// Creates a new controller instance.
  CameralyController({
    required CameraDescription description,
    CaptureSettings? settings,
  })  : _description = description,
        _settings = settings ?? const CaptureSettings(),
        _permissionHandler = const CameralyPermissionHandler(),
        super(const CameralyValue.uninitialized());

  final CameraDescription _description;
  final CaptureSettings _settings;
  final CameralyPermissionHandler _permissionHandler;
  CameraController? _controller;

  /// The camera description this controller is using
  CameraDescription get description => _description;

  /// The current settings being used
  CaptureSettings get settings => _settings;

  /// Whether the controller has been initialized
  bool get isInitialized => value.isInitialized;

  /// The underlying camera controller
  CameraController? get cameraController => _controller;

  /// Initializes the camera controller.
  Future<void> initialize() async {
    try {
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

      value = CameralyValue(
        isInitialized: true,
        flashMode: _settings.flashMode,
        exposureMode: _settings.exposureMode,
        focusMode: _settings.focusMode,
        deviceOrientation: _settings.deviceOrientation,
        permissionState: CameraPermissionState.granted,
        isFrontCamera: _description.lensDirection == CameraLensDirection.front,
      );

      // Apply initial settings
      await setFlashMode(_settings.flashMode);
      await setExposureMode(_settings.exposureMode);
      await setFocusMode(_settings.focusMode);
    } on CameraException catch (e) {
      value = value.copyWith(
        error: 'Failed to initialize camera: ${e.description}',
        permissionState: CameraPermissionState.denied,
      );
      rethrow;
    }
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
      final file = await _controller!.takePicture();
      value = value.copyWith(isTakingPicture: false);
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
    try {
      await _controller!.setFlashMode(mode);
      value = value.copyWith(flashMode: mode);
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
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
      value = value.copyWith(isRecordingVideo: false);
      return file;
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
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
      final cameras = await availableCameras();

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

        // Dispose current controller
        await _controller?.dispose();

        // Create a new controller with the new camera
        final newController = CameralyController(
          description: newCamera,
          settings: previousSettings,
        );

        // Initialize the new controller
        await newController.initialize();

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
      // Debug print
      print('Setting focus and exposure at: $point');

      // The point is already normalized (0.0 to 1.0) from the CameralyPreview
      // Make sure it's within valid bounds
      final normalizedPoint = Offset(
        point.dx.clamp(0.0, 1.0),
        point.dy.clamp(0.0, 1.0),
      );

      // Update the value with the new focus and exposure points immediately
      // This will trigger the UI update for the focus circle right away
      value = value.copyWith(
        focusPoint: normalizedPoint,
        exposurePoint: normalizedPoint,
        focusMode: FocusMode.auto,
        exposureMode: ExposureMode.auto,
        error: null, // Clear any previous errors
      );

      // Set focus mode to auto to enable tap-to-focus
      await _controller!.setFocusMode(FocusMode.auto);

      // Set exposure mode to auto to enable tap-to-expose
      await _controller!.setExposureMode(ExposureMode.auto);

      // Set the focus point
      await _controller!.setFocusPoint(normalizedPoint);

      // Set the exposure point
      await _controller!.setExposurePoint(normalizedPoint);
    } catch (e) {
      print('Error setting focus and exposure: $e');
      value = value.copyWith(
        error: 'Failed to set focus and exposure point: $e',
      );
    }
  }

  /// Disposes of the controller.
  @override
  Future<void> dispose() async {
    await _controller?.dispose();
    super.dispose();
  }
}
