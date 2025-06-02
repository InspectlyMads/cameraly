import 'package:camera/camera.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/camera_service.dart';
import '../services/media_service.dart';
import 'permission_providers.dart';

part 'camera_providers.g.dart';

// Service provider
final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

// Media service provider
final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService();
});

// Available cameras provider
@riverpod
Future<List<CameraDescription>> availableCameras(AvailableCamerasRef ref) async {
  final cameraService = ref.read(cameraServiceProvider);
  return await cameraService.getAvailableCameras();
}

// Main camera state provider
@riverpod
class CameraController extends _$CameraController {
  @override
  CameraState build() {
    // Auto-dispose camera when provider is disposed
    ref.onDispose(() {
      _disposeCamera();
    });

    return const CameraState();
  }

  /// Initialize camera system
  Future<void> initializeCamera() async {
    await _initializeCamera();
  }

  /// Switch camera mode
  Future<void> switchMode(CameraMode newMode) async {
    if (state.mode == newMode) return;

    state = state.copyWith(mode: newMode);

    // If switching to/from video mode, reinitialize to handle audio requirements
    if ((state.mode == CameraMode.video || newMode == CameraMode.video) && state.controller != null) {
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

    state = state.copyWith(isLoading: true);

    try {
      final newController = await service.switchCamera(
        currentController: state.controller!,
        cameras: state.availableCameras,
        newLensDirection: newLensDirection,
      );

      state = state.copyWith(
        controller: newController,
        lensDirection: newLensDirection,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      final service = ref.read(cameraServiceProvider);
      state = state.copyWith(
        isLoading: false,
        errorMessage: service.getErrorMessage(e),
      );
    }
  }

  /// Cycle flash mode
  Future<void> cycleFlashMode() async {
    if (!state.isInitialized || state.controller == null) return;

    final service = ref.read(cameraServiceProvider);

    // Only allow flash on back camera
    if (!service.hasFlash(state.controller!)) {
      return;
    }

    final nextFlashMode = service.getNextFlashMode(state.flashMode);

    try {
      await service.setFlashMode(
        controller: state.controller!,
        flashMode: nextFlashMode,
      );

      state = state.copyWith(flashMode: nextFlashMode);
    } catch (e) {
      final service = ref.read(cameraServiceProvider);
      state = state.copyWith(
        errorMessage: service.getErrorMessage(e),
      );
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
  Future<XFile?> stopVideoRecording() async {
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
        return XFile(savedPath);
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
  Future<XFile?> takePicture() async {
    if (!state.isInitialized || state.controller == null) {
      return null;
    }

    try {
      final imageFile = await state.controller!.takePicture();

      // Save the image to app directory
      final mediaService = ref.read(mediaServiceProvider);
      final imageBytes = await imageFile.readAsBytes();
      final savedPath = await mediaService.savePhoto(imageBytes);

      if (savedPath != null) {
        // Return XFile pointing to saved location
        return XFile(savedPath);
      }

      return imageFile;
    } catch (e) {
      final service = ref.read(cameraServiceProvider);
      state = state.copyWith(
        errorMessage: service.getErrorMessage(e),
      );
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Private method to initialize camera
  Future<void> _initializeCamera() async {
    // Check permissions using the permission service
    final permissionService = ref.read(permissionServiceProvider);
    final hasPermissions = await permissionService.hasAllCameraPermissions();

    if (!hasPermissions) {
      state = state.copyWith(
        errorMessage: 'Camera and microphone permissions are required',
      );
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final service = ref.read(cameraServiceProvider);

      // Get available cameras
      final cameras = await service.getAvailableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No cameras found on this device',
        );
        return;
      }

      // Initialize camera controller
      final controller = await service.initializeCamera(
        cameras: cameras,
        lensDirection: state.lensDirection,
      );

      state = state.copyWith(
        controller: controller,
        isInitialized: true,
        availableCameras: cameras,
        isLoading: false,
        errorMessage: null,
      );

      // Set initial flash mode
      await service.setFlashMode(
        controller: controller,
        flashMode: state.flashMode,
      );
    } catch (e) {
      final service = ref.read(cameraServiceProvider);
      state = state.copyWith(
        isLoading: false,
        errorMessage: service.getErrorMessage(e),
      );
    }
  }

  /// Private method to reinitialize camera (e.g., for mode changes)
  Future<void> _reinitializeCamera() async {
    if (state.controller != null) {
      await ref.read(cameraServiceProvider).disposeCamera(state.controller);
    }

    state = state.copyWith(
      controller: null,
      isInitialized: false,
    );

    await _initializeCamera();
  }

  /// Private method to dispose camera
  Future<void> _disposeCamera() async {
    if (state.controller != null) {
      await ref.read(cameraServiceProvider).disposeCamera(state.controller);
      state = state.copyWith(
        controller: null,
        isInitialized: false,
        isRecording: false,
      );
    }
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
  final service = ref.read(cameraServiceProvider);
  return service.getFlashDisplayName(cameraState.flashMode);
}

@riverpod
String flashModeIcon(FlashModeIconRef ref) {
  final cameraState = ref.watch(cameraControllerProvider);
  final service = ref.read(cameraServiceProvider);
  return service.getFlashIcon(cameraState.flashMode);
}
