import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service to handle storage-related operations and checks
class StorageService {
  static const int _minRequiredSpaceMB = 100; // Minimum 100MB required
  
  /// Check if there's enough storage space for recording
  static Future<bool> hasEnoughSpace({int requiredMB = _minRequiredSpaceMB}) async {
    try {
      // Get the temporary directory where camera files are saved
      final directory = await getTemporaryDirectory();
      
      // Platform-specific storage check
      if (Platform.isAndroid) {
        // Android: Use statfs to get available space
        final stat = await Process.run('df', [directory.path]);
        if (stat.exitCode == 0) {
          final output = stat.stdout.toString();
          final lines = output.split('\n');
          for (final line in lines) {
            if (line.contains(directory.path)) {
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length >= 4) {
                // Parse available space (usually in KB)
                final availableKB = int.tryParse(parts[3]) ?? 0;
                final availableMB = availableKB ~/ 1024;
                return availableMB >= requiredMB;
              }
            }
          }
        }
      }
      
      // Fallback: Check by attempting to create a test file
      final testFile = File('${directory.path}/storage_test.tmp');
      try {
        // Try to create a 1MB test file
        await testFile.writeAsBytes(List.filled(1024 * 1024, 0));
        await testFile.delete();
        return true;
      } catch (e) {
        return false;
      }
    } catch (e) {
      // If we can't check, assume there's space
      return true;
    }
  }
  
  /// Get available storage space in MB
  static Future<int> getAvailableSpaceMB() async {
    try {
      final directory = await getTemporaryDirectory();
      
      if (Platform.isAndroid || Platform.isIOS) {
        final stat = await Process.run('df', [directory.path]);
        if (stat.exitCode == 0) {
          final output = stat.stdout.toString();
          final lines = output.split('\n');
          for (final line in lines) {
            if (line.contains(directory.path) || line.contains('/data')) {
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length >= 4) {
                final availableKB = int.tryParse(parts[3]) ?? 0;
                return availableKB ~/ 1024;
              }
            }
          }
        }
      }
      
      return -1; // Unknown
    } catch (e) {
      return -1;
    }
  }
  
  /// Clean up old temporary files
  static Future<void> cleanupOldFiles({int daysOld = 7}) async {
    try {
      final directory = await getTemporaryDirectory();
      final now = DateTime.now();
      
      await for (final entity in directory.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified).inDays;
          
          if (age > daysOld && 
              (entity.path.endsWith('.jpg') || 
               entity.path.endsWith('.mp4') ||
               entity.path.endsWith('.tmp'))) {
            try {
              await entity.delete();
            } catch (e) {
              // Ignore deletion errors
            }
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}