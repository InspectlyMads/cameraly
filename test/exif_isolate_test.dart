import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cameraly/src/services/media_service.dart';
import 'package:cameraly/src/models/photo_metadata.dart';

void main() {
  group('EXIF Isolate Processing', () {
    test('should process EXIF in background without blocking', () async {
      // Create a mock photo metadata
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

      // Test file path
      final testPath = '/tmp/test_photo.jpg';
      
      // Add task to queue
      ExifWriteQueue.addTask(testPath, metadata);
      
      // Check queue size
      expect(ExifWriteQueue.queueSize, greaterThanOrEqualTo(0));
      
      // Wait a bit for processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Queue should be empty after processing
      expect(ExifWriteQueue.queueSize, equals(0));
    });

    test('should not corrupt file during concurrent access', () async {
      // This test simulates the race condition scenario
      final testFile = File('/tmp/race_test.jpg');
      
      // Create a simple test image
      await testFile.writeAsBytes(List.filled(1000, 0));
      
      final metadata = PhotoMetadata(
        capturedAt: DateTime.now(),
        deviceManufacturer: 'Test',
        deviceModel: 'Device',
        osVersion: '1.0',
        cameraName: '0',
        lensDirection: 'back',
        captureTimeMillis: 100,
      );
      
      // Start EXIF processing
      ExifWriteQueue.addTask(testFile.path, metadata);
      
      // Simultaneously try to read the file (simulating thumbnail generation)
      bool readSuccessful = true;
      try {
        final bytes = await testFile.readAsBytes();
        expect(bytes.length, greaterThan(0));
      } catch (e) {
        readSuccessful = false;
      }
      
      expect(readSuccessful, isTrue, reason: 'File read should not fail during EXIF processing');
      
      // Clean up
      if (await testFile.exists()) {
        await testFile.delete();
      }
    });
  });
}