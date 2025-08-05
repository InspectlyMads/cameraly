import 'dart:io';
import 'dart:collection';
import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:native_exif/native_exif.dart';

import '../models/media_item.dart';
import '../models/orientation_data.dart';
import '../models/photo_metadata.dart';

/// Task for queued EXIF writing
class ExifWriteTask {
  final String filePath;
  final PhotoMetadata metadata;
  final DateTime queuedAt;
  
  ExifWriteTask({
    required this.filePath,
    required this.metadata,
  }) : queuedAt = DateTime.now();
}

/// Background EXIF write queue that processes metadata writes in an isolate
class ExifWriteQueue {
  static final Queue<ExifWriteTask> _queue = Queue<ExifWriteTask>();
  static bool _isProcessing = false;
  
  /// Add a task to the queue
  static void addTask(String filePath, PhotoMetadata metadata) {
    _queue.add(ExifWriteTask(
      filePath: filePath,
      metadata: metadata,
    ));
    
    debugPrint('📝 Added EXIF task to queue. Queue size: ${_queue.length}');
    
    // Start processing if not already running
    if (!_isProcessing) {
      _startProcessing();
    }
  }
  
  /// Start processing the queue
  static void _startProcessing() async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    debugPrint('🚀 Starting EXIF processing...');
    
