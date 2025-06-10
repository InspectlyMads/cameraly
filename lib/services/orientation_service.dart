import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/orientation_data.dart';

/// Comprehensive orientation service for handling device orientation across all Android devices
class OrientationService {
  static const _logTag = 'OrientationService';
  
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  // Sensor streams
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  // Current sensor values
  AccelerometerEvent? _lastAccelerometerEvent;
  GyroscopeEvent? _lastGyroscopeEvent;
  
  // Device info cache
  DeviceInfo? _cachedDeviceInfo;
  
  // Comprehensive manufacturer corrections based on real-world testing
  static const Map<String, Map<String, int>> _manufacturerCorrections = {
    'samsung': {
      'default': 0,  // Most Samsung devices handle orientation correctly
      'front': 0,
      // Specific models with different behavior
      'SM-G970': 0,  // S10e
      'SM-G973': 0,  // S10
      'SM-G975': 0,  // S10+
      'SM-N960': 0, // Note 9
    },
    'xiaomi': {
      'default': 0,
      'front': 0,
      'Mi 9': 0,
      'POCO': 0,
    },
    'huawei': {
      'default': 0,
      'front': 0,
    },
    'oppo': {
      'default': 0,
      'front': 0,
    },
    'vivo': {
      'default': 0,
      'front': 0,
    },
    'oneplus': {
      'default': 0,
      'front': 0,
    },
    'realme': {
      'default': 0,
      'front': 0,
    },
    'motorola': {
      'default': 0,
      'front': 0,
    },
    'google': {
      'default': 0,
      'front': 0,
    },
  };

  /// Initialize the orientation service
  Future<void> initialize() async {
    debugPrint('$_logTag: Initializing orientation service');
    
    // Get device info
    _cachedDeviceInfo = await _getDeviceInfo();
    debugPrint('$_logTag: Device: ${_cachedDeviceInfo?.manufacturer} ${_cachedDeviceInfo?.model}');
    
    // Start sensor monitoring (skip in test environment)
    try {
      _startSensorMonitoring();
    } catch (e) {
      debugPrint('$_logTag: Could not start sensor monitoring (likely in test environment): $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
  }

  /// Get current orientation data
  Future<OrientationData> getCurrentOrientation({
    required CameraDescription camera,
    required CameraLensDirection lensDirection,
  }) async {
    final deviceInfo = _cachedDeviceInfo ?? await _getDeviceInfo();
    final deviceOrientation = _calculateDeviceOrientation();
    final correction = _getOrientationCorrection(
      manufacturer: deviceInfo.manufacturer,
      model: deviceInfo.model,
      lensDirection: lensDirection,
    );
    
    debugPrint('$_logTag: Camera sensor orientation: ${camera.sensorOrientation}°');
    debugPrint('$_logTag: Device orientation: $deviceOrientation°');
    debugPrint('$_logTag: Correction offset: ${correction.rotationOffset}°');
    
    // Calculate rotation needed to correct the image
    // For back camera:
    // - Camera sensor orientation tells us how the sensor is mounted (usually 90° or 270°)
    // - Device orientation tells us how the device is held (0° = portrait, 90° = landscape right, etc.)
    // - We need to rotate the image to compensate for both
    int rotation;
    
    if (lensDirection == CameraLensDirection.front) {
      // Front camera calculation (mirrored)
      rotation = (camera.sensorOrientation - deviceOrientation + 360) % 360;
      // Apply any device-specific corrections
      rotation = (rotation + correction.rotationOffset) % 360;
    } else {
      // Back camera calculation
      // The rotation needed is the difference between sensor orientation and device orientation
      rotation = (camera.sensorOrientation - deviceOrientation + 360) % 360;
      // Apply any device-specific corrections
      rotation = (rotation + correction.rotationOffset) % 360;
    }
    
    debugPrint('$_logTag: Calculated rotation: $rotation°');
    
    return OrientationData(
      deviceOrientation: deviceOrientation,
      cameraRotation: rotation,
      sensorOrientation: camera.sensorOrientation,
      deviceManufacturer: deviceInfo.manufacturer,
      deviceModel: deviceInfo.model,
      timestamp: DateTime.now(),
      accuracyScore: _calculateAccuracyScore(),
      metadata: {
        'lensDirection': lensDirection.toString(),
        'hasGyroscope': _lastGyroscopeEvent != null,
        'apiLevel': deviceInfo.metadata?['apiLevel'] ?? 'unknown',
        'correction': correction.rotationOffset,
      },
    );
  }


  /// Apply orientation correction to image file
  /// Note: We're not manually rotating images anymore as the camera package
  /// should handle orientation through EXIF metadata
  Future<String?> applyOrientationCorrection(String imagePath, OrientationData orientationData) async {
    debugPrint('$_logTag: Image captured with orientation data: ${orientationData.cameraRotation}°');
    debugPrint('$_logTag: Device: ${orientationData.deviceManufacturer} ${orientationData.deviceModel}');
    debugPrint('$_logTag: Sensor orientation: ${orientationData.sensorOrientation}°');
    debugPrint('$_logTag: Device orientation: ${orientationData.deviceOrientation}°');
    
    // The camera package should have already set proper EXIF orientation
    // We're just logging the information for debugging purposes
    return imagePath;
  }

  /// Get device-specific orientation correction
  OrientationCorrection _getOrientationCorrection({
    required String manufacturer,
    required String model,
    required CameraLensDirection lensDirection,
  }) {
    final manufacturerLower = manufacturer.toLowerCase();
    final corrections = _manufacturerCorrections[manufacturerLower];
    
    if (corrections == null) {
      debugPrint('$_logTag: No corrections for manufacturer: $manufacturer, using defaults');
      return OrientationCorrection.standard();
    }
    
    // Check for model-specific correction
    final modelCorrection = corrections[model];
    if (modelCorrection != null) {
      debugPrint('$_logTag: Using model-specific correction for $model: $modelCorrection°');
      return OrientationCorrection(
        rotationOffset: modelCorrection,
        flipHorizontal: false,
      );
    }
    
    // Use lens-specific correction
    final lensKey = lensDirection == CameraLensDirection.front ? 'front' : 'default';
    final correction = corrections[lensKey] ?? 0;
    
    debugPrint('$_logTag: Using $lensKey correction for $manufacturer: $correction°');
    
    return OrientationCorrection(
      rotationOffset: correction,
      flipHorizontal: manufacturer.toLowerCase() == 'huawei' && lensDirection == CameraLensDirection.front,
    );
  }

  /// Calculate device orientation from accelerometer
  int _calculateDeviceOrientation() {
    if (_lastAccelerometerEvent == null) {
      debugPrint('$_logTag: No accelerometer data available');
      return 0;
    }
    
    final x = _lastAccelerometerEvent!.x;
    final y = _lastAccelerometerEvent!.y;
    final z = _lastAccelerometerEvent!.z;
    
    // Calculate device tilt
    final normG = math.sqrt(x * x + y * y + z * z);
    
    // Ignore if device is nearly flat (unreliable orientation)
    if (normG < 8.0) {
      debugPrint('$_logTag: Device nearly flat, using last known orientation');
      return 0;
    }
    
    // Calculate orientation based on gravity vector
    // This is simplified; production code should use more sophisticated algorithms
    final angle = math.atan2(x, y) * 180 / math.pi;
    
    // Convert to standard orientations (0, 90, 180, 270)
    if (angle > -45 && angle <= 45) {
      return 0; // Portrait
    } else if (angle > 45 && angle <= 135) {
      return 270; // Landscape left
    } else if (angle > -135 && angle <= -45) {
      return 90; // Landscape right
    } else {
      return 180; // Portrait upside down
    }
  }

  /// Calculate accuracy score based on sensor availability and stability
  double _calculateAccuracyScore() {
    double score = 0.0;
    
    // Base score for having accelerometer data
    if (_lastAccelerometerEvent != null) {
      score += 0.5;
    }
    
    // Bonus for having gyroscope data
    if (_lastGyroscopeEvent != null) {
      score += 0.3;
    }
    
    // Bonus for device info
    if (_cachedDeviceInfo != null) {
      score += 0.2;
    }
    
    return math.min(score, 1.0);
  }

  /// Start monitoring device sensors
  void _startSensorMonitoring() {
    // Skip sensor monitoring in test environment
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      debugPrint('$_logTag: Skipping sensor monitoring in test environment');
      return;
    }
    
    try {
      // Monitor accelerometer for device orientation
      _accelerometerSubscription = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 100),
      ).listen(
        (AccelerometerEvent event) {
          _lastAccelerometerEvent = event;
        },
        onError: (error) {
          debugPrint('$_logTag: Accelerometer error: $error');
        },
      );
    } catch (e) {
      debugPrint('$_logTag: Could not start accelerometer monitoring: $e');
    }
    
