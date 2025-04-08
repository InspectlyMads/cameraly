import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

/// Utility class for handling video transcoding
/// Particularly for converting HEVC (H.265) videos to more compatible H.264 format
class VideoTranscoder {
  static const MethodChannel _channel = MethodChannel('com.cameraly/video_transcoder');

  /// Checks if a video file uses HEVC encoding and transcodes it to H.264 if necessary
  ///
  /// Returns the original file if it's already H.264 or if transcoding fails
  /// Returns a new XFile with the transcoded video if successful
  static Future<XFile> ensureH264Encoding(XFile videoFile) async {
    try {
      // Only process iOS videos - Android typically uses H.264 already
      if (!Platform.isIOS) return videoFile;

      // Use VideoCompress to get media info
      final mediaInfo = await VideoCompress.getMediaInfo(videoFile.path);

      // Check if the video uses HEVC encoding
      final isHevc = _isHevcVideo(mediaInfo);

      if (isHevc) {
        debugPrint('🎥 Detected HEVC video, transcoding to H.264: ${videoFile.path}');
        return await _transcodeToH264(videoFile);
      } else {
        debugPrint('🎥 Video already uses H.264 or other compatible format: ${videoFile.path}');
        return videoFile;
      }
    } catch (e) {
      debugPrint('🎥 Error checking video encoding: $e');
      return videoFile; // Return original file on error
    }
  }

  /// Detects if a video uses HEVC encoding based on its media info
  static bool _isHevcVideo(MediaInfo mediaInfo) {
    // Possible HEVC format identifiers
    const hevcIdentifiers = ['hevc', 'hvc1', 'hev1', 'h.265', 'h265', 'x265'];

    // Check title and metadata for HEVC indicators
    final format = (mediaInfo.title ?? '').toLowerCase();
    final path = mediaInfo.path?.toLowerCase() ?? '';

    // Look for HEVC identifiers in format string or path
    for (final id in hevcIdentifiers) {
      if (format.contains(id) || path.contains(id)) {
        return true;
      }
    }

    // If we can't determine from format, check file size vs resolution as a heuristic
    // HEVC files are typically smaller than H.264 for the same quality
    // This is an imperfect heuristic but can help in some cases
    if (mediaInfo.filesize != null && mediaInfo.width != null && mediaInfo.height != null) {
      final resolution = mediaInfo.width! * mediaInfo.height!;
      final bitsPerPixel = (mediaInfo.filesize! * 8) / (resolution * (mediaInfo.duration ?? 1));

      // If bits per pixel is very low for the resolution, it's likely HEVC
      // This is a rough estimate and may not be accurate for all videos
      if (resolution > 1920 * 1080 && bitsPerPixel < 0.1) {
        return true;
      }
    }

    return false;
  }

  /// Transcodes a video file from HEVC to H.264 format
  static Future<XFile> _transcodeToH264(XFile videoFile) async {
    try {
      // Two approaches: Try native method channel first, fall back to VideoCompress

      // First approach: Use native iOS AVAssetExportSession through method channel
      // This is more reliable for explicit H.264 transcoding
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempDir = await getTemporaryDirectory();
        final outputPath = '${tempDir.path}/h264_$timestamp.mp4';

        final result = await _channel.invokeMethod<String>('transcodeToH264', {
          'inputPath': videoFile.path,
          'outputPath': outputPath,
          'quality': 'high', // high quality to minimize losses
        });

        if (result != null && File(result).existsSync()) {
          debugPrint('🎥 Successfully transcoded to H.264 using native API: $result');
          return XFile(result, mimeType: 'video/mp4');
        }

        // If we get here, native transcoding failed, fall through to backup method
        debugPrint('🎥 Native transcoding failed, trying backup method');
      } catch (e) {
        debugPrint('🎥 Error in native transcoding: $e, falling back to VideoCompress');
      }

      // Second approach (fallback): Use VideoCompress with specific settings
      // This is less reliable for codec change but better than nothing
      final result = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.HighestQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (result?.path != null) {
        debugPrint('🎥 Completed fallback transcoding (VideoCompress): ${result!.path}');
        return XFile(result.path!, mimeType: 'video/mp4');
      }

      debugPrint('🎥 All transcoding methods failed, returning original file');
      return videoFile;
    } catch (e) {
      debugPrint('🎥 Error during transcoding: $e');
      return videoFile; // Return original file if transcoding fails
    } finally {
      // Clean up VideoCompress resources
      try {
        await VideoCompress.cancelCompression();
      } catch (e) {
        debugPrint('🎥 Error canceling compression: $e');
      }
    }
  }
}
