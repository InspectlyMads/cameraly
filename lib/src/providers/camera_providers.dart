import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart' as camera;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/camera_settings.dart';
import '../services/camera_service.dart';
import '../services/media_service.dart';
import '../services/metadata_service.dart';
import '../services/camera_ui_service.dart';
import '../services/camera_error_handler.dart';
import '../services/camera_info_service.dart';
import '../utils/zoom_helper.dart';
import 'permission_providers.dart';

part 'camera_providers.g.dart';

// ignore_for_file: deprecated_member_use_from_same_package, unnecessary_import

// Service provider
final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

// Metadata service provider
final metadataServiceProvider = Provider<MetadataService>((ref) {
  return MetadataService();
});

// Media service provider
final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService();
});

// Available cameras provider
@riverpod
Future<List<camera.CameraDescription>> availableCameras(AvailableCamerasRef ref) async {
  final service = ref.read(cameraServiceProvider);
  return service.getAvailableCameras();
}

// Main camera state provider
@riverpod
class CameraController extends _$CameraController {
  bool _captureLocationMetadata = true;
  CameraSettings _cameraSettings = const CameraSettings();
  Timer? _retryTimer;
  
  @override
  CameraState build() {
    // Auto-dispose camera and services when provider is disposed
    ref.onDispose(() {
      _retryTimer?.cancel();
      
      // Store controller reference before clearing state
      final controllerToDispose = state.controller;
      
      // Clear state immediately
      if (state.controller != null) {
        state = state.copyWith(
          controller: null,
          isInitialized: false,
          isRecording: false,
          isLoading: false,
          isTransitioning: false,
        );
      }
      
      // Dispose services
      _disposeServices();
      
      // Schedule camera disposal to happen after provider disposal
      if (controllerToDispose != null) {
        // Use a delayed microtask to ensure disposal happens after all providers are disposed
        Future.delayed(Duration.zero, () async {
          try {
            // Direct disposal without accessing providers
            await controllerToDispose.stopImageStream().catchError((_) {});
            await controllerToDispose.pausePreview().catchError((_) {});
            await Future.delayed(const Duration(milliseconds: 100)); // Buffer cleanup
            await controllerToDispose.dispose();
            debugPrint('✅ Camera controller disposed from provider');
          } catch (e) {
            debugPrint('Camera disposal error from provider: $e');
          }
        });
      }
    });

    return const CameraState();
  }

  /// Initialize camera system
  Future<void> initializeCamera({
    bool captureLocationMetadata = true,
    CameraSettings? settings,
  }) async {
    _captureLocationMetadata = captureLocationMetadata;
    _cameraSettings = settings ?? const CameraSettings();
    await _initializeCamera();
  }

  /// Switch camera mode
  Future<void> switchMode(CameraMode newMode) async {
    if (state.mode == newMode) return;

    final oldMode = state.mode;
    state = state.copyWith(mode: newMode);

    // Update flash settings for new mode
    if (state.controller != null) {
      final service = ref.read(cameraServiceProvider);
      await service.setFlashModeForContext(
        controller: state.controller!,
        cameraMode: newMode,
        photoMode: state.photoFlashMode,
        videoMode: state.videoFlashMode,
      );
    }

    // If switching to/from video mode, reinitialize to handle audio requirements and quality settings
    if ((oldMode == CameraMode.video || newMode == CameraMode.video) && state.controller != null) {
      await _reinitializeCamera();
    }
  }

  /// Switch camera lens direction
  Future<void> switchCamera() async {
    if (!state.isInitialized || state.availableCameras.length < 2) {

      return;
    }

    final service = ref.read(cameraServiceProvider);
    final newLensDirection = service.getOppositeLensDirection(state.lensDirection);



    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final newController = await service.switchCamera(
        currentController: state.controller!,
        cameras: state.availableCameras,
        newLensDirection: newLensDirection,
        enableAudio: state.mode != CameraMode.photo,
      );

      state = state.copyWith(
        controller: newController,
        lensDirection: newLensDirection,
        isLoading: false,
        errorMessage: null,
      );
      
      // Re-initialize zoom for new camera
      await _initializeZoom(newController);

      // Reset flash mode after switching (front camera usually doesn't have flash)
      await _setInitialFlashMode(newController);


    } catch (e) {

      final service = ref.read(cameraServiceProvider);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to switch camera: ${service.getErrorMessage(e)}',
      );

