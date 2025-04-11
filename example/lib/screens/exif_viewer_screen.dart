import 'dart:io';

import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// A screen that allows capturing an image and then displaying its EXIF metadata
class ExifViewerScreen extends StatefulWidget {
  const ExifViewerScreen({super.key});

  @override
  State<ExifViewerScreen> createState() => _ExifViewerScreenState();
}

class _ExifViewerScreenState extends State<ExifViewerScreen> {
  // Keep track of captured media
  XFile? _capturedImage;
  Map<String, dynamic> _exifData = {};
  bool _isLoading = false;
  bool _checkingPermissions = true;
  String? _permissionError;
  Position? _locationData;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    setState(() {
      _checkingPermissions = true;
      _permissionError = null;
    });

    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _checkingPermissions = false;
          _permissionError = 'Location services are disabled. Please enable location services in your device settings.';
        });
        return;
      }

      // Check permission status
      var permission = await Geolocator.checkPermission();

      // If denied, request permission
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          setState(() {
            _checkingPermissions = false;
            _permissionError = 'Location permission denied. Location metadata won\'t be added to photos.';
          });
          return;
        }
      }

      // Handle permanently denied permissions
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _checkingPermissions = false;
          _permissionError = 'Location permissions are permanently denied. Please enable them in app settings.';
        });
        return;
      }

      // Permission granted
      setState(() {
        _checkingPermissions = false;
      });

      // Try to get location once to trigger the permission dialog
      try {
        await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 2));
      } catch (e) {
        // It's okay if this fails, we just want to trigger the permission prompt
        debugPrint('Initial location check: $e');
      }
    } catch (e) {
      setState(() {
        _checkingPermissions = false;
        _permissionError = 'Error checking location permission: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(appBar: AppBar(title: const Text('EXIF Metadata Viewer'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop())), body: _buildBody()));
  }

  Widget _buildBody() {
    // Show loading indicator while checking permissions
    if (_checkingPermissions) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Checking location permissions...')]));
    }

    // Show error message if permission check failed
    if (_permissionError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_disabled, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_permissionError!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _checkLocationPermission, child: const Text('Try Again')),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _permissionError = null;
                  });
                },
                child: const Text('Continue Anyway'),
              ),
            ],
          ),
        ),
      );
    }

    // Show camera or EXIF data
    return _capturedImage == null ? _buildCameraView() : _buildExifDataView();
  }

  Widget _buildCameraView() {
    return CameralyCamera(
      settings: CameraPreviewSettings(
        // Camera settings - photo only mode with high resolution
        cameraMode: CameraMode.photoOnly,
        resolution: ResolutionPreset.high,
        flashMode: FlashMode.auto,
        enableAudio: false,
        // Enable location metadata for GPS information
        addLocationMetadata: true,

        // UI configuration
        showSwitchCameraButton: true,
        showFlashButton: true,
        showMediaStack: false,
        showCaptureButton: true,

        // Loading text
        loadingText: 'Initializing camera for EXIF test...',

        // Debug location services before capture
        onInitialized: (controller) async {
          debugPrint('🔍 EXIF Debug: Camera initialized');
          try {
            // Check if location services are enabled
            final serviceEnabled = await Geolocator.isLocationServiceEnabled();
            debugPrint('🔍 EXIF Debug: Location services enabled? $serviceEnabled');

            // Check permission status
            final permission = await Geolocator.checkPermission();
            debugPrint('🔍 EXIF Debug: Location permission status: $permission');

            // Try to get current position
            try {
              final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 5));
              debugPrint('🔍 EXIF Debug: Current location available: ${position.latitude}, ${position.longitude}');
            } catch (e) {
              debugPrint('🔍 EXIF Debug: Failed to get current location: $e');
            }
          } catch (e) {
            debugPrint('🔍 EXIF Debug: Error checking location: $e');
          }
        },

        // Capture callback to process the image
        onCapture: (file) {
          debugPrint('Captured image: ${file.path}');
          debugPrint('🔍 EXIF Debug: Image captured, loading EXIF data');
          setState(() {
            _capturedImage = file;
            _loadExifData(file);
          });
        },

        onError: (source, message, {error, isRecoverable = false}) {
          debugPrint('❌ Camera error ($source): $message');
          if (error != null) {
            debugPrint('❌ Error details: $error');
          }
        },
      ),
    );
  }

  Widget _buildExifDataView() {
    return Column(
      children: [
        // Image preview at the top (limited height)
        SizedBox(height: 200, width: double.infinity, child: _capturedImage != null ? Image.file(File(_capturedImage!.path), fit: BoxFit.contain) : const SizedBox()),

        // EXIF data in a scrollable list
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Custom location section with better formatting
                      _buildLocationSection(),

                      // Image Section
                      _buildSection('Image Information', _getImageData()),

                      // Camera Section
                      _buildSection('Camera Information', _getCameraData()),
                    ],
                  ),
        ),

        // Button to take another photo
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _capturedImage = null;
                _exifData = {};
                _locationData = null;
              });
            },
            child: const Text('Take Another Photo'),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Map<String, dynamic> data) {
    if (data.isEmpty) return const SizedBox();

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(), ...data.entries.map((entry) => _buildExifEntry(entry.key, entry.value))]),
      ),
    );
  }

  Widget _buildExifEntry(String key, dynamic value) {
    // Format the value if it's a list or map
    final formattedValue = value is List || value is Map ? value.toString() : value?.toString() ?? 'null';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(flex: 2, child: Text(key, style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(flex: 3, child: Text(formattedValue, style: const TextStyle(color: Colors.black87)))],
      ),
    );
  }

  Future<void> _loadExifData(XFile file) async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔍 EXIF Debug: Loading EXIF data from ${file.path}');

      // Try to get location data using ExifManager (checks both embedded EXIF and sidecar file)
      _locationData = await ExifManager.getLocationFromImage(file.path);

      if (_locationData != null) {
        // Determine if we're using EXIF or sidecar
        final bool isEmbeddedExif = await _isEmbeddedExifData(file.path);
        final String source = isEmbeddedExif ? "embedded EXIF metadata" : "sidecar file";

        debugPrint('📍 Location data found in $source');

        // Convert Position to a map for display
        final Map<String, dynamic> locationMap = {
          'GPSLatitude': _locationData!.latitude,
          'GPSLongitude': _locationData!.longitude,
          'GPSAltitude': _locationData!.altitude,
          'GPSAccuracy': _locationData!.accuracy,
          'GPSTimestamp': DateTime.fromMillisecondsSinceEpoch(_locationData!.timestamp.millisecondsSinceEpoch).toString(),
          'MetadataSource': source.toUpperCase(),
        };

        setState(() {
          _exifData = locationMap;
          _isLoading = false;
        });

        // Log EXIF data for debugging
        debugPrint('Location data loaded from $source');
        _logGpsData();
      } else {
        debugPrint('⚠️ No location data found in image or sidecar file');
        setState(() {
          _exifData = {};
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading location data: $e');
      setState(() {
        _exifData = {};
        _isLoading = false;
      });
    }
  }

  // Helper method to check if data is coming from embedded EXIF
  Future<bool> _isEmbeddedExifData(String filePath) async {
    try {
      // Check for the sidecar file first - if it exists, we're using that
      final sidecarFile = File('$filePath.location.json');
      if (await sidecarFile.exists()) {
        return false; // Using sidecar file
      }

      // Use ExifManager's method to attempt to read from EXIF
      final position = await ExifManager.getLocationFromImage(filePath);

      // If we get position data and no sidecar exists, it must be embedded EXIF
      return position != null;
    } catch (e) {
      debugPrint('Error checking for embedded EXIF: $e');
      return false;
    }
  }

  // Checks if GPS data is present
  bool _hasGpsData() {
    return _locationData != null;
  }

  // Extracts GPS data
  Map<String, dynamic> _getGpsData() {
    if (_locationData == null) {
      return {};
    }

    return {
      'Latitude': _locationData!.latitude,
      'Longitude': _locationData!.longitude,
      'Altitude': _locationData!.altitude,
      'Accuracy': _locationData!.accuracy,
      'Timestamp': DateTime.fromMillisecondsSinceEpoch(_locationData!.timestamp.millisecondsSinceEpoch).toString(),
    };
  }

  // Log GPS data
  void _logGpsData() {
    if (_locationData != null) {
      debugPrint('📍 GPS Data found:');
      debugPrint('  Latitude: ${_locationData!.latitude}');
      debugPrint('  Longitude: ${_locationData!.longitude}');
      debugPrint('  Altitude: ${_locationData!.altitude}');
      debugPrint('  Timestamp: ${_locationData!.timestamp}');
    } else {
      debugPrint('📍 No GPS data found in the image');
    }
  }

  // For compatibility with existing UI that expects camera properties
  Map<String, dynamic> _getCameraData() {
    if (_capturedImage == null) {
      return {'Note': 'No image captured'};
    }

    // Extract information from file path - this is crude but can give some information
    // Example path: .../compressed_1744362382407.jpg
    final filename = _capturedImage!.path.split('/').last;
    final extension = filename.split('.').last.toLowerCase();

    // Add basic information about the capture
    return {'Source': 'Cameraly App', 'File Type': extension.toUpperCase(), 'Capture Time': DateTime.now().toString(), 'Note': 'Full camera metadata not available in sidecar file'};
  }

  // For compatibility with existing UI that expects image properties
  Map<String, dynamic> _getImageData() {
    File? imageFile = _capturedImage != null ? File(_capturedImage!.path) : null;

    if (imageFile != null && imageFile.existsSync()) {
      try {
        // Get basic file stats
        final fileStat = imageFile.statSync();
        final fileSize = (fileStat.size / 1024).toStringAsFixed(2);
        final modified = DateTime.fromMillisecondsSinceEpoch(fileStat.modified.millisecondsSinceEpoch);

        // Try to get image dimensions using the Image class if possible
        // For a real implementation, you might use a package like image_size_getter

        return {
          'Filename': _capturedImage!.path.split('/').last,
          'File Size': '$fileSize KB',
          'Last Modified': modified.toString(),
          'Creation Time': DateTime.fromMillisecondsSinceEpoch(fileStat.changed.millisecondsSinceEpoch).toString(),
          'Path': _capturedImage!.path,
        };
      } catch (e) {
        debugPrint('Error getting image stats: $e');
      }
    }

    return {'Note': 'Image metadata not available'};
  }

  // Add a new method to display location data properly
  Widget _buildLocationSection() {
    if (_locationData == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [Text('Location Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Divider(), Text('No location data available for this image', style: TextStyle(fontStyle: FontStyle.italic))],
          ),
        ),
      );
    }

    // Check if we know the metadata source
    final String metadataSource = _exifData.containsKey('MetadataSource') ? _exifData['MetadataSource'].toString() : 'UNKNOWN SOURCE';

    // Format location data nicely
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Location Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            // Add metadata source with appropriate styling
            _buildStyledExifEntry('Source', metadataSource, style: TextStyle(fontWeight: FontWeight.w600, color: metadataSource.contains('EMBEDDED') ? Colors.green.shade700 : Colors.orange.shade800)),
            _buildExifEntry('Latitude', '${_locationData!.latitude.toStringAsFixed(6)}° ${_locationData!.latitude >= 0 ? 'N' : 'S'}'),
            _buildExifEntry('Longitude', '${_locationData!.longitude.toStringAsFixed(6)}° ${_locationData!.longitude >= 0 ? 'E' : 'W'}'),
            _buildExifEntry('Altitude', '${_locationData!.altitude.toStringAsFixed(1)} meters'),
            _buildExifEntry('Accuracy', '${_locationData!.accuracy.toStringAsFixed(1)} meters'),
            _buildExifEntry('Timestamp', _locationData!.timestamp.toString()),
          ],
        ),
      ),
    );
  }

  // Version with styling options
  Widget _buildStyledExifEntry(String key, String value, {TextStyle? style}) {
    final String formattedValue = value.isEmpty ? 'None' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(flex: 2, child: Text(key, style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(flex: 3, child: Text(formattedValue, style: style ?? const TextStyle(color: Colors.black87)))],
      ),
    );
  }
}
