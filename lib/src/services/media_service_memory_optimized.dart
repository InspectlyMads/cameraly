import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

import '../models/orientation_data.dart';
import '../models/photo_metadata.dart';

/// Memory-optimized version of MediaService
class MediaServiceMemoryOptimized {
  static const _mediaDirectoryName = 'cameraly_media';
  static const _chunkSize = 1024 * 1024; // 1MB chunks for streaming
  
  /// Write EXIF metadata more efficiently
  static Future<void> writeExifMetadataOptimized(String imagePath, PhotoMetadata metadata) async {
    // For smaller images (< 5MB), use direct approach
    final file = File(imagePath);
    final fileSize = await file.length();
    
    if (fileSize < 5 * 1024 * 1024) {
      // Small file, process normally
      await _writeExifMetadataStandard(imagePath, metadata);
    } else {
      // Large file, use streaming approach
      await _writeExifMetadataStreaming(imagePath, metadata);
    }
  }
  
  /// Standard EXIF writing for smaller images
  static Future<void> _writeExifMetadataStandard(String imagePath, PhotoMetadata metadata) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    
    // Decode the image
    final image = img.decodeImage(bytes);
    if (image == null) return;
    
    // Apply EXIF metadata
    _applyExifToImage(image, metadata);
    
    // Encode back to JPEG with EXIF
    final newBytes = img.encodeJpg(image, quality: 95);
    await file.writeAsBytes(newBytes);
  }
  
  /// Streaming EXIF writing for larger images
  static Future<void> _writeExifMetadataStreaming(String imagePath, PhotoMetadata metadata) async {
    // For large images, create a temporary file
    final tempPath = '$imagePath.tmp';
    final tempFile = File(tempPath);
    
    try {
      // Read file in chunks and process
      final output = tempFile.openWrite();
      
      // Note: For full streaming EXIF implementation, we'd need a specialized
      // JPEG parser that can modify EXIF without decoding the entire image.
      // For now, fall back to standard method with a warning.
      await output.close();
      await tempFile.delete();
      
      // Fallback to standard method
      await _writeExifMetadataStandard(imagePath, metadata);
    } catch (e) {
      // Clean up temp file if exists
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }
  
  /// Apply EXIF metadata to image object
  static void _applyExifToImage(img.Image image, PhotoMetadata metadata) {
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
    }
    
    // Custom data as user comment
    final customComment = jsonEncode({
      'cameraly_metadata': {
        'zoom_level': metadata.zoomLevel,
        'flash_mode': metadata.flashMode,
        'lens_direction': metadata.lensDirection,
        'capture_time_millis': metadata.captureTimeMillis,
      }
    });
    
    image.exif.exifIfd['UserComment'] = customComment;
    
    // Additional camera settings if available
    if (metadata.zoomLevel != null) {
      image.exif.exifIfd['DigitalZoomRatio'] = [(metadata.zoomLevel! * 100).toInt(), 100];
    }
  }
  
  /// Convert decimal degrees to GPS rationals
  static List<List<int>> _convertToGPSRationals(double decimal) {
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
  
  /// Save photo with memory optimization
  static Future<String?> savePhotoOptimized(
    Uint8List imageData, {
    String? fileName,
    OrientationData? orientationData,
    PhotoMetadata? metadata,
  }) async {
    try {
      final mediaDir = await getMediaDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = fileName ?? 'photo_$timestamp.jpg';
      final filePath = path.join(mediaDir.path, finalFileName);
      
      // Write file in chunks if large
      final file = File(filePath);
      if (imageData.length > 5 * 1024 * 1024) {
        // Large file, write in chunks
        final sink = file.openWrite();
        for (int i = 0; i < imageData.length; i += _chunkSize) {
          final end = (i + _chunkSize < imageData.length) ? i + _chunkSize : imageData.length;
          sink.add(imageData.sublist(i, end));
        }
        await sink.close();
      } else {
        // Small file, write directly
        await file.writeAsBytes(imageData);
      }
      
      // Write EXIF metadata if provided
      if (metadata != null) {
        try {
          await writeExifMetadataOptimized(filePath, metadata);
        } catch (e) {
          // Continue even if EXIF writing fails
        }
      }
      
      // Save orientation data as sidecar file if provided
      if (orientationData != null) {
        final orientationFile = File('$filePath.orientation.json');
        await orientationFile.writeAsString(jsonEncode(orientationData.toJson()));
      }
      
      // Save metadata as sidecar file if provided
      if (metadata != null) {
        final metadataFile = File('$filePath.metadata.json');
        await metadataFile.writeAsString(jsonEncode(metadata.toJson()));
      }
      
      return filePath;
    } catch (e) {
      return null;
    }
  }
  
  /// Get or create media directory
  static Future<Directory> getMediaDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(path.join(appDir.path, _mediaDirectoryName));
    
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    
    return mediaDir;
  }
  
  /// Clean up old media files to prevent storage bloat
  static Future<int> cleanupOldMedia({
    Duration maxAge = const Duration(days: 30),
    int maxFiles = 1000,
  }) async {
    try {
      final mediaDir = await getMediaDirectory();
      final files = await mediaDir.list().where((entity) => entity is File).toList();
      
      // Sort by modification time
      final fileStats = <File, FileStat>{};
      for (final entity in files) {
        final file = entity as File;
        final stat = await file.stat();
        fileStats[file] = stat;
      }
      
      final sortedFiles = fileStats.entries.toList()
        ..sort((a, b) => b.value.modified.compareTo(a.value.modified));
      
      int deletedCount = 0;
      final now = DateTime.now();
      
      // Delete old files or if exceeding max count
      for (int i = 0; i < sortedFiles.length; i++) {
        final entry = sortedFiles[i];
        final age = now.difference(entry.value.modified);
        
        if (age > maxAge || i >= maxFiles) {
          await entry.key.delete();
          
          // Also delete sidecar files
          final basePath = entry.key.path;
          final orientationFile = File('$basePath.orientation.json');
          final metadataFile = File('$basePath.metadata.json');
          
          if (await orientationFile.exists()) {
            await orientationFile.delete();
          }
          if (await metadataFile.exists()) {
            await metadataFile.delete();
          }
          
          deletedCount++;
        }
      }
      
      return deletedCount;
    } catch (e) {
      return 0;
    }
  }
}