import 'dart:io';

import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

/// Utility class for handling video transcoding
/// Particularly for converting HEVC (H.265) videos to more compatible H.264 format
class VideoTranscoder {
  static const MethodChannel _channel = MethodChannel('com.cameraly/video_transcoder');
  static const MethodChannel _codecChannel = MethodChannel('com.cameraly/video_codec');

  /// Checks if a video file uses HEVC encoding and transcodes it to H.264 if necessary
  ///
  /// Returns the original file if it's already H.264 or if transcoding fails
  /// Returns a new XFile with the transcoded video if successful
  static Future<XFile> ensureH264Encoding(XFile videoFile) async {
    try {
      // Only process iOS videos - Android typically uses H.264 already
      if (!Platform.isIOS) return videoFile;

      // Check if the video uses HEVC encoding
      final isHevc = await _isHevcVideo(videoFile.path);

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

  /// Detects if a video uses HEVC encoding based on its media info and native API
  static Future<bool> _isHevcVideo(String path) async {
    // First try the native API for more accurate detection (iOS only)
    if (Platform.isIOS) {
      try {
        final isHevc = await _codecChannel.invokeMethod<bool>('isVideoHevc', {'path': path});
        if (isHevc != null) {
          debugPrint('🎥 Native API detected video codec: ${isHevc ? 'HEVC' : 'Not HEVC'}');
          return isHevc;
        }
      } catch (e) {
        debugPrint('🎥 Error using native API to detect codec: $e');
        // Fall through to alternative detection methods
      }
    }

    // Fallback to VideoCompress if native detection failed
    try {
      final mediaInfo = await VideoCompress.getMediaInfo(path);

      // Possible HEVC format identifiers
      const hevcIdentifiers = ['hevc', 'hvc1', 'hev1', 'h.265', 'h265', 'x265'];

      // Check title and metadata for HEVC indicators
      final format = (mediaInfo.title ?? '').toLowerCase();
      final videoPath = mediaInfo.path?.toLowerCase() ?? '';

      // Look for HEVC identifiers in format string or path
      for (final id in hevcIdentifiers) {
        if (format.contains(id) || videoPath.contains(id)) {
          debugPrint('🎥 Detected HEVC identifier: $id');
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
          debugPrint('🎥 Detected likely HEVC based on bitrate/resolution');
          return true;
        }
      }
    } catch (e) {
      debugPrint('🎥 Error using VideoCompress to detect codec: $e');
    }

    // For iOS, we more aggressively assume HEVC since most modern iOS devices record in HEVC
    // This is to ensure we don't miss any HEVC videos that our detection methods fail to identify
    if (Platform.isIOS) {
      final fileExtension = path.split('.').last.toLowerCase();
      // If it's a MOV file from iOS camera, it's more likely to be HEVC
      if (fileExtension == 'mov') {
        debugPrint('🎥 iOS MOV file, treating as potential HEVC');
        return true;
      }
    }

    return false;
  }

  /// Transcodes a video file from HEVC to H.264 format
  static Future<XFile> _transcodeToH264(XFile videoFile) async {
    try {
      // Always start with VideoCompress on iOS since plugin isn't working
      if (Platform.isIOS) {
        try {
          debugPrint('🎥 Using VideoCompress for iOS HEVC transcoding');
          final result = await VideoCompress.compressVideo(
            videoFile.path,
            quality: VideoQuality.MediumQuality,
            deleteOrigin: false,
            includeAudio: true,
            frameRate: 30,
          );

          if (result?.path != null) {
            final outputFile = File(result!.path!);
            if (await outputFile.exists()) {
              debugPrint('🎥 VideoCompress transcoding succeeded: ${result.path}');
              return XFile(result.path!, mimeType: 'video/mp4');
            }
          }
          debugPrint('🎥 VideoCompress failed, trying alternative methods');
        } catch (e) {
          debugPrint('🎥 Error in VideoCompress: $e');
        }
      }

      // Try direct native iOS method for transcoding
      if (Platform.isIOS) {
        try {
          final result = await _codecChannel.invokeMethod<String>('transcodeHevcToH264', {
            'path': videoFile.path,
          });

          if (result != null && File(result).existsSync()) {
            debugPrint('🎥 Successfully transcoded to H.264 using direct native API: $result');
            return XFile(result, mimeType: 'video/mp4');
          }
          // Fall through to next method if this fails
        } catch (e) {
          debugPrint('🎥 Error in direct native transcoding: $e, trying alternative method');
        }
      }

      // Second approach: Use AVAssetExportSession through method channel
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
          debugPrint('🎥 Successfully transcoded to H.264 using AVAssetExportSession API: $result');
          return XFile(result, mimeType: 'video/mp4');
        }

        // If we get here, native transcoding failed, fall through to backup method
        debugPrint('🎥 Native transcoding failed, trying backup method');
      } catch (e) {
        debugPrint('🎥 Error in AVAssetExportSession transcoding: $e, falling back to VideoCompress');
      }

      // Try FFmpeg transcoding as a last resort (iOS only)
      if (Platform.isIOS) {
        try {
          debugPrint('🎥 Attempting FFmpeg transcoding as last resort');
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final tempDir = await getTemporaryDirectory();
          final outputPath = '${tempDir.path}/ffmpeg_h264_$timestamp.mp4';

          // Command to transcode using FFmpeg with h264 codec
          // -i: input file
          // -c:v: video codec (libx264 = H.264)
          // -preset: encoding speed/quality tradeoff (medium = balanced)
          // -crf: quality (23 = good quality, lower = better)
          // -c:a: audio codec (aac = standard audio codec for MP4)
          // -strict: experimental flag (needed for some aac encoders)
          final command = '-i "${videoFile.path}" -c:v libx264 -preset medium -crf 23 -c:a aac -strict experimental "$outputPath"';

          debugPrint('🎥 Running FFmpeg command: $command');
          final session = await FFmpegKit.execute(command);
          final returnCode = await session.getReturnCode();

          if (ReturnCode.isSuccess(returnCode)) {
            final outputFile = File(outputPath);
            if (await outputFile.exists()) {
              debugPrint('🎥 FFmpeg transcoding succeeded: $outputPath');
              return XFile(outputPath, mimeType: 'video/mp4');
            }
          } else {
            final logs = await session.getLogs();
            debugPrint('🎥 FFmpeg failed with logs: ${logs.join('\n')}');
          }
        } catch (e) {
          debugPrint('🎥 Error in FFmpeg transcoding: $e');
        }
      }

      // Final fallback: Use VideoCompress again with different settings
      try {
        final result = await VideoCompress.compressVideo(
          videoFile.path,
          quality: VideoQuality.LowQuality, // Try with lower quality as a last resort
          deleteOrigin: false,
          includeAudio: true,
        );

        if (result?.path != null) {
          final outputFile = File(result!.path!);
          if (await outputFile.exists()) {
            debugPrint('🎥 Final VideoCompress fallback succeeded: ${result.path}');
            return XFile(result.path!, mimeType: 'video/mp4');
          }
        }
      } catch (e) {
        debugPrint('🎥 Error in final VideoCompress attempt: $e');
      }

      // Return original file if all transcoding attempts failed
      debugPrint('🎥 All transcoding attempts failed, returning original file');
      return videoFile;
    } catch (e) {
      debugPrint('🎥 Unexpected error in transcoding process: $e');
      return videoFile; // Return original file on error
    }
  }
}
