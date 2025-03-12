import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A utility class that uses a method channel to get the exact device rotation from the platform.
class OrientationChannel {
  /// The method channel used to communicate with the platform-specific code.
  static const MethodChannel _channel = MethodChannel('com.cameraly/orientation');

  /// Gets the current device orientation from the platform.
  ///
  /// Returns a [DeviceOrientation] based on the device's actual rotation.
  ///
  /// This is more reliable than using MediaQuery or view padding to detect
  /// landscape left vs landscape right on Android devices.
  static Future<DeviceOrientation> getPlatformOrientation() async {
    try {
      // Request the raw rotation value from the platform (0, 1, 2, or 3)
      final int rotation = await _channel.invokeMethod('getDeviceRotation');
      debugPrint('🧭 Native rotation value: $rotation');

      // Convert the rotation value to a DeviceOrientation
      DeviceOrientation orientation;
      switch (rotation) {
        case 0:
          orientation = DeviceOrientation.portraitUp;
          break;
        case 1:
          orientation = DeviceOrientation.landscapeLeft;
          break;
        case 2:
          orientation = DeviceOrientation.portraitDown;
          break;
        case 3:
          orientation = DeviceOrientation.landscapeRight;
          break;
        default:
          orientation = DeviceOrientation.portraitUp;
          debugPrint('🧭 Unknown rotation value $rotation, defaulting to portraitUp');
          break;
      }

      debugPrint('🧭 Mapped to $orientation');
      return orientation;
    } catch (e) {
      debugPrint('❌ Error getting platform orientation: $e');
      return DeviceOrientation.portraitUp; // Fallback to portrait
    }
  }

  /// Gets the raw rotation value from the platform.
  ///
  /// This method returns the unmapped integer value from the platform:
  /// - 0: Portrait up (Surface.ROTATION_0)
  /// - 1: Landscape right (Surface.ROTATION_90)
  /// - 2: Portrait down (Surface.ROTATION_180)
  /// - 3: Landscape left (Surface.ROTATION_270)
  ///
  /// This is useful for debugging orientation issues.
  static Future<int> getRawRotationValue() async {
    try {
      final int rotation = await _channel.invokeMethod('getDeviceRotation');
      debugPrint('🧭 Raw rotation value: $rotation');
      return rotation;
    } catch (e) {
      debugPrint('❌ Error getting raw rotation: $e');
      return -1; // Error value
    }
  }

  /// Checks if the device is currently in landscape left orientation.
  static Future<bool> isLandscapeLeft() async {
    final orientation = await getPlatformOrientation();
    return orientation == DeviceOrientation.landscapeLeft;
  }
}
