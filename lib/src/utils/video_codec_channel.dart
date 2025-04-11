import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Channel for configuring video codec options on native side
class VideoCodecChannel {
  static const MethodChannel _channel = MethodChannel('com.cameraly/video_codec');

  /// Forces H.264 encoding for video recordings on iOS
  /// Returns true if successfully configured
  static Future<bool> forceH264Encoding() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('forceH264Encoding');
      return result ?? false;
    } catch (e) {
      debugPrint('⚠️ Error setting video codec to H.264: $e');
      return false;
    }
  }

  /// Checks if a video file is HEVC encoded
  /// Returns true if the video is HEVC encoded
  static Future<bool> isVideoHevc(String path) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isVideoHevc', {'path': path});
      return result ?? false;
    } catch (e) {
      debugPrint('⚠️ Error checking if video is HEVC: $e');
      return false;
    }
  }

  /// Transcodes an HEVC video to H.264 for better compatibility
  /// Returns the path to the transcoded video file, or null if transcoding failed
  static Future<String?> transcodeHevcToH264(String path) async {
    if (!Platform.isIOS) return null;

    try {
      final result = await _channel.invokeMethod<String>('transcodeHevcToH264', {'path': path});
      return result;
    } catch (e) {
      debugPrint('⚠️ Error transcoding HEVC to H.264: $e');
      return null;
    }
  }
}
