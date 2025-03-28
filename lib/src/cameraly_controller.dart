import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_exif/native_exif.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

import 'cameraly_value.dart';
import 'types/camera_mode.dart';
import 'types/capture_settings.dart';
import 'utils/media_manager.dart';
import 'utils/orientation_channel.dart';

/// Controller for the Cameraly camera interface.
class CameralyController extends ValueNotifier<CameralyValue> with WidgetsBindingObserver {
  /// Creates a new controller instance.
  CameralyController({required CameraDescription description, CaptureSettings? settings, CameralyMediaManager? mediaManager, CameralyMediaManager? existingMediaManager})
      : _description = description,
        _settings = settings ?? const CaptureSettings(),
        _mediaManager = existingMediaManager ?? mediaManager ?? CameralyMediaManager(),
        super(const CameralyValue.uninitialized()) {
    // Register as an observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  final CameraDescription _description;
  final CaptureSettings _settings;
  final CameralyMediaManager _mediaManager;
  CameraController? _controller;
  Timer? _recordingTimer;
  DateTime? _recordingStartTime;
  bool _isDisposing = false;
  bool _isResuming = false;

  /// The camera description this controller is using
  CameraDescription get description => _description;

  /// The current settings being used
  CaptureSettings get settings => _settings;

  /// Whether the controller has been initialized
  bool get isInitialized => value.isInitialized;

  /// The underlying camera controller
  CameraController? get cameraController => _controller;

  /// The media manager for handling captured photos and videos
  CameralyMediaManager get mediaManager => _mediaManager;

  // Location tracking
  Position? _lastKnownLocation;
  DateTime? _lastLocationTime;
  bool _isGettingLocation = false;

  /// Gets the current location if enabled in settings.
  ///
  /// Returns the current location or null if location services are disabled,
  /// permission is denied, or location retrieval fails.
  Future<Position?> _getCurrentLocation() async {
    // Skip if location metadata is not enabled
    if (!_settings.addLocationMetadata) {
      return null;
    }

    // Avoid concurrent location requests
    if (_isGettingLocation) {
      return _lastKnownLocation;
    }

    // Check if we have a recent location (within last 30 seconds)
    final now = DateTime.now();
    if (_lastKnownLocation != null && _lastLocationTime != null) {
      final locationAge = now.difference(_lastLocationTime!);
      if (locationAge.inSeconds < 30) {
        return _lastKnownLocation;
      }
    }

    _isGettingLocation = true;

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        _isGettingLocation = false;
        return null;
      }

      // Check for location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          _isGettingLocation = false;
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        _isGettingLocation = false;
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _settings.locationAccuracy,
      );

      // Store for caching
      _lastKnownLocation = position;
      _lastLocationTime = now;

