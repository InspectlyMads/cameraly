import 'package:cameraly/cameraly.dart';

/// Example of how to provide custom localization for Cameraly
/// 
/// This example shows how to integrate with easy_localization or any other
/// localization solution.
class CustomCameralyLocalizations extends CameralyLocalizations {
  // For easy_localization users:
  @override
  String get modePhoto => 'camera.mode.photo'.tr();
  
  @override
  String get modeVideo => 'camera.mode.video'.tr();
  
  @override
  String get flashOff => 'camera.flash.off'.tr();
  
  @override
  String get flashAuto => 'camera.flash.auto'.tr();
  
  @override
  String get flashOn => 'camera.flash.on'.tr();
  
  @override
  String get permissionCameraRequired => 'permissions.camera.required'.tr();
  
  @override
  String get permissionCameraAndMicrophoneRequired => 'permissions.camera_mic.required'.tr();
  
  @override
  String get errorCameraNotFound => 'errors.camera.not_found'.tr();
  
  @override
  String get buttonTakePhoto => 'buttons.take_photo'.tr();
  
  @override
  String get buttonGrantPermissions => 'buttons.grant_permissions'.tr();
  
  @override
  String recordingDuration(String duration) => duration; // Usually no translation needed
  
  @override
  String zoomLevel(double zoom) => '${zoom.toStringAsFixed(1)}x'; // Usually no translation needed
  
  // ... override all other strings as needed
}

/// Alternative example using a simple map-based localization
class MapBasedCameralyLocalizations extends CameralyLocalizations {
  final Map<String, String> translations;
  
  MapBasedCameralyLocalizations(this.translations);
  
  @override
  String get modePhoto => translations['mode_photo'] ?? super.modePhoto;
  
  @override
  String get modeVideo => translations['mode_video'] ?? super.modeVideo;
  
  // ... and so on
}

/// Example usage in your app
void setupCameralyLocalization() {
  // Method 1: Using easy_localization
  CameralyLocalizations.setInstance(CustomCameralyLocalizations());
  
  // Method 2: Using a simple map
  CameralyLocalizations.setInstance(
    MapBasedCameralyLocalizations({
      'mode_photo': 'Foto',
      'mode_video': 'Video',
      'flash_off': 'Aus',
      'flash_auto': 'Auto',
      'flash_on': 'Ein',
      'permission_camera_required': 'Kameraberechtigung erforderlich',
      // ... add all translations
    }),
  );
  
  // Method 3: Create your own implementation
  // CameralyLocalizations.setInstance(YourCustomLocalizationClass());
}

// Extension to simulate easy_localization's .tr() method
extension StringLocalization on String {
  String tr() {
    // In a real app, this would use easy_localization
    // For this example, we just return the key
    return this;
  }
}