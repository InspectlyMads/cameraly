import 'package:json_annotation/json_annotation.dart';

part 'photo_metadata.g.dart';

@JsonSerializable()
class PhotoMetadata {
  // Location data
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? speed; // meters/second
  final double? speedAccuracy;
  final double? heading; // degrees from north
  final double? headingAccuracy;
  final double? accuracy; // location accuracy in meters
  final String? placeName; // reverse geocoded place name
  
  // Device info
  final String deviceManufacturer;
  final String deviceModel;
  final String osVersion;
  
  // Camera settings
  final String cameraName;
  final String lensDirection; // front/back
  final double? focalLength;
  final double? aperture;
  final double? exposureTime; // in seconds
  final int? iso;
  final double? zoomLevel;
  final String? flashMode;
  final String? whiteBalance;
  final String? focusMode;
  
  // Environmental data
  final double? temperature; // celsius
  final double? pressure; // hPa
  final double? humidity; // percentage
  final double? lightLevel; // lux
  
  // Accelerometer/Gyroscope
  final double? deviceTiltX;
  final double? deviceTiltY;
  final double? deviceTiltZ;
  
  // Timestamps
  final DateTime capturedAt;
  final int captureTimeMillis; // time taken to capture
  
  // Image properties
  final int? imageWidth;
  final int? imageHeight;
  final int? fileSize;
  final String? mimeType;
  
  // Additional info
  final String? photographer;
  final String? copyright;
  final String? description;
  final List<String>? tags;
  final Map<String, dynamic>? customData;

  const PhotoMetadata({
    this.latitude,
    this.longitude,
    this.altitude,
    this.speed,
    this.speedAccuracy,
    this.heading,
    this.headingAccuracy,
    this.accuracy,
    this.placeName,
    required this.deviceManufacturer,
    required this.deviceModel,
    required this.osVersion,
    required this.cameraName,
    required this.lensDirection,
    this.focalLength,
    this.aperture,
    this.exposureTime,
    this.iso,
    this.zoomLevel,
    this.flashMode,
    this.whiteBalance,
    this.focusMode,
    this.temperature,
    this.pressure,
    this.humidity,
    this.lightLevel,
    this.deviceTiltX,
    this.deviceTiltY,
    this.deviceTiltZ,
    required this.capturedAt,
    required this.captureTimeMillis,
    this.imageWidth,
    this.imageHeight,
    this.fileSize,
    this.mimeType,
    this.photographer,
    this.copyright,
    this.description,
    this.tags,
    this.customData,
  });

  factory PhotoMetadata.fromJson(Map<String, dynamic> json) => _$PhotoMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoMetadataToJson(this);
  
  PhotoMetadata copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    double? speed,
    double? speedAccuracy,
    double? heading,
    double? headingAccuracy,
    double? accuracy,
    String? placeName,
    String? deviceManufacturer,
    String? deviceModel,
    String? osVersion,
    String? cameraName,
    String? lensDirection,
    double? focalLength,
    double? aperture,
    double? exposureTime,
    int? iso,
    double? zoomLevel,
    String? flashMode,
    String? whiteBalance,
    String? focusMode,
    double? temperature,
    double? pressure,
    double? humidity,
    double? lightLevel,
    double? deviceTiltX,
    double? deviceTiltY,
    double? deviceTiltZ,
    DateTime? capturedAt,
    int? captureTimeMillis,
    int? imageWidth,
    int? imageHeight,
    int? fileSize,
    String? mimeType,
    String? photographer,
    String? copyright,
    String? description,
    List<String>? tags,
    Map<String, dynamic>? customData,
  }) {
    return PhotoMetadata(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      speedAccuracy: speedAccuracy ?? this.speedAccuracy,
      heading: heading ?? this.heading,
      headingAccuracy: headingAccuracy ?? this.headingAccuracy,
      accuracy: accuracy ?? this.accuracy,
      placeName: placeName ?? this.placeName,
      deviceManufacturer: deviceManufacturer ?? this.deviceManufacturer,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      cameraName: cameraName ?? this.cameraName,
      lensDirection: lensDirection ?? this.lensDirection,
      focalLength: focalLength ?? this.focalLength,
      aperture: aperture ?? this.aperture,
      exposureTime: exposureTime ?? this.exposureTime,
      iso: iso ?? this.iso,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      flashMode: flashMode ?? this.flashMode,
      whiteBalance: whiteBalance ?? this.whiteBalance,
      focusMode: focusMode ?? this.focusMode,
      temperature: temperature ?? this.temperature,
      pressure: pressure ?? this.pressure,
      humidity: humidity ?? this.humidity,
      lightLevel: lightLevel ?? this.lightLevel,
      deviceTiltX: deviceTiltX ?? this.deviceTiltX,
      deviceTiltY: deviceTiltY ?? this.deviceTiltY,
      deviceTiltZ: deviceTiltZ ?? this.deviceTiltZ,
      capturedAt: capturedAt ?? this.capturedAt,
      captureTimeMillis: captureTimeMillis ?? this.captureTimeMillis,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      photographer: photographer ?? this.photographer,
      copyright: copyright ?? this.copyright,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      customData: customData ?? this.customData,
    );
  }
}