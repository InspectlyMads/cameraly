import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

enum CameraMode { photo, video, combined }

enum CameraFlashMode { off, auto, on, torch }

enum CameraLensDirection { front, back }

class CameraState {
  final CameraController? controller;
  final bool isInitialized;
  final bool isRecording;
  final CameraMode mode;
  final CameraFlashMode flashMode;
  final CameraLensDirection lensDirection;
  final List<CameraDescription> availableCameras;
  final String? errorMessage;
  final bool isLoading;

  const CameraState({
    this.controller,
    this.isInitialized = false,
    this.isRecording = false,
    this.mode = CameraMode.photo,
    this.flashMode = CameraFlashMode.off,
    this.lensDirection = CameraLensDirection.back,
    this.availableCameras = const [],
    this.errorMessage,
    this.isLoading = false,
  });

  CameraState copyWith({
    CameraController? controller,
    bool? isInitialized,
    bool? isRecording,
    CameraMode? mode,
    CameraFlashMode? flashMode,
    CameraLensDirection? lensDirection,
    List<CameraDescription>? availableCameras,
    String? errorMessage,
    bool? isLoading,
  }) {
    return CameraState(
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      isRecording: isRecording ?? this.isRecording,
      mode: mode ?? this.mode,
      flashMode: flashMode ?? this.flashMode,
      lensDirection: lensDirection ?? this.lensDirection,
      availableCameras: availableCameras ?? this.availableCameras,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CameraState &&
        other.controller == controller &&
        other.isInitialized == isInitialized &&
        other.isRecording == isRecording &&
        other.mode == mode &&
        other.flashMode == flashMode &&
        other.lensDirection == lensDirection &&
        listEquals(other.availableCameras, availableCameras) &&
        other.errorMessage == errorMessage &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return Object.hash(
      controller,
      isInitialized,
      isRecording,
      mode,
      flashMode,
      lensDirection,
      availableCameras,
      errorMessage,
      isLoading,
    );
  }
}

class CameraService {
  static const String _logTag = 'CameraService';

  /// Initialize available cameras
  Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      final cameras = await availableCameras();
      debugPrint('$_logTag: Found ${cameras.length} cameras');
      return cameras;
    } catch (e) {
      debugPrint('$_logTag: Error getting available cameras: $e');
      return [];
    }
  }

  /// Initialize camera controller
  Future<CameraController> initializeCamera({
    required List<CameraDescription> cameras,
    required CameraLensDirection lensDirection,
  }) async {
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }

    // Find camera with desired lens direction
    CameraDescription? selectedCamera;
    for (final camera in cameras) {
      if (lensDirection == CameraLensDirection.back && camera.lensDirection == CameraLensDirection.back) {
        selectedCamera = camera;
        break;
      } else if (lensDirection == CameraLensDirection.front && camera.lensDirection == CameraLensDirection.front) {
        selectedCamera = camera;
        break;
      }
    }

    // Fallback to first available camera
    selectedCamera ??= cameras.first;

    debugPrint('$_logTag: Initializing camera: ${selectedCamera.name}');

    final controller = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await controller.initialize();
    debugPrint('$_logTag: Camera initialized successfully');

    return controller;
  }

  /// Switch camera lens direction
  Future<CameraController> switchCamera({
    required CameraController currentController,
    required List<CameraDescription> cameras,
    required CameraLensDirection newLensDirection,
  }) async {
    debugPrint('$_logTag: Switching to ${newLensDirection.name} camera');

    // Dispose current controller
    await currentController.dispose();

    // Initialize new camera
    return await initializeCamera(
      cameras: cameras,
      lensDirection: newLensDirection,
    );
  }

  /// Set flash mode
  Future<void> setFlashMode({
    required CameraController controller,
    required CameraFlashMode flashMode,
  }) async {
    if (!controller.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    final cameraFlashMode = _mapFlashMode(flashMode);
    await controller.setFlashMode(cameraFlashMode);
    debugPrint('$_logTag: Flash mode set to ${flashMode.name}');
  }

  /// Map our flash mode to camera package flash mode
  FlashMode _mapFlashMode(CameraFlashMode flashMode) {
    switch (flashMode) {
      case CameraFlashMode.off:
        return FlashMode.off;
      case CameraFlashMode.auto:
        return FlashMode.auto;
      case CameraFlashMode.on:
        return FlashMode.always;
      case CameraFlashMode.torch:
        return FlashMode.torch;
    }
  }

  /// Check if camera has flash
  bool hasFlash(CameraController controller) {
    return controller.description.lensDirection == CameraLensDirection.back;
  }

  /// Dispose camera controller
  Future<void> disposeCamera(CameraController? controller) async {
    if (controller != null && controller.value.isInitialized) {
      debugPrint('$_logTag: Disposing camera controller');
      await controller.dispose();
    }
  }

  /// Handle camera errors
  String getErrorMessage(Object error) {
    if (error is CameraException) {
      switch (error.code) {
        case 'CameraAccessDenied':
          return 'Camera access denied. Please enable camera permission.';
        case 'CameraAccessDeniedWithoutPrompt':
          return 'Camera access denied. Please enable camera permission in settings.';
        case 'CameraAccessRestricted':
          return 'Camera access restricted.';
        case 'AudioAccessDenied':
          return 'Microphone access denied. Please enable microphone permission.';
        case 'AudioAccessDeniedWithoutPrompt':
          return 'Microphone access denied. Please enable microphone permission in settings.';
        case 'AudioAccessRestricted':
          return 'Microphone access restricted.';
        default:
          return 'Camera error: ${error.description}';
      }
    }
    return 'An unexpected error occurred: $error';
  }

  /// Get next flash mode for cycling
  CameraFlashMode getNextFlashMode(CameraFlashMode current) {
    switch (current) {
      case CameraFlashMode.off:
        return CameraFlashMode.auto;
      case CameraFlashMode.auto:
        return CameraFlashMode.on;
      case CameraFlashMode.on:
        return CameraFlashMode.torch;
      case CameraFlashMode.torch:
        return CameraFlashMode.off;
    }
  }

  /// Get flash mode icon
  String getFlashIcon(CameraFlashMode flashMode) {
    switch (flashMode) {
      case CameraFlashMode.off:
        return '⚡'; // Flash off
      case CameraFlashMode.auto:
        return '⚡'; // Flash auto
      case CameraFlashMode.on:
        return '💡'; // Flash on
      case CameraFlashMode.torch:
        return '🔦'; // Torch
    }
  }

  /// Get flash mode display name
  String getFlashDisplayName(CameraFlashMode flashMode) {
    switch (flashMode) {
      case CameraFlashMode.off:
        return 'Off';
      case CameraFlashMode.auto:
        return 'Auto';
      case CameraFlashMode.on:
        return 'On';
      case CameraFlashMode.torch:
        return 'Torch';
    }
  }

  /// Get opposite lens direction for camera switching
  CameraLensDirection getOppositeLensDirection(CameraLensDirection current) {
    return current == CameraLensDirection.back ? CameraLensDirection.front : CameraLensDirection.back;
  }
}
