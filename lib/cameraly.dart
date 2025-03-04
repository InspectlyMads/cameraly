/// A Flutter camera package that provides an enhanced, easy-to-use interface
/// on top of the official camera plugin.
///
/// This package extends the functionality of the official camera plugin while
/// maintaining a simpler, more intuitive API for common camera operations.
library cameraly;

// Re-export necessary types from the camera package
export 'package:camera/camera.dart' show CameraException, CameraImage, FlashMode, ExposureMode, FocusMode, ResolutionPreset;

// Export our enhanced types and controllers
export 'src/cameraly_controller.dart';
export 'src/cameraly_preview.dart';
export 'src/cameraly_value.dart';
export 'src/types/camera_device.dart';
// Export configuration types
export 'src/types/capture_settings.dart';
export 'src/types/photo_settings.dart';
export 'src/types/video_settings.dart';
// Export utility functions
export 'src/utils/cameraly_utils.dart';
export 'src/utils/permission_handler.dart';
