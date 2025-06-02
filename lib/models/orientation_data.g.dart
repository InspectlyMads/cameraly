// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orientation_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrientationData _$OrientationDataFromJson(Map<String, dynamic> json) =>
    OrientationData(
      deviceOrientation:
          $enumDecode(_$DeviceOrientationEnumMap, json['deviceOrientation']),
      cameraRotation: (json['cameraRotation'] as num).toInt(),
      sensorOrientation: (json['sensorOrientation'] as num).toInt(),
      deviceManufacturer: json['deviceManufacturer'] as String,
      deviceModel: json['deviceModel'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      accuracyScore: (json['accuracyScore'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$OrientationDataToJson(OrientationData instance) =>
    <String, dynamic>{
      'deviceOrientation':
          _$DeviceOrientationEnumMap[instance.deviceOrientation]!,
      'cameraRotation': instance.cameraRotation,
      'sensorOrientation': instance.sensorOrientation,
      'deviceManufacturer': instance.deviceManufacturer,
      'deviceModel': instance.deviceModel,
      'timestamp': instance.timestamp.toIso8601String(),
      'accuracyScore': instance.accuracyScore,
      'metadata': instance.metadata,
    };

const _$DeviceOrientationEnumMap = {
  DeviceOrientation.portraitUp: 'portraitUp',
  DeviceOrientation.landscapeLeft: 'landscapeLeft',
  DeviceOrientation.portraitDown: 'portraitDown',
  DeviceOrientation.landscapeRight: 'landscapeRight',
};

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => DeviceInfo(
      manufacturer: json['manufacturer'] as String,
      model: json['model'] as String,
      androidVersion: json['androidVersion'] as String,
      sdkVersion: json['sdkVersion'] as String,
    );

Map<String, dynamic> _$DeviceInfoToJson(DeviceInfo instance) =>
    <String, dynamic>{
      'manufacturer': instance.manufacturer,
      'model': instance.model,
      'androidVersion': instance.androidVersion,
      'sdkVersion': instance.sdkVersion,
    };

OrientationCorrection _$OrientationCorrectionFromJson(
        Map<String, dynamic> json) =>
    OrientationCorrection(
      rotationOffset: (json['rotationOffset'] as num?)?.toInt() ?? 0,
      requiresTransformMatrix:
          json['requiresTransformMatrix'] as bool? ?? false,
      transformMatrix:
          json['transformMatrix'] as Map<String, dynamic>? ?? const {},
      flipHorizontal: json['flipHorizontal'] as bool? ?? false,
      flipVertical: json['flipVertical'] as bool? ?? false,
    );

Map<String, dynamic> _$OrientationCorrectionToJson(
        OrientationCorrection instance) =>
    <String, dynamic>{
      'rotationOffset': instance.rotationOffset,
      'requiresTransformMatrix': instance.requiresTransformMatrix,
      'transformMatrix': instance.transformMatrix,
      'flipHorizontal': instance.flipHorizontal,
      'flipVertical': instance.flipVertical,
    };