      // Try to recover by reinitializing the original camera
      try {
        await _initializeCamera();
      } catch (recoveryError) {
        // Recovery failed, error already logged
        debugPrint('Camera recovery failed: $recoveryError');
      }
    }
  }

  /// Set initial flash mode based on camera capabilities
  Future<void> _setInitialFlashMode(camera.CameraController controller) async {
    final service = ref.read(cameraServiceProvider);

    // Reset to off for front camera (no flash), keep current for back camera
    final photoFlashMode = service.hasFlash(controller) ? state.photoFlashMode : PhotoFlashMode.off;
    final videoFlashMode = service.hasFlash(controller) ? state.videoFlashMode : VideoFlashMode.off;

    try {
      await service.setFlashModeForContext(
        controller: controller,
        cameraMode: state.mode,
        photoMode: photoFlashMode,
        videoMode: videoFlashMode,
      );

      state = state.copyWith(
        photoFlashMode: photoFlashMode,
        videoFlashMode: videoFlashMode,
      );

    } catch (e) {
      // Ignore errors during refresh - flash mode is not critical
      debugPrint('Error setting flash mode: $e');
    }
  }

  /// Cycle flash mode based on current camera mode
  Future<void> cycleFlashMode() async {
    if (!state.isInitialized || state.controller == null) return;

    final service = ref.read(cameraServiceProvider);

    // Only allow flash on back camera
    if (!service.hasFlash(state.controller!)) {
      return;
    }

    if (state.mode == CameraMode.video) {
      final nextVideoMode = service.getNextVideoFlashMode(state.videoFlashMode);
      await service.setFlashModeForContext(
        controller: state.controller!,
        cameraMode: state.mode,
        videoMode: nextVideoMode,
      );
      state = state.copyWith(videoFlashMode: nextVideoMode);
    } else {
      final nextPhotoMode = service.getNextPhotoFlashMode(state.photoFlashMode);
      await service.setFlashModeForContext(
        controller: state.controller!,
        cameraMode: state.mode,
        photoMode: nextPhotoMode,
      );
      state = state.copyWith(photoFlashMode: nextPhotoMode);
    }
  }

  /// Start video recording
  Future<void> startVideoRecording() async {
    if (!state.isInitialized || state.controller == null || state.isRecording) {
      return;
    }

    try {
      await state.controller!.startVideoRecording();
      state = state.copyWith(isRecording: true);
    } catch (e) {
      final service = ref.read(cameraServiceProvider);
      state = state.copyWith(
        errorMessage: service.getErrorMessage(e),
      );
    }
  }

  /// Stop video recording
  Future<camera.XFile?> stopVideoRecording() async {
    if (!state.isRecording || state.controller == null) {
      return null;
    }

    try {
      final videoFile = await state.controller!.stopVideoRecording();
      state = state.copyWith(isRecording: false);

      // Save the video to app directory
      final mediaService = ref.read(mediaServiceProvider);
      final savedPath = await mediaService.saveVideo(videoFile.path);

      if (savedPath != null) {
        // Return XFile pointing to saved location
        return camera.XFile(savedPath);
      }

      return videoFile;
    } catch (e) {
      final service = ref.read(cameraServiceProvider);
      state = state.copyWith(
        isRecording: false,
        errorMessage: service.getErrorMessage(e),
      );
      return null;
    }
  }

  /// Take picture
  Future<camera.XFile?> takePicture() async {
    if (!state.isInitialized || state.controller == null || state.isTransitioning) {
      return null;
    }

    try {
      final service = ref.read(cameraServiceProvider);
      
      // Get current camera description
      final currentCamera = state.availableCameras.firstWhere(
        (camera) => service.mapCameraLensDirection(camera.lensDirection) == state.lensDirection,
        orElse: () => state.availableCameras.first,
      );
      
      // Get current device orientation for debugging
      final orientationData = await service.getCurrentOrientation(
        cameraDescription: currentCamera,
        lensDirection: state.lensDirection,
      );
      




      
      // Lock the capture orientation to the current device orientation
      // This ensures the camera package correctly handles the image orientation
      final deviceOrientation = _mapToDeviceOrientation(orientationData.deviceOrientation);
      if (deviceOrientation != null) {

        await state.controller!.lockCaptureOrientation(deviceOrientation);
      }
      
      // Record the time before capture for metadata
      final captureStartTime = DateTime.now();
      
      // Take the picture
      final imageFile = await state.controller!.takePicture();
      
      // Unlock capture orientation after taking the picture
      if (deviceOrientation != null) {
        await state.controller!.unlockCaptureOrientation();

      }

      // Capture metadata
      final metadataService = ref.read(metadataServiceProvider);
      final metadata = await metadataService.captureMetadata(
        cameraController: state.controller!,
        captureStartTime: captureStartTime,
        cameraName: currentCamera.name,
        zoomLevel: state.currentZoom,
        flashMode: state.mode == CameraMode.photo 
          ? state.photoFlashMode.toString() 
          : state.videoFlashMode.toString(),
      );
      
      // Save the image to app directory
      final mediaService = ref.read(mediaServiceProvider);
      // Use direct file copy instead of readAsBytes for better performance
      final savedPath = await mediaService.savePhotoFile(
        imageFile.path,
        orientationData: orientationData,
        metadata: metadata,
      );

      if (savedPath != null) {
        // Log orientation data for debugging (no manual rotation needed)
        await service.processCapturedPhoto(
          imagePath: savedPath,
          orientationData: orientationData,
        );
        
        return camera.XFile(savedPath);
      }

      // Save failed - don't return temp file as it may not exist
      debugPrint('❌ Failed to save photo to app directory');
      return null;
    } catch (e) {
      final service = ref.read(cameraServiceProvider);
      state = state.copyWith(
        errorMessage: service.getErrorMessage(e),
      );
      return null;
    }
  }
  
  /// Map orientation degrees to DeviceOrientation enum
  DeviceOrientation? _mapToDeviceOrientation(int degrees) {
    switch (degrees) {
      case 0:
        return DeviceOrientation.portraitUp;
      case 90:
        return DeviceOrientation.landscapeRight;
      case 180:
        return DeviceOrientation.portraitDown;
      case 270:
        return DeviceOrientation.landscapeLeft;
      default:
        return null;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Toggle grid overlay
  void toggleGrid() {
    state = state.copyWith(showGrid: !state.showGrid);
  }
  
  /// Set focus point
  Future<void> setFocusPoint(Offset point) async {
    if (!state.isInitialized || state.controller == null) return;
    
    try {
      final service = ref.read(cameraServiceProvider);
      await service.setFocusPoint(
        controller: state.controller!,
        point: point,
      );

    } catch (e) {
      // Focus errors are non-critical
      debugPrint('Failed to set focus point: $e');
    }
  }

  /// Set zoom level
  Future<void> setZoomLevel(double zoom) async {
    if (!state.isInitialized || state.controller == null) return;
    
    // Get the actual controller limits
    final controllerMinZoom = await state.controller!.getMinZoomLevel();
    final controllerMaxZoom = await state.controller!.getMaxZoomLevel();
    
    // For UI purposes, we use device capabilities, but for actual zoom we need controller limits
    // Map the UI zoom value to the controller's zoom range
    double actualZoom = zoom;
    
    // If zoom is less than 1.0 but controller doesn't support it, clamp to min
    if (zoom < 1.0 && controllerMinZoom >= 1.0) {
      actualZoom = controllerMinZoom;

    } else if (zoom > controllerMaxZoom) {
      // If zoom exceeds controller max, clamp to max
      actualZoom = controllerMaxZoom;

    } else {
      // Ensure zoom is within controller bounds
      actualZoom = zoom.clamp(controllerMinZoom, controllerMaxZoom);
    }
    
    try {
      await state.controller!.setZoomLevel(actualZoom);
      // Store the requested zoom for UI (not the clamped value)
      state = state.copyWith(currentZoom: zoom);

    } catch (e) {
      // Zoom errors are non-critical
      debugPrint('Failed to set zoom level: $e');
    }
  }

  /// Get zoom capabilities and initialize zoom
  Future<void> _initializeZoom(camera.CameraController controller) async {
    try {
      // Get the actual zoom levels from the camera controller
      final controllerMinZoom = await controller.getMinZoomLevel();
      final controllerMaxZoom = await controller.getMaxZoomLevel();
      
      debugPrint('📷 Camera zoom capabilities:');
      debugPrint('  Controller min zoom: $controllerMinZoom');
      debugPrint('  Controller max zoom: $controllerMaxZoom');
      
      // Get device-specific zoom capabilities
      await ZoomHelper.getDeviceZoomCapabilities();


      
      // Analyze camera configuration
      final cameras = state.availableCameras;
      final cameraInfo = CameraInfoService.analyzeCameras(cameras);
      
      debugPrint('  Detected cameras: ${cameras.length}');
      debugPrint('  Has ultra-wide: ${cameraInfo.hasUltraWide}');
      debugPrint('  Has telephoto: ${cameraInfo.hasTelephoto}');
      




      
      // Determine effective zoom range based on camera analysis and controller capabilities
      double effectiveMinZoom = controllerMinZoom;
      double effectiveMaxZoom = controllerMaxZoom;
      
      // Only show 0.5x button if the controller actually supports zoom < 1.0
      // Don't show it if controller min zoom is 1.0 or higher
      if (cameraInfo.hasUltraWide && controllerMinZoom < 1.0) {
        effectiveMinZoom = controllerMinZoom;

      }
      
      // Set appropriate max zoom based on camera configuration
      // If controller reports very limited zoom (like 1.0), use device defaults
      if (controllerMaxZoom <= 1.0) {

        effectiveMaxZoom = cameraInfo.hasTelephoto ? 30.0 : 8.0;
      } else if (cameraInfo.hasTelephoto) {
        // Pro model with telephoto - allow full zoom range

      } else if (effectiveMaxZoom > 8.0) {
        // Non-Pro model - limit to reasonable digital zoom
        effectiveMaxZoom = 8.0;

      }
      
      
      debugPrint('  Effective zoom range: ${effectiveMinZoom}x - ${effectiveMaxZoom}x');
      
      state = state.copyWith(
        minZoom: effectiveMinZoom,
        maxZoom: effectiveMaxZoom,
        currentZoom: 1.0,
      );
      
      // Set initial zoom to 1x (within controller limits)
      final initialZoom = 1.0.clamp(controllerMinZoom, controllerMaxZoom);
      await controller.setZoomLevel(initialZoom);
      

    } catch (e) {

      // Default to a reasonable zoom range if initialization fails
      state = state.copyWith(
        minZoom: 1.0,
        maxZoom: 8.0,
        currentZoom: 1.0,
      );
    }
  }

  /// Private method to initialize camera
  Future<void> _initializeCamera() async {
    // Check permissions using the permission service with retry mechanism
    final permissionService = ref.read(permissionServiceProvider);

    // Debug: Log current mode
    debugPrint('🎥 Initializing camera in mode: ${state.mode}');

    // Check permissions based on current mode
    var hasPermissions = await permissionService.hasRequiredPermissionsForMode(state.mode);

    if (!hasPermissions) {
      // Don't automatically request permissions - just report the error
      // The UI will handle showing the permission dialog
      debugPrint('🔐 Permissions not granted for mode: ${state.mode}');
      
      final errorMessage = state.mode == CameraMode.photo 
        ? 'Camera permission is required'
        : 'Camera and microphone permissions are required';
      state = state.copyWith(
        errorMessage: errorMessage,
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final service = ref.read(cameraServiceProvider);
      
      // Initialize the camera service (including orientation service)
      await service.initialize();
      
      // Initialize metadata service for GPS and sensor data in the background
      // Don't await this - let GPS initialize while camera starts up
      final metadataService = ref.read(metadataServiceProvider);
      metadataService.initialize(captureLocation: _captureLocationMetadata).then((_) {
        debugPrint('📍 GPS initialization completed in background');
      }).catchError((e) {
        debugPrint('⚠️ GPS initialization error (non-blocking): $e');
      });

      // Get available cameras
      final cameras = await service.getAvailableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No cameras found on this device',
        );
        return;
      }

      // Initialize camera controller with quality settings
      final resolution = state.mode == CameraMode.video 
        ? CameraService.videoQualityToResolution(_cameraSettings.videoQuality)
        : CameraService.photoQualityToResolution(_cameraSettings.photoQuality);
        
      final controller = await service.initializeCamera(
        cameras: cameras,
        lensDirection: state.lensDirection,
        resolution: resolution,
        enableAudio: state.mode != CameraMode.photo, // Only enable audio for video/combined modes
      );

      state = state.copyWith(
        controller: controller,
        isInitialized: true,
        availableCameras: cameras,
        isLoading: false,
        errorMessage: null,
      );

      // Set initial flash mode
      await _setInitialFlashMode(controller);
      
      // Initialize zoom capabilities
      await _initializeZoom(controller);
    } catch (e) {
      final service = ref.read(cameraServiceProvider);
      final errorInfo = service.getErrorInfo(e);
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorInfo.userMessage ?? errorInfo.message,
      );

      // Attempt recovery for recoverable errors
      if (errorInfo.isRecoverable && errorInfo.type != CameraErrorType.permissionDenied) {
        _retryTimer?.cancel(); // Cancel any existing retry
        _retryTimer = Timer(errorInfo.retryDelay ?? const Duration(seconds: 1), () {
          _initializeCamera();
        });
      }
    }
  }

  /// Private method to reinitialize camera (e.g., for mode changes)
  Future<void> _reinitializeCamera() async {
    // Store the controller reference before nulling it
    final oldController = state.controller;
    
    // Immediately null the controller to prevent UI from using it
    state = state.copyWith(
      controller: null,
      isInitialized: false,
    );
    
    // Now dispose the old controller - must complete before initializing new one
    if (oldController != null) {
      await ref.read(cameraServiceProvider).disposeCamera(oldController);
    }
    
    // Small delay to ensure Android surface is ready
    if (Platform.isAndroid) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await _initializeCamera();
  }

  /// Private method to dispose camera
  Future<void> _disposeCamera() async {
    if (state.controller != null) {
      // Store reference and immediately null it in state to prevent further use
      final controllerToDispose = state.controller;
      
      // Clear state first to prevent any operations on disposing controller
      state = state.copyWith(
        controller: null,
        isInitialized: false,
        isRecording: false,
        isLoading: false,
        isTransitioning: false,
      );
      
      // Now dispose the controller - use try/catch to handle disposal errors
      try {
        await ref.read(cameraServiceProvider).disposeCamera(controllerToDispose);
      } catch (e) {
        // Provider might already be disposed, ignore errors
        debugPrint('Camera disposal error (likely provider already disposed): $e');
      }
    }
  }
  
  /// Private method to dispose services
  Future<void> _disposeServices() async {
    try {
      // Dispose metadata service (which handles GPS and sensors)
      final metadataService = ref.read(metadataServiceProvider);
      metadataService.dispose();
    } catch (e) {
      // Provider might already be disposed, ignore errors
      debugPrint('Metadata service disposal error: $e');
    }
    
    try {
      // Dispose camera service (which includes orientation service)
      final cameraService = ref.read(cameraServiceProvider);
      cameraService.dispose();
    } catch (e) {
      // Provider might already be disposed, ignore errors
      debugPrint('Camera service disposal error: $e');
    }
  }

  /// Dispose camera completely (for Android background handling)
  Future<void> disposeCamera() async {
    debugPrint('📱 disposeCamera called - disposing camera completely');
    await _disposeCamera();
  }

  /// Pause camera (for app lifecycle management)
  Future<void> pauseCamera() async {
    debugPrint('📱 pauseCamera called - controller exists: ${state.controller != null}, initialized: ${state.isInitialized}');
    if (state.controller != null && state.isInitialized) {
      try {
        // Stop any ongoing recording
        if (state.isRecording) {
          debugPrint('🎥 Stopping recording before pause');
          await stopVideoRecording();
        }
        
        // Pause the preview instead of disposing the camera
        // This maintains the camera connection while saving resources
        if (!state.controller!.value.isPreviewPaused) {
          debugPrint('⏸️ Pausing camera preview');
          await state.controller!.pausePreview();
          debugPrint('✅ Camera preview paused successfully');
        } else {
          debugPrint('ℹ️ Camera preview already paused');
        }
      } catch (e) {
        debugPrint('❌ Error pausing camera preview: $e');
      }
    } else {
      debugPrint('⚠️ Cannot pause - camera not initialized');
    }
  }

  /// Resume camera (for app lifecycle management)
  Future<void> resumeCamera() async {
    debugPrint('📱 resumeCamera called - controller exists: ${state.controller != null}, initialized: ${state.isInitialized}, loading: ${state.isLoading}, transitioning: ${state.isTransitioning}');
    
    // Prevent concurrent operations
    if (state.isLoading || state.isTransitioning) {
      debugPrint('⚠️ Camera is already in transition, skipping resume');
      return;
    }
    
    if (state.controller != null && state.isInitialized) {
      try {
        // Check if controller is still valid
        final isControllerInitialized = state.controller!.value.isInitialized;
        final isPreviewPaused = state.controller!.value.isPreviewPaused;
        debugPrint('📷 Controller state - initialized: $isControllerInitialized, preview paused: $isPreviewPaused');
        
        if (!isControllerInitialized) {
          debugPrint('⚠️ Camera controller not initialized, reinitializing');
          await _initializeCamera();
          return;
        }
        
        // Resume the preview if it was paused
        if (isPreviewPaused) {
          debugPrint('▶️ Resuming camera preview');
          // Try to resume with a timeout to prevent hanging
          try {
            await state.controller!.resumePreview().timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                throw TimeoutException('Camera resume timed out after 3 seconds');
              },
            );
            debugPrint('✅ Camera preview resumed successfully');
          } catch (timeoutError) {
            debugPrint('⏱️ Resume timed out, will reinitialize: $timeoutError');
            rethrow;
          }
        } else {
          debugPrint('ℹ️ Camera preview already running');
        }
      } catch (e) {
        debugPrint('❌ Error resuming camera preview: $e');
        debugPrint('Stack trace: ${StackTrace.current}');
        
        // Check if it's a timeout error
        if (e.toString().contains('TimeoutException') || e.toString().contains('is not done within')) {
          debugPrint('⏱️ Camera timeout detected, waiting before retry');
          // Wait a bit longer before trying to reinitialize
          await Future.delayed(const Duration(seconds: 1));
        }
        
        // If resume fails, try reinitializing as fallback
        debugPrint('🔄 Attempting camera reinitialization as fallback');
        try {
          await _initializeCamera();
          debugPrint('✅ Camera reinitialized successfully');
        } catch (reinitError) {
          debugPrint('❌ Failed to reinitialize camera: $reinitError');
          state = state.copyWith(
            errorMessage: 'Failed to resume camera. Please restart the app.',
          );
        }
      }
    } else if (!state.isInitialized) {
      debugPrint('📷 Camera not initialized, initializing now');
      // Initialize camera if not already initialized
      await _initializeCamera();
    } else {
      debugPrint('⚠️ Unexpected state - controller: ${state.controller}, initialized: ${state.isInitialized}');
    }
  }
  
  /// Handle camera disconnection and attempt recovery
  Future<void> handleCameraDisconnection() async {
    state = state.copyWith(
      errorMessage: 'Camera disconnected. Attempting to reconnect...',
    );
    
    // Wait a moment before attempting reconnection
    await Future.delayed(const Duration(seconds: 2));
    
    // Try to reinitialize
    await _reinitializeCamera();
  }
  
  /// Update camera orientation without full reinitialization
  /// Used for handling orientation changes on Android
  Future<void> updateCameraOrientation() async {
    if (state.controller == null || !state.isInitialized) return;
    
    // Set transitioning state immediately
    state = state.copyWith(isTransitioning: true);
    
    try {
      // For Android, we need to handle the surface recreation during orientation changes
      // Save current camera state before reinitializing
      final currentZoom = state.currentZoom;
      final photoFlashMode = state.photoFlashMode;
      final videoFlashMode = state.videoFlashMode;
      
      // Stop any ongoing recording
      if (state.isRecording) {
        await stopVideoRecording();
      }
      
      // Reinitialize the camera to handle surface changes
      // This is necessary because the surface has been destroyed during orientation change
      await _reinitializeCamera();
      
      // Restore zoom level after reinitialization
      if (state.controller != null && currentZoom > 1.0) {
        await setZoomLevel(currentZoom);
      }
      
      // Restore flash modes and clear transition state
      state = state.copyWith(
        photoFlashMode: photoFlashMode,
        videoFlashMode: videoFlashMode,
        isTransitioning: false,
        isPreparing: false,
      );
      
    } catch (e) {
      debugPrint('Error updating camera orientation: $e');
      // Clear transition state on error
      state = state.copyWith(isTransitioning: false, isPreparing: false);
    }
  }
  
  /// Check camera health periodically
  Future<bool> checkCameraHealth() async {
    if (state.controller == null || !state.isInitialized) {
      return false;
    }
    
    try {
      // Check if controller is still responsive
      await state.controller!.getMinZoomLevel();
      return true;
    } catch (e) {
      // Camera might be disconnected
      await handleCameraDisconnection();
      return false;
    }
  }
  
  /// Set preparing state for immediate visual feedback
  void setPreparing(bool preparing) {
    state = state.copyWith(isPreparing: preparing);
  }
}

