import 'package:flutter_test/flutter_test.dart';
import 'package:cameraly/src/models/orientation_data.dart';

void main() {
  group('OrientationData Tests', () {
    test('OrientationData constructor initializes correctly', () {
      final timestamp = DateTime.now();
      final metadata = {'key': 'value'};
      
      final orientationData = OrientationData(
        deviceOrientation: 90,
        cameraRotation: 180,
        sensorOrientation: 270,
        deviceManufacturer: 'Apple',
        deviceModel: 'iPhone 15',
        timestamp: timestamp,
        accuracyScore: 0.95,
        metadata: metadata,
      );
      
      expect(orientationData.deviceOrientation, 90);
      expect(orientationData.cameraRotation, 180);
      expect(orientationData.sensorOrientation, 270);
      expect(orientationData.deviceManufacturer, 'Apple');
      expect(orientationData.deviceModel, 'iPhone 15');
      expect(orientationData.timestamp, timestamp);
      expect(orientationData.accuracyScore, 0.95);
      expect(orientationData.metadata, metadata);
    });
    
    test('OrientationData uses default values', () {
      final timestamp = DateTime.now();
      
      final orientationData = OrientationData(
        deviceOrientation: 0,
        cameraRotation: 0,
        sensorOrientation: 0,
        deviceManufacturer: 'Test',
        deviceModel: 'Model',
        timestamp: timestamp,
      );
      
      expect(orientationData.accuracyScore, 0.0);
      expect(orientationData.metadata, isEmpty);
    });
    
    test('OrientationData copyWith works correctly', () {
      final timestamp = DateTime.now();
      final newTimestamp = DateTime.now().add(const Duration(hours: 1));
      
      final original = OrientationData(
        deviceOrientation: 90,
        cameraRotation: 180,
        sensorOrientation: 270,
        deviceManufacturer: 'Apple',
        deviceModel: 'iPhone 15',
        timestamp: timestamp,
      );
      
      final copied = original.copyWith(
        deviceOrientation: 0,
        timestamp: newTimestamp,
        accuracyScore: 0.8,
      );
      
      expect(copied.deviceOrientation, 0);
      expect(copied.cameraRotation, 180);
      expect(copied.sensorOrientation, 270);
      expect(copied.deviceManufacturer, 'Apple');
      expect(copied.deviceModel, 'iPhone 15');
      expect(copied.timestamp, newTimestamp);
      expect(copied.accuracyScore, 0.8);
    });
    
    test('OrientationData equality works correctly', () {
      final timestamp = DateTime.now();
      
      final data1 = OrientationData(
        deviceOrientation: 90,
        cameraRotation: 180,
        sensorOrientation: 270,
        deviceManufacturer: 'Apple',
        deviceModel: 'iPhone 15',
        timestamp: timestamp,
        accuracyScore: 0.95,
      );
      
      final data2 = OrientationData(
        deviceOrientation: 90,
        cameraRotation: 180,
        sensorOrientation: 270,
        deviceManufacturer: 'Apple',
        deviceModel: 'iPhone 15',
        timestamp: timestamp,
        accuracyScore: 0.95,
      );
      
      final data3 = OrientationData(
        deviceOrientation: 0,
        cameraRotation: 180,
        sensorOrientation: 270,
        deviceManufacturer: 'Apple',
        deviceModel: 'iPhone 15',
        timestamp: timestamp,
        accuracyScore: 0.95,
      );
      
      expect(data1, equals(data2));
      expect(data1, isNot(equals(data3)));
      expect(data1.hashCode, equals(data2.hashCode));
    });
    
    test('OrientationData toString formats correctly', () {
      final timestamp = DateTime.now();
      
      final orientationData = OrientationData(
        deviceOrientation: 90,
        cameraRotation: 180,
        sensorOrientation: 270,
        deviceManufacturer: 'Apple',
        deviceModel: 'iPhone 15',
        timestamp: timestamp,
        accuracyScore: 0.95,
      );
      
      final string = orientationData.toString();
      
      expect(string, contains('deviceOrientation: 90'));
      expect(string, contains('cameraRotation: 180'));
      expect(string, contains('sensorOrientation: 270'));
      expect(string, contains('device: Apple iPhone 15'));
      expect(string, contains('accuracy: 95.0%'));
    });
  });
  
  group('DeviceInfo Tests', () {
    test('DeviceInfo constructor initializes correctly', () {
      final metadata = {'key': 'value'};
      
      final deviceInfo = DeviceInfo(
        manufacturer: 'Apple',
        model: 'iPhone 15',
        androidVersion: null,
        sdkVersion: '18.0',
        osVersion: 'iOS 18.0',
        metadata: metadata,
      );
      
      expect(deviceInfo.manufacturer, 'Apple');
      expect(deviceInfo.model, 'iPhone 15');
      expect(deviceInfo.androidVersion, isNull);
      expect(deviceInfo.sdkVersion, '18.0');
      expect(deviceInfo.osVersion, 'iOS 18.0');
      expect(deviceInfo.metadata, metadata);
    });
    
    test('DeviceInfo toString formats correctly', () {
      final deviceInfo1 = const DeviceInfo(
        manufacturer: 'Apple',
        model: 'iPhone 15',
        osVersion: 'iOS 18.0',
      );
      
      final deviceInfo2 = const DeviceInfo(
        manufacturer: 'Samsung',
        model: 'Galaxy S24',
      );
      
      expect(deviceInfo1.toString(), 'Apple iPhone 15 (iOS 18.0)');
      expect(deviceInfo2.toString(), 'Samsung Galaxy S24');
    });
  });
  
  group('OrientationCorrection Tests', () {
    test('OrientationCorrection constructor with defaults', () {
      const correction = OrientationCorrection();
      
      expect(correction.rotationOffset, 0);
      expect(correction.requiresTransformMatrix, isFalse);
      expect(correction.transformMatrix, isEmpty);
      expect(correction.flipHorizontal, isFalse);
      expect(correction.flipVertical, isFalse);
    });
    
    test('OrientationCorrection constructor with values', () {
      const correction = OrientationCorrection(
        rotationOffset: 90,
        requiresTransformMatrix: true,
        transformMatrix: {'a': 1, 'b': 0},
        flipHorizontal: true,
        flipVertical: false,
      );
      
      expect(correction.rotationOffset, 90);
      expect(correction.requiresTransformMatrix, isTrue);
      expect(correction.transformMatrix, {'a': 1, 'b': 0});
      expect(correction.flipHorizontal, isTrue);
      expect(correction.flipVertical, isFalse);
    });
    
    test('OrientationCorrection.standard creates default correction', () {
      final correction = OrientationCorrection.standard();
      
      expect(correction.rotationOffset, 0);
      expect(correction.requiresTransformMatrix, isFalse);
      expect(correction.transformMatrix, isEmpty);
      expect(correction.flipHorizontal, isFalse);
      expect(correction.flipVertical, isFalse);
    });
    
    test('OrientationCorrection.forDevice returns correct corrections', () {
      // Samsung
      final samsungDevice = const DeviceInfo(
        manufacturer: 'Samsung',
        model: 'Galaxy S24',
      );
      final samsungCorrection = OrientationCorrection.forDevice(samsungDevice);
      
      expect(samsungCorrection.rotationOffset, 90);
      expect(samsungCorrection.requiresTransformMatrix, isTrue);
      
      // Xiaomi
      final xiaomiDevice = const DeviceInfo(
        manufacturer: 'Xiaomi',
        model: 'Mi 11',
      );
      final xiaomiCorrection = OrientationCorrection.forDevice(xiaomiDevice);
      
      expect(xiaomiCorrection.rotationOffset, 270);
      expect(xiaomiCorrection.requiresTransformMatrix, isTrue);
      
      // Huawei
      final huaweiDevice = const DeviceInfo(
        manufacturer: 'Huawei',
        model: 'P50 Pro',
      );
      final huaweiCorrection = OrientationCorrection.forDevice(huaweiDevice);
      
      expect(huaweiCorrection.rotationOffset, 180);
      expect(huaweiCorrection.flipHorizontal, isTrue);
      
      // Unknown manufacturer
      final unknownDevice = const DeviceInfo(
        manufacturer: 'Unknown',
        model: 'Model X',
      );
      final unknownCorrection = OrientationCorrection.forDevice(unknownDevice);
      
      expect(unknownCorrection.rotationOffset, 0);
      expect(unknownCorrection.requiresTransformMatrix, isFalse);
      expect(unknownCorrection.flipHorizontal, isFalse);
    });
    
    test('OrientationCorrection.forDevice is case-insensitive', () {
      final uppercaseDevice = const DeviceInfo(
        manufacturer: 'SAMSUNG',
        model: 'Galaxy S24',
      );
      final correction = OrientationCorrection.forDevice(uppercaseDevice);
      
      expect(correction.rotationOffset, 90);
      expect(correction.requiresTransformMatrix, isTrue);
    });
  });
}