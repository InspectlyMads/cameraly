import 'package:camera/camera.dart';

/// Represents the current state of the camera overlay.
class CameralyOverlayState {
  /// Creates a new camera overlay state.
  const CameralyOverlayState({
    required this.isRecording,
    required this.isVideoMode,
    required this.isFrontCamera,
    required this.flashMode,
    required this.torchEnabled,
    required this.recordingDuration,
  });

  /// Whether the camera is currently recording video.
  final bool isRecording;

  /// Whether the camera is in video mode (as opposed to photo mode).
  final bool isVideoMode;

  /// Whether the front camera is currently active.
  final bool isFrontCamera;

  /// The current flash mode.
  final FlashMode flashMode;

  /// Whether the torch is enabled (in video mode).
  final bool torchEnabled;

  /// The current recording duration (zero if not recording).
  final Duration recordingDuration;

  /// Creates a copy of this state with the specified fields replaced.
  CameralyOverlayState copyWith({
    bool? isRecording,
    bool? isVideoMode,
    bool? isFrontCamera,
    FlashMode? flashMode,
    bool? torchEnabled,
    Duration? recordingDuration,
  }) {
    return CameralyOverlayState(
      isRecording: isRecording ?? this.isRecording,
      isVideoMode: isVideoMode ?? this.isVideoMode,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      flashMode: flashMode ?? this.flashMode,
      torchEnabled: torchEnabled ?? this.torchEnabled,
      recordingDuration: recordingDuration ?? this.recordingDuration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CameralyOverlayState &&
          runtimeType == other.runtimeType &&
          isRecording == other.isRecording &&
          isVideoMode == other.isVideoMode &&
          isFrontCamera == other.isFrontCamera &&
          flashMode == other.flashMode &&
          torchEnabled == other.torchEnabled &&
          recordingDuration == other.recordingDuration;

  @override
  int get hashCode => isRecording.hashCode ^ isVideoMode.hashCode ^ isFrontCamera.hashCode ^ flashMode.hashCode ^ torchEnabled.hashCode ^ recordingDuration.hashCode;
}