      debugPrint('📍 Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    } finally {
      _isGettingLocation = false;
    }
  }

  /// Adds location metadata to an image file if location services are enabled.
  ///
  /// This adds GPS latitude, longitude, altitude, and timestamp to the EXIF data.
  Future<XFile> _addLocationMetadataToImage(XFile imageFile, Position? location) async {
    // Skip if no location data or location metadata is disabled
    if (location == null || !_settings.addLocationMetadata) {
      return imageFile;
    }

    try {
      // Initialize native exif editor
      final exif = await Exif.fromPath(imageFile.path);

      // Format latitude according to EXIF standards (DMS format)
      final latitude = location.latitude;
      final latDegrees = latitude.abs().floor();
      final latMinutes = ((latitude.abs() - latDegrees) * 60).floor();
      final latSeconds = ((latitude.abs() - latDegrees - latMinutes / 60) * 3600).round();

      // Format longitude according to EXIF standards (DMS format)
      final longitude = location.longitude;
      final longDegrees = longitude.abs().floor();
      final longMinutes = ((longitude.abs() - longDegrees) * 60).floor();
      final longSeconds = ((longitude.abs() - longDegrees - longMinutes / 60) * 3600).round();

      // Set latitude values
      await exif.writeAttribute('GPSLatitudeRef', latitude >= 0 ? 'N' : 'S');
      await exif.writeAttribute('GPSLatitude', '$latDegrees/1,$latMinutes/1,$latSeconds/100');

      // Set longitude values
      await exif.writeAttribute('GPSLongitudeRef', longitude >= 0 ? 'E' : 'W');
      await exif.writeAttribute('GPSLongitude', '$longDegrees/1,$longMinutes/1,$longSeconds/100');

      // Add altitude if available
      if (location.altitude != 0) {
        await exif.writeAttribute('GPSAltitudeRef', '0'); // 0 = above sea level
        await exif.writeAttribute('GPSAltitude', '${location.altitude.abs().round()}/1');
      }

      // Add timestamp
      final now = DateTime.now();
      await exif.writeAttribute('GPSDateStamp', '${now.year}:${now.month.toString().padLeft(2, '0')}:${now.day.toString().padLeft(2, '0')}');
      await exif.writeAttribute('GPSTimeStamp', '${now.hour}/1,${now.minute}/1,${now.second}/1');

      // Save the updated EXIF data
      // No need to call saveAttributes as writeAttribute already saves

      // Close the exif interface
      await exif.close();

      debugPrint('📍 Added location metadata to image: ${location.latitude}, ${location.longitude}');
      return imageFile;
    } catch (e) {
      debugPrint('Error adding location metadata: $e');
      // Return the original file if adding metadata fails
      return imageFile;
    }
  }

  /// Gets a list of available cameras on the device.
  ///
  /// This is a convenience method to avoid importing the camera package directly.
  static Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      // Get cameras from the camera plugin
      final List<CameraDescription> cameras = await availableCameras();

      if (cameras.isEmpty) {
        debugPrint('📸 No cameras found by availableCameras()');
      } else {
        debugPrint('📸 Found ${cameras.length} cameras via availableCameras()');
        for (int i = 0; i < cameras.length; i++) {
          final camera = cameras[i];
          debugPrint('📸 Camera $i: ${camera.name}, direction: ${camera.lensDirection}, sensorOrientation: ${camera.sensorOrientation}');
        }
      }

      return cameras;
    } catch (e) {
      debugPrint('📸 Error getting available cameras: $e');
      return [];
    }
  }

  /// Creates and initializes a CameralyController with the first available camera.
  ///
  /// This is a convenience method that:
  /// 1. Gets available cameras
  /// 2. Creates a controller with the first camera (or specified cameraIndex)
  /// 3. Initializes the controller
  ///
  /// Returns null if no cameras are available or initialization fails.
  ///
  /// Example usage:
  /// ```dart
  /// // For photo mode
  /// final controller = await CameralyController.initializeCamera(
  ///   settings: CaptureSettings(cameraMode: CameraMode.photoOnly)
  /// );
  ///
  /// // For video mode
  /// final controller = await CameralyController.initializeCamera(
  ///   settings: CaptureSettings(cameraMode: CameraMode.videoOnly, enableAudio: true)
  /// );
  ///
  /// // For both photos and videos
  /// final controller = await CameralyController.initializeCamera();
  /// ```
  static Future<CameralyController?> initializeCamera({int cameraIndex = 0, CaptureSettings? settings, bool enableFallback = true}) async {
    try {
      // Get available cameras
      final cameras = await getAvailableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        return null;
      }

      // Make sure the camera index is valid
      if (cameraIndex >= cameras.length) {
        debugPrint('Camera index out of range, using first camera');
        cameraIndex = 0;
      }

      // Create controller with the selected camera
      final controller = CameralyController(description: cameras[cameraIndex], settings: settings);

      // Initialize the controller with fallback if enabled
      if (enableFallback) {
        await controller.initializeWithFallback();
      } else {
        await controller.initialize();
      }

      return controller;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      return null;
    }
  }

  /// Initializes the camera controller.
  ///
  /// Note: This method no longer handles permissions. Permissions should be
  /// handled by CameralyPermissionManager before calling initialize.
  Future<void> initialize() async {
    try {
      debugPrint('📸 Initializing camera with mode: ${_settings.cameraMode}');
      debugPrint('📸 Audio enabled: ${_settings.enableAudio}');

      _controller = CameraController(_description, _settings.resolution, enableAudio: _settings.enableAudio);

      await _controller!.initialize();

      // Listen for camera value changes to update our value
      _controller!.addListener(_updateValueFromController);

      // Set initial orientation for Android
      if (Platform.isAndroid) {
        await handleDeviceOrientationChange();
      }

      // Default to assuming flash is available, we'll update this if we detect otherwise
      bool hasFlashCapability = true;

      // Get the current device orientation - we'll update this after initialization
      // but we need a default value for now
      final deviceOrientation = _settings.deviceOrientation;

      // IMPORTANT: Properly determine if this is a front camera based on lens direction
      final bool isFrontCamera = _description.lensDirection == CameraLensDirection.front;
      debugPrint('📸 Is front camera? $isFrontCamera (based on lens direction: ${_description.lensDirection})');

      // Create initialization value but don't notify listeners yet
      final initialValue = CameralyValue(
        isInitialized: true,
        flashMode: _settings.flashMode,
        exposureMode: _settings.exposureMode,
        focusMode: _settings.focusMode,
        deviceOrientation: deviceOrientation,
        permissionState: CameraPermissionState.granted,
        isFrontCamera: isFrontCamera,
        zoomLevel: 1.0,
        hasFlashCapability: hasFlashCapability,
      );

      // Temporarily set value without notification
      value = initialValue;

      // Apply initial settings
      // Try to set flash mode, but handle gracefully if it fails
      try {
        await setFlashMode(_settings.flashMode);
      } catch (e) {
        debugPrint('Failed to set initial flash mode: $e');
        // If we get an error setting flash mode, update our state to indicate no flash capability
        if (e.toString().toLowerCase().contains('flash') || e.toString().toLowerCase().contains('torch')) {
          value = value.copyWith(hasFlashCapability: false);
        }
      }

      await setExposureMode(_settings.exposureMode);
      await setFocusMode(_settings.focusMode);

      // Get the actual zoom level after initialization
      try {
        final zoom = await _controller!.getMaxZoomLevel();
        if (zoom > 1.0) {
          // Only update if we got a valid zoom level
          value = value.copyWith(zoomLevel: 1.0);
        }
      } catch (e) {
        // Ignore zoom errors during initialization
      }

      // Minimal delay to reduce flickering during initialization
      await Future.delayed(const Duration(milliseconds: 30));

      // Final value update with notification
      notifyListeners();
    } on CameraException catch (e) {
      value = value.copyWith(error: 'Failed to initialize camera: ${e.description}');
      rethrow;
    }
  }

  // Add a static variable to lock camera recreation during orientation changes
  static bool _isHandlingOrientation = false;

  /// Handles device orientation changes.
  ///
  /// This method is called when the device orientation changes and updates
  /// the camera preview to match the new orientation.
  Future<void> handleDeviceOrientationChange() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('📸 Cannot handle orientation change: Controller not ready');
      return;
    }

    // Check if we're already handling an orientation change
    if (_isHandlingOrientation) {
      debugPrint('📸 Orientation change already in progress, ignoring duplicate');
      return;
    }

    _isHandlingOrientation = true;

    try {
      final newOrientation = await _getDeviceOrientation();

      debugPrint('📸 Handling device orientation change: $newOrientation');

      // First update our local value
      value = value.copyWith(deviceOrientation: newOrientation);

      // Check again if controller is still valid before proceeding
      if (_controller == null) {
        debugPrint('📸 Controller became null during orientation change');
        _isHandlingOrientation = false;
        return;
      }

      // On Android, handle the orientation change explicitly
      if (Platform.isAndroid) {
        try {
          // Use a small delay before locking orientation to avoid freezing
          await Future.delayed(const Duration(milliseconds: 100));

          // Check again for null controller after delay
          if (_controller == null) {
            debugPrint('📸 Controller became null during orientation change delay');
            _isHandlingOrientation = false;
            return;
          }

          await setDeviceOrientation(newOrientation);

          // Force camera resume to fix freezing issues on Android
          await Future.delayed(const Duration(milliseconds: 300));

          // Verify controller is still valid before attempting resume
          if (_controller == null) {
            debugPrint('📸 Controller became null before camera resume');
            _isHandlingOrientation = false;
            return;
          }

          await handleCameraResume();
        } catch (e) {
          debugPrint('❌ Error setting device orientation on Android: $e');
        }
      } else {
        // For iOS, just set the orientation
        try {
          await setDeviceOrientation(newOrientation);
        } catch (e) {
          debugPrint('❌ Error setting device orientation on iOS: $e');
        }
      }
    } finally {
      _isHandlingOrientation = false;
    }
  }

  /// Updates the value notifier based on the underlying camera controller's value.
  void _updateValueFromController() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      // Get current values from the controller
      final cameraValue = _controller!.value;

      // IMPORTANT: Maintain the isFrontCamera value based on lens direction
      // This ensures it stays correct even during controller updates
      final isFrontCamera = _description.lensDirection == CameraLensDirection.front;

      // Update our value object with current state from the controller
      // Note: we don't update all properties because some are managed by this wrapper
      value = value.copyWith(
        isInitialized: cameraValue.isInitialized,
        isTakingPicture: cameraValue.isTakingPicture,
        isRecordingVideo: cameraValue.isRecordingVideo,
        isRecordingPaused: cameraValue.isRecordingPaused,
        // Keep our explicitly set values for these properties
        flashMode: value.flashMode,
        exposureMode: value.exposureMode,
        focusMode: value.focusMode,
        isFrontCamera: isFrontCamera, // Use lens direction as the source of truth
      );
    } catch (e) {
      debugPrint('📸 Error updating value from controller: $e');
      // Don't update the value in case of error
    }
  }

  /// Takes a picture and adds it to the media manager
  ///
  /// Returns the [XFile] of the captured picture
  Future<XFile> takePicture() async {
    if (!value.isInitialized) {
      throw CameraException(
        'cameraly_not_initialized',
        'Cannot take picture. CameralyController is not initialized.',
      );
    }

    if (value.isTakingPicture) {
      throw CameraException(
        'picture_in_progress',
        'Cannot take another picture while one is already in progress.',
      );
    }

    value = value.copyWith(isTakingPicture: true);

    try {
      // Take the picture
      final XFile pictureFile = await _controller!.takePicture();

      // Process the image file (compression according to settings)
      final XFile processedFile = await _processImageFile(pictureFile);

      // Add the captured media to the media manager
      _mediaManager.addMedia(processedFile, isVideo: false);

      value = value.copyWith(isTakingPicture: false, lastCapturedPhoto: processedFile);
      return processedFile;
    } on CameraException {
      value = value.copyWith(isTakingPicture: false);
      rethrow;
    }
  }

  /// Processes and compresses an image file based on the resolution settings
  Future<XFile> _processImageFile(XFile originalFile) async {
    try {
      // Skip compression if set to none
      if (_settings.compressionQuality == CompressionQuality.none) {
        debugPrint('📸 Skipping image compression (compressionQuality = none)');
        return originalFile;
      }

      // Map resolution preset to target dimensions based on compression quality
      int targetWidth;
      int targetHeight;
      int quality;

      // Determine quality setting
      switch (_settings.compressionQuality) {
        case CompressionQuality.light:
          quality = _settings.imageQuality.clamp(85, 95);
          break;
        case CompressionQuality.medium:
          quality = _settings.imageQuality.clamp(75, 85);
          break;
        case CompressionQuality.high:
          quality = _settings.imageQuality.clamp(60, 75);
          break;
        case CompressionQuality.auto:
          // Auto quality based on resolution
          switch (_settings.resolution) {
            case ResolutionPreset.low:
              quality = 75;
              break;
            case ResolutionPreset.medium:
              quality = 80;
              break;
            case ResolutionPreset.high:
              quality = 85;
              break;
            case ResolutionPreset.veryHigh:
              quality = 90;
              break;
            case ResolutionPreset.ultraHigh:
            case ResolutionPreset.max:
              quality = 95;
              break;
          }
          break;
        case CompressionQuality.none:
          // This should not happen as we check for this earlier
          quality = _settings.imageQuality;
          break;
      }

      // Determine target dimensions based on resolution and compression
      switch (_settings.resolution) {
        case ResolutionPreset.low:
          targetWidth = 640;
          targetHeight = 480;
          break;
        case ResolutionPreset.medium:
          targetWidth = 1280;
          targetHeight = 720;
          break;
        case ResolutionPreset.high:
          targetWidth = 1920;
          targetHeight = 1080;
          break;
        case ResolutionPreset.veryHigh:
          targetWidth = 2560;
          targetHeight = 1440;
          break;
        case ResolutionPreset.ultraHigh:
          targetWidth = 3840;
          targetHeight = 2160;
          break;
        case ResolutionPreset.max:
          // For max, we'll keep original dimensions but might still compress a bit
          targetWidth = 0; // 0 means keep original dimension
          targetHeight = 0;
          break;
      }

      debugPrint('📸 Compressing image to ${targetWidth}x$targetHeight with quality $quality%');

      // Create a compressed file path with a timestamp to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalPath = originalFile.path;
      final directory = File(originalPath).parent;
      final extension = originalPath.split('.').last;
      final compressedPath = '${directory.path}/compressed_$timestamp.$extension';

      // Compress the image
      final result = await FlutterImageCompress.compressAndGetFile(
        originalFile.path,
        compressedPath,
        quality: quality,
        minWidth: targetWidth > 0 ? targetWidth : 3840, // Default to high resolution if 0
        minHeight: targetHeight > 0 ? targetHeight : 2160, // Default to high resolution if 0
        // Keep EXIF data (important for image orientation)
        keepExif: true,
      );

      if (result != null) {
        // Check if compression actually reduced the file size
        final originalFile = File(originalPath);
        final compressedFile = File(result.path);

        if (await compressedFile.exists()) {
          final originalSize = await originalFile.length();
          final compressedSize = await compressedFile.length();

          debugPrint('📸 Original size: ${originalSize ~/ 1024}KB, Compressed size: ${compressedSize ~/ 1024}KB');

          // If compressed file is actually smaller, use it
          if (compressedSize < originalSize) {
            // Delete the original file if it's different from the compressed file
            if (originalPath != result.path) {
              try {
                await originalFile.delete();
                debugPrint('📸 Deleted original image file after compression');
              } catch (e) {
                debugPrint('Warning: Could not delete original image file: $e');
              }
            }

            return XFile(result.path, mimeType: 'image/${extension.toLowerCase()}');
          } else {
            // If compression didn't help, delete compressed file and use original
            try {
              await compressedFile.delete();
              debugPrint('📸 Compression didn\'t reduce file size, using original');
            } catch (e) {
              debugPrint('Warning: Could not delete unused compressed file: $e');
            }
          }
        }
      }

      // Return the original file if compression failed or didn't help
      return originalFile;
    } catch (e) {
      debugPrint('⚠️ Error compressing image: $e');
      // Return the original file if compression fails
      return originalFile;
    }
  }

  /// Sets the flash mode.
  Future<void> setFlashMode(FlashMode mode) async {
    if (!value.isInitialized) return;

    // If the camera doesn't have flash capability, don't try to set the flash mode
    if (!value.hasFlashCapability) {
      debugPrint('Camera does not have flash capabilities, ignoring flash mode change');
      return;
    }

    try {
      // Try to set the flash mode, but catch any exceptions related to flash capabilities
      await _controller!.setFlashMode(mode);
      value = value.copyWith(flashMode: mode);
    } on CameraException catch (e) {
      debugPrint('Error setting flash mode: ${e.description}');

      // Check if the error is related to flash capabilities
      if (e.description?.toLowerCase().contains('flash') == true || e.description?.toLowerCase().contains('torch') == true) {
        // If it's a flash-related error, update the value to indicate no flash capability
        debugPrint('Camera does not have flash capabilities, updating state');
        value = value.copyWith(flashMode: FlashMode.off, hasFlashCapability: false);
      } else {
        // For other types of errors, update the error state
        value = value.copyWith(error: e.description);
      }
    }
  }

  /// Sets the exposure mode.
  Future<void> setExposureMode(ExposureMode mode) async {
    if (!value.isInitialized) return;
    try {
      await _controller!.setExposureMode(mode);
      value = value.copyWith(exposureMode: mode);
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
    }
  }

  /// Sets the focus mode.
  Future<void> setFocusMode(FocusMode mode) async {
    if (!value.isInitialized) return;
    try {
      await _controller!.setFocusMode(mode);
      value = value.copyWith(focusMode: mode);
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
    }
  }

  /// Starts video recording.
  Future<void> startVideoRecording() async {
    if (!value.isInitialized) {
      throw CameraException('notInitialized', 'Camera has not been initialized');
    }

    if (value.isRecordingVideo) {
      throw CameraException('captureInProgress', 'A video recording is already in progress');
    }

    try {
      // Ensure the orientation is set correctly before starting recording
      // Only needed for Android - iOS handles orientation correctly by itself
      if (Platform.isAndroid) {
        try {
          // Get the exact device rotation from the platform
          final DeviceOrientation deviceOrientation = await OrientationChannel.getPlatformOrientation();

          debugPrint('🎥 Starting video recording with orientation from platform channel: $deviceOrientation');

          // Ensure orientation is set correctly before recording
          await _controller!.lockCaptureOrientation(deviceOrientation);
        } catch (e) {
          // If platform channel fails, use the current orientation from our value
          final deviceOrientation = value.deviceOrientation;
          debugPrint('⚠️ Error getting platform orientation for video recording: $e');
          debugPrint('🎥 Falling back to current orientation value: $deviceOrientation');

          // Lock the capture orientation to ensure the video is recorded correctly
          await _controller!.lockCaptureOrientation(deviceOrientation);
        }
      }

      await _controller!.startVideoRecording();
      value = value.copyWith(isRecordingVideo: true);
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
    }
  }

  /// Stops video recording and returns the file.
  Future<XFile> stopVideoRecording() async {
    if (!value.isInitialized) {
      throw CameraException(
        'cameraly_not_initialized',
        'Cannot stop recording. CameralyController is not initialized.',
      );
    }

    if (!value.isRecordingVideo) {
      throw CameraException(
        'no_recording_in_progress',
        'Cannot stop recording when no recording is in progress.',
      );
    }

    try {
      // Cancel the timer if it's running
      _recordingTimer?.cancel();
      _recordingTimer = null;

      final recordingDuration = _recordingStartTime != null ? DateTime.now().difference(_recordingStartTime!) : Duration.zero;
      final XFile videoFile = await _controller!.stopVideoRecording();

      debugPrint('Video recording stopped: ${videoFile.path} (duration: ${recordingDuration.inSeconds}s)');

      // Process the video file (fixing extension, compression)
      final XFile processedFile = await _processVideoFile(videoFile);

      value = value.copyWith(isRecordingVideo: false, lastRecordedVideo: processedFile);
      // Add the recorded video to the media manager
      _mediaManager.addMedia(processedFile, isVideo: true);
      return processedFile;
    } on CameraException catch (e) {
      value = value.copyWith(isRecordingVideo: false);
      debugPrint('Error stopping video recording: ${e.code} - ${e.description}');
      rethrow;
    }
  }

  /// Processes the recorded video file to use a proper extension.
  /// This converts .temp files (from CameraX plugin) to .mp4, compresses the video based on settings, and generates a thumbnail
  Future<XFile> _processVideoFile(XFile originalFile) async {
    final String originalPath = originalFile.path;
    XFile processedFile = originalFile;

    // Check if the file has a .temp extension
    if (originalPath.toLowerCase().endsWith('.temp')) {
      try {
        // Create a new path with .mp4 extension
        final String newPath = originalPath.replaceAll(RegExp(r'\.temp$', caseSensitive: false), '.mp4');

        // Rename the file
        final File tempFile = File(originalPath);
        final File newFile = tempFile.renameSync(newPath);

        // Create a new XFile with the updated path
        processedFile = XFile(newFile.path, mimeType: 'video/mp4');
      } catch (e) {
        // If renaming fails, return the original file
        debugPrint('Error renaming video file: $e');
        processedFile = originalFile;
      }
    }

    // Skip compression if set to none
    if (_settings.compressionQuality == CompressionQuality.none) {
      debugPrint('🎥 Skipping video compression (compressionQuality = none)');

      // Generate a thumbnail and return the uncompressed file
      await _generateThumbnail(processedFile);
      return processedFile;
    }

    // Compress the video based on resolution setting
    try {
      // Map resolution preset to compression quality
      VideoQuality compressionQuality;

      // Determine quality based on compression settings
      switch (_settings.compressionQuality) {
        case CompressionQuality.light:
          compressionQuality = VideoQuality.HighestQuality;
          break;
        case CompressionQuality.medium:
          compressionQuality = VideoQuality.DefaultQuality;
          break;
        case CompressionQuality.high:
          compressionQuality = VideoQuality.MediumQuality;
          break;
        case CompressionQuality.auto:
          // Auto quality based on resolution
          switch (_settings.resolution) {
            case ResolutionPreset.low:
              compressionQuality = VideoQuality.LowQuality;
              break;
            case ResolutionPreset.medium:
              compressionQuality = VideoQuality.MediumQuality;
              break;
            case ResolutionPreset.high:
              compressionQuality = VideoQuality.DefaultQuality;
              break;
            case ResolutionPreset.veryHigh:
              compressionQuality = VideoQuality.HighestQuality;
              break;
            case ResolutionPreset.ultraHigh:
            case ResolutionPreset.max:
              compressionQuality = VideoQuality.Res1280x720Quality; // 720p
              break;
          }
          break;
        case CompressionQuality.none:
          // This should not happen as we check for this earlier
          compressionQuality = VideoQuality.HighestQuality;
          break;
      }

      // Set the frame rate based on quality
      int frameRate = 30;
      if (_settings.videoQuality < 80) {
        frameRate = 24;
      }

      debugPrint('🎥 Compressing video to ${compressionQuality.toString()} resolution with framerate $frameRate...');

      final compressedVideoInfo = await VideoCompress.compressVideo(
        processedFile.path,
        quality: compressionQuality,
        deleteOrigin: false, // Keep original file until compression completes successfully
        includeAudio: _settings.enableAudio,
        frameRate: frameRate,
      );

      if (compressedVideoInfo != null && compressedVideoInfo.path != null) {
        // Create a new XFile from the compressed video
        final compressedFile = XFile(compressedVideoInfo.path!, mimeType: 'video/mp4');

        // Delete the original file if it's different from the compressed file
        if (processedFile.path != compressedFile.path) {
          try {
            await File(processedFile.path).delete();
            debugPrint('🎥 Deleted original video file after compression');
          } catch (e) {
            debugPrint('Warning: Could not delete original video file: $e');
          }
        }

        // Use the compressed file for further processing
        processedFile = compressedFile;

        // Log compression results
        if (compressedVideoInfo.filesize != null && compressedVideoInfo.filesize! > 0) {
          final originalSize = await originalFile.length();
          final compressionRatio = originalSize / compressedVideoInfo.filesize!;
          debugPrint('🎥 Video compressed successfully: Size reduced to ${compressedVideoInfo.filesize! ~/ 1024}KB (${compressionRatio.toStringAsFixed(2)}x compression)');
        } else {
          debugPrint('🎥 Video compressed successfully: Size reduced to ${compressedVideoInfo.filesize! ~/ 1024}KB');
        }
      } else {
        debugPrint('⚠️ Video compression returned null result, using original file');
      }
    } catch (e) {
      debugPrint('⚠️ Error compressing video: $e');
      // Continue with the uncompressed file if compression fails
    }

    // Generate a thumbnail for the video
    await _generateThumbnail(processedFile);

    // Return the processed file
    return processedFile;
  }

  /// Helper method to generate a video thumbnail
  Future<void> _generateThumbnail(XFile videoFile) async {
    try {
      // Determine the thumbnail path (same as video but with .jpg extension)
      final String thumbnailPath = videoFile.path.replaceAll(RegExp(r'\.(mp4|mov|avi|temp)$', caseSensitive: false), '.jpg');

      // Generate the thumbnail
      debugPrint('Generating thumbnail for video: ${videoFile.path}');
      final String? generatedThumbnailPath = await vt.VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: thumbnailPath,
        imageFormat: vt.ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );

      if (generatedThumbnailPath != null) {
        debugPrint('Thumbnail generated successfully: $generatedThumbnailPath');

        // Store the thumbnail path in the media manager for later use
        _mediaManager.setThumbnailForVideo(videoFile.path, generatedThumbnailPath);
      } else {
        debugPrint('Failed to generate thumbnail');
      }
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
    }
  }

  /// Pauses video recording.
  Future<void> pauseVideoRecording() async {
    if (!value.isInitialized || !value.isRecordingVideo) return;
    try {
      await _controller!.pauseVideoRecording();
      value = value.copyWith(isRecordingPaused: true);
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
    }
  }

  /// Resumes video recording.
  Future<void> resumeVideoRecording() async {
    if (!value.isInitialized || !value.isRecordingVideo) return;
    try {
      await _controller!.resumeVideoRecording();
      value = value.copyWith(isRecordingPaused: false);
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
    }
  }

  /// Gets the maximum zoom level.
  Future<double> getMaxZoomLevel() async {
    if (!value.isInitialized) return 1.0;
    try {
      return await _controller!.getMaxZoomLevel();
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      return 1.0;
    }
  }

  /// Gets the minimum zoom level.
  Future<double> getMinZoomLevel() async {
    if (!value.isInitialized) return 1.0;
    try {
      return await _controller!.getMinZoomLevel();
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      return 1.0;
    }
  }

  /// Sets the zoom level.
  Future<void> setZoomLevel(double zoom) async {
    if (!value.isInitialized) return;
    try {
      await _controller!.setZoomLevel(zoom);
      value = value.copyWith(zoomLevel: zoom);
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
    }
  }

  /// Handles pinch-to-zoom gestures with sensitivity adjustment.
  ///
  /// This method takes the raw scale value from a scale gesture and applies
  /// sensitivity adjustment to make zooming more controlled.
  ///
  /// Parameters:
  /// - [scale]: The raw scale value from the gesture detector
  /// - [sensitivity]: Optional sensitivity factor (0.0-1.0), defaults to 0.3 (30%)
  /// - [minZoom]: Optional minimum zoom level, defaults to 1.0
  /// - [maxZoom]: Optional maximum zoom level, defaults to 5.0
  ///
  /// Returns a Future that completes when the zoom is applied.
  Future<void> handleScale(double scale, {double sensitivity = 0.3, double? minZoom, double? maxZoom}) async {
    if (!value.isInitialized) return;

    try {
      // Get current zoom level and initial zoom level (if set)
      final baseZoom = value.initialZoomLevel ?? value.zoomLevel;

      // Get min/max zoom levels if not provided
      final effectiveMinZoom = minZoom ?? await getMinZoomLevel();
      final effectiveMaxZoom = maxZoom ?? await getMaxZoomLevel();

      // Apply sensitivity adjustment to make zooming more controlled
      // Use the initial zoom level as the base for calculations to prevent jumps
      final newZoom = (baseZoom * scale).clamp(effectiveMinZoom, effectiveMaxZoom);

      // Apply the new zoom level
      await setZoomLevel(newZoom);
    } on CameraException catch (e) {
      value = value.copyWith(error: e.description);
      rethrow;
    }
  }

  /// Toggles the flash mode between off and auto.
  Future<void> toggleFlash() async {
    if (!value.isInitialized) return;

    final FlashMode newMode;
    switch (value.flashMode) {
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        newMode = FlashMode.off;
        break;
    }

    await setFlashMode(newMode);
  }

  /// Switches between front and back cameras.
  Future<CameralyController?> switchCamera() async {
    if (!value.isInitialized) {
      debugPrint('📸 Cannot switch camera: Camera not initialized');
      return null;
    }

    try {
      // Get available cameras
      final cameras = await getAvailableCameras();
      debugPrint('📸 Available cameras: ${cameras.length}');

      // Log all available cameras for debugging
      for (int i = 0; i < cameras.length; i++) {
        final camera = cameras[i];
        debugPrint('📸 Camera $i: ${camera.name}, direction: ${camera.lensDirection}, sensorOrientation: ${camera.sensorOrientation}');
      }

      // If there's only one camera, we can't switch
      if (cameras.length <= 1) {
        debugPrint('📸 No alternative cameras available');
        return null;
      }

      // Determine current camera index
      int currentIndex = -1;
      for (int i = 0; i < cameras.length; i++) {
        if (cameras[i].name == _description.name) {
          currentIndex = i;
          break;
        }
      }

      if (currentIndex == -1) {
        debugPrint('📸 Current camera not found in available cameras');
        return null;
      }

      // Simply choose the next camera in the list, wrapping around if needed
      final newIndex = (currentIndex + 1) % cameras.length;
      final newCamera = cameras[newIndex];

      debugPrint('📸 Switching from camera index $currentIndex to index $newIndex');
      debugPrint('📸 Switching from ${_description.name} (${_description.lensDirection}) to ${newCamera.name} (${newCamera.lensDirection})');
      debugPrint('📸 Current isFrontCamera value: ${value.isFrontCamera}');

      // Immediately determine if the new camera is front-facing
      final bool isNewCameraFront = newCamera.lensDirection == CameraLensDirection.front;
      debugPrint('📸 New camera will be front-facing: $isNewCameraFront');

      // If we're switching to the same camera, return null
      if (newCamera.name == _description.name) {
        debugPrint('📸 Selected the same camera, not switching');
        return null;
      }

      // Save current settings to transfer to new controller
      final previousSettings = _settings;
      final wasRecording = value.isRecordingVideo;
      final currentZoomLevel = value.zoomLevel;
      final currentFlashMode = value.flashMode;
      final currentFocusMode = value.focusMode;
      final currentExposureMode = value.exposureMode;
      final currentOrientation = value.deviceOrientation;

      // Update UI to show we're transitioning
      value = value.copyWith(isChangingController: true);
      notifyListeners();

      // Store the current media manager to reuse in the new controller
      final currentMediaManager = mediaManager;

      // Stop recording if needed
      if (wasRecording) {
        debugPrint('📸 Stopping current recording before switching');
        await stopVideoRecording();
      }

      // Pause camera preview first to prevent issues during transition
      if (_controller != null && _controller!.value.isInitialized) {
        try {
          await _controller!.pausePreview();
        } catch (e) {
          debugPrint('📸 Error pausing camera preview: $e');
        }
      }

      // Minimal delay to ensure camera preview is paused
      await Future.delayed(const Duration(milliseconds: 50));

      // Dispose the current controller
      debugPrint('📸 Disposing current controller: ${_controller?.hashCode}');
      final oldController = _controller;
      _controller = null;

      try {
        // Using a timeout to prevent hanging on disposal
        await oldController?.dispose().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            debugPrint('📸 Controller disposal timed out, continuing anyway');
            return;
          },
        );
      } catch (e) {
        debugPrint('📸 Error disposing controller: $e');
      }

      // Create a new controller with the new camera and existing media manager
      final newController = CameralyController(
        description: newCamera,
        settings: previousSettings,
        existingMediaManager: currentMediaManager, // Use existing media manager
      );
      debugPrint('📸 Created new controller with hashcode: ${newController.hashCode}');

      try {
        // Initialize the new controller
        debugPrint('📸 Initializing new controller');
        await newController.initialize().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            throw TimeoutException('Camera initialization timed out');
          },
        );

        // Restore previous camera settings
        if (currentZoomLevel > 1.0) {
          try {
            await newController._controller?.setZoomLevel(currentZoomLevel);
          } catch (e) {
            debugPrint('📸 Error restoring zoom level: $e');
          }
        }

        if (currentFlashMode != FlashMode.off) {
          try {
            await newController._controller?.setFlashMode(currentFlashMode);
          } catch (e) {
            debugPrint('📸 Error restoring flash mode: $e');
          }
        }

        try {
          await newController._controller?.setExposureMode(currentExposureMode);
          await newController._controller?.setFocusMode(currentFocusMode);
        } catch (e) {
          debugPrint('📸 Error restoring focus/exposure mode: $e');
        }

        // Double-check if native controller is initialized
        if (newController._controller != null && newController._controller!.value.isInitialized) {
          debugPrint('📸 Native camera controller is initialized');
        } else {
          debugPrint('⚠️ Native camera controller is NOT initialized');
        }

        // IMPORTANT: Always update the isFrontCamera property after initialization
        // Use lens direction as the source of truth
        final bool isActuallyFrontCamera = newCamera.lensDirection == CameraLensDirection.front;

        // Force update the isFrontCamera value to match the actual lens direction
        if (newController.value.isFrontCamera != isActuallyFrontCamera) {
          debugPrint('📸 Fixing mismatch: value.isFrontCamera (${newController.value.isFrontCamera}) != actual lens direction ($isActuallyFrontCamera)');
          newController.value = newController.value.copyWith(isFrontCamera: isActuallyFrontCamera);
        }

        debugPrint('📸 Updated isFrontCamera to: ${newController.value.isFrontCamera}');
        debugPrint('📸 New controller initialized successfully');
      } catch (e) {
        debugPrint('📸 Failed to initialize new controller: $e');
        rethrow;
      }

      // Restore previous state
      if (wasRecording) {
        debugPrint('📸 Restoring recording state');
        await newController.startVideoRecording();
      }

      // Return the new controller
      return newController;
    } catch (e) {
      debugPrint('📸 Error switching camera: $e');
      rethrow;
    }
  }

  /// Captures a photo or toggles video recording based on the current state.
  Future<XFile?> captureMedia() async {
    if (!value.isInitialized) return null;

    try {
      if (value.isRecordingVideo) {
        // If recording, stop recording and return the video file
        return await stopVideoRecording();
      } else {
        // Otherwise take a picture
        return await takePicture();
      }
    } catch (e) {
      value = value.copyWith(error: 'Failed to capture media: $e');
      return null;
    }
  }

  /// Toggles video recording (starts or stops).
  Future<XFile?> toggleVideoRecording() async {
    if (!value.isInitialized) return null;

    try {
      if (value.isRecordingVideo) {
        // If recording, stop recording and return the video file
        return await stopVideoRecording();
      } else {
        // Otherwise start recording
        await startVideoRecording();
        return null;
      }
    } catch (e) {
      value = value.copyWith(error: 'Failed to toggle video recording: $e');
      return null;
    }
  }

  /// Sets the focus and exposure point.
  Future<void> setFocusAndExposurePoint(Offset point) async {
    if (!value.isInitialized) return;

    try {
      // Debug print
      debugPrint('Setting focus and exposure at: $point');

      // The point is already normalized (0.0 to 1.0) from the CameralyPreview
      // Make sure it's within valid bounds
      final normalizedPoint = Offset(point.dx.clamp(0.0, 1.0), point.dy.clamp(0.0, 1.0));

      // Update the value with the new focus and exposure points immediately
      // This will trigger the UI update for the focus circle right away
      value = value.copyWith(
        focusPoint: normalizedPoint,
        exposurePoint: normalizedPoint,
        focusMode: FocusMode.auto,
        exposureMode: ExposureMode.auto,
        error: null, // Clear any previous errors
      );

      // Set focus mode to auto to enable tap-to-focus
      await _controller!.setFocusMode(FocusMode.auto);

      // Set exposure mode to auto to enable tap-to-expose
      await _controller!.setExposureMode(ExposureMode.auto);

      // Set the focus point
      await _controller!.setFocusPoint(normalizedPoint);

      // Set the exposure point
      await _controller!.setExposurePoint(normalizedPoint);
    } catch (e) {
      debugPrint('Error setting focus and exposure: $e');
      value = value.copyWith(error: 'Failed to set focus and exposure point: $e');
    }
  }

  /// Initializes the camera with fallback options if the initial initialization fails.
  ///
  /// This method attempts to initialize the camera with the current settings.
  /// If that fails, it tries alternative settings in the following order:
  /// 1. Disable flash if it's enabled
  /// 2. Lower resolution if it's high
  /// 3. Try video-only mode if photo mode fails
  ///
  /// Returns true if initialization succeeds with any settings, false otherwise.
  Future<bool> initializeWithFallback() async {
    try {
      // First try with current settings
      debugPrint('Attempting to initialize camera with current settings');
      await initialize();
      debugPrint('Camera initialized successfully with current settings');
      return true;
    } catch (e) {
      debugPrint('Error initializing camera with current settings: $e');

      // Try with flash disabled if the error is related to flash
      if (e.toString().contains('flash') || e.toString().contains('Flash')) {
        debugPrint('Flash capability error detected, retrying with flash disabled');
        try {
          // Create new settings with flash disabled
          final newSettings = CaptureSettings(
            resolution: _settings.resolution,
            flashMode: FlashMode.off,
            enableAudio: _settings.enableAudio,
            cameraMode: _settings.cameraMode,
            deviceOrientation: _settings.deviceOrientation,
            exposureMode: _settings.exposureMode,
            focusMode: _settings.focusMode,
          );

          // Create a new controller with the new settings
          final newController = CameralyController(description: _description, settings: newSettings);

          // Initialize the new controller
          await newController.initialize();

          // Update this controller with the new controller's values
          _controller = newController._controller;
          value = newController.value.copyWith(hasFlashCapability: false);

          debugPrint('Camera initialized successfully with flash disabled');
          return true;
        } catch (retryError) {
          debugPrint('Retry with flash disabled also failed: $retryError');
        }
      }

      // Try with lower resolution if current resolution is high
      if (_settings.resolution == ResolutionPreset.high || _settings.resolution == ResolutionPreset.veryHigh || _settings.resolution == ResolutionPreset.ultraHigh || _settings.resolution == ResolutionPreset.max) {
        debugPrint('Trying with lower resolution');
        try {
          // Create new settings with lower resolution
          final newSettings = CaptureSettings(
            resolution: ResolutionPreset.medium,
            flashMode: FlashMode.off,
            enableAudio: _settings.enableAudio,
            cameraMode: _settings.cameraMode,
            deviceOrientation: _settings.deviceOrientation,
            exposureMode: _settings.exposureMode,
            focusMode: _settings.focusMode,
          );

          // Create a new controller with the new settings
          final newController = CameralyController(description: _description, settings: newSettings);

          // Initialize the new controller
          await newController.initialize();

          // Update this controller with the new controller's values
          _controller = newController._controller;
          value = newController.value.copyWith(hasFlashCapability: false);

          debugPrint('Camera initialized successfully with lower resolution');
          return true;
        } catch (resolutionError) {
          debugPrint('Retry with lower resolution also failed: $resolutionError');
        }
      }

      // As a last resort, try video-only mode with audio disabled
      debugPrint('Attempting video-only initialization as last resort');
      try {
        // Create new settings for video-only mode
        const newSettings = CaptureSettings(resolution: ResolutionPreset.medium, enableAudio: false, cameraMode: CameraMode.videoOnly);

        // Create a new controller with video settings
        final newController = CameralyController(description: _description, settings: newSettings);

        // Initialize the new controller
        await newController.initialize();

        // Update this controller with the new controller's values
        _controller = newController._controller;
        value = newController.value.copyWith(hasFlashCapability: false);

        debugPrint('Video-only initialization successful');
        return true;
      } catch (videoError) {
        debugPrint('Video-only initialization also failed: $videoError');
      }

      // If all attempts fail, update the value with an error
      value = value.copyWith(error: 'Failed to initialize camera after multiple attempts');

      return false;
    }
  }

  /// Initializes the camera with platform-specific optimizations.
  ///
  /// This method handles platform-specific camera initialization:
  /// - On Android, it ensures proper orientation handling with CameraX
  /// - On iOS, it handles specific iOS camera quirks
  ///
  /// Returns true if initialization succeeds, false otherwise.
  Future<bool> initializeWithPlatformOptimizations() async {
    try {
      // First, initialize the camera
      await initialize();

      // Then apply platform-specific optimizations
      if (Platform.isAndroid) {
        // For Android with CameraX, we need to set the target rotation
        if (_controller != null) {
          try {
            // This is a dummy call to ensure controller is initialized
            await _controller!.setExposureOffset(0.0);
            debugPrint('Using CameraX on Android with explicit orientation handling');
          } catch (e) {
            debugPrint('Error setting camera orientation: $e');
          }
        }
      } else if (Platform.isIOS) {
        // iOS-specific optimizations if needed
        debugPrint('Applying iOS-specific camera optimizations');
      }

      return true;
    } catch (e) {
      debugPrint('Error in platform-optimized initialization: $e');
      return false;
    }
  }

  /// Sets the device orientation for the camera.
  ///
  /// This method sets the device orientation for the camera without pausing/resuming
  /// the preview, which can cause locking issues.
  Future<void> setDeviceOrientation(DeviceOrientation orientation) async {
    if (!value.isInitialized || _controller == null) return;

    // Skip orientation handling for iOS - it handles orientation correctly by itself
    if (!Platform.isAndroid) {
      debugPrint('📱 Skipping setDeviceOrientation on iOS - handled natively');
      return;
    }

    try {
      // Only update if the orientation has changed
      if (value.deviceOrientation != orientation) {
        value = value.copyWith(deviceOrientation: orientation);
      }

      // On some Android devices, lockCaptureOrientation can cause preview freezing
      // Try with a timeout to prevent UI blocking
      await _controller!.lockCaptureOrientation(orientation).timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {
          debugPrint('⚠️ Orientation lock timed out, continuing anyway');
          return;
        },
      );

      debugPrint('🔒 Locked capture orientation to: $orientation');
    } catch (e) {
      debugPrint('❌ Error setting device orientation: $e');
    }
  }

  @override
  void didChangeMetrics() {
    // This method is called whenever the device orientation changes
    super.didChangeMetrics();

    debugPrint('📊 METRICS CHANGED - Device orientation might have changed');

    // Handle orientation changes directly in the controller
    if (value.isInitialized) {
      handleDeviceOrientationChange();
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposing) return;

    _isDisposing = true;
    WidgetsBinding.instance.removeObserver(this);

    // Cancel any ongoing operations
    _recordingTimer?.cancel();

    // Cancel any ongoing video compression
    try {
      await VideoCompress.cancelCompression();
    } catch (e) {
      debugPrint('📸 Error canceling video compression: $e');
    }

    // Add a small delay to ensure any pending frame operations complete
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      if (_controller != null) {
        // Pause preview first to prevent frame access errors
        try {
          if (Platform.isAndroid && _controller!.value.isInitialized) {
            await _controller!.pausePreview();
          }
        } catch (e) {
          debugPrint('📸 Error pausing preview during dispose: $e');
        }

        await Future.delayed(const Duration(milliseconds: 50));
        await _controller!.dispose();
        _controller = null;
      }
    } catch (e) {
      debugPrint('📸 Error disposing camera controller: $e');
    } finally {
      // Clean up temp files created by this instance
      _cleanupOldTempFiles();

      _isDisposing = false;
      super.dispose();
    }
  }

  /// Manually detects and prints the current device orientation.
  /// This method can be called from outside to debug orientation issues.
  Future<void> printCurrentOrientation(BuildContext context) async {
    final mediaQuery = MediaQuery.of(context);
    final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
    final size = platformDispatcher.views.first.physicalSize;
    final isLandscape = size.width > size.height;
    final orientation = mediaQuery.orientation;
    final windowPadding = mediaQuery.viewPadding;
    final devicePixelRatio = mediaQuery.devicePixelRatio;

    debugPrint('📊 ORIENTATION DEBUG INFO:');
    debugPrint('📱 Device Physical Size: $size');
    debugPrint('📱 MediaQuery Orientation: $orientation');
    debugPrint('📱 Is Landscape (by size): $isLandscape');
    debugPrint('📱 Window Padding: $windowPadding');
    debugPrint('📱 Device Pixel Ratio: $devicePixelRatio');
    debugPrint('🧭 Current Controller Orientation: ${value.deviceOrientation}');
    debugPrint('📷 Camera Description: ${_description.name}');
    debugPrint('📷 Camera Lens Direction: ${_description.lensDirection}');
    debugPrint('📷 Camera Sensor Orientation: ${_description.sensorOrientation}°');

    // Try to get the platform orientation
    try {
      final rawRotation = await OrientationChannel.getRawRotationValue();
      final platformOrientation = await OrientationChannel.getPlatformOrientation();
      debugPrint('🧭 Raw Rotation Value: $rawRotation');
      debugPrint('🧭 Platform Orientation: $platformOrientation');
    } catch (e) {
      debugPrint('⚠️ Error getting platform orientation: $e');
    }

    // Try to determine if we're in landscape left or right using padding
    if (orientation == Orientation.landscape) {
      // If the right padding is greater than the left padding, it's likely landscape left
      final isLandscapeLeft = windowPadding.right > windowPadding.left;
      debugPrint('📱 Is Landscape Left (by padding): $isLandscapeLeft');
      debugPrint('📱 Detected Orientation (by padding): ${isLandscapeLeft ? "Landscape LEFT" : "Landscape RIGHT"}');
    }
  }

  /// Gets the actual aspect ratio, correcting for known platform issues.
  /// iPads often report 16:9 when they should be 4:3.
  double getAdjustedAspectRatio() {
    // Get the reported aspect ratio from the camera controller
    final reportedRatio = cameraController?.value.aspectRatio ?? 1.0;

    // Check if this is likely an iPad or tablet device using updated Flutter APIs
    final view = PlatformDispatcher.instance.views.first;
    final size = view.physicalSize;
    final isLikelyTablet = size.shortestSide > 900;

    // Check if the reported aspect ratio is suspiciously close to 16:9 (1.77)
    // when we expect 4:3 (1.33) for most tablet cameras
    if (isLikelyTablet && (reportedRatio > 1.7 && reportedRatio < 1.8)) {
      debugPrint('📱 Detected tablet device with incorrect aspect ratio (${reportedRatio.toStringAsFixed(2)}), correcting to 4:3');
      //return 4 / 3; // Return the corrected aspect ratio for tablets (4:3)
      //Current the camera package is not working correctly with tablets
      //So we will return the reported ratio
      return reportedRatio; //This return 16:9 for tablets even though it should be 4:3. Changeing thi,s make the ui look correct but the capture is still 16:9
    }

    return reportedRatio;
  }

  // Add a global lock to prevent multiple camera initializations
  static bool _isResumingAnyCamera = false;

  /// Handles camera resume with a complete controller recreation for Android
  /// This is a more aggressive approach to fix freezing issues on orientation changes
  Future<void> handleCameraResume() async {
    // Global lock to prevent ANY camera from being resumed simultaneously
    if (_isResumingAnyCamera) {
      debugPrint('📸 Another camera is already being resumed, skipping duplicate request');
      return;
    }

    if (!value.isInitialized || _controller == null) return;

    if (_isResuming) {
      debugPrint('📸 Camera resume already in progress for this controller, skipping duplicate request');
      return;
    }

    if (_isHandlingOrientation) {
      debugPrint('📸 Orientation change already in progress, handling resume as part of it');
    }

    // Set BOTH locks
    _isResuming = true;
    _isResumingAnyCamera = true;

    try {
      debugPrint('📸 Explicit camera resume requested');

      // For Android, completely recreate the controller as a more aggressive fix
      if (Platform.isAndroid) {
        debugPrint('📸 Using aggressive camera recovery for Android');

        // Save current state
        final currentFlashMode = value.flashMode;
        final currentZoomLevel = value.zoomLevel;
        final currentFocusMode = value.focusMode;
        final currentExposureMode = value.exposureMode;
        final currentOrientation = value.deviceOrientation;
        final wasRecording = value.isRecordingVideo;
        final isFrontCamera = value.isFrontCamera;

        // Update value to show we're in progress with camera change
        value = value.copyWith(
          isChangingController: true,
        );
        notifyListeners();

        // Create a reference to the old controller and null out _controller
        // immediately to prevent any other code from using it
        final oldController = _controller;
        _controller = null;

        try {
          // Pause the preview first to prevent access to frames after they're released
          try {
            if (oldController != null && oldController.value.isInitialized) {
              await oldController.pausePreview();
              debugPrint('📸 Successfully paused old controller preview');
            }
          } catch (e) {
            debugPrint('📸 Error pausing preview: $e');
          }

          // Add a minimal delay before disposal
          await Future.delayed(const Duration(milliseconds: 150));

          // Dispose the old controller with timeout protection
          try {
            debugPrint('📸 Disposing old camera controller');
            await oldController?.dispose().timeout(
              const Duration(seconds: 2),
              onTimeout: () {
                debugPrint('📸 Controller disposal timed out, continuing anyway');
                return;
              },
            );
            debugPrint('📸 Old controller successfully disposed');
          } catch (e) {
            debugPrint('📸 Error disposing controller: $e');
          }

          // Add extra delay to ensure disposal is complete
          await Future.delayed(const Duration(milliseconds: 200));

          // Create new controller with same settings
          debugPrint('📸 Creating new camera controller');
          final newController = CameraController(
            _description,
            _settings.resolution,
            enableAudio: _settings.enableAudio,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );

          try {
            // Initialize the new controller with timeout protection
            debugPrint('📸 Initializing new camera controller');
            await newController.initialize().timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                throw TimeoutException('Camera initialization timed out');
              },
            );
            debugPrint('📸 New controller successfully initialized');

            // Add extra stabilization delay
            await Future.delayed(const Duration(milliseconds: 200));

            // Verify controller is initialized before continuing
            if (!newController.value.isInitialized) {
              throw StateError('Camera controller initialize() completed but controller is not initialized');
            }

            // Assign the new controller AFTER it's fully initialized
            _controller = newController;

            // CRITICAL: Explicitly set orientation first
            try {
              debugPrint('📸 Setting device orientation to: $currentOrientation');
              await _controller!.lockCaptureOrientation(currentOrientation);
            } catch (e) {
              debugPrint('📸 Error setting orientation: $e');
            }

            // Minimal pause to let the orientation change apply
            await Future.delayed(const Duration(milliseconds: 100));

            // Restore previous state
            debugPrint('📸 Restoring camera parameters');
            if (currentFlashMode != FlashMode.off) {
              try {
                await _controller!.setFlashMode(currentFlashMode);
              } catch (e) {
                debugPrint('📸 Error restoring flash mode: $e');
              }
            }

            try {
              await _controller!.setExposureMode(currentExposureMode);
              await _controller!.setFocusMode(currentFocusMode);
            } catch (e) {
              debugPrint('📸 Error restoring focus/exposure: $e');
            }

            if (currentZoomLevel > 1.0) {
              try {
                await _controller!.setZoomLevel(currentZoomLevel);
              } catch (e) {
                debugPrint('📸 Error restoring zoom: $e');
              }
            }

            // Update our value to reflect the new controller
            _updateValueFromController();

            // Force explicit value update to ensure orientation and camera state are correct
            value = value.copyWith(
              deviceOrientation: currentOrientation,
              isInitialized: true,
              error: null,
              isChangingController: false, // Important: mark the controller change as complete
              isFrontCamera: isFrontCamera, // Preserve front/back camera state
            );

            // Force update the UI
            notifyListeners();

            debugPrint('📸 Camera recovered successfully');
          } catch (e) {
            debugPrint('📸 Failed to recover camera: $e');

            // Try a simpler recovery as fallback
            try {
              if (_controller != null) {
                debugPrint('📸 Falling back to simple resumePreview');
                await _controller!.resumePreview();

                // Still need to mark controller change as complete
                value = value.copyWith(isChangingController: false, error: 'Camera recovery partially succeeded with fallback');
                notifyListeners();
              } else {
                // Critical failure - the controller is null after recovery attempt
                value = value.copyWith(isChangingController: false, error: 'Camera recovery failed: $e', isInitialized: false);
                notifyListeners();
              }
            } catch (e2) {
              debugPrint('📸 Even simple resumePreview failed: $e2');
              value = value.copyWith(isChangingController: false, error: 'Camera recovery failed: $e2', isInitialized: false);
              notifyListeners();
            }
          }
        } catch (e) {
          debugPrint('📸 Critical error during camera rebuild: $e');
          value = value.copyWith(isChangingController: false, error: 'Critical camera error: $e', isInitialized: false);
          notifyListeners();
        }
      } else {
        // For iOS, simple resumePreview works fine
        if (_controller != null) {
          try {
            await _controller!.resumePreview();
            debugPrint('📸 iOS camera resumed with simple resumePreview');
          } catch (e) {
            debugPrint('📸 Error resuming iOS camera: $e');
            value = value.copyWith(error: 'Failed to resume camera: $e');
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('📸 Error in handleCameraResume: $e');
      // Ensure we always reset the changing controller state
      value = value.copyWith(isChangingController: false);
      notifyListeners();
    } finally {
      // Reset BOTH locks
      _isResuming = false;
      _isResumingAnyCamera = false;
    }
  }

  /// Gets the current device orientation from the platform
  Future<DeviceOrientation> _getDeviceOrientation() async {
    try {
      // Get the current device orientation from the platform
      final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
      final size = platformDispatcher.views.first.physicalSize;

      // Determine orientation based on physical dimensions
      final isLandscape = size.width > size.height;

      // Print orientation information
      debugPrint('📱 DEVICE ORIENTATION CHANGED:');
      debugPrint('📐 Physical Size: $size');
      debugPrint('📱 Is Landscape: $isLandscape');
      debugPrint('🧭 Previous Orientation: ${value.deviceOrientation}');

      // Get device orientation from platform channel if available
      DeviceOrientation newOrientation;

      try {
        // Try to get orientation from platform-specific method channel
        // This should be defined in the OrientationChannel class
        newOrientation = await OrientationChannel.getPlatformOrientation();
        debugPrint('🧭 Detected orientation: $newOrientation');
      } catch (e) {
        // If method channel fails, use a simple landscape/portrait detection
        debugPrint('⚠️ Error getting rotation: $e, using fallback orientation detection');
        newOrientation = isLandscape ? DeviceOrientation.landscapeRight : DeviceOrientation.portraitUp;
      }

      // Check if the orientation actually changed
      if (value.deviceOrientation == newOrientation) {
        debugPrint('🧭 Orientation unchanged, skipping update');
      }

      return newOrientation;
    } catch (e) {
      debugPrint('⚠️ Error determining device orientation: $e');
      // Return current orientation as fallback
      return value.deviceOrientation;
    }
  }

  /// Processes media files by applying compression settings and adding location metadata if needed.
  ///
  /// Returns the processed file.
  Future<XFile> processMediaFile(XFile file, bool isVideo) async {
    XFile processedFile = file;

    try {
      // First apply compression if needed
      if (isVideo) {
        // Video compression
        try {
          final info = await VideoCompress.compressVideo(
            file.path,
            quality: _convertToVideoQuality(_settings.videoQuality),
            deleteOrigin: false,
            includeAudio: true,
          );

          if (info?.path != null) {
            processedFile = XFile(info!.path!);
            debugPrint('🎬 Compressed video: ${file.path} -> ${processedFile.path}');
          }
        } catch (e) {
          debugPrint('🎬 Error compressing video: $e');
          // If compression fails, use the original file
          processedFile = file;
        } finally {
          // Properly clean up VideoCompress resources to prevent memory leaks
          try {
            await VideoCompress.cancelCompression();
          } catch (e) {
            debugPrint('🎬 Error canceling video compression: $e');
          }
        }
      } else {
        // Image compression
        if (_settings.imageQuality != null || _settings.compressionQuality != null) {
          final quality = _settings.imageQuality ?? 80;
          final compressionQuality = _settings.compressionQuality ?? 0.8;
          File? tempFile;

          try {
            final result = await FlutterImageCompress.compressWithFile(
              file.path,
              quality: quality,
              minWidth: 1080,
              minHeight: 1080,
            );

            if (result != null) {
              // Save compressed result to a temporary file
              final dir = await getTemporaryDirectory();
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final targetPath = '${dir.path}/compressed_$timestamp.jpg';

              tempFile = File(targetPath);
              await tempFile.writeAsBytes(result);
              processedFile = XFile(targetPath);

              debugPrint('🖼️ Compressed image: ${file.path} -> ${processedFile.path}');

              // Register the temp file for cleanup when the app closes
              _registerTempFileForCleanup(tempFile);
            }
          } catch (e) {
            debugPrint('🖼️ Error compressing image: $e');
            // If compression fails, use the original file
            processedFile = file;
          }
        }
      }

      // Add location metadata to images
      if (!isVideo && _settings.addLocationMetadata) {
        try {
          // Get current location
          final location = await _getCurrentLocation();
          // Add location metadata to the image
          processedFile = await _addLocationMetadataToImage(processedFile, location);
        } catch (e) {
          debugPrint('Error adding location metadata: $e');
        }
      }
    } catch (e) {
      debugPrint('Error processing media file: $e');
      // Return the original file if any part of processing fails
      return file;
    }

    return processedFile;
  }

  // List to track temporary files for cleanup
  static final List<File> _tempFiles = [];

  // Register a temporary file for cleanup
  void _registerTempFileForCleanup(File file) {
    _tempFiles.add(file);
    // If we have too many temp files, clean up old ones
    if (_tempFiles.length > 20) {
      _cleanupOldTempFiles();
    }
  }

  // Clean up old temporary files
  static void _cleanupOldTempFiles() {
    debugPrint('🧹 Cleaning up old temporary files');
    // Keep the 10 most recent files, delete the rest
    if (_tempFiles.length > 10) {
      final filesToRemove = _tempFiles.sublist(0, _tempFiles.length - 10);
      for (final file in filesToRemove) {
        try {
          if (file.existsSync()) {
            file.deleteSync();
            debugPrint('🧹 Deleted temp file: ${file.path}');
          }
        } catch (e) {
          debugPrint('🧹 Error deleting temp file: $e');
        }
      }
      _tempFiles.removeRange(0, _tempFiles.length - 10);
    }
  }

  // Clean up all temporary files
  static void cleanupAllTempFiles() {
    debugPrint('🧹 Cleaning up all temporary files');
    for (final file in _tempFiles) {
      try {
        if (file.existsSync()) {
          file.deleteSync();
          debugPrint('🧹 Deleted temp file: ${file.path}');
        }
      } catch (e) {
        debugPrint('🧹 Error deleting temp file: $e');
      }
    }
    _tempFiles.clear();
  }

  /// Converts integer video quality to VideoQuality enum
  VideoQuality _convertToVideoQuality(int quality) {
    switch (quality) {
      case 0:
        return VideoQuality.LowQuality;
      case 1:
        return VideoQuality.MediumQuality;
      case 2:
        return VideoQuality.HighestQuality;
      default:
        return VideoQuality.DefaultQuality;
    }
  }
}
