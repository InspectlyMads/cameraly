import 'package:permission_handler/permission_handler.dart';

import '../services/camera_service.dart';

class PermissionService {
  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted || status.isLimited;
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted || status.isLimited;
  }

  /// Request camera permission
  Future<PermissionStatus> requestCameraPermission() async {
    return await Permission.camera.request();
  }

  /// Request microphone permission
  Future<PermissionStatus> requestMicrophonePermission() async {
    return await Permission.microphone.request();
  }

  /// Request both camera and microphone permissions
  Future<Map<Permission, PermissionStatus>> requestCameraPermissions() async {
    // Request permissions one by one to ensure proper handling on iOS
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();
    
    return {
      Permission.camera: cameraStatus,
      Permission.microphone: microphoneStatus,
    };
  }
  
  /// Check if both camera and microphone permissions are granted
  Future<bool> checkCameraAndMicrophonePermissions() async {
    return await hasAllCameraPermissions();
  }
  
  /// Request both camera and microphone permissions and return success status
  Future<bool> requestCameraAndMicrophonePermissions() async {
    final results = await requestCameraPermissions();
    return results[Permission.camera]?.isGranted == true && 
           results[Permission.microphone]?.isGranted == true;
  }
  
  /// Request location permission
  Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.location.request();
  }
  
  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }
  
  /// Check if only camera permission is granted (no microphone check)
  Future<bool> hasCameraOnlyPermission() async {
    return await hasCameraPermission();
  }
  
  /// Request camera-only permission and return success status
  Future<bool> requestCameraOnlyPermission() async {
    final status = await requestCameraPermission();
    return status.isGranted || status.isLimited;
  }
  
  /// Check permissions based on camera mode
  /// For photo mode, only camera permission is needed
  /// For video/combined modes, both camera and microphone are needed
  Future<bool> hasRequiredPermissionsForMode(CameraMode mode) async {
    if (mode == CameraMode.photo) {
      return await hasCameraOnlyPermission();
    } else {
      return await hasAllCameraPermissions();
    }
  }
  
  /// Request permissions based on camera mode
  Future<bool> requestPermissionsForMode(CameraMode mode) async {
    if (mode == CameraMode.photo) {
      return await requestCameraOnlyPermission();
    } else {
      return await requestCameraAndMicrophonePermissions();
    }
  }

  /// Check if both permissions are granted with retry mechanism
  /// This helps handle race conditions where permissions are just granted
  /// but not yet reflected in the system state
  Future<bool> hasAllCameraPermissionsWithRetry({
    int maxAttempts = 3,
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final hasPermissions = await hasAllCameraPermissions();
      if (hasPermissions) {
        return true;
      }

      // Don't delay on the last attempt
      if (attempt < maxAttempts - 1) {
        await Future.delayed(Duration(milliseconds: delay.inMilliseconds * (attempt + 1)));
      }
    }

    return false;
  }

  /// Check if both permissions are granted
  Future<bool> hasAllCameraPermissions() async {
    final cameraGranted = await hasCameraPermission();
    final microphoneGranted = await hasMicrophonePermission();
    return cameraGranted && microphoneGranted;
  }

  /// Get detailed permission status
  Future<CameraPermissionStatus> getCameraPermissionStatus() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    return CameraPermissionStatus(
      camera: cameraStatus,
      microphone: microphoneStatus,
    );
  }

  /// Check if user should be shown permission rationale
  Future<bool> shouldShowPermissionRationale() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    return cameraStatus.isDenied || microphoneStatus.isDenied || cameraStatus.isPermanentlyDenied || microphoneStatus.isPermanentlyDenied;
  }

  /// Open app settings if permissions are permanently denied
  Future<bool> openAppSettingsScreen() async {
    return await openAppSettings();
  }
}

class CameraPermissionStatus {
  final PermissionStatus camera;
  final PermissionStatus microphone;

  const CameraPermissionStatus({
    required this.camera,
    required this.microphone,
  });

  bool get isGranted => camera.isGranted && microphone.isGranted;
  bool get isDenied => camera.isDenied || microphone.isDenied;
  bool get isPermanentlyDenied => camera.isPermanentlyDenied || microphone.isPermanentlyDenied;
  bool get isRestricted => camera.isRestricted || microphone.isRestricted;

  @override
  String toString() {
    return 'CameraPermissionStatus(camera: $camera, microphone: $microphone)';
  }
}
