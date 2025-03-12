import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../types/camera_mode.dart';

/// Enum defining the possible states of a permission
enum PermissionState {
  /// Permission has not been requested yet
  notDetermined,

  /// Permission has been granted
  granted,

  /// Permission has been denied but can be requested again
  denied,

  /// Permission has been permanently denied (user selected "Don't ask again")
  permanentlyDenied,

  /// Permission is restricted (iOS)
  restricted,

  /// Permission request is in progress
  requesting
}

/// A centralized manager for handling camera and microphone permissions
class CameralyPermissionManager extends ChangeNotifier {
  /// Creates a new [CameralyPermissionManager] instance
  CameralyPermissionManager({
    this.cameraMode = CameraMode.both,
    this.requireMicrophoneForVideo = true,
  }) {
    // Check initial permission status
    _checkInitialPermissions();
  }

  /// The current camera mode
  CameraMode cameraMode;

  /// Whether microphone is required for video recording
  bool requireMicrophoneForVideo;

  /// The current camera permission state
  PermissionState _cameraPermissionState = PermissionState.notDetermined;

  /// The current microphone permission state
  PermissionState _microphonePermissionState = PermissionState.notDetermined;

  /// Whether to show the permission UI
  bool _showPermissionUI = false;

  /// Gets the current camera permission state
  PermissionState get cameraPermissionState => _cameraPermissionState;

  /// Gets the current microphone permission state
  PermissionState get microphonePermissionState => _microphonePermissionState;

  /// Whether to show the permission UI
  bool get showPermissionUI => _showPermissionUI;

  /// Whether camera permission is granted
  bool get hasCameraPermission => _cameraPermissionState == PermissionState.granted;

  /// Whether microphone permission is granted
  bool get hasMicrophonePermission => _microphonePermissionState == PermissionState.granted;

  /// Whether all required permissions are granted
  bool get hasRequiredPermissions {
    final needsMicrophone = needsMicrophonePermission();

    if (needsMicrophone) {
      return hasCameraPermission && hasMicrophonePermission;
    }

    return hasCameraPermission;
  }

  /// Whether microphone permission is needed based on camera mode
  ///
  /// Returns false if:
  /// 1. Camera mode is photoOnly (regardless of requireMicrophoneForVideo)
  /// 2. requireMicrophoneForVideo is false
  bool needsMicrophonePermission() {
    // PhotoOnly mode should NEVER require microphone permissions
    if (cameraMode == CameraMode.photoOnly) {
      return false;
    }

    // For other modes, check the requireMicrophoneForVideo setting
    return requireMicrophoneForVideo;
  }

  /// Updates the camera mode and rechecks permissions if needed
  void updateCameraMode(CameraMode newMode) {
    if (cameraMode == newMode) return;

    bool permissionNeedsUpdate = false;

    // Check if we're switching to/from photo mode which affects audio permissions
    if ((newMode == CameraMode.photoOnly) != (cameraMode == CameraMode.photoOnly)) {
      permissionNeedsUpdate = true;
    }

    cameraMode = newMode;

    // If we need to update permissions, do it
    if (permissionNeedsUpdate) {
      _checkPermissions();
    }

    notifyListeners();
  }

  /// Checks the initial permission statuses
  Future<void> _checkInitialPermissions() async {
    await _updateCameraPermissionState();

    if (needsMicrophonePermission()) {
      await _updateMicrophonePermissionState();
    } else {
      // In photo-only mode, we never need microphone permissions
      // Reset microphone state to not determined
      _microphonePermissionState = PermissionState.notDetermined;
    }

    // Determine if we need to show the permission UI
    _updateShowPermissionUI();

    notifyListeners();
  }

  /// Requests all permissions needed for the current camera mode
  Future<bool> requestPermissions() async {
    _showPermissionUI = true;
    notifyListeners();

    // Request camera permission first
    final hasCameraAccess = await requestCameraPermission();

    // If camera permission is denied, no need to ask for microphone
    if (!hasCameraAccess) {
      _updateShowPermissionUI();
      notifyListeners();
      return false;
    }

    // Request microphone permission if needed
    if (needsMicrophonePermission()) {
      await requestMicrophonePermission();

      _updateShowPermissionUI();
      notifyListeners();

      // Return true only if both permissions are granted
      // Note that we still allow operation if microphone is denied but camera is granted
      return hasCameraAccess;
    }

    _updateShowPermissionUI();
    notifyListeners();
    return hasCameraAccess;
  }

