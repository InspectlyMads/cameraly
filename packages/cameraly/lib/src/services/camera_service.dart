import 'package:camera/camera.dart' as camera;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'camera_error_handler.dart';
import 'orientation_service.dart';
import '../models/orientation_data.dart';
import '../models/camera_settings.dart';

enum CameraMode { photo, video, combined }

enum PhotoFlashMode { off, auto, on }

enum VideoFlashMode { off, torch }

enum CameraLensDirection { front, back }

class CameraState {
  final camera.CameraController? controller;
  final bool isInitialized;
  final bool isRecording;
  final CameraMode mode;
  final PhotoFlashMode photoFlashMode;
  final VideoFlashMode videoFlashMode;
  final CameraLensDirection lensDirection;
  final List<camera.CameraDescription> availableCameras;
  final String? errorMessage;
  final bool isLoading;
  final bool showGrid;
  final double currentZoom;
  final double minZoom;
  final double maxZoom;

  const CameraState({
    this.controller,
    this.isInitialized = false,
    this.isRecording = false,
    this.mode = CameraMode.photo,
    this.photoFlashMode = PhotoFlashMode.off,
    this.videoFlashMode = VideoFlashMode.off,
    this.lensDirection = CameraLensDirection.back,
    this.availableCameras = const [],
    this.errorMessage,
    this.isLoading = false,
    this.showGrid = false,
    this.currentZoom = 1.0,
    this.minZoom = 1.0,
    this.maxZoom = 1.0,
  });

  CameraState copyWith({
    camera.CameraController? controller,
    bool? isInitialized,
    bool? isRecording,
    CameraMode? mode,
    PhotoFlashMode? photoFlashMode,
    VideoFlashMode? videoFlashMode,
    CameraLensDirection? lensDirection,
    List<camera.CameraDescription>? availableCameras,
    String? errorMessage,
    bool? isLoading,
    bool? showGrid,
    double? currentZoom,
    double? minZoom,
    double? maxZoom,
  }) {
    return CameraState(
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      isRecording: isRecording ?? this.isRecording,
      mode: mode ?? this.mode,
      photoFlashMode: photoFlashMode ?? this.photoFlashMode,
      videoFlashMode: videoFlashMode ?? this.videoFlashMode,
      lensDirection: lensDirection ?? this.lensDirection,
      availableCameras: availableCameras ?? this.availableCameras,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      showGrid: showGrid ?? this.showGrid,
      currentZoom: currentZoom ?? this.currentZoom,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
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
        other.photoFlashMode == photoFlashMode &&
        other.videoFlashMode == videoFlashMode &&
        other.lensDirection == lensDirection &&
        listEquals(other.availableCameras, availableCameras) &&
        other.errorMessage == errorMessage &&
        other.isLoading == isLoading &&
        other.showGrid == showGrid &&
        other.currentZoom == currentZoom &&
        other.minZoom == minZoom &&
        other.maxZoom == maxZoom;
  }

  @override
  int get hashCode {
    return Object.hash(
      controller,
      isInitialized,
      isRecording,
      mode,
      photoFlashMode,
      videoFlashMode,
      lensDirection,
      availableCameras,
      errorMessage,
      isLoading,
      showGrid,
      currentZoom,
      minZoom,
      maxZoom,
    );
  }
}

class CameraService {
  static const String _logTag = 'CameraService';
  
  final OrientationService _orientationService = OrientationService();
  
  /// Initialize the camera service
  Future<void> initialize() async {
    await _orientationService.initialize();
  }

  /// Initialize available cameras
  Future<List<camera.CameraDescription>> getAvailableCameras() async {
    try {
      final cameras = await camera.availableCameras();

      for (final cameraDesc in cameras) {



      }
      return cameras;
    } catch (e) {

      return [];
    }
  }

  /// Map camera package lens direction to our enum
  CameraLensDirection _mapFromCameraLensDirection(camera.CameraLensDirection lensDirection) {
    switch (lensDirection) {
      case camera.CameraLensDirection.front:
        return CameraLensDirection.front;
      case camera.CameraLensDirection.back:
        return CameraLensDirection.back;
      case camera.CameraLensDirection.external:
        return CameraLensDirection.back; // Default external cameras to back
    }
  }

