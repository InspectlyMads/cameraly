import 'package:flutter_test/flutter_test.dart';
import 'package:cameraly/cameraly.dart';

void main() {
  group('CameraSettings Tests', () {
    test('Default settings are initialized correctly', () {
      const settings = CameraSettings();
      
      expect(settings.photoQuality, PhotoQuality.high);
      expect(settings.videoQuality, VideoQuality.fullHd);
      expect(settings.photoTimerSeconds, isNull);
      expect(settings.enableSounds, isTrue);
      expect(settings.enableHaptics, isTrue);
      expect(settings.maxVideoSizeMB, isNull);
      expect(settings.autoSaveToGallery, isTrue);
    });
    
    test('copyWith creates new instance with updated values', () {
      const original = CameraSettings();
      final updated = original.copyWith(
        photoQuality: PhotoQuality.max,
        photoTimerSeconds: 5,
      );
      
      expect(updated.photoQuality, PhotoQuality.max);
      expect(updated.photoTimerSeconds, 5);
      // Other values should remain unchanged
      expect(updated.videoQuality, VideoQuality.fullHd);
      expect(updated.enableSounds, isTrue);
    });
  });
  
  group('MediaItem Tests', () {
    test('MediaItem creation with required fields', () {
      final now = DateTime.now();
      final item = MediaItem(
        path: '/path/to/photo.jpg',
        type: MediaType.photo,
        capturedAt: now,
      );
      
      expect(item.path, '/path/to/photo.jpg');
      expect(item.type, MediaType.photo);
      expect(item.capturedAt, now);
      expect(item.thumbnailPath, isNull);
      expect(item.metadata, isNull);
    });
    
    test('MediaItem identifies photo correctly', () {
      final photo = MediaItem(
        path: '/path/to/photo.jpg',
        type: MediaType.photo,
        capturedAt: DateTime.now(),
      );
      
      expect(photo.type, MediaType.photo);
    });
    
    test('MediaItem identifies video correctly', () {
      final video = MediaItem(
        path: '/path/to/video.mp4',
        type: MediaType.video,
        capturedAt: DateTime.now(),
      );
      
      expect(video.type, MediaType.video);
    });
  });
  
  group('CameraErrorInfo Tests', () {
    test('CameraErrorInfo has correct default values', () {
      const error = CameraErrorInfo(
        message: 'Test error message',
        type: CameraErrorType.unknown,
      );
      
      expect(error.message, 'Test error message');
      expect(error.type, CameraErrorType.unknown);
      expect(error.isRecoverable, isTrue);
      expect(error.userMessage, isNull);
      expect(error.retryDelay, isNull);
    });
    
    test('Permission denied error can be recoverable', () {
      const error = CameraErrorInfo(
        message: 'Camera permission denied',
        type: CameraErrorType.permissionDenied,
        isRecoverable: true,
      );
      
      expect(error.isRecoverable, isTrue);
      expect(error.type, CameraErrorType.permissionDenied);
    });
    
    test('Camera not found error is not recoverable', () {
      const error = CameraErrorInfo(
        message: 'No camera found',
        type: CameraErrorType.cameraNotFound,
        isRecoverable: false,
      );
      
      expect(error.isRecoverable, isFalse);
    });
  });
  
  group('PhotoMetadata Tests', () {
    test('PhotoMetadata JSON serialization', () {
      final metadata = PhotoMetadata(
        capturedAt: DateTime(2025, 1, 6, 12, 0, 0),
        captureTimeMillis: 100,
        deviceManufacturer: 'Apple',
        deviceModel: 'iPhone 15',
        osVersion: 'iOS 18.0',
        cameraName: 'Back Camera',
        lensDirection: 'back',
        latitude: 37.7749,
        longitude: -122.4194,
        altitude: 10.5,
        speed: 0.0,
        zoomLevel: 1.0,
        flashMode: 'off',
      );
      
      final json = metadata.toJson();
      expect(json['deviceModel'], 'iPhone 15');
      expect(json['latitude'], 37.7749);
      expect(json['zoomLevel'], 1.0);
      
      final restored = PhotoMetadata.fromJson(json);
      expect(restored.deviceModel, metadata.deviceModel);
      expect(restored.latitude, metadata.latitude);
      expect(restored.capturedAt, metadata.capturedAt);
    });
  });
}