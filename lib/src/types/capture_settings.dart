import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;

import 'camera_mode.dart';

/// Settings for camera capture.
class CaptureSettings {
  /// Creates a new [CaptureSettings] instance.
  const CaptureSettings({
    this.enableAudio = true,
    this.resolution = ResolutionPreset.max,
    this.flashMode = FlashMode.auto,
    this.exposureMode = ExposureMode.auto,
    this.focusMode = FocusMode.auto,
    this.deviceOrientation = DeviceOrientation.portraitUp,
    this.cameraMode = CameraMode.both,
  });

  /// Whether to enable audio recording.
  final bool enableAudio;

  /// The resolution preset to use.
  final ResolutionPreset resolution;

  /// The flash mode to use.
  final FlashMode flashMode;

  /// The exposure mode to use.
  final ExposureMode exposureMode;

  /// The focus mode to use.
  final FocusMode focusMode;

  /// The device orientation to use.
  final DeviceOrientation deviceOrientation;

  /// The camera mode to use.
  final CameraMode cameraMode;

  /// Creates a copy of this settings with the given fields replaced.
  CaptureSettings copyWith({
    bool? enableAudio,
    ResolutionPreset? resolution,
    FlashMode? flashMode,
    ExposureMode? exposureMode,
    FocusMode? focusMode,
    DeviceOrientation? deviceOrientation,
    CameraMode? cameraMode,
  }) {
    return CaptureSettings(
      enableAudio: enableAudio ?? this.enableAudio,
      resolution: resolution ?? this.resolution,
      flashMode: flashMode ?? this.flashMode,
      exposureMode: exposureMode ?? this.exposureMode,
      focusMode: focusMode ?? this.focusMode,
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
      cameraMode: cameraMode ?? this.cameraMode,
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
          cameraMode == other.cameraMode;

  @override
  int get hashCode => enableAudio.hashCode ^ resolution.hashCode ^ flashMode.hashCode ^ exposureMode.hashCode ^ focusMode.hashCode ^ deviceOrientation.hashCode ^ cameraMode.hashCode;

  @override
  String toString() => 'CaptureSettings('
      'enableAudio: $enableAudio, '
      'resolution: $resolution, '
      'flashMode: $flashMode, '
      'exposureMode: $exposureMode, '
      'focusMode: $focusMode, '
      'deviceOrientation: $deviceOrientation, '
      'cameraMode: $cameraMode)';
}