  /// Public method to map camera package lens direction to our enum
  CameraLensDirection mapCameraLensDirection(camera.CameraLensDirection lensDirection) {
    return _mapFromCameraLensDirection(lensDirection);
  }

  /// Initialize camera controller
  Future<camera.CameraController> initializeCamera({
    required List<camera.CameraDescription> cameras,
    required CameraLensDirection lensDirection,
    camera.ResolutionPreset? resolution,
  }) async {
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }

    // Find camera with desired lens direction
    camera.CameraDescription? selectedCamera;
    for (final cameraDesc in cameras) {
      final mappedDirection = _mapFromCameraLensDirection(cameraDesc.lensDirection);
      if (mappedDirection == lensDirection) {
        selectedCamera = cameraDesc;
        break;
      }
    }

    // Fallback to first available camera
    selectedCamera ??= cameras.first;





    final controller = camera.CameraController(
      selectedCamera,
      resolution ?? camera.ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: camera.ImageFormatGroup.jpeg,
    );

    await controller.initialize();


    return controller;
  }

  /// Switch camera lens direction
  Future<camera.CameraController> switchCamera({
    required camera.CameraController currentController,
    required List<camera.CameraDescription> cameras,
    required CameraLensDirection newLensDirection,
  }) async {


    // Find camera with desired lens direction
    camera.CameraDescription? targetCamera;
    for (final cameraDesc in cameras) {
      final mappedDirection = _mapFromCameraLensDirection(cameraDesc.lensDirection);
      if (mappedDirection == newLensDirection) {
        targetCamera = cameraDesc;
        break;
      }
    }

    if (targetCamera == null) {
      throw Exception('No ${newLensDirection.name} camera found');
    }



    // Dispose current controller
    await currentController.dispose();


    // Initialize new camera
    final newController = camera.CameraController(
      targetCamera,
      camera.ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: camera.ImageFormatGroup.jpeg,
    );

    await newController.initialize();


    return newController;
  }