    // Process tasks one by one
    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst();
      await _processTask(task);
    }
    
    _isProcessing = false;
    debugPrint('✅ EXIF processing complete');
  }
  
  /// Process a single task in an isolate
  static Future<void> _processTask(ExifWriteTask task) async {
    try {
      // Check if file still exists
      final file = File(task.filePath);
      if (!await file.exists()) {
        debugPrint('⚠️ File no longer exists: ${task.filePath}');
        return;
      }
      
      // Get root isolate token for platform channel access
      final RootIsolateToken? rootIsolateToken = RootIsolateToken.instance;
      if (rootIsolateToken == null) {
        debugPrint('⚠️ No root isolate token, falling back to main thread EXIF processing');
        await _processTaskOnMainThread(task);
        return;
      }
      
      // Process in isolate with proper initialization
      try {
        await Isolate.run(() async {
          // Initialize BackgroundIsolateBinaryMessenger for platform channels
          BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
          
          final tempPath = '${task.filePath}.exif_tmp';
          
          try {
            // Copy original to temp file
            await File(task.filePath).copy(tempPath);
            debugPrint('📄 Created temp file for EXIF processing: $tempPath');
            
            // Write EXIF metadata to temp file
            await _writeExifMetadataInIsolate(tempPath, task.metadata);
            
            // Atomically replace original with EXIF-enhanced version
            final tempFile = File(tempPath);
            if (await tempFile.exists()) {
              await tempFile.rename(task.filePath);
              debugPrint('✅ EXIF metadata written successfully to ${task.filePath}');
            }
          } catch (e) {
            debugPrint('❌ EXIF processing failed in isolate: $e');
            // Clean up temp file if it exists
            try {
              final tempFile = File(tempPath);
              if (await tempFile.exists()) {
                await tempFile.delete();
              }
            } catch (_) {}
            rethrow;
          }
        });
      } catch (e) {
        debugPrint('❌ Isolate execution failed: $e');
        debugPrint('⚠️ Falling back to main thread EXIF processing');
        // Fallback to main thread if isolate fails
        await _processTaskOnMainThread(task);
      }
    } catch (e) {
      debugPrint('❌ Background EXIF write failed: $e');
      // Don't re-queue failed tasks to avoid infinite loops
    }
  }
  
  
  /// Process task on main thread (fallback)
  static Future<void> _processTaskOnMainThread(ExifWriteTask task) async {
    final tempPath = '${task.filePath}.exif_tmp';
    
    try {
      // Copy original to temp file
      await File(task.filePath).copy(tempPath);
      debugPrint('📄 Created temp file for EXIF processing: $tempPath');
      
      // Write EXIF metadata to temp file
      await MediaService._writeExifMetadataStatic(tempPath, task.metadata);
      
      // Atomically replace original with EXIF-enhanced version
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.rename(task.filePath);
        debugPrint('✅ EXIF metadata written successfully to ${task.filePath}');
      }
    } catch (e) {
      debugPrint('❌ EXIF processing failed: $e');
      // Clean up temp file if it exists
      try {
        final tempFile = File(tempPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
      rethrow;
    }
  }
  
  /// Write EXIF metadata in isolate (static for isolate access)
  static Future<void> _writeExifMetadataInIsolate(String imagePath, PhotoMetadata metadata) async {
    debugPrint('📍 Writing EXIF metadata to $imagePath in isolate');
    debugPrint('📍 GPS data: lat=${metadata.latitude}, lon=${metadata.longitude}');
    
    try {
      // Use native_exif for writing GPS data
      final exif = await Exif.fromPath(imagePath);
      
      // Set basic metadata
      await exif.writeAttributes({
        'Make': metadata.deviceManufacturer,
        'Model': metadata.deviceModel,
        'Software': 'Cameraly ${metadata.osVersion}',
        'DateTime': metadata.capturedAt.toIso8601String().replaceAll('T', ' ').substring(0, 19),
      });
      
      // Set GPS data if available
      if (metadata.latitude != null && metadata.longitude != null) {
        debugPrint('📍 Writing GPS coordinates using native_exif');
        
        // Write GPS coordinates
        await exif.writeAttributes({
          'GPSLatitude': metadata.latitude!.abs().toString(),
          'GPSLatitudeRef': metadata.latitude! >= 0 ? 'N' : 'S',
          'GPSLongitude': metadata.longitude!.abs().toString(),
          'GPSLongitudeRef': metadata.longitude! >= 0 ? 'E' : 'W',
        });
        
        if (metadata.altitude != null) {
          await exif.writeAttribute('GPSAltitude', metadata.altitude!.abs().toString());
          await exif.writeAttribute('GPSAltitudeRef', metadata.altitude! >= 0 ? '0' : '1');
        }
        
        debugPrint('✅ GPS data written with native_exif');
      }
      
      await exif.close();
      debugPrint('✅ EXIF metadata written successfully in isolate');
      
    } catch (e) {
      debugPrint('❌ Error writing EXIF in isolate: $e');
      rethrow;
    }
  }
  
  /// Get queue size for debugging
  static int get queueSize => _queue.length;
  
  /// Clear the queue (useful for cleanup)
  static void clear() {
    _queue.clear();
    _isProcessing = false;
  }
}

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
  // Custom save path can be set by the app
  static String? _customSavePath;
  
  /// Set a custom save path for media files
  static void setCustomSavePath(String? path) {
    _customSavePath = path;
  }

  /// Get the directory where captured media is stored
  Future<Directory> getMediaDirectory() async {
    Directory mediaDir;
    
    if (_customSavePath != null) {
      // Use custom path if provided
      mediaDir = Directory(_customSavePath!);
    } else {
      // Default to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      mediaDir = Directory(path.join(appDir.path, 'captured_media'));
    }

    // Create directory if it doesn't exist
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    return mediaDir;
  }

  /// Discover all captured media files
  Future<List<MediaItem>> discoverMediaFiles() async {
    try {


      final mediaDir = await getMediaDirectory();
      final List<MediaItem> mediaItems = [];

      // List all files in the media directory
      await for (final entity in mediaDir.list()) {
        if (entity is File) {
          final mediaItem = await MediaItem.fromFile(entity);
          if (mediaItem != null) {
            mediaItems.add(mediaItem);

          }
        }
      }

      // Sort by capture date (newest first)
      mediaItems.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));


      return mediaItems;
    } catch (e) {

      return [];
    }
  }

  /// Save captured photo to media directory with EXIF metadata
  Future<String?> savePhoto(Uint8List imageData, {String? fileName, OrientationData? orientationData, PhotoMetadata? metadata}) async {
    try {
      final mediaDir = await getMediaDirectory();
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final finalFileName = fileName ?? 'capture_$timestamp.jpg';
      final filePath = path.join(mediaDir.path, finalFileName);

      // Write initial file
      final file = File(filePath);
      await file.writeAsBytes(imageData);

      // Queue EXIF metadata writing for background processing
      if (metadata != null) {
        debugPrint('📍 Queuing EXIF metadata for background writing...');
        ExifWriteQueue.addTask(filePath, metadata);
      } else {
        debugPrint('⚠️ No metadata provided to savePhoto');
      }



      return filePath;
    } catch (e) {

      return null;
    }
  }
  
  /// Save captured photo file directly (optimized version)
  Future<String?> savePhotoFile(String sourcePath, {String? fileName, OrientationData? orientationData, PhotoMetadata? metadata}) async {
    try {
      final mediaDir = await getMediaDirectory();
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final finalFileName = fileName ?? 'capture_$timestamp.jpg';
      final targetPath = path.join(mediaDir.path, finalFileName);

      // Copy file directly (much faster than readAsBytes)
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        debugPrint('❌ Source file does not exist: $sourcePath');
        return null;
      }
      
      await sourceFile.copy(targetPath);
      
      // Verify the file was actually copied
      final targetFile = File(targetPath);
      if (!await targetFile.exists()) {
        debugPrint('❌ Failed to copy file to: $targetPath');
        return null;
      }
      
      debugPrint('📷 Photo saved to: $targetPath');

      // Queue EXIF metadata writing for background processing
      if (metadata != null) {
        debugPrint('📍 Queuing EXIF metadata for background writing...');
        ExifWriteQueue.addTask(targetPath, metadata);
      } else {
        debugPrint('⚠️ No metadata provided to savePhotoFile');
      }

      return targetPath;
    } catch (e) {
      debugPrint('❌ Error saving photo file: $e');
      return null;
    }
  }

  /// Move captured video to media directory
  Future<String?> saveVideo(String sourcePath, {String? fileName}) async {
    try {
      final mediaDir = await getMediaDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = fileName ?? 'recording_$timestamp.mp4';
      final targetPath = path.join(mediaDir.path, finalFileName);

      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(targetPath);
        // Optionally delete the source file
        // await sourceFile.delete();


        return targetPath;
      }

      return null;
    } catch (e) {

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


        return true;
      }
      return false;
    } catch (e) {

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


    return deletedCount;
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

      return null;
    }
  }

  /// Get media file metadata
  Future<MediaItem> getMediaMetadata(MediaItem mediaItem) async {
    try {
      Duration? videoDuration;

      if (mediaItem.type == MediaType.video) {
        videoDuration = await getVideoDuration(mediaItem);
      }

      return mediaItem.copyWith(
        videoDuration: videoDuration,
      );
    } catch (e) {

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

    } catch (e) {
      // Ignore errors during cleanup
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

  /// Write EXIF metadata to image file (keeping for potential non-isolate use)
  static Future<void> _writeExifMetadataStatic(String imagePath, PhotoMetadata metadata) async {
    debugPrint('📍 Writing EXIF metadata to $imagePath');
    debugPrint('📍 GPS data: lat=${metadata.latitude}, lon=${metadata.longitude}');
    
    try {
      // Use native_exif for writing GPS data
      final exif = await Exif.fromPath(imagePath);
      
      // Set basic metadata
      await exif.writeAttributes({
        'Make': metadata.deviceManufacturer,
        'Model': metadata.deviceModel,
        'Software': 'Cameraly ${metadata.osVersion}',
        'DateTime': metadata.capturedAt.toIso8601String().replaceAll('T', ' ').substring(0, 19),
      });
      
      // Set GPS data if available
      if (metadata.latitude != null && metadata.longitude != null) {
        debugPrint('📍 Writing GPS coordinates using native_exif');
        
        // Write GPS coordinates
        await exif.writeAttributes({
          'GPSLatitude': metadata.latitude!.abs().toString(),
          'GPSLatitudeRef': metadata.latitude! >= 0 ? 'N' : 'S',
          'GPSLongitude': metadata.longitude!.abs().toString(),
          'GPSLongitudeRef': metadata.longitude! >= 0 ? 'E' : 'W',
        });
        
        if (metadata.altitude != null) {
          await exif.writeAttribute('GPSAltitude', metadata.altitude!.abs().toString());
          await exif.writeAttribute('GPSAltitudeRef', metadata.altitude! >= 0 ? '0' : '1');
        }
        
        debugPrint('✅ GPS data written with native_exif');
        
        // Verify by reading back
        final attributes = await exif.getAttributes();
        debugPrint('📋 Verified GPS data: lat=${attributes?['GPSLatitude']}, lon=${attributes?['GPSLongitude']}');
      }
      
      await exif.close();
      debugPrint('✅ EXIF metadata written successfully');
      
    } catch (e) {
      debugPrint('❌ Error writing EXIF with native_exif: $e');
      debugPrint('⚠️ Skipping EXIF metadata to preserve image quality');
      // Skip EXIF writing to preserve original image quality
    }
  }
  
}
