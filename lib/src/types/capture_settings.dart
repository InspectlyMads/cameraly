import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:geolocator/geolocator.dart';

import '../cameraly_camera.dart'; // Import for CameraPreviewSettings
import 'camera_mode.dart';

/// Compression quality level for captured media.
enum CompressionQuality {
  /// No compression, original quality.
  none,

  /// Light compression, high quality.
  light,

  /// Medium compression, good quality.
  medium,

  /// High compression, reduced quality.
  high,

  /// Automatic compression based on the resolution setting.
  /// This is the default and recommended option.
  auto,
}

/// Base settings for camera capture operations.
///
/// This class contains the technical settings for camera hardware configuration,
/// such as resolution, flash mode, and camera mode. It is used by [CameralyController]
/// for camera initialization and configuration.
///
/// For UI-related settings, see [CameraPreviewSettings] in the CameralyCamera.
///
/// Note: [CaptureSettings] focuses on the technical aspects of camera operation,
/// while [CameraPreviewSettings] is used by [CameralyCamera] and includes both
/// technical settings and UI configuration options.
class CaptureSettings {
  /// Creates settings for camera capture.
  ///
  /// Note: When [cameraMode] is set to [CameraMode.photoOnly], [enableAudio] will
  /// automatically be set to false regardless of the value provided.
  const CaptureSettings({
    this.cameraMode = CameraMode.both,
    bool enableAudio = true,
    this.flashMode = FlashMode.auto,
    this.resolution = ResolutionPreset.max,
    this.exposureMode = ExposureMode.auto,
    this.focusMode = FocusMode.auto,
    this.deviceOrientation = DeviceOrientation.portraitUp,
    this.maxVideoDuration,
    this.compressionQuality = CompressionQuality.auto,
    this.imageQuality = 90,
    this.videoQuality = 85,
    this.addLocationMetadata = false,
    this.locationAccuracy = LocationAccuracy.high,
  })  :
        // Force enableAudio to false when in photoOnly mode
        enableAudio = cameraMode == CameraMode.photoOnly ? false : enableAudio,
        assert(
          maxVideoDuration == null || cameraMode != CameraMode.photoOnly,
          'maxVideoDuration can only be used with CameraMode.videoOnly or CameraMode.both',
        ),
        assert(
          imageQuality >= 0 && imageQuality <= 100,
          'imageQuality must be between 0 and 100',
        ),
        assert(
          videoQuality >= 0 && videoQuality <= 100,
          'videoQuality must be between 0 and 100',
        );

  /// The camera mode (photo, video, or both).
  final CameraMode cameraMode;

  /// Whether to enable audio recording for videos.
  ///
  /// This is always false when [cameraMode] is [CameraMode.photoOnly].
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

  /// The compression quality level for captured media.
  /// Affects both images and videos.
  ///
  /// Default is [CompressionQuality.auto], which automatically sets compression
  /// based on the resolution.
  final CompressionQuality compressionQuality;

  /// Image quality percentage (0-100) when compression is enabled.
  ///
  /// Only used when [compressionQuality] is not [CompressionQuality.none].
  /// Higher values mean better quality but larger file sizes.
  /// Default is 90, which provides good quality with reasonable compression.
  final int imageQuality;

  /// Video quality percentage (0-100) when compression is enabled.
  ///
  /// Only used when [compressionQuality] is not [CompressionQuality.none].
  /// Higher values mean better quality but larger file sizes.
  /// Default is 85, which provides good quality with reasonable compression.
  final int videoQuality;

  /// Whether to add location metadata to captured media.
  final bool addLocationMetadata;

