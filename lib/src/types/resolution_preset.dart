/// Preset resolution for camera preview and capture.
enum ResolutionPreset {
  /// 240p (320x240) resolution
  low,

  /// 480p (640x480) resolution
  medium,

  /// 720p (1280x720) resolution
  high,

  /// 1080p (1920x1080) resolution
  veryHigh,

  /// 2160p (3840x2160) resolution
  ultraHigh,

  /// The highest resolution available on the device
  max
}

/// Extension on [ResolutionPreset] to provide additional functionality.
extension ResolutionPresetExtension on ResolutionPreset {
  /// Returns the width and height for this resolution preset.
  ///
  /// Note: The actual resolution might be different depending on the device's
  /// capabilities and orientation.
  (int width, int height) get dimensions {
    switch (this) {
      case ResolutionPreset.low:
        return (320, 240);
      case ResolutionPreset.medium:
        return (640, 480);
      case ResolutionPreset.high:
        return (1280, 720);
      case ResolutionPreset.veryHigh:
        return (1920, 1080);
      case ResolutionPreset.ultraHigh:
        return (3840, 2160);
      case ResolutionPreset.max:
        return (0, 0); // Will be determined by the device
    }
  }

  /// Returns true if this preset is supported on the current device.
  ///
  /// Note: This is a placeholder implementation. The actual implementation
  /// will need to check device capabilities.
  bool get isSupported {
    // TODO: Implement actual device capability check
    return true;
  }
}
