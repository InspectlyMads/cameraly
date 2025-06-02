import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../models/media_item.dart';

class GalleryState {
  final List<MediaItem> mediaItems;
  final bool isLoading;
  final String? errorMessage;
  final MediaItem? selectedItem;

  const GalleryState({
    this.mediaItems = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedItem,
  });

  GalleryState copyWith({
    List<MediaItem>? mediaItems,
    bool? isLoading,
    String? errorMessage,
    MediaItem? selectedItem,
  }) {
    return GalleryState(
      mediaItems: mediaItems ?? this.mediaItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedItem: selectedItem ?? this.selectedItem,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GalleryState && listEquals(other.mediaItems, mediaItems) && other.isLoading == isLoading && other.errorMessage == errorMessage && other.selectedItem == selectedItem;
  }

  @override
  int get hashCode {
    return Object.hash(
      mediaItems,
      isLoading,
      errorMessage,
      selectedItem,
    );
  }
}

class MediaService {
  static const String _logTag = 'MediaService';

  /// Get the directory where captured media is stored
  Future<Directory> getMediaDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(path.join(appDir.path, 'captured_media'));

    // Create directory if it doesn't exist
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    return mediaDir;
  }

  /// Discover all captured media files
  Future<List<MediaItem>> discoverMediaFiles() async {
    try {
      debugPrint('$_logTag: Starting media discovery');

      final mediaDir = await getMediaDirectory();
      final List<MediaItem> mediaItems = [];

      // List all files in the media directory
      await for (final entity in mediaDir.list()) {
        if (entity is File) {
          final mediaItem = await MediaItem.fromFile(entity);
          if (mediaItem != null) {
            mediaItems.add(mediaItem);
            debugPrint('$_logTag: Found media: ${mediaItem.fileName}');
          }
        }
      }

      // Sort by capture date (newest first)
      mediaItems.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

      debugPrint('$_logTag: Discovered ${mediaItems.length} media files');
      return mediaItems;
    } catch (e) {
      debugPrint('$_logTag: Error discovering media files: $e');
      return [];
    }
  }

  /// Save captured photo to media directory
  Future<String?> savePhoto(Uint8List imageData, {String? fileName}) async {
    try {
      final mediaDir = await getMediaDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = fileName ?? 'photo_$timestamp.jpg';
      final filePath = path.join(mediaDir.path, finalFileName);

      final file = File(filePath);
      await file.writeAsBytes(imageData);

      debugPrint('$_logTag: Saved photo to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('$_logTag: Error saving photo: $e');
      return null;
    }
  }

  /// Move captured video to media directory
  Future<String?> saveVideo(String sourcePath, {String? fileName}) async {
    try {
      final mediaDir = await getMediaDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = fileName ?? 'video_$timestamp.mp4';
      final targetPath = path.join(mediaDir.path, finalFileName);

      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(targetPath);
        // Optionally delete the source file
        // await sourceFile.delete();

        debugPrint('$_logTag: Saved video to: $targetPath');
        return targetPath;
      }

      return null;
    } catch (e) {
      debugPrint('$_logTag: Error saving video: $e');
      return null;
    }
  }

  /// Delete a media file
  Future<bool> deleteMediaFile(MediaItem mediaItem) async {
    try {
      final file = File(mediaItem.path);
      if (await file.exists()) {
        await file.delete();

        // Also delete thumbnail if it exists
        if (mediaItem.thumbnailPath != null) {
          final thumbnailFile = File(mediaItem.thumbnailPath!);
          if (await thumbnailFile.exists()) {
            await thumbnailFile.delete();
          }
        }

        debugPrint('$_logTag: Deleted media file: ${mediaItem.path}');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('$_logTag: Error deleting media file: $e');
      return false;
    }
  }

  /// Delete multiple media files
  Future<int> deleteMediaFiles(List<MediaItem> mediaItems) async {
    int deletedCount = 0;

    for (final mediaItem in mediaItems) {
      if (await deleteMediaFile(mediaItem)) {
        deletedCount++;
      }
    }

    debugPrint('$_logTag: Deleted $deletedCount out of ${mediaItems.length} media files');
    return deletedCount;
  }

  /// Generate video thumbnail
  Future<String?> generateVideoThumbnail(MediaItem videoItem) async {
    if (videoItem.type != MediaType.video) return null;

    try {
      final controller = VideoPlayerController.file(File(videoItem.path));
      await controller.initialize();

      // Get thumbnail directory
      final mediaDir = await getMediaDirectory();
      final thumbnailDir = Directory(path.join(mediaDir.path, 'thumbnails'));
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      // Generate thumbnail path
      final thumbnailFileName = '${videoItem.fileName}_thumb.jpg';
      final thumbnailPath = path.join(thumbnailDir.path, thumbnailFileName);

      // For now, we'll return null since thumbnail generation is complex
      // In a production app, you'd use a plugin like flutter_ffmpeg
      await controller.dispose();

      debugPrint('$_logTag: Video thumbnail generation not implemented yet');
      return null;
    } catch (e) {
      debugPrint('$_logTag: Error generating video thumbnail: $e');
      return null;
    }
  }

  /// Get video duration
  Future<Duration?> getVideoDuration(MediaItem videoItem) async {
    if (videoItem.type != MediaType.video) return null;

    try {
      final controller = VideoPlayerController.file(File(videoItem.path));
      await controller.initialize();

      final duration = controller.value.duration;
      await controller.dispose();

      return duration;
    } catch (e) {
      debugPrint('$_logTag: Error getting video duration: $e');
      return null;
    }
  }

  /// Get media file metadata
  Future<MediaItem> getMediaMetadata(MediaItem mediaItem) async {
    try {
      Duration? videoDuration;
      String? thumbnailPath;

      if (mediaItem.type == MediaType.video) {
        videoDuration = await getVideoDuration(mediaItem);
        thumbnailPath = await generateVideoThumbnail(mediaItem);
      }

      return mediaItem.copyWith(
        videoDuration: videoDuration,
        thumbnailPath: thumbnailPath,
      );
    } catch (e) {
      debugPrint('$_logTag: Error getting metadata for ${mediaItem.path}: $e');
      return mediaItem;
    }
  }

  /// Clear all media files (for testing)
  Future<void> clearAllMedia() async {
    try {
      final mediaDir = await getMediaDirectory();
      if (await mediaDir.exists()) {
        await for (final entity in mediaDir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
      debugPrint('$_logTag: Cleared all media files');
    } catch (e) {
      debugPrint('$_logTag: Error clearing media files: $e');
    }
  }

  /// Get total storage used by media files
  Future<int> getTotalStorageUsed() async {
    try {
      final mediaItems = await discoverMediaFiles();
      int totalSize = 0;

      for (final item in mediaItems) {
        if (item.fileSize != null) {
          totalSize += item.fileSize!;
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('$_logTag: Error calculating storage usage: $e');
      return 0;
    }
  }

  /// Format storage size for display
  String formatStorageSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }
}
