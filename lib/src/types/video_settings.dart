import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'capture_settings.dart';

/// Settings specific to video capture operations.
@immutable
class VideoSettings extends CaptureSettings {
  /// Creates a new [VideoSettings] instance.
  const VideoSettings({
    super.resolution = ResolutionPreset.high,
    super.flashMode = FlashMode.auto,
    super.exposureMode = ExposureMode.auto,
    super.focusMode = FocusMode.auto,
    super.deviceOrientation = DeviceOrientation.portraitUp,
    super.enableAudio = true,
    this.maxDuration,
    this.videoBitrate,
    this.audioBitrate = 128000,
    this.videoFormat = VideoFormat.mp4,
    this.stabilizationMode = VideoStabilizationMode.auto,
  });

  /// Maximum duration of the video recording.
  final Duration? maxDuration;

  /// Video bitrate in bits per second.
  final int? videoBitrate;

  /// Audio bitrate in bits per second.
  final int audioBitrate;

  /// The format to use for saving the video.
  final VideoFormat videoFormat;

  /// The video stabilization mode to use.
  final VideoStabilizationMode stabilizationMode;

  /// Creates a copy of this settings instance with the given fields replaced.
  @override
  VideoSettings copyWith({
    ResolutionPreset? resolution,
    FlashMode? flashMode,
    ExposureMode? exposureMode,
    FocusMode? focusMode,
    DeviceOrientation? deviceOrientation,
    bool? enableAudio,
    Duration? maxDuration,
    int? videoBitrate,
    int? audioBitrate,
    VideoFormat? videoFormat,
    VideoStabilizationMode? stabilizationMode,
  }) {
    return VideoSettings(
      resolution: resolution ?? this.resolution,
      flashMode: flashMode ?? this.flashMode,
      exposureMode: exposureMode ?? this.exposureMode,
      focusMode: focusMode ?? this.focusMode,
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
      enableAudio: enableAudio ?? this.enableAudio,
      maxDuration: maxDuration ?? this.maxDuration,
      videoBitrate: videoBitrate ?? this.videoBitrate,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      videoFormat: videoFormat ?? this.videoFormat,
      stabilizationMode: stabilizationMode ?? this.stabilizationMode,
    );
  }

  /// Creates a new settings instance optimized for high-quality video recording.
  factory VideoSettings.highQuality() => const VideoSettings(
        resolution: ResolutionPreset.veryHigh,
        flashMode: FlashMode.off,
        exposureMode: ExposureMode.auto,
        focusMode: FocusMode.auto,
        videoBitrate: 10000000, // 10 Mbps
        audioBitrate: 256000, // 256 kbps
        stabilizationMode: VideoStabilizationMode.standard,
      );

  /// Creates a new settings instance optimized for storage efficiency.
  factory VideoSettings.efficient() => const VideoSettings(
        resolution: ResolutionPreset.medium,
        flashMode: FlashMode.off,
        exposureMode: ExposureMode.auto,
        focusMode: FocusMode.auto,
        videoBitrate: 2000000, // 2 Mbps
        audioBitrate: 96000, // 96 kbps
        stabilizationMode: VideoStabilizationMode.off,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is VideoSettings &&
          runtimeType == other.runtimeType &&
          maxDuration == other.maxDuration &&
          videoBitrate == other.videoBitrate &&
          audioBitrate == other.audioBitrate &&
          videoFormat == other.videoFormat &&
          stabilizationMode == other.stabilizationMode;

  @override
  int get hashCode => super.hashCode ^ maxDuration.hashCode ^ videoBitrate.hashCode ^ audioBitrate.hashCode ^ videoFormat.hashCode ^ stabilizationMode.hashCode;

  @override
  String toString() => 'VideoSettings(${super.toString()}, '
      'maxDuration: $maxDuration, videoBitrate: $videoBitrate, '
      'audioBitrate: $audioBitrate, videoFormat: $videoFormat, '
      'stabilizationMode: $stabilizationMode)';
}

/// The format to use when saving videos.
enum VideoFormat {
  /// MP4 format (H.264/AAC).
  mp4,

  /// MOV format (QuickTime).
  mov,

  /// WebM format (VP8/Vorbis).
  webm,
}

/// Video stabilization modes.
enum VideoStabilizationMode {
  /// No stabilization.
  off,

  /// Standard stabilization.
  standard,

  /// Cinematic stabilization.
  cinematic,

  /// Automatic selection based on device capabilities.
  auto,
}
