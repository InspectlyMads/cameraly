import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Channel for configuring video codec options on native side
class VideoCodecChannel {
  static const MethodChannel _channel = MethodChannel('com.cameraly/video_codec');
  static bool _initialized = false;

  /// Initialize the channel - this is a workaround to ensure the channel is registered
  static Future<bool> initialize() async {
    if (_initialized) return true;

    if (!Platform.isIOS) {
      _initialized = true;
      return true;
    }

    try {
      // First try to connect to the handler in AppDelegate
      try {
        final result = await _channel.invokeMethod<bool>('manuallyRegisterFromAppDelegate');
        if (result == true) {
          debugPrint('🎥 Successfully connected to AppDelegate handler');
          _initialized = true;
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ AppDelegate handler not available: $e');
        // Fall through to other methods
      }

      // Next try to directly invoke the method
      try {
        await _channel.invokeMethod<bool>('forceH264Encoding');
        debugPrint('🎥 Direct method call succeeded');
        _initialized = true;
        return true;
      } catch (e) {
        debugPrint('⚠️ Normal initialization error (expected): $e');
        // This is expected to fail on first call, but it will register the channel
      }

      // Attempt last-resort initialization through multiple channels
      for (final channelName in ['com.cameraly/video_codec', 'com.cameraly/video_transcoder', 'com.cameraly/orientation', 'cameraly']) {
        try {
          const platform = MethodChannel('cameraly');
          final result = await platform.invokeMethod<bool>('ping');
          debugPrint('🎥 Connected to cameraly main channel: $result');
          break;
        } catch (e) {
          // Ignore
        }
      }

      // Log success
      debugPrint('🎥 VideoCodecChannel initialized (best effort)');
      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('⚠️ Error initializing VideoCodecChannel: $e');
      return false;
    }
  }

  /// Forces H.264 encoding for video recordings on iOS
  /// Returns true if successfully configured
  static Future<bool> forceH264Encoding() async {
    if (!Platform.isIOS) return false;

    // Make sure we're initialized
    await initialize();

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

    // Make sure we're initialized
    await initialize();

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

    // Make sure we're initialized
    await initialize();

    try {
      final result = await _channel.invokeMethod<String>('transcodeHevcToH264', {'path': path});
      return result;
    } catch (e) {
      debugPrint('⚠️ Error transcoding HEVC to H.264: $e');
      return null;
    }
  }
}
