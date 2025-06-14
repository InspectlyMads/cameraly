// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhotoMetadata _$PhotoMetadataFromJson(Map<String, dynamic> json) =>
    PhotoMetadata(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      speedAccuracy: (json['speedAccuracy'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      headingAccuracy: (json['headingAccuracy'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      placeName: json['placeName'] as String?,
      deviceManufacturer: json['deviceManufacturer'] as String,
      deviceModel: json['deviceModel'] as String,
      osVersion: json['osVersion'] as String,
      cameraName: json['cameraName'] as String,
      lensDirection: json['lensDirection'] as String,
      focalLength: (json['focalLength'] as num?)?.toDouble(),
      aperture: (json['aperture'] as num?)?.toDouble(),
      exposureTime: (json['exposureTime'] as num?)?.toDouble(),
      iso: (json['iso'] as num?)?.toInt(),
      zoomLevel: (json['zoomLevel'] as num?)?.toDouble(),
      flashMode: json['flashMode'] as String?,
      whiteBalance: json['whiteBalance'] as String?,
      focusMode: json['focusMode'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      pressure: (json['pressure'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      lightLevel: (json['lightLevel'] as num?)?.toDouble(),
      deviceTiltX: (json['deviceTiltX'] as num?)?.toDouble(),
      deviceTiltY: (json['deviceTiltY'] as num?)?.toDouble(),
      deviceTiltZ: (json['deviceTiltZ'] as num?)?.toDouble(),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      captureTimeMillis: (json['captureTimeMillis'] as num).toInt(),
      imageWidth: (json['imageWidth'] as num?)?.toInt(),
      imageHeight: (json['imageHeight'] as num?)?.toInt(),
      fileSize: (json['fileSize'] as num?)?.toInt(),
      mimeType: json['mimeType'] as String?,
      photographer: json['photographer'] as String?,
      copyright: json['copyright'] as String?,
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      customData: json['customData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PhotoMetadataToJson(PhotoMetadata instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'altitude': instance.altitude,
      'speed': instance.speed,
      'speedAccuracy': instance.speedAccuracy,
      'heading': instance.heading,
      'headingAccuracy': instance.headingAccuracy,
      'accuracy': instance.accuracy,
      'placeName': instance.placeName,
      'deviceManufacturer': instance.deviceManufacturer,
      'deviceModel': instance.deviceModel,
      'osVersion': instance.osVersion,
      'cameraName': instance.cameraName,
      'lensDirection': instance.lensDirection,
      'focalLength': instance.focalLength,
      'aperture': instance.aperture,
      'exposureTime': instance.exposureTime,
      'iso': instance.iso,
      'zoomLevel': instance.zoomLevel,
      'flashMode': instance.flashMode,
      'whiteBalance': instance.whiteBalance,
      'focusMode': instance.focusMode,
      'temperature': instance.temperature,
      'pressure': instance.pressure,
      'humidity': instance.humidity,
      'lightLevel': instance.lightLevel,
      'deviceTiltX': instance.deviceTiltX,
      'deviceTiltY': instance.deviceTiltY,
      'deviceTiltZ': instance.deviceTiltZ,
      'capturedAt': instance.capturedAt.toIso8601String(),
      'captureTimeMillis': instance.captureTimeMillis,
      'imageWidth': instance.imageWidth,
      'imageHeight': instance.imageHeight,
      'fileSize': instance.fileSize,
      'mimeType': instance.mimeType,
      'photographer': instance.photographer,
      'copyright': instance.copyright,
      'description': instance.description,
      'tags': instance.tags,
      'customData': instance.customData,
    };
