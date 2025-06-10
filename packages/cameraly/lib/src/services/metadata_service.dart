import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/photo_metadata.dart';

/// Service for capturing comprehensive metadata for photos
class MetadataService {
  // Cached data for performance
  Position? _lastPosition;
  DateTime? _lastLocationUpdate;
  StreamSubscription<Position>? _positionSubscription;
  
  // Device info (cached on first use)
  AndroidDeviceInfo? _androidInfo;
  IosDeviceInfo? _iosInfo;
  String? _osVersion;
  
  // Sensor data
  AccelerometerEvent? _lastAccelerometerEvent;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  // Update intervals
  static const _locationUpdateInterval = Duration(seconds: 30);
  static const _locationDistanceFilter = 10.0; // meters
  
  // Track if location capture is enabled
  bool _captureLocationEnabled = false;
  
  /// Initialize the metadata service
  Future<void> initialize({bool captureLocation = true}) async {
    _captureLocationEnabled = captureLocation;
    
    if (captureLocation) {
      // Check location permission
      var permission = await Geolocator.checkPermission();
      
      // Request permission if not granted
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      // Only proceed if permission is granted
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        // Get initial location
        await _updateLocation();
        
        // Start listening to location updates
        _startLocationUpdates();
      }
    }
    
    // Start listening to accelerometer
    _startAccelerometerUpdates();
    
    // Cache device info
    await _cacheDeviceInfo();
  }
  
  /// Dispose of resources
  void dispose() {
    _positionSubscription?.cancel();
    _accelerometerSubscription?.cancel();
  }
  
  /// Capture current metadata for a photo
  Future<PhotoMetadata> captureMetadata({
    required CameraController cameraController,
    required DateTime captureStartTime,
    required String cameraName,
    double? zoomLevel,
    String? flashMode,
    String? photographer,
    String? copyright,
    String? description,
    List<String>? tags,
    Map<String, dynamic>? customData,
  }) async {
    final captureEndTime = DateTime.now();
    final captureTimeMillis = captureEndTime.difference(captureStartTime).inMilliseconds;
    
    // Ensure we have recent location data if enabled
    if (_captureLocationEnabled && _shouldUpdateLocation()) {
      await _updateLocation();
    }
    
    // Get device info
    final deviceInfo = await _getDeviceInfo();
    
    // Get camera info
    final lensDirection = cameraController.description.lensDirection == CameraLensDirection.front ? 'front' : 'back';
    
    // Build metadata
    return PhotoMetadata(
      // Location data (only if enabled)
      latitude: _captureLocationEnabled ? _lastPosition?.latitude : null,
      longitude: _captureLocationEnabled ? _lastPosition?.longitude : null,
      altitude: _captureLocationEnabled ? _lastPosition?.altitude : null,
      speed: _captureLocationEnabled ? _lastPosition?.speed : null,
      speedAccuracy: _captureLocationEnabled ? _lastPosition?.speedAccuracy : null,
      heading: _captureLocationEnabled ? _lastPosition?.heading : null,
      headingAccuracy: _captureLocationEnabled ? _lastPosition?.headingAccuracy : null,
      accuracy: _captureLocationEnabled ? _lastPosition?.accuracy : null,
      
      // Device info
      deviceManufacturer: deviceInfo['manufacturer'] ?? 'Unknown',
      deviceModel: deviceInfo['model'] ?? 'Unknown',
      osVersion: _osVersion ?? 'Unknown',
      
      // Camera settings
      cameraName: cameraName,
      lensDirection: lensDirection,
      zoomLevel: zoomLevel,
      flashMode: flashMode,
      
      // Accelerometer data
      deviceTiltX: _lastAccelerometerEvent?.x,
      deviceTiltY: _lastAccelerometerEvent?.y,
      deviceTiltZ: _lastAccelerometerEvent?.z,
      
      // Timestamps
      capturedAt: captureEndTime,
      captureTimeMillis: captureTimeMillis,
      
      // Additional info
      photographer: photographer,
      copyright: copyright,
      description: description,
      tags: tags,
      customData: customData,
    );
  }
  
  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }
  
  /// Request location permission
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Open app settings
      await Geolocator.openAppSettings();
      return false;
    }
    
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }
  
  /// Update current location
  Future<void> _updateLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }
      
      _lastPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      _lastLocationUpdate = DateTime.now();
    } catch (e) {
      // Silently fail if location cannot be obtained
    }
  }
  
  /// Start listening to location updates
  void _startLocationUpdates() {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _locationDistanceFilter.toInt(),
    );
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _lastPosition = position;
        _lastLocationUpdate = DateTime.now();
      },
      onError: (e) {
        // Silently handle errors
      },
    );
  }
  
  /// Start listening to accelerometer updates
  void _startAccelerometerUpdates() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        _lastAccelerometerEvent = event;
      },
      onError: (e) {
        // Silently handle errors
      },
    );
  }
  
  /// Check if we should update location
  bool _shouldUpdateLocation() {
    if (_lastPosition == null || _lastLocationUpdate == null) {
      return true;
    }
    
    final timeSinceLastUpdate = DateTime.now().difference(_lastLocationUpdate!);
    return timeSinceLastUpdate > _locationUpdateInterval;
  }
  
  /// Cache device info
  Future<void> _cacheDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      _androidInfo = await deviceInfo.androidInfo;
      _osVersion = 'Android ${_androidInfo!.version.release}';
    } else if (Platform.isIOS) {
      _iosInfo = await deviceInfo.iosInfo;
      _osVersion = 'iOS ${_iosInfo!.systemVersion}';
    }
  }
  
  /// Get device info
  Future<Map<String, String>> _getDeviceInfo() async {
    if (_androidInfo != null) {
      return {
        'manufacturer': _androidInfo!.manufacturer,
        'model': _androidInfo!.model,
      };
    } else if (_iosInfo != null) {
      return {
        'manufacturer': 'Apple',
        'model': _iosInfo!.model,
      };
    }
    
    return {
      'manufacturer': 'Unknown',
      'model': 'Unknown',
    };
  }
}