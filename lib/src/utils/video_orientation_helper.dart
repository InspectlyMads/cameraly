import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Helper class for handling video orientation during recording and playback
class VideoOrientationHelper {
  static const MethodChannel _channel = MethodChannel('com.cameraly/video_orientation');

  /// Reads orientation metadata from a video file
  /// Returns 'portrait', 'landscape', or null if orientation can't be determined
  static Future<String?> getVideoOrientation(String filePath) async {
    try {
      if (!Platform.isAndroid) return null;

      final result = await _channel.invokeMethod<String>('getVideoOrientation', {
        'filePath': filePath,
      });

      return result;
    } catch (e) {
      debugPrint('Error getting video orientation: $e');
      return null;
    }
  }

  /// Applies orientation metadata to a video file
  /// This allows fixing incorrectly rotated videos on Android
  static Future<bool> applyOrientationMetadata(String filePath, bool isPortrait) async {
    try {
      if (!Platform.isAndroid) return false;

      final result = await _channel.invokeMethod<bool>('applyOrientationMetadata', {
        'filePath': filePath,
        'isPortrait': isPortrait,
      });

      return result ?? false;
    } catch (e) {
      debugPrint('Error applying orientation metadata: $e');
      return false;
    }
  }

  /// Determines if a video has correct orientation metadata based on device orientation
  static bool needsOrientationFix(String filePath, double aspectRatio, bool isPortraitDevice) {
    // Check if this is likely a portrait video incorrectly marked as landscape
    // Portrait videos should have aspect ratio < 1.0
    if (isPortraitDevice && aspectRatio > 1.0) {
      return true;
    }

    // Check if this is likely a landscape video incorrectly marked as portrait
    // Landscape videos should have aspect ratio > 1.0
    if (!isPortraitDevice && aspectRatio < 1.0) {
      return true;
    }

    return false;
  }

  /// Gets the corrected aspect ratio for videos with incorrect orientation metadata
  static double getCorrectedAspectRatio(double originalAspectRatio, bool shouldInvert) {
    if (shouldInvert) {
      return 1.0 / originalAspectRatio;
    }
    return originalAspectRatio;
  }
}
