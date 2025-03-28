import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A utility class to help track and debug camera state changes
class CameraLogger {
  static final CameraLogger _instance = CameraLogger._internal();
  factory CameraLogger() => _instance;
  CameraLogger._internal();

  // Flags to track operations
  bool _isInitializingCamera = false;
  bool _isChangingOrientation = false;
  DateTime? _lastOrientationChange;
  DateTime? _lastLog;

  // Maximum logs per interval
  static const int _maxLogsPerInterval = 5;
  static const int _logIntervalMs = 1000;
  int _logCount = 0;

  /// Track if camera is currently being initialized
  bool get isInitializingCamera => _isInitializingCamera;
  set isInitializingCamera(bool value) {
    _isInitializingCamera = value;
    if (value) {
      _log("🎬 CAMERA INIT STARTED", LogLevel.info);
    } else {
      _log("🎬 CAMERA INIT COMPLETED", LogLevel.info);
    }
  }

  /// Track if orientation is changing
  bool get isChangingOrientation => _isChangingOrientation;
  set isChangingOrientation(bool value) {
    _isChangingOrientation = value;
    if (value) {
      _lastOrientationChange = DateTime.now();
      _log("🔄 ORIENTATION CHANGE STARTED", LogLevel.info);
    } else {
      _log("🔄 ORIENTATION CHANGE COMPLETED", LogLevel.info);
    }
  }

  /// Check if orientation change is allowed
  bool canChangeOrientation() {
    if (_isChangingOrientation) {
      _log("🔄 Orientation change already in progress", LogLevel.warning);
      return false;
    }

    if (_lastOrientationChange != null) {
      final elapsed = DateTime.now().difference(_lastOrientationChange!).inMilliseconds;
      if (elapsed < 2000) {
        _log("🔄 Orientation change too soon (${elapsed}ms), ignoring", LogLevel.warning);
        return false;
      }
    }

    return true;
  }

  /// Reset all flags and tracking
  void reset() {
    _isInitializingCamera = false;
    _isChangingOrientation = false;
    _log("🔄 Camera tracking reset", LogLevel.info);
  }

  /// Get the current orientation
  Future<DeviceOrientation> getCurrentOrientation() async {
    try {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final size = view.physicalSize;
      final isLandscape = size.width > size.height;

      if (isLandscape) {
        return DeviceOrientation.landscapeRight;
      } else {
        return DeviceOrientation.portraitUp;
      }
    } catch (e) {
      _log("🔄 Error getting orientation: $e", LogLevel.error);
      return DeviceOrientation.portraitUp;
    }
  }

  /// Log a message with throttling to prevent log spam
  void _log(String message, LogLevel level) {
    final now = DateTime.now();

    // Reset log count after interval
    if (_lastLog != null && now.difference(_lastLog!).inMilliseconds > _logIntervalMs) {
      _logCount = 0;
    }

    // Skip logs if too many in short time
    if (_logCount >= _maxLogsPerInterval) {
      return;
    }

    _lastLog = now;
    _logCount++;

    switch (level) {
      case LogLevel.info:
        debugPrint(message);
        break;
      case LogLevel.warning:
        debugPrint('⚠️ $message');
        break;
      case LogLevel.error:
        debugPrint('❌ $message');
        break;
    }
  }
}

/// Log levels for the camera logger
enum LogLevel { info, warning, error }
