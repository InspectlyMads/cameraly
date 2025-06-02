import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';

part 'orientation_data.g.dart';

@JsonSerializable()
class OrientationData {
  final DeviceOrientation deviceOrientation;
  final int cameraRotation;
  final int sensorOrientation;
  final String deviceManufacturer;
  final String deviceModel;
  final DateTime timestamp;
  final double accuracyScore;
  final Map<String, dynamic> metadata;

  const OrientationData({
    required this.deviceOrientation,
    required this.cameraRotation,
    required this.sensorOrientation,
    required this.deviceManufacturer,
    required this.deviceModel,
    required this.timestamp,
    this.accuracyScore = 0.0,
    this.metadata = const {},
  });

  factory OrientationData.fromJson(Map<String, dynamic> json) => _$OrientationDataFromJson(json);

  Map<String, dynamic> toJson() => _$OrientationDataToJson(this);

  OrientationData copyWith({
    DeviceOrientation? deviceOrientation,
    int? cameraRotation,
    int? sensorOrientation,
    String? deviceManufacturer,
    String? deviceModel,
    DateTime? timestamp,
    double? accuracyScore,
    Map<String, dynamic>? metadata,
  }) {
    return OrientationData(
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
      cameraRotation: cameraRotation ?? this.cameraRotation,
      sensorOrientation: sensorOrientation ?? this.sensorOrientation,
      deviceManufacturer: deviceManufacturer ?? this.deviceManufacturer,
      deviceModel: deviceModel ?? this.deviceModel,
      timestamp: timestamp ?? this.timestamp,
      accuracyScore: accuracyScore ?? this.accuracyScore,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrientationData &&
        other.deviceOrientation == deviceOrientation &&
        other.cameraRotation == cameraRotation &&
        other.sensorOrientation == sensorOrientation &&
        other.deviceManufacturer == deviceManufacturer &&
        other.deviceModel == deviceModel &&
        other.timestamp == timestamp &&
        other.accuracyScore == accuracyScore;
  }

  @override
  int get hashCode {
    return Object.hash(
      deviceOrientation,
      cameraRotation,
      sensorOrientation,
      deviceManufacturer,
      deviceModel,
      timestamp,
      accuracyScore,
    );
  }

  @override
  String toString() {
    return 'OrientationData('
        'deviceOrientation: $deviceOrientation, '
        'cameraRotation: $cameraRotation, '
        'sensorOrientation: $sensorOrientation, '
        'device: $deviceManufacturer $deviceModel, '
        'accuracy: ${(accuracyScore * 100).toStringAsFixed(1)}%)';
  }
}

@JsonSerializable()
class DeviceInfo {
  final String manufacturer;
  final String model;
  final String androidVersion;
  final String sdkVersion;

  const DeviceInfo({
    required this.manufacturer,
    required this.model,
    required this.androidVersion,
    required this.sdkVersion,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => _$DeviceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceInfoToJson(this);

  @override
  String toString() => '$manufacturer $model (Android $androidVersion)';
}

@JsonSerializable()
class OrientationCorrection {
  final int rotationOffset;
  final bool requiresTransformMatrix;
  final Map<String, dynamic> transformMatrix;
  final bool flipHorizontal;
  final bool flipVertical;

  const OrientationCorrection({
    this.rotationOffset = 0,
    this.requiresTransformMatrix = false,
    this.transformMatrix = const {},
    this.flipHorizontal = false,
    this.flipVertical = false,
  });

  factory OrientationCorrection.fromJson(Map<String, dynamic> json) => _$OrientationCorrectionFromJson(json);

  Map<String, dynamic> toJson() => _$OrientationCorrectionToJson(this);

  static OrientationCorrection forDevice(DeviceInfo deviceInfo) {
    // Manufacturer-specific corrections based on common issues
    switch (deviceInfo.manufacturer.toLowerCase()) {
      case 'samsung':
        return const OrientationCorrection(
          rotationOffset: 90,
          requiresTransformMatrix: true,
        );
      case 'xiaomi':
        return const OrientationCorrection(
          rotationOffset: 270,
          requiresTransformMatrix: true,
        );
      case 'huawei':
        return const OrientationCorrection(
          rotationOffset: 180,
          flipHorizontal: true,
        );
      default:
        return const OrientationCorrection();
    }
  }
}