  /// Set flash mode based on camera mode context
  Future<void> setFlashModeForContext({
    required camera.CameraController controller,
    required CameraMode cameraMode,
    PhotoFlashMode? photoMode,
    VideoFlashMode? videoMode,
  }) async {
    if (!controller.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    camera.FlashMode flashMode;
    if (cameraMode == CameraMode.video) {
      flashMode = _mapVideoFlashMode(videoMode ?? VideoFlashMode.off);
    } else {
      flashMode = _mapPhotoFlashMode(photoMode ?? PhotoFlashMode.off);
    }

    await controller.setFlashMode(flashMode);

  }

  /// Map photo flash modes to camera package flash modes
  camera.FlashMode _mapPhotoFlashMode(PhotoFlashMode mode) {
    switch (mode) {
      case PhotoFlashMode.off:
        return camera.FlashMode.off;
      case PhotoFlashMode.auto:
        return camera.FlashMode.auto;
      case PhotoFlashMode.on:
        return camera.FlashMode.always;
    }
  }

  /// Map video flash modes to camera package flash modes
  camera.FlashMode _mapVideoFlashMode(VideoFlashMode mode) {
    switch (mode) {
      case VideoFlashMode.off:
        return camera.FlashMode.off;
      case VideoFlashMode.torch:
        return camera.FlashMode.torch;
    }
  }

  /// Check if camera has flash
  bool hasFlash(camera.CameraController controller) {
    return controller.description.lensDirection == camera.CameraLensDirection.back;
  }

  /// Dispose camera controller
  Future<void> disposeCamera(camera.CameraController? controller) async {
    if (controller != null && controller.value.isInitialized) {

      await controller.dispose();
    }
  }

  /// Get opposite lens direction for camera switching
  CameraLensDirection getOppositeLensDirection(CameraLensDirection current) {
    return current == CameraLensDirection.back ? CameraLensDirection.front : CameraLensDirection.back;
  }
  
  /// Handle camera errors
  String getErrorMessage(Object error) {
    final errorInfo = CameraErrorHandler.analyzeError(error);
    return errorInfo.userMessage ?? errorInfo.message;
  }

  /// Check if error is a camera exception
  bool isCameraException(Object error) {
    return error is camera.CameraException;
  }

  /// Get camera exception code
  String? getCameraExceptionCode(Object error) {
    if (error is camera.CameraException) {
      return error.code;
    }
    return null;
  }

  /// Get detailed error information
  CameraErrorInfo getErrorInfo(Object error) {
    return CameraErrorHandler.analyzeError(error);
  }
  
  /// Get next photo flash mode for cycling
  PhotoFlashMode getNextPhotoFlashMode(PhotoFlashMode current) {
    switch (current) {
      case PhotoFlashMode.off:
        return PhotoFlashMode.auto;
      case PhotoFlashMode.auto:
        return PhotoFlashMode.on;
      case PhotoFlashMode.on:
        return PhotoFlashMode.off;
    }
  }

  /// Get next video flash mode for cycling
  VideoFlashMode getNextVideoFlashMode(VideoFlashMode current) {
    switch (current) {
      case VideoFlashMode.off:
        return VideoFlashMode.torch;
      case VideoFlashMode.torch:
        return VideoFlashMode.off;
    }
  }

  /// Dispose service resources
  void dispose() {
    _orientationService.dispose();
  }

  /// Get current orientation data
  Future<OrientationData> getCurrentOrientation({
    required camera.CameraDescription cameraDescription,
    required CameraLensDirection lensDirection,
  }) async {
    // Convert our enum to camera package enum
    final cameraLensDirection = lensDirection == CameraLensDirection.front
        ? camera.CameraLensDirection.front
        : camera.CameraLensDirection.back;
    
    return await _orientationService.getCurrentOrientation(
      camera: cameraDescription,
      lensDirection: cameraLensDirection,
    );
  }

  /// Process captured photo with orientation correction
  Future<String?> processCapturedPhoto({
    required String imagePath,
    required OrientationData orientationData,
  }) async {
    // Apply orientation correction
    final correctedPath = await _orientationService.applyOrientationCorrection(
      imagePath,
      orientationData,
    );
    
    
    return correctedPath;
  }

  /// Get orientation debug info
  Map<String, dynamic> getOrientationDebugInfo() {
    return _orientationService.getDebugInfo();
  }
  
  /// Set focus and exposure point
  Future<void> setFocusPoint({
    required camera.CameraController controller,
    required Offset point,
  }) async {
    if (!controller.value.isInitialized) {
      throw Exception('Camera not initialized');
    }
    
    try {
      // Set exposure and focus point
      await controller.setExposurePoint(point);
      await controller.setFocusPoint(point);
      

    } catch (e) {

      rethrow;
    }
  }
  
  /// Reset focus and exposure to auto
  Future<void> resetFocus({
    required camera.CameraController controller,
  }) async {
    if (!controller.value.isInitialized) {
      throw Exception('Camera not initialized');
    }
    
    try {
      // Reset to auto by setting null
      await controller.setExposurePoint(null);
      await controller.setFocusPoint(null);
      

    } catch (e) {

    }
  }
  
  /// Convert photo quality to resolution preset
  static camera.ResolutionPreset photoQualityToResolution(PhotoQuality quality) {
    switch (quality) {
      case PhotoQuality.low:
        return camera.ResolutionPreset.low;
      case PhotoQuality.medium:
        return camera.ResolutionPreset.medium;
      case PhotoQuality.high:
        return camera.ResolutionPreset.high;
      case PhotoQuality.max:
        return camera.ResolutionPreset.max;
    }
  }
  
  /// Convert video quality to resolution preset
  static camera.ResolutionPreset videoQualityToResolution(VideoQuality quality) {
    switch (quality) {
      case VideoQuality.hd:
        return camera.ResolutionPreset.high; // 720p
      case VideoQuality.fullHd:
        return camera.ResolutionPreset.veryHigh; // 1080p
      case VideoQuality.uhd:
        return camera.ResolutionPreset.ultraHigh; // 4K if available
    }
  }
}
