// Core exports
// Re-export camera package enums that users might need
export 'package:camera/camera.dart' show FlashMode, ResolutionPreset;

// Localization
export 'src/localization/cameraly_localizations.dart';

export 'src/models/media_item.dart';
export 'src/models/orientation_data.dart';
export 'src/models/photo_metadata.dart';
export 'src/models/camera_custom_widgets.dart';
export 'src/models/camera_settings.dart';
// Provider exports (for customization)
export 'src/providers/camera_providers.dart';
export 'src/providers/permission_providers.dart';
export 'src/screens/camera_screen.dart' show CameraView, CameraScreen;
export 'src/services/camera_error_handler.dart';
export 'src/services/camera_info_service.dart';
// Service exports (for advanced users)
export 'src/services/camera_service.dart';
export 'src/services/camera_ui_service.dart';
export 'src/services/media_service.dart';
export 'src/services/metadata_service.dart';
export 'src/services/orientation_service.dart';
export 'src/services/permission_service.dart';
export 'src/services/memory_manager.dart';
export 'src/services/storage_service.dart';
export 'src/utils/camera_preview_utils.dart';
// Utility exports
export 'src/utils/orientation_ui_helper.dart';
export 'src/utils/zoom_helper.dart';
// Widget exports (for composition)
export 'src/widgets/camera_grid_overlay.dart';
export 'src/widgets/camera_zoom_control.dart';
export 'src/widgets/focus_indicator.dart';
