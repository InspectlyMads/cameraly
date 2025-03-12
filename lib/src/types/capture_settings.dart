import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;

import '../cameraly_previewer.dart'; // Import for CameraPreviewSettings
import 'camera_mode.dart';

/// Settings for camera capture.
///
/// This class focuses on the technical aspects of camera operation.
/// For UI-related settings, see [CameraPreviewSettings] in the CameraPreviewer.
///
/// [CaptureSettings] is used by [CameralyController] to configure the camera hardware,
/// while [CameraPreviewSettings] is used by [CameraPreviewer] and includes both
/// camera hardware settings and UI/overlay configuration.
class CaptureSettings {
  /// Creates settings for camera capture.
  const CaptureSettings({
    this.cameraMode = CameraMode.both,
    this.enableAudio = true,
    this.flashMode = FlashMode.auto,
    this.resolution = ResolutionPreset.max,
    this.exposureMode = ExposureMode.auto,
    this.focusMode = FocusMode.auto,
    this.deviceOrientation = DeviceOrientation.portraitUp,
    this.maxVideoDuration,
  }) : assert(
          maxVideoDuration == null || cameraMode != CameraMode.photoOnly,
          'maxVideoDuration can only be used with CameraMode.videoOnly or CameraMode.both',
        );

  /// The camera mode (photo, video, or both).
  final CameraMode cameraMode;

  /// Whether to enable audio recording for videos.
  final bool enableAudio;

  /// The initial flash mode.
  final FlashMode flashMode;

  /// The resolution preset for the camera.
  final ResolutionPreset resolution;

  /// The exposure mode for the camera.
  final ExposureMode exposureMode;

  /// The focus mode for the camera.
  final FocusMode focusMode;

  /// The device orientation for the camera.
  final DeviceOrientation deviceOrientation;

  /// Maximum duration for video recording.
  /// Only applicable when [cameraMode] is [CameraMode.videoOnly] or [CameraMode.both].
  final Duration? maxVideoDuration;

  /// Creates a copy of this settings object with the given fields replaced.
  CaptureSettings copyWith({
    CameraMode? cameraMode,
    bool? enableAudio,
    FlashMode? flashMode,
    ResolutionPreset? resolution,
    ExposureMode? exposureMode,
    FocusMode? focusMode,
    DeviceOrientation? deviceOrientation,
    Duration? maxVideoDuration,
  }) {
    return CaptureSettings(
      cameraMode: cameraMode ?? this.cameraMode,
      enableAudio: enableAudio ?? this.enableAudio,
      flashMode: flashMode ?? this.flashMode,
      resolution: resolution ?? this.resolution,
      exposureMode: exposureMode ?? this.exposureMode,
      focusMode: focusMode ?? this.focusMode,
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
      maxVideoDuration: maxVideoDuration ?? this.maxVideoDuration,
    );
  }

  /// Creates a new settings instance with optimal settings for low light.
  factory CaptureSettings.lowLight() => const CaptureSettings(
        resolution: ResolutionPreset.high,
        flashMode: FlashMode.auto,
        exposureMode: ExposureMode.auto,
        focusMode: FocusMode.auto,
      );

  /// Creates a new settings instance with optimal settings for action shots.
  factory CaptureSettings.action() => const CaptureSettings(
        resolution: ResolutionPreset.veryHigh,
        flashMode: FlashMode.off,
        exposureMode: ExposureMode.auto,
        focusMode: FocusMode.auto,
      );

  /// Creates a new settings instance from a [CameraPreviewSettings] object.
  ///
  /// This allows for seamless conversion between the two settings classes.
  factory CaptureSettings.fromPreviewSettings(CameraPreviewSettings settings) {
    return CaptureSettings(
      cameraMode: settings.cameraMode,
      enableAudio: settings.enableAudio,
      flashMode: settings.flashMode,
      resolution: settings.resolution,
      maxVideoDuration: settings.videoDurationLimit,
      // Use defaults for other properties
      exposureMode: ExposureMode.auto,
      focusMode: FocusMode.auto,
      deviceOrientation: DeviceOrientation.portraitUp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaptureSettings &&
          runtimeType == other.runtimeType &&
          enableAudio == other.enableAudio &&
          resolution == other.resolution &&
          flashMode == other.flashMode &&
          exposureMode == other.exposureMode &&
          focusMode == other.focusMode &&
          deviceOrientation == other.deviceOrientation &&
          cameraMode == other.cameraMode &&
          maxVideoDuration == other.maxVideoDuration;

  @override
  int get hashCode => enableAudio.hashCode ^ resolution.hashCode ^ flashMode.hashCode ^ exposureMode.hashCode ^ focusMode.hashCode ^ deviceOrientation.hashCode ^ cameraMode.hashCode ^ maxVideoDuration.hashCode;

  @override
  String toString() => 'CaptureSettings('
      'enableAudio: $enableAudio, '
      'resolution: $resolution, '
      'flashMode: $flashMode, '
      'exposureMode: $exposureMode, '
      'focusMode: $focusMode, '
      'deviceOrientation: $deviceOrientation, '
      'cameraMode: $cameraMode, '
      'maxVideoDuration: $maxVideoDuration)';
}
