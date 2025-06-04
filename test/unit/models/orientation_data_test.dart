import 'package:camera_test/models/orientation_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrientationData', () {
    test('serializes to JSON correctly', () {
      final orientation = OrientationData(
        deviceOrientation: 90, // 90 degrees for landscape left
        cameraRotation: 90,
        sensorOrientation: 270,
        deviceManufacturer: 'Samsung',
        deviceModel: 'Galaxy S21',
        timestamp: DateTime(2025, 6, 2, 12, 0),
        accuracyScore: 0.95,
        metadata: {'test': 'value'},
      );

      final json = orientation.toJson();
      expect(json['deviceOrientation'], equals(90));
      expect(json['cameraRotation'], equals(90));
      expect(json['sensorOrientation'], equals(270));
      expect(json['deviceManufacturer'], equals('Samsung'));
      expect(json['deviceModel'], equals('Galaxy S21'));
      expect(json['accuracyScore'], equals(0.95));
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'deviceOrientation': 90,
        'cameraRotation': 90,
        'sensorOrientation': 270,
        'deviceManufacturer': 'Samsung',
        'deviceModel': 'Galaxy S21',
        'timestamp': '2025-06-02T12:00:00.000',
        'accuracyScore': 0.95,
        'metadata': {'test': 'value'},
      };

      final orientation = OrientationData.fromJson(json);
      expect(orientation.deviceOrientation, equals(90));
      expect(orientation.cameraRotation, equals(90));
      expect(orientation.sensorOrientation, equals(270));
      expect(orientation.deviceManufacturer, equals('Samsung'));
      expect(orientation.deviceModel, equals('Galaxy S21'));
      expect(orientation.accuracyScore, equals(0.95));
      expect(orientation.metadata['test'], equals('value'));
    });

    test('copyWith creates correct copy', () {
      final original = OrientationData(
        deviceOrientation: 0, // Portrait up
        cameraRotation: 0,
        sensorOrientation: 0,
        deviceManufacturer: 'Google',
        deviceModel: 'Pixel 6',
        timestamp: DateTime.now(),
      );

      final copied = original.copyWith(
        deviceOrientation: 90, // Landscape left
        accuracyScore: 0.85,
      );

      expect(copied.deviceOrientation, equals(90));
      expect(copied.accuracyScore, equals(0.85));
      expect(copied.deviceManufacturer, equals('Google'));
      expect(copied.deviceModel, equals('Pixel 6'));
    });

    test('toString returns formatted string', () {
      final orientation = OrientationData(
        deviceOrientation: 90, // Landscape left
        cameraRotation: 90,
        sensorOrientation: 270,
        deviceManufacturer: 'Samsung',
        deviceModel: 'Galaxy S21',
        timestamp: DateTime.now(),
        accuracyScore: 0.95,
      );

      final str = orientation.toString();
      expect(str, contains('90')); // deviceOrientation value
      expect(str, contains('Samsung Galaxy S21'));
      expect(str, contains('95.0%'));
    });

    test('equality works correctly', () {
      final timestamp = DateTime.now();
      final orientation1 = OrientationData(
        deviceOrientation: 0, // Portrait up
        cameraRotation: 0,
        sensorOrientation: 0,
        deviceManufacturer: 'Google',
        deviceModel: 'Pixel 6',
        timestamp: timestamp,
        accuracyScore: 0.95,
      );

      final orientation2 = OrientationData(
        deviceOrientation: 0, // Portrait up
        cameraRotation: 0,
        sensorOrientation: 0,
        deviceManufacturer: 'Google',
        deviceModel: 'Pixel 6',
        timestamp: timestamp,
        accuracyScore: 0.95,
      );

      expect(orientation1, equals(orientation2));
      expect(orientation1.hashCode, equals(orientation2.hashCode));
    });
  });

  group('DeviceInfo', () {
    test('serializes and deserializes correctly', () {
      final deviceInfo = DeviceInfo(
        manufacturer: 'Samsung',
        model: 'Galaxy S21',
        androidVersion: '13',
        sdkVersion: '33',
      );

      final json = deviceInfo.toJson();
      final restored = DeviceInfo.fromJson(json);

      expect(restored.manufacturer, equals(deviceInfo.manufacturer));
      expect(restored.model, equals(deviceInfo.model));
      expect(restored.androidVersion, equals(deviceInfo.androidVersion));
      expect(restored.sdkVersion, equals(deviceInfo.sdkVersion));
    });

    test('toString returns formatted string', () {
      final deviceInfo = DeviceInfo(
        manufacturer: 'Samsung',
        model: 'Galaxy S21',
        androidVersion: '13',
        sdkVersion: '33',
        osVersion: '13', // Add osVersion for toString
      );

      final str = deviceInfo.toString();
      expect(str, equals('Samsung Galaxy S21 (13)')); // New format uses osVersion
    });
  });

  group('OrientationCorrection', () {
    test('forDevice returns correct Samsung correction', () {
      final samsung = DeviceInfo(
        manufacturer: 'Samsung',
        model: 'Galaxy S21',
        androidVersion: '13',
        sdkVersion: '33',
      );

      final correction = OrientationCorrection.forDevice(samsung);
      expect(correction.rotationOffset, equals(90));
      expect(correction.requiresTransformMatrix, isTrue);
    });

    test('forDevice returns correct Xiaomi correction', () {
      final xiaomi = DeviceInfo(
        manufacturer: 'Xiaomi',
        model: 'Redmi Note 10',
        androidVersion: '12',
        sdkVersion: '31',
      );

      final correction = OrientationCorrection.forDevice(xiaomi);
      expect(correction.rotationOffset, equals(270));
      expect(correction.requiresTransformMatrix, isTrue);
    });

    test('forDevice returns default correction for unknown manufacturer', () {
      final unknown = DeviceInfo(
        manufacturer: 'UnknownBrand',
        model: 'UnknownModel',
        androidVersion: '13',
        sdkVersion: '33',
      );

      final correction = OrientationCorrection.forDevice(unknown);
      expect(correction.rotationOffset, equals(0));
      expect(correction.requiresTransformMatrix, isFalse);
    });

    test('serializes and deserializes correctly', () {
      final correction = OrientationCorrection(
        rotationOffset: 90,
        requiresTransformMatrix: true,
        transformMatrix: {'a': 1.0, 'b': 0.0},
        flipHorizontal: true,
      );

      final json = correction.toJson();
      final restored = OrientationCorrection.fromJson(json);

      expect(restored.rotationOffset, equals(correction.rotationOffset));
      expect(restored.requiresTransformMatrix, equals(correction.requiresTransformMatrix));
      expect(restored.flipHorizontal, equals(correction.flipHorizontal));
    });
  });
}
