library cameraly;

// Core exports
export 'src/screens/camera_screen.dart';
export 'src/models/media_item.dart';
export 'src/models/orientation_data.dart';

// Service exports (for advanced users)
export 'src/services/camera_service.dart';
export 'src/services/media_service.dart';
export 'src/services/permission_service.dart';
export 'src/services/orientation_service.dart';
export 'src/services/camera_error_handler.dart';
export 'src/services/camera_ui_service.dart';
export 'src/services/camera_info_service.dart';

// Provider exports (for customization)
export 'src/providers/camera_providers.dart';
export 'src/providers/permission_providers.dart';

// Widget exports (for composition)
export 'src/widgets/camera_grid_overlay.dart';
export 'src/widgets/camera_zoom_control.dart';
export 'src/widgets/focus_indicator.dart';
export 'src/widgets/orientation_debug_overlay.dart';

// Utility exports
export 'src/utils/orientation_ui_helper.dart';
export 'src/utils/zoom_helper.dart';
export 'src/utils/camera_preview_utils.dart';

// Re-export camera package enums that users might need
export 'package:camera/camera.dart' show FlashMode, ResolutionPreset;