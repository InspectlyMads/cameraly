import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:image/image.dart' as img;

import '../models/media_item.dart';
import '../models/orientation_data.dart';
import '../models/photo_metadata.dart';

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
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = fileName ?? 'photo_$timestamp.jpg';
      final filePath = path.join(mediaDir.path, finalFileName);

      // Write initial file
      final file = File(filePath);
      await file.writeAsBytes(imageData);

      // Write EXIF metadata if provided
      if (metadata != null) {
        try {
          await _writeExifMetadata(filePath, metadata);

        } catch (e) {

          // Continue even if EXIF writing fails
        }
      }



      return filePath;
    } catch (e) {

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

  /// Write EXIF metadata to image file
  Future<void> _writeExifMetadata(String imagePath, PhotoMetadata metadata) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    
    // Decode the image
    final image = img.decodeImage(bytes);
    if (image == null) {

      return;
    }
    
    // Ensure EXIF data exists
    image.exif = img.ExifData();
    
    // Set basic EXIF tags
    image.exif.imageIfd['Make'] = metadata.deviceManufacturer;
    image.exif.imageIfd['Model'] = metadata.deviceModel;
    image.exif.imageIfd['Software'] = 'Cameraly ${metadata.osVersion}';
    
    // Set date/time
    final dateTimeStr = metadata.capturedAt.toIso8601String().replaceAll('T', ' ').substring(0, 19);
    image.exif.imageIfd['DateTime'] = dateTimeStr;
    image.exif.exifIfd['DateTimeOriginal'] = dateTimeStr;
    image.exif.exifIfd['DateTimeDigitized'] = dateTimeStr;
    
    // Set GPS data if available
    if (metadata.latitude != null && metadata.longitude != null) {
      image.exif.gpsIfd['GPSLatitudeRef'] = metadata.latitude! >= 0 ? 'N' : 'S';
      image.exif.gpsIfd['GPSLatitude'] = _convertToGPSRationals(metadata.latitude!);
      image.exif.gpsIfd['GPSLongitudeRef'] = metadata.longitude! >= 0 ? 'E' : 'W';
      image.exif.gpsIfd['GPSLongitude'] = _convertToGPSRationals(metadata.longitude!);
      
      if (metadata.altitude != null) {
        image.exif.gpsIfd['GPSAltitudeRef'] = metadata.altitude! >= 0 ? 0 : 1;
        image.exif.gpsIfd['GPSAltitude'] = [metadata.altitude!.abs().toInt(), 1];
      }
      
      if (metadata.speed != null) {
        // Convert m/s to km/h
        final speedKmh = metadata.speed! * 3.6;
        image.exif.gpsIfd['GPSSpeed'] = [(speedKmh * 100).toInt(), 100];
        image.exif.gpsIfd['GPSSpeedRef'] = 'K'; // K for km/h
      }
      
      // Set GPS timestamp
      final gpsTimeStr = metadata.capturedAt.toIso8601String().split('T')[1].substring(0, 8);
      image.exif.gpsIfd['GPSTimeStamp'] = gpsTimeStr;
      image.exif.gpsIfd['GPSDateStamp'] = metadata.capturedAt.toIso8601String().split('T')[0];
    }
    
    // Custom data as user comment
    final customComment = jsonEncode({
      'cameraly_metadata': {
        'zoom_level': metadata.zoomLevel,
        'flash_mode': metadata.flashMode,
        'lens_direction': metadata.lensDirection,
        'device_tilt': {
          'x': metadata.deviceTiltX,
          'y': metadata.deviceTiltY,
          'z': metadata.deviceTiltZ,
        },
        'capture_time_millis': metadata.captureTimeMillis,
      }
    });
    
    image.exif.exifIfd['UserComment'] = customComment;
    
    // Additional camera settings if available
    if (metadata.zoomLevel != null) {
      image.exif.exifIfd['DigitalZoomRatio'] = [(metadata.zoomLevel! * 100).toInt(), 100];
    }
    
    // Encode back to JPEG with EXIF
    final newBytes = img.encodeJpg(image, quality: 95);
    await file.writeAsBytes(newBytes);
    

  }
  
  /// Convert decimal degrees to GPS rationals
  List<List<int>> _convertToGPSRationals(double decimal) {
    final absDecimal = decimal.abs();
    final degrees = absDecimal.floor();
    final minutes = ((absDecimal - degrees) * 60).floor();
    final seconds = ((absDecimal - degrees - minutes / 60) * 3600 * 100).round();
    
    return [
      [degrees, 1],
      [minutes, 1],
      [seconds, 100],
    ];
  }
}
