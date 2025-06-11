import 'dart:async';
import 'dart:io';

import 'media_service_memory_optimized.dart';

/// Manages memory usage and cleanup for the camera package
class MemoryManager {
  static Timer? _cleanupTimer;
  static bool _isCleaningUp = false;
  
  /// Start periodic memory cleanup
  static void startPeriodicCleanup({
    Duration interval = const Duration(hours: 24),
    Duration maxMediaAge = const Duration(days: 7),
    int maxMediaFiles = 500,
  }) {
    stopPeriodicCleanup();
    
    _cleanupTimer = Timer.periodic(interval, (_) async {
      await performCleanup(
        maxMediaAge: maxMediaAge,
        maxMediaFiles: maxMediaFiles,
      );
    });
    
    // Also perform initial cleanup
    performCleanup(
      maxMediaAge: maxMediaAge,
      maxMediaFiles: maxMediaFiles,
    );
  }
  
  /// Stop periodic cleanup
  static void stopPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }
  
  /// Perform memory cleanup
  static Future<void> performCleanup({
    Duration maxMediaAge = const Duration(days: 7),
    int maxMediaFiles = 500,
  }) async {
    if (_isCleaningUp) return;
    
    _isCleaningUp = true;
    try {
      // Clean up old media files
      final deletedCount = await MediaServiceMemoryOptimized.cleanupOldMedia(
        maxAge: maxMediaAge,
        maxFiles: maxMediaFiles,
      );
      
      if (deletedCount > 0) {
        print('[MemoryManager] Cleaned up $deletedCount old media files');
      }
      
      // Force garbage collection hint
      // This is just a hint to the Dart VM, not guaranteed
      await Future.delayed(const Duration(milliseconds: 100));
      
    } catch (e) {
      print('[MemoryManager] Cleanup error: $e');
    } finally {
      _isCleaningUp = false;
    }
  }
  
  /// Get memory usage statistics
  static Future<MemoryStats> getMemoryStats() async {
    try {
      // Get process memory info
      final processInfo = ProcessInfo.currentRss;
      final rssInMB = processInfo / (1024 * 1024);
      
      // Get app documents directory size
      final appDocsSize = await _getDirectorySize();
      
      return MemoryStats(
        processMemoryMB: rssInMB,
        mediaCacheSizeMB: appDocsSize / (1024 * 1024),
      );
    } catch (e) {
      return const MemoryStats(
        processMemoryMB: 0,
        mediaCacheSizeMB: 0,
      );
    }
  }
  
  /// Calculate directory size
  static Future<int> _getDirectorySize() async {
    try {
      final dir = await MediaServiceMemoryOptimized.getMediaDirectory();
      int totalSize = 0;
      
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
  
  /// Clear all cached media (use with caution)
  static Future<void> clearAllMedia() async {
    try {
      final dir = await MediaServiceMemoryOptimized.getMediaDirectory();
      await for (final entity in dir.list()) {
        await entity.delete(recursive: true);
      }
    } catch (e) {
      print('[MemoryManager] Error clearing media: $e');
    }
  }
}

/// Memory usage statistics
class MemoryStats {
  final double processMemoryMB;
  final double mediaCacheSizeMB;
  
  const MemoryStats({
    required this.processMemoryMB,
    required this.mediaCacheSizeMB,
  });
  
  double get totalMemoryMB => processMemoryMB + mediaCacheSizeMB;
  
  @override
  String toString() => 'MemoryStats(process: ${processMemoryMB.toStringAsFixed(1)}MB, media: ${mediaCacheSizeMB.toStringAsFixed(1)}MB)';
}