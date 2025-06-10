import 'dart:io';
import 'dart:convert';

import 'orientation_data.dart';

enum MediaType { photo, video }

class MediaItem {
  final String path;
  final MediaType type;
  final DateTime capturedAt;
  final String? orientationData;
  final OrientationData? orientationInfo;
  final String? thumbnailPath;
  final Duration? videoDuration;
  final int? fileSize;

  const MediaItem({
    required this.path,
    required this.type,
    required this.capturedAt,
    this.orientationData,
    this.orientationInfo,
    this.thumbnailPath,
    this.videoDuration,
    this.fileSize,
  });

  /// Create MediaItem from file
  static Future<MediaItem?> fromFile(File file) async {
    try {
      final stat = await file.stat();
      final path = file.path;
      final fileName = path.split('/').last.toLowerCase();

      MediaType type;
      if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png')) {
        type = MediaType.photo;
      } else if (fileName.endsWith('.mp4') || fileName.endsWith('.mov') || fileName.endsWith('.avi')) {
        type = MediaType.video;
      } else {
        return null; // Unsupported file type
      }

      // Try to load orientation data from sidecar file
      OrientationData? orientationInfo;
      final orientationFile = File('$path.orientation.json');
      if (await orientationFile.exists()) {
        try {
          final jsonStr = await orientationFile.readAsString();
          final jsonData = json.decode(jsonStr);
          orientationInfo = OrientationData.fromJson(jsonData);
        } catch (e) {
          // Failed to parse orientation data
        }
      }

      return MediaItem(
        path: path,
        type: type,
        capturedAt: stat.modified,
        fileSize: stat.size,
        orientationInfo: orientationInfo,
      );
    } catch (e) {
      return null; // Error reading file
    }
  }

  /// Get file name without extension
  String get fileName {
    final name = path.split('/').last;
    final lastDot = name.lastIndexOf('.');
    return lastDot > 0 ? name.substring(0, lastDot) : name;
  }

  /// Get file extension
  String get fileExtension {
    final name = path.split('/').last;
    final lastDot = name.lastIndexOf('.');
    return lastDot > 0 ? name.substring(lastDot + 1).toLowerCase() : '';
  }
  
  /// Check if this media item is a video
  bool get isVideo => type == MediaType.video;

  /// Get file size in human readable format
  String get fileSizeFormatted {
    if (fileSize == null) return 'Unknown';

    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = fileSize!.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Check if file exists
  Future<bool> exists() async {
    return await File(path).exists();
  }

  MediaItem copyWith({
    String? path,
    MediaType? type,
    DateTime? capturedAt,
    String? orientationData,
    OrientationData? orientationInfo,
    String? thumbnailPath,
    Duration? videoDuration,
    int? fileSize,
  }) {
    return MediaItem(
      path: path ?? this.path,
      type: type ?? this.type,
      capturedAt: capturedAt ?? this.capturedAt,
      orientationData: orientationData ?? this.orientationData,
      orientationInfo: orientationInfo ?? this.orientationInfo,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      videoDuration: videoDuration ?? this.videoDuration,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaItem &&
        other.path == path &&
        other.type == type &&
        other.capturedAt == capturedAt &&
        other.orientationData == orientationData &&
        other.orientationInfo == orientationInfo &&
        other.thumbnailPath == thumbnailPath &&
        other.videoDuration == videoDuration &&
        other.fileSize == fileSize;
  }

  @override
  int get hashCode {
    return Object.hash(
      path,
      type,
      capturedAt,
      orientationData,
      orientationInfo,
      thumbnailPath,
      videoDuration,
      fileSize,
    );
  }

  @override
  String toString() {
    return 'MediaItem(path: $path, type: $type, capturedAt: $capturedAt, size: $fileSizeFormatted)';
  }
}
