import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// The state of camera permissions.
enum CameraPermissionState {
  /// Permission status is unknown
  unknown,

  /// Camera permission has been granted
  granted,

  /// Camera permission has been denied
  denied,
}

/// Holds the current state of the camera.
@immutable
class CameralyValue {
  /// Creates a new [CameralyValue] instance.
  const CameralyValue({
    this.isInitialized = false,
    this.isTakingPicture = false,
    this.isRecordingVideo = false,
    this.isRecordingPaused = false,
    this.flashMode = FlashMode.auto,
    this.exposureMode = ExposureMode.auto,
    this.focusMode = FocusMode.auto,
    this.deviceOrientation = DeviceOrientation.portraitUp,
    this.permissionState = CameraPermissionState.unknown,
    this.error,
    this.zoomLevel = 1.0,
  });

  /// Creates an uninitialized value.
  const CameralyValue.uninitialized()
      : isInitialized = false,
        isTakingPicture = false,
        isRecordingVideo = false,
        isRecordingPaused = false,
        flashMode = FlashMode.auto,
        exposureMode = ExposureMode.auto,
        focusMode = FocusMode.auto,
        deviceOrientation = DeviceOrientation.portraitUp,
        permissionState = CameraPermissionState.unknown,
        error = null,
        zoomLevel = 1.0;

  /// Whether the camera has been initialized
  final bool isInitialized;

  /// Whether a picture is currently being taken
  final bool isTakingPicture;

  /// Whether a video is currently being recorded
  final bool isRecordingVideo;

  /// Whether video recording is paused
  final bool isRecordingPaused;

  /// The current flash mode
  final FlashMode flashMode;

  /// The current exposure mode
  final ExposureMode exposureMode;

  /// The current focus mode
  final FocusMode focusMode;

  /// The current device orientation
  final DeviceOrientation deviceOrientation;

  /// The current permission state
  final CameraPermissionState permissionState;

  /// The current error message, if any
  final String? error;

  /// The current zoom level
  final double zoomLevel;

  /// Creates a copy of this value with the given fields replaced.
  CameralyValue copyWith({
    bool? isInitialized,
    bool? isTakingPicture,
    bool? isRecordingVideo,
    bool? isRecordingPaused,
    FlashMode? flashMode,
    ExposureMode? exposureMode,
    FocusMode? focusMode,
    DeviceOrientation? deviceOrientation,
    CameraPermissionState? permissionState,
    String? error,
    double? zoomLevel,
  }) {
    return CameralyValue(
      isInitialized: isInitialized ?? this.isInitialized,
      isTakingPicture: isTakingPicture ?? this.isTakingPicture,
      isRecordingVideo: isRecordingVideo ?? this.isRecordingVideo,
      isRecordingPaused: isRecordingPaused ?? this.isRecordingPaused,
      flashMode: flashMode ?? this.flashMode,
      exposureMode: exposureMode ?? this.exposureMode,
      focusMode: focusMode ?? this.focusMode,
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
      permissionState: permissionState ?? this.permissionState,
      error: error,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CameralyValue &&
          runtimeType == other.runtimeType &&
          isInitialized == other.isInitialized &&
          isTakingPicture == other.isTakingPicture &&
          isRecordingVideo == other.isRecordingVideo &&
          isRecordingPaused == other.isRecordingPaused &&
          flashMode == other.flashMode &&
          exposureMode == other.exposureMode &&
          focusMode == other.focusMode &&
          deviceOrientation == other.deviceOrientation &&
          permissionState == other.permissionState &&
          error == other.error &&
          zoomLevel == other.zoomLevel;

  @override
  int get hashCode =>
      isInitialized.hashCode ^
      isTakingPicture.hashCode ^
      isRecordingVideo.hashCode ^
      isRecordingPaused.hashCode ^
      flashMode.hashCode ^
      exposureMode.hashCode ^
      focusMode.hashCode ^
      deviceOrientation.hashCode ^
      permissionState.hashCode ^
      error.hashCode ^
      zoomLevel.hashCode;

  @override
  String toString() => 'CameralyValue('
      'isInitialized: $isInitialized, '
      'isTakingPicture: $isTakingPicture, '
      'isRecordingVideo: $isRecordingVideo, '
      'isRecordingPaused: $isRecordingPaused, '
      'flashMode: $flashMode, '
      'exposureMode: $exposureMode, '
      'focusMode: $focusMode, '
      'deviceOrientation: $deviceOrientation, '
      'permissionState: $permissionState, '
      'error: $error, '
      'zoomLevel: $zoomLevel)';
}
