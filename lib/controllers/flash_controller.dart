import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart' as camera;
import '../providers/camera_providers.dart';
import '../services/camera_service.dart';

class FlashController {
  /// Get the appropriate icon for the current flash mode
  static IconData getIcon(CameraMode mode, dynamic flashMode) {
    if (mode == CameraMode.video) {
      return flashMode == true ? Icons.flashlight_on : Icons.flashlight_off;
    }
    
    // Photo mode
    switch (flashMode as camera.FlashMode?) {
      case camera.FlashMode.off:
        return Icons.flash_off;
      case camera.FlashMode.auto:
        return Icons.flash_auto;
      case camera.FlashMode.always:
        return Icons.flash_on;
      case camera.FlashMode.torch:
        return Icons.flashlight_on;
      default:
        return Icons.flash_off;
    }
  }
  
  /// Get the display name for the current flash mode
  static String getDisplayName(CameraMode mode, dynamic flashMode) {
    if (mode == CameraMode.video) {
      return flashMode == true ? 'Torch' : 'Off';
    }
    
    // Photo mode
    switch (flashMode as camera.FlashMode?) {
      case camera.FlashMode.off:
        return 'Off';
      case camera.FlashMode.auto:
        return 'Auto';
      case camera.FlashMode.always:
        return 'On';
      case camera.FlashMode.torch:
        return 'Torch';
      default:
        return 'Off';
    }
  }
  
  /// Cycle to the next flash mode
  static void cycle(WidgetRef ref, bool isVideoMode) {
    final cameraState = ref.read(cameraControllerProvider);
    
    if (cameraState.controller == null) return;
    
    if (isVideoMode || cameraState.mode == CameraMode.video) {
      // Video flash cycling
      final currentVideoFlashMode = cameraState.videoFlashMode;
      final nextMode = currentVideoFlashMode == VideoFlashMode.off 
          ? VideoFlashMode.torch 
          : VideoFlashMode.off;
      // Update the state directly since we don't have a setVideoFlashMode method
      // We'll use cycleFlashMode instead
      ref.read(cameraControllerProvider.notifier).cycleFlashMode();
    } else {
      // Photo flash cycling  
      final currentPhotoFlashMode = cameraState.photoFlashMode;
      PhotoFlashMode nextMode;
      
      switch (currentPhotoFlashMode) {
        case PhotoFlashMode.off:
          nextMode = PhotoFlashMode.auto;
          break;
        case PhotoFlashMode.auto:
          nextMode = PhotoFlashMode.on;
          break;
        case PhotoFlashMode.on:
        default:
          nextMode = PhotoFlashMode.off;
          break;
      }
      
      // Update the state directly since we don't have a setPhotoFlashMode method
      // We'll use cycleFlashMode instead
      ref.read(cameraControllerProvider.notifier).cycleFlashMode();
    }
  }
  
  /// Get the current flash mode based on camera mode
  static dynamic getCurrentFlashMode(CameraState cameraState, bool isVideoMode) {
    if (cameraState.mode == CameraMode.video || (cameraState.mode == CameraMode.combined && isVideoMode)) {
      // For video mode, return whether torch is on
      return cameraState.videoFlashMode == VideoFlashMode.torch;
    }
    // For photo mode, return the actual flash mode from controller
    return cameraState.controller?.value.flashMode ?? camera.FlashMode.off;
  }
}