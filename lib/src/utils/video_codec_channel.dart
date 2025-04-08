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
}
