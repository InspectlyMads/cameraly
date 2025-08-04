import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cameraly/src/services/media_service.dart';
import 'package:cameraly/src/models/photo_metadata.dart';

void main() {
  group('EXIF Isolate with Proper Initialization', () {
    test('should process EXIF in isolate with platform channels', () async {
      // Create a test image file
      final testFile = File('/tmp/test_isolate_exif.jpg');
      
      // Write a minimal JPEG header
      await testFile.writeAsBytes([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46,
        0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01,
        0x00, 0x01, 0x00, 0x00, 0xFF, 0xD9
      ]);
      
      final metadata = PhotoMetadata(
        latitude: 37.7749,
        longitude: -122.4194,
        altitude: 10.0,
        capturedAt: DateTime.now(),
        deviceManufacturer: 'Apple',
        deviceModel: 'iPhone 15',
        osVersion: 'iOS 17.0',
        cameraName: '0',
        zoomLevel: 1.0,
        flashMode: 'off',
        lensDirection: 'back',
        captureTimeMillis: 100,
      );
      
      // Clear any existing queue
      ExifWriteQueue.clear();
      
      // Add task to queue
      ExifWriteQueue.addTask(testFile.path, metadata);
      
      // Wait for processing
      await Future.delayed(const Duration(seconds: 3));
      
      // Queue should be empty after processing
      expect(ExifWriteQueue.queueSize, equals(0));
      
      // File should still exist
      expect(await testFile.exists(), isTrue);
      
      // Clean up
      if (await testFile.exists()) {
        await testFile.delete();
      }
    });
  });
}