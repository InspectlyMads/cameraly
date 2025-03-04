import 'package:meta/meta.dart';

/// Represents a physical camera device on the user's device.
@immutable
class CameraDevice {
  /// Creates a new [CameraDevice] instance.
  const CameraDevice({
    required this.id,
    required this.name,
    required this.lensDirection,
    this.sensorOrientation = 0,
  });

  /// Unique identifier for this camera device.
  final String id;

  /// Human-readable name of the camera device.
  final String name;

  /// The direction that the camera lens faces.
  final CameraLensDirection lensDirection;

  /// The orientation of the camera sensor in degrees.
  final int sensorOrientation;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CameraDevice && runtimeType == other.runtimeType && id == other.id && name == other.name && lensDirection == other.lensDirection && sensorOrientation == other.sensorOrientation;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ lensDirection.hashCode ^ sensorOrientation.hashCode;

  @override
  String toString() => 'CameraDevice(id: $id, name: $name, lensDirection: $lensDirection, sensorOrientation: $sensorOrientation)';
}

/// The direction that the camera lens faces.
enum CameraLensDirection {
  /// The camera lens points in the same direction as the device's screen.
  front,

  /// The camera lens points in the opposite direction of the device's screen.
  back,

  /// The camera lens points in an arbitrary direction relative to the device's screen.
  external,
}
