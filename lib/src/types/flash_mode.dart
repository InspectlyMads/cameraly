/// Controls the flash mode of the camera.
enum FlashMode {
  /// Flash will not be used.
  off,

  /// Flash will always be fired during capture.
  always,

  /// Flash will be fired automatically when required.
  auto,

  /// Flash will be fired in torch mode (continuous light).
  torch;

  /// Returns true if this flash mode is supported on the current device.
  ///
  /// Note: This is a placeholder implementation. The actual implementation
  /// will need to check device capabilities.
  bool get isSupported {
    // TODO: Implement actual device capability check
    return true;
  }

  /// Returns a human-readable description of the flash mode.
  String get description {
    switch (this) {
      case FlashMode.off:
        return 'Flash is disabled';
      case FlashMode.always:
        return 'Flash will fire on every capture';
      case FlashMode.auto:
        return 'Flash will fire automatically when needed';
      case FlashMode.torch:
        return 'Flash will stay on continuously';
    }
  }

  /// Returns the icon name associated with this flash mode.
  String get iconName {
    switch (this) {
      case FlashMode.off:
        return 'flash_off';
      case FlashMode.always:
        return 'flash_on';
      case FlashMode.auto:
        return 'flash_auto';
      case FlashMode.torch:
        return 'highlight';
    }
  }
}