// Convenience providers for specific camera properties
@riverpod
bool cameraHasFlash(CameraHasFlashRef ref) {
  final cameraState = ref.watch(cameraControllerProvider);
  if (!cameraState.isInitialized || cameraState.controller == null) {
    return false;
  }

  final service = ref.read(cameraServiceProvider);
  return service.hasFlash(cameraState.controller!);
}

@riverpod
bool canSwitchCamera(CanSwitchCameraRef ref) {
  final cameraState = ref.watch(cameraControllerProvider);
  return cameraState.availableCameras.length >= 2;
}

@riverpod
String flashModeDisplayName(FlashModeDisplayNameRef ref) {
  final cameraState = ref.watch(cameraControllerProvider);

  if (cameraState.mode == CameraMode.video) {
    return CameraUIService.getVideoFlashDisplayName(cameraState.videoFlashMode);
  } else {
    return CameraUIService.getPhotoFlashDisplayName(cameraState.photoFlashMode);
  }
}

@riverpod
String flashModeIcon(FlashModeIconRef ref) {
  final cameraState = ref.watch(cameraControllerProvider);

  if (cameraState.mode == CameraMode.video) {
    return CameraUIService.getVideoFlashIcon(cameraState.videoFlashMode);
  } else {
    return CameraUIService.getPhotoFlashIcon(cameraState.photoFlashMode);
  }
}
