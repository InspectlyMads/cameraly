/// Photo quality presets
enum PhotoQuality {
  /// Lowest quality, smallest file size
  low,
  
  /// Balanced quality and file size
  medium,
  
  /// High quality, larger file size
  high,
  
  /// Maximum available quality
  max,
}

/// Video quality presets
enum VideoQuality {
  /// 720p (1280x720)
  hd,
  
  /// 1080p (1920x1080)
  fullHd,
  
  /// 4K (3840x2160) - if supported by device
  uhd,
}

/// Camera aspect ratio options
enum CameraAspectRatio {
  /// 4:3 ratio (native camera aspect ratio)
  ratio_4_3,
}

/// Camera configuration settings
class CameraSettings {
  /// Photo capture quality
  final PhotoQuality photoQuality;
  
  /// Video recording quality
  final VideoQuality videoQuality;
  
  
  /// Timer delay for photo capture (in seconds)
  final int? photoTimerSeconds;
  
  /// Enable/disable sound effects
  final bool enableSounds;
  
  /// Enable/disable haptic feedback
  final bool enableHaptics;
  
  /// Maximum video file size in MB (null for unlimited)
  final int? maxVideoSizeMB;
  
  /// Auto-save to device gallery
  final bool autoSaveToGallery;

  const CameraSettings({
    this.photoQuality = PhotoQuality.high,
    this.videoQuality = VideoQuality.fullHd,
    this.photoTimerSeconds,
    this.enableSounds = true,
    this.enableHaptics = true,
    this.maxVideoSizeMB,
    this.autoSaveToGallery = true,
  });
  
  CameraSettings copyWith({
    PhotoQuality? photoQuality,
    VideoQuality? videoQuality,
    int? photoTimerSeconds,
    bool? enableSounds,
    bool? enableHaptics,
    int? maxVideoSizeMB,
    bool? autoSaveToGallery,
  }) {
    return CameraSettings(
      photoQuality: photoQuality ?? this.photoQuality,
      videoQuality: videoQuality ?? this.videoQuality,
      photoTimerSeconds: photoTimerSeconds ?? this.photoTimerSeconds,
      enableSounds: enableSounds ?? this.enableSounds,
      enableHaptics: enableHaptics ?? this.enableHaptics,
      maxVideoSizeMB: maxVideoSizeMB ?? this.maxVideoSizeMB,
      autoSaveToGallery: autoSaveToGallery ?? this.autoSaveToGallery,
    );
  }
}