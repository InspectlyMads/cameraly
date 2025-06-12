import 'package:flutter/material.dart';
import 'package:camera/camera.dart' as camera;
import 'camera_service.dart';

/// Service for camera-related UI helpers and display logic
class CameraUIService {
  /// Get display name for camera lens direction
  static String getLensDirectionName(camera.CameraLensDirection direction) {
    switch (direction) {
      case camera.CameraLensDirection.front:
        return 'Front';
      case camera.CameraLensDirection.back:
        return 'Back';
      case camera.CameraLensDirection.external:
        return 'External';
    }
  }
  
  /// Get icon for camera lens direction
  static IconData getLensDirectionIcon(camera.CameraLensDirection direction) {
    switch (direction) {
      case camera.CameraLensDirection.front:
        return Icons.camera_front;
      case camera.CameraLensDirection.back:
        return Icons.camera_rear;
      case camera.CameraLensDirection.external:
        return Icons.camera;
    }
  }
  
  /// Get display string for camera mode
  static String getCameraModeDisplayName(CameraMode mode) {
    switch (mode) {
      case CameraMode.photo:
        return 'Photo';
      case CameraMode.video:
        return 'Video';
      case CameraMode.combined:
        return 'Photo/Video';
    }
  }
  
  /// Get photo flash mode display name
  static String getPhotoFlashDisplayName(PhotoFlashMode mode) {
    switch (mode) {
      case PhotoFlashMode.off:
        return 'Off';
      case PhotoFlashMode.auto:
        return 'Auto';
      case PhotoFlashMode.on:
        return 'On';
    }
  }

  /// Get video flash mode display name
  static String getVideoFlashDisplayName(VideoFlashMode mode) {
    switch (mode) {
      case VideoFlashMode.off:
        return 'Off';
      case VideoFlashMode.torch:
        return 'Torch';
    }
  }
  
  /// Get photo flash mode icon
  static String getPhotoFlashIcon(PhotoFlashMode mode) {
    switch (mode) {
      case PhotoFlashMode.off:
        return '⚫';
      case PhotoFlashMode.auto:
        return '⚡';
      case PhotoFlashMode.on:
        return '💡';
    }
  }

  /// Get video flash mode icon
  static String getVideoFlashIcon(VideoFlashMode mode) {
    switch (mode) {
      case VideoFlashMode.off:
        return '⚫';
      case VideoFlashMode.torch:
        return '🔦';
    }
  }
  
  /// Get resolution preset display name
  static String getResolutionPresetName(camera.ResolutionPreset preset) {
    switch (preset) {
      case camera.ResolutionPreset.low:
        return 'Low (240p)';
      case camera.ResolutionPreset.medium:
        return 'Medium (480p)';
      case camera.ResolutionPreset.high:
        return 'High (720p)';
      case camera.ResolutionPreset.veryHigh:
        return 'Very High (1080p)';
      case camera.ResolutionPreset.ultraHigh:
        return 'Ultra High (2160p)';
      case camera.ResolutionPreset.max:
        return 'Maximum';
    }
  }
  
  /// Get user-friendly error message
  static String getErrorMessage(camera.CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
        return 'Camera access denied. Please enable camera permissions.';
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Camera access denied. Please go to Settings to enable permissions.';
      case 'CameraAccessRestricted':
        return 'Camera access is restricted on this device.';
      case 'AudioAccessDenied':
        return 'Microphone access denied. Please enable microphone permissions.';
      case 'AudioAccessDeniedWithoutPrompt':
        return 'Microphone access denied. Please go to Settings to enable permissions.';
      case 'AudioAccessRestricted':
        return 'Microphone access is restricted on this device.';
      case 'cameraNotFound':
        return 'No camera found on this device.';
      default:
        return 'Camera error: ${e.description ?? e.code}';
    }
  }
  
  /// Format recording duration
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
  
  /// Get appropriate camera icon based on state
  static IconData getCameraStateIcon(CameraState state) {
    if (state.errorMessage != null) {
      return Icons.error_outline;
    }
    if (state.isRecording) {
      return Icons.videocam;
    }
    if (state.controller?.value.isInitialized ?? false) {
      return Icons.camera_alt;
    }
    return Icons.camera_alt_outlined;
  }
}