import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
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
    return await [
      Permission.camera,
      Permission.microphone,
    ].request();
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
  Future<bool> openAppSettings() async {
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