  /// Requests camera permission
  Future<bool> requestCameraPermission() async {
    if (_cameraPermissionState == PermissionState.requesting || _cameraPermissionState == PermissionState.permanentlyDenied) {
      return hasCameraPermission;
    }

    _cameraPermissionState = PermissionState.requesting;
    notifyListeners();

    final status = await Permission.camera.request();
    await _updateCameraPermissionState(status: status);

    notifyListeners();
    return hasCameraPermission;
  }

  /// Requests microphone permission
  Future<bool> requestMicrophonePermission() async {
    // Never request microphone permission in photo-only mode
    if (cameraMode == CameraMode.photoOnly) {
      return true;
    }

    if (_microphonePermissionState == PermissionState.requesting || _microphonePermissionState == PermissionState.permanentlyDenied) {
      return hasMicrophonePermission;
    }

    _microphonePermissionState = PermissionState.requesting;
    notifyListeners();

    final status = await Permission.microphone.request();
    await _updateMicrophonePermissionState(status: status);

    notifyListeners();
    return hasMicrophonePermission;
  }

  /// Updates the camera permission state
  Future<void> _updateCameraPermissionState({PermissionStatus? status}) async {
    final permissionStatus = status ?? await Permission.camera.status;

    debugPrint('📸 Camera permission status: $permissionStatus');

    switch (permissionStatus) {
      case PermissionStatus.granted:
        _cameraPermissionState = PermissionState.granted;
        break;
      case PermissionStatus.denied:
        _cameraPermissionState = PermissionState.denied;
        break;
      case PermissionStatus.permanentlyDenied:
        _cameraPermissionState = PermissionState.permanentlyDenied;
        break;
      case PermissionStatus.restricted:
        _cameraPermissionState = PermissionState.restricted;
        break;
      case PermissionStatus.limited:
        // Treat limited as granted
        _cameraPermissionState = PermissionState.granted;
        break;
      case PermissionStatus.provisional:
        // Treat provisional as granted
        _cameraPermissionState = PermissionState.granted;
        break;
    }
  }

  /// Updates the microphone permission state
  Future<void> _updateMicrophonePermissionState({PermissionStatus? status}) async {
    // In photo-only mode, we skip microphone permission checking
    if (cameraMode == CameraMode.photoOnly) {
      _microphonePermissionState = PermissionState.notDetermined;
      return;
    }

    final permissionStatus = status ?? await Permission.microphone.status;

    debugPrint('🎤 Microphone permission status: $permissionStatus');

    switch (permissionStatus) {
      case PermissionStatus.granted:
        _microphonePermissionState = PermissionState.granted;
        break;
      case PermissionStatus.denied:
        _microphonePermissionState = PermissionState.denied;
        break;
      case PermissionStatus.permanentlyDenied:
        _microphonePermissionState = PermissionState.permanentlyDenied;
        break;
      case PermissionStatus.restricted:
        _microphonePermissionState = PermissionState.restricted;
        break;
      case PermissionStatus.limited:
        // Treat limited as granted
        _microphonePermissionState = PermissionState.granted;
        break;
      case PermissionStatus.provisional:
        // Treat provisional as granted
        _microphonePermissionState = PermissionState.granted;
        break;
    }
  }

  /// Checks the current permission states
  Future<void> _checkPermissions() async {
    await _updateCameraPermissionState();

    if (needsMicrophonePermission()) {
      await _updateMicrophonePermissionState();
    } else {
      // Reset microphone state when not needed
      _microphonePermissionState = PermissionState.notDetermined;
    }

    _updateShowPermissionUI();
    notifyListeners();
  }

  /// Determines whether to show the permission UI
  void _updateShowPermissionUI() {
    // Show permission UI if camera permission is not granted
    if (_cameraPermissionState != PermissionState.granted) {
      _showPermissionUI = true;
      return;
    }

    // If we need microphone permission and it's not granted, still show UI
    if (needsMicrophonePermission() && _microphonePermissionState != PermissionState.granted && _microphonePermissionState != PermissionState.notDetermined) {
      _showPermissionUI = true;
      return;
    }

    // Otherwise, hide the permission UI
    _showPermissionUI = false;
  }

  /// Opens the app settings page
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Forces rechecking of permissions
  Future<void> refreshPermissions() async {
    await _checkPermissions();
  }

  /// Dismisses the permission UI (for "Continue without microphone" scenario)
  void dismissPermissionUI() {
    _showPermissionUI = false;
    notifyListeners();
  }
}