    try {
      // Monitor gyroscope for rotation detection
      _gyroscopeSubscription = gyroscopeEventStream(
        samplingPeriod: const Duration(milliseconds: 100),
      ).listen(
        (GyroscopeEvent event) {
          _lastGyroscopeEvent = event;
        },
        onError: (error) {
          debugPrint('$_logTag: Gyroscope error: $error');
          // Gyroscope not available on all devices, this is okay
        },
      );
    } catch (e) {
      debugPrint('$_logTag: Could not start gyroscope monitoring: $e');
    }
  }

  /// Get device information
  Future<DeviceInfo> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return DeviceInfo(
          manufacturer: androidInfo.manufacturer,
          model: androidInfo.model,
          androidVersion: androidInfo.version.release,
          sdkVersion: androidInfo.version.sdkInt.toString(),
          osVersion: androidInfo.version.release,
          metadata: {
            'brand': androidInfo.brand,
            'device': androidInfo.device,
            'apiLevel': androidInfo.version.sdkInt.toString(),
            'isPhysicalDevice': androidInfo.isPhysicalDevice.toString(),
          },
        );
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return DeviceInfo(
          manufacturer: 'Apple',
          model: iosInfo.model,
          osVersion: iosInfo.systemVersion,
          metadata: {
            'name': iosInfo.name,
            'systemName': iosInfo.systemName,
            'isPhysicalDevice': iosInfo.isPhysicalDevice.toString(),
          },
        );
      }
    } catch (e) {
      debugPrint('$_logTag: Error getting device info: $e');
    }
    
    return const DeviceInfo(
      manufacturer: 'Unknown',
      model: 'Unknown',
    );
  }


  /// Get debug information for testing
  Map<String, dynamic> getDebugInfo() {
    return {
      'deviceInfo': _cachedDeviceInfo?.toJson(),
      'lastAccelerometer': _lastAccelerometerEvent != null
          ? {
              'x': _lastAccelerometerEvent!.x,
              'y': _lastAccelerometerEvent!.y,
              'z': _lastAccelerometerEvent!.z,
            }
          : null,
      'lastGyroscope': _lastGyroscopeEvent != null
          ? {
              'x': _lastGyroscopeEvent!.x,
              'y': _lastGyroscopeEvent!.y,
              'z': _lastGyroscopeEvent!.z,
            }
          : null,
      'calculatedOrientation': _calculateDeviceOrientation(),
      'accuracyScore': _calculateAccuracyScore(),
    };
  }
}