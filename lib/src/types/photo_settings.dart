import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'camera_mode.dart';
import 'capture_settings.dart';

/// Settings specific to photo capture operations.
@immutable
class PhotoSettings extends CaptureSettings {
  /// Creates a new [PhotoSettings] instance.
  const PhotoSettings({
    super.resolution = ResolutionPreset.high,
    super.flashMode = FlashMode.auto,
    super.exposureMode = ExposureMode.auto,
    super.focusMode = FocusMode.auto,
    super.deviceOrientation = DeviceOrientation.portraitUp,
    super.cameraMode = CameraMode.photoOnly,
    this.enableShutterSound = true,
    this.enableRedEyeReduction = false,
    this.imageFormat = ImageFormat.jpeg,
    this.quality = 95,
  }) : super(enableAudio: false);

  /// Whether to play a shutter sound when taking a photo.
  final bool enableShutterSound;

  /// Whether to enable red-eye reduction.
  final bool enableRedEyeReduction;

  /// The format to use for saving the image.
  final ImageFormat imageFormat;

  /// The quality of the image (0-100).
  final int quality;

  /// Creates a copy of this settings instance with the given fields replaced.
  ///
  /// Note: This override maintains type safety while allowing photo-specific parameters.
  @override
  PhotoSettings copyWith({
    ResolutionPreset? resolution,
    FlashMode? flashMode,
    ExposureMode? exposureMode,
    FocusMode? focusMode,
    DeviceOrientation? deviceOrientation,
    CameraMode? cameraMode,
    bool? enableAudio,
    bool? enableShutterSound,
    bool? enableRedEyeReduction,
    ImageFormat? imageFormat,
    int? quality,
    Duration? maxVideoDuration,
  }) {
    return PhotoSettings(
      resolution: resolution ?? this.resolution,
      flashMode: flashMode ?? this.flashMode,
      exposureMode: exposureMode ?? this.exposureMode,
      focusMode: focusMode ?? this.focusMode,
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
      cameraMode: cameraMode ?? this.cameraMode,
      enableShutterSound: enableShutterSound ?? this.enableShutterSound,
      enableRedEyeReduction: enableRedEyeReduction ?? this.enableRedEyeReduction,
      imageFormat: imageFormat ?? this.imageFormat,
      quality: quality ?? this.quality,
    );
  }

  /// Creates a new settings instance optimized for portrait photography.
  factory PhotoSettings.portrait() => const PhotoSettings(
        resolution: ResolutionPreset.veryHigh,
        flashMode: FlashMode.auto,
        exposureMode: ExposureMode.auto,
        focusMode: FocusMode.auto,
        cameraMode: CameraMode.photoOnly,
        enableRedEyeReduction: true,
      );

  /// Creates a new settings instance optimized for landscape photography.
  factory PhotoSettings.landscape() => const PhotoSettings(
        resolution: ResolutionPreset.ultraHigh,
        flashMode: FlashMode.off,
        exposureMode: ExposureMode.auto,
        focusMode: FocusMode.auto,
        cameraMode: CameraMode.photoOnly,
        deviceOrientation: DeviceOrientation.landscapeRight,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is PhotoSettings &&
          runtimeType == other.runtimeType &&
          enableShutterSound == other.enableShutterSound &&
          enableRedEyeReduction == other.enableRedEyeReduction &&
          imageFormat == other.imageFormat &&
          quality == other.quality;

  @override
  int get hashCode => super.hashCode ^ enableShutterSound.hashCode ^ enableRedEyeReduction.hashCode ^ imageFormat.hashCode ^ quality.hashCode;

  @override
  String toString() => 'PhotoSettings(${super.toString()}, '
      'enableShutterSound: $enableShutterSound, '
      'enableRedEyeReduction: $enableRedEyeReduction, '
      'imageFormat: $imageFormat, quality: $quality)';
}

/// The format to use when saving images.
enum ImageFormat {
  /// JPEG format with compression.
  jpeg,

  /// PNG format (lossless).
  png,

  /// Raw sensor data.
  raw,

  /// HEIF format (high efficiency).
  heif,
}