  /// The accuracy level for location metadata.
  final LocationAccuracy locationAccuracy;

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
    CompressionQuality? compressionQuality,
    int? imageQuality,
    int? videoQuality,
    bool? addLocationMetadata,
    LocationAccuracy? locationAccuracy,
  }) {
    final newCameraMode = cameraMode ?? this.cameraMode;
    // If new camera mode is photoOnly, force enableAudio to false
    final newEnableAudio = newCameraMode == CameraMode.photoOnly ? false : (enableAudio ?? this.enableAudio);

    return CaptureSettings(
      cameraMode: newCameraMode,
      enableAudio: newEnableAudio,
      flashMode: flashMode ?? this.flashMode,
      resolution: resolution ?? this.resolution,
      exposureMode: exposureMode ?? this.exposureMode,
      focusMode: focusMode ?? this.focusMode,
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
      maxVideoDuration: maxVideoDuration ?? this.maxVideoDuration,
      compressionQuality: compressionQuality ?? this.compressionQuality,
      imageQuality: imageQuality ?? this.imageQuality,
      videoQuality: videoQuality ?? this.videoQuality,
      addLocationMetadata: addLocationMetadata ?? this.addLocationMetadata,
      locationAccuracy: locationAccuracy ?? this.locationAccuracy,
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

  /// Creates a new settings instance optimized for file size (more compression).
  factory CaptureSettings.optimizeStorage() => const CaptureSettings(
        resolution: ResolutionPreset.medium,
        flashMode: FlashMode.auto,
        exposureMode: ExposureMode.auto,
        focusMode: FocusMode.auto,
        compressionQuality: CompressionQuality.high,
        imageQuality: 80,
        videoQuality: 75,
      );

  /// Creates a new settings instance optimized for quality (less compression).
  factory CaptureSettings.highQuality() => const CaptureSettings(
        resolution: ResolutionPreset.veryHigh,
        flashMode: FlashMode.auto,
        exposureMode: ExposureMode.auto,
        focusMode: FocusMode.auto,
        compressionQuality: CompressionQuality.light,
        imageQuality: 95,
        videoQuality: 90,
      );

  /// Creates a new settings instance with maximum quality and no compression.
  factory CaptureSettings.maxQuality() => const CaptureSettings(
        resolution: ResolutionPreset.max,
        flashMode: FlashMode.auto,
        exposureMode: ExposureMode.auto,
        focusMode: FocusMode.auto,
        compressionQuality: CompressionQuality.none,
        imageQuality: 100,
        videoQuality: 100,
      );

  /// Creates a new settings instance from a [CameraPreviewSettings] object.
  ///
  /// This allows for seamless conversion between the two settings classes.
  factory CaptureSettings.fromPreviewSettings(CameraPreviewSettings settings) {
    final cameraMode = settings.cameraMode;
    // If camera mode is photoOnly, force enableAudio to false
    final enableAudio = cameraMode == CameraMode.photoOnly ? false : settings.enableAudio;

    return CaptureSettings(
      cameraMode: cameraMode,
      enableAudio: enableAudio,
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
          maxVideoDuration == other.maxVideoDuration &&
          compressionQuality == other.compressionQuality &&
          imageQuality == other.imageQuality &&
          videoQuality == other.videoQuality &&
          addLocationMetadata == other.addLocationMetadata &&
          locationAccuracy == other.locationAccuracy;

  @override
  int get hashCode =>
      enableAudio.hashCode ^
      resolution.hashCode ^
      flashMode.hashCode ^
      exposureMode.hashCode ^
      focusMode.hashCode ^
      deviceOrientation.hashCode ^
      cameraMode.hashCode ^
      maxVideoDuration.hashCode ^
      compressionQuality.hashCode ^
      imageQuality.hashCode ^
      videoQuality.hashCode ^
      addLocationMetadata.hashCode ^
      locationAccuracy.hashCode;

  @override
  String toString() => 'CaptureSettings('
      'enableAudio: $enableAudio, '
      'resolution: $resolution, '
      'flashMode: $flashMode, '
      'exposureMode: $exposureMode, '
      'focusMode: $focusMode, '
      'deviceOrientation: $deviceOrientation, '
      'cameraMode: $cameraMode, '
      'maxVideoDuration: $maxVideoDuration, '
      'compressionQuality: $compressionQuality, '
      'imageQuality: $imageQuality, '
      'videoQuality: $videoQuality, '
      'addLocationMetadata: $addLocationMetadata, '
      'locationAccuracy: $locationAccuracy)';
}
