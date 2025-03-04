import 'package:camera/camera.dart' show CameraDescription, CameraLensDirection, ResolutionPreset, availableCameras, CameraException;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Utility functions for camera operations.
class CameralyUtils {
  /// Private constructor to prevent instantiation
  const CameralyUtils._();

  /// Returns a list of available cameras on the device.
  static Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      return await availableCameras();
    } on CameraException catch (e) {
      throw CameraException(
        'Failed to get cameras',
        'Error getting available cameras: ${e.description}',
      );
    }
  }

  /// Generates a unique file path for storing media.
  static Future<String> generateFilePath({
    required String prefix,
    required String extension,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$prefix-$timestamp.$extension';
    return path.join(directory.path, fileName);
  }

  /// Filters the available cameras based on the preferred lens direction.
  /// If no direction is specified, returns all cameras.
  static List<CameraDescription> filterCameras(
    List<CameraDescription> cameras, {
    CameraLensDirection? preferredLensDirection,
  }) {
    if (preferredLensDirection == null) {
      return cameras;
    }
    return cameras.where((camera) => camera.lensDirection == preferredLensDirection).toList();
  }

  /// Gets the name of the camera.
  static String getCameraName(CameraDescription camera) => camera.name;

  /// Gets a human-readable description of the camera.
  static String getCameraDescription(CameraDescription camera) {
    return '${camera.name} (${getLensDirectionName(camera.lensDirection)}, '
        '${formatOrientation(camera.sensorOrientation)})';
  }

  /// Formats the orientation in degrees with the degree symbol.
  static String formatOrientation(int orientation) => '$orientation°';

  /// Gets a human-readable name for the lens direction.
  static String getLensDirectionName(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.front:
        return 'front';
      case CameraLensDirection.back:
        return 'back';
      case CameraLensDirection.external:
        return 'external';
    }
  }

  /// Gets a human-readable name for the resolution preset.
  static String getResolutionPresetName(ResolutionPreset preset) {
    switch (preset) {
      case ResolutionPreset.low:
        return 'low';
      case ResolutionPreset.medium:
        return 'medium';
      case ResolutionPreset.high:
        return 'high';
      case ResolutionPreset.veryHigh:
        return 'very high';
      case ResolutionPreset.ultraHigh:
        return 'ultra high';
      case ResolutionPreset.max:
        return 'max';
    }
  }

  /// Returns the best matching camera for the specified lens direction.
  static Future<CameraDescription?> getBestCamera(
    CameraLensDirection direction,
  ) async {
    final cameras = await getAvailableCameras();
    return cameras.firstWhere(
      (camera) => camera.lensDirection == direction,
      orElse: () => cameras.first,
    );
  }

  /// Formats the camera resolution as a string.
  static String formatResolution(ResolutionPreset resolution) {
    switch (resolution) {
      case ResolutionPreset.low:
        return '320x240';
      case ResolutionPreset.medium:
        return '640x480';
      case ResolutionPreset.high:
        return '1280x720';
      case ResolutionPreset.veryHigh:
        return '1920x1080';
      case ResolutionPreset.ultraHigh:
        return '3840x2160';
      case ResolutionPreset.max:
        return 'Maximum available';
    }
  }
}
