import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_exif/native_exif.dart';

/// A manager for handling EXIF operations with robust error handling
/// and fallback mechanisms for reliable operation across platforms.
class ExifManager {
  /// Adds GPS metadata to an image by directly embedding the data
  /// with a sidecar file fallback when direct embedding fails.
  static Future<bool> addGpsMetadata({
    required String filePath,
    required double latitude,
    required double longitude,
    double? altitude,
    DateTime? timestamp,
  }) async {
    debugPrint('📍 ExifManager: Adding GPS metadata to $filePath');
    debugPrint('📍 ExifManager: Location: lat=$latitude, lng=$longitude, alt=$altitude');

    final File file = File(filePath);
    if (!await file.exists()) {
      debugPrint('⚠️ ExifManager: File does not exist: $filePath');
      return false;
    }

    // Try direct EXIF embedding first
    bool directEmbeddingSuccess = await _embedExifMetadata(filePath, latitude, longitude, altitude, timestamp);

    if (directEmbeddingSuccess) {
      debugPrint('✅ ExifManager: Successfully embedded GPS metadata into image file');
      return true;
    }

    // Fall back to sidecar file if direct embedding fails
    debugPrint('ℹ️ ExifManager: Direct EXIF embedding failed, using sidecar file fallback');
    return _createSidecarFile(filePath, latitude, longitude, altitude, timestamp);
  }

  /// Embeds EXIF metadata directly into the image file using native_exif
  static Future<bool> _embedExifMetadata(
    String filePath,
    double latitude,
    double longitude,
    double? altitude,
    DateTime? timestamp,
  ) async {
    try {
      // Create backup first
      final backupPath = '${filePath}_backup';
      await File(filePath).copy(backupPath);

      // Only support JPG/JPEG for now since native_exif works best with them
      final extension = filePath.split('.').last.toLowerCase();
      if (extension != 'jpg' && extension != 'jpeg') {
        debugPrint('⚠️ ExifManager: Only JPG/JPEG supported for direct EXIF embedding, falling back to sidecar for $extension');
        await File(backupPath).delete();
        return false;
      }

      // Use native_exif to write GPS data
      final exif = await Exif.fromPath(filePath);

      // Convert lat/lng to appropriate format
      // GPS coordinates in EXIF need to be stored in a specific format
      final latStr = latitude.abs().toString();
      final latRef = latitude >= 0 ? 'N' : 'S';

      final lngStr = longitude.abs().toString();
      final lngRef = longitude >= 0 ? 'E' : 'W';

      // Write attributes
      final attributes = <String, String>{
        'GPSLatitude': latStr,
        'GPSLatitudeRef': latRef,
        'GPSLongitude': lngStr,
        'GPSLongitudeRef': lngRef,
      };

      // Add altitude if provided
      if (altitude != null) {
        attributes['GPSAltitude'] = altitude.abs().toString();
        attributes['GPSAltitudeRef'] = altitude >= 0 ? '0' : '1'; // 0 = above sea level, 1 = below
      }

      // Add timestamp
      final now = timestamp ?? DateTime.now();
      final dateTimeFormat = '${now.year}:${now.month.toString().padLeft(2, '0')}:${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      attributes['DateTimeOriginal'] = dateTimeFormat;

      // Write all GPS attributes at once
      await exif.writeAttributes(attributes);

      // Close exif to ensure changes are saved
      await exif.close();

      // Verify the file is good and data was written
      try {
        final verifyExif = await Exif.fromPath(filePath);
        final coords = await verifyExif.getLatLong();
        if (coords != null) {
          debugPrint('✅ ExifManager: GPS coordinates verified: ${coords.latitude}, ${coords.longitude}');
          await verifyExif.close();
          await File(backupPath).delete();
          return true;
        } else {
          debugPrint('⚠️ ExifManager: Could not verify GPS data was written');
        }
        await verifyExif.close();
      } catch (e) {
        debugPrint('⚠️ ExifManager: Error verifying EXIF data: $e');
      }

      // If we get here, something went wrong - restore from backup
      try {
        await File(backupPath).copy(filePath);
        await File(backupPath).delete();
        debugPrint('⚠️ ExifManager: Restored from backup due to verification failure');
      } catch (e) {
        debugPrint('⚠️ ExifManager: Error restoring backup: $e');
      }

      return false;
    } catch (e) {
      debugPrint('⚠️ ExifManager: Error in EXIF embedding: $e');

      // Try to restore from backup if it exists
      try {
        final backupFile = File('${filePath}_backup');
        if (await backupFile.exists()) {
          await backupFile.copy(filePath);
          await backupFile.delete();
          debugPrint('⚠️ ExifManager: Restored from backup after error');
        }
      } catch (e) {
        debugPrint('⚠️ ExifManager: Error restoring backup: $e');
      }

      return false;
    }
  }

  /// Creates a sidecar file with location data
  /// This is used as a fallback when direct EXIF editing fails
  static Future<bool> _createSidecarFile(
    String imagePath,
    double latitude,
    double longitude,
    double? altitude,
    DateTime? timestamp,
  ) async {
    try {
      // Create a simple JSON file with the location data
      final sidecarPath = '$imagePath.location.json';
      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'timestamp': (timestamp ?? DateTime.now()).millisecondsSinceEpoch,
      };

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(locationData);

      // Write to file
      await File(sidecarPath).writeAsString(jsonString);
      debugPrint('📍 ExifManager: Created location sidecar file: $sidecarPath');
      return true;
    } catch (e) {
      debugPrint('⚠️ ExifManager: Error creating location sidecar file: $e');
      return false;
    }
  }

  /// Reads location data from an image file or its sidecar JSON file
  static Future<Position?> getLocationFromImage(String imagePath) async {
    try {
      // Try to read embedded EXIF data first using native_exif
      try {
        final exif = await Exif.fromPath(imagePath);
        final latLong = await exif.getLatLong();

        if (latLong != null) {
          debugPrint('📍 ExifManager: Found embedded GPS data in image using native_exif');

          // Get altitude if available
          double altitude = 0;
          try {
            final attrs = await exif.getAttributes();
            if (attrs != null) {
              if (attrs.containsKey('GPSAltitude')) {
                final altString = attrs['GPSAltitude']?.toString();
                if (altString != null) {
                  altitude = double.tryParse(altString) ?? 0;
                  // Check if below sea level
                  if (attrs.containsKey('GPSAltitudeRef')) {
                    final altRef = attrs['GPSAltitudeRef']?.toString();
                    if (altRef == '1') {
                      altitude = -altitude;
                    }
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('⚠️ ExifManager: Error reading altitude: $e');
          }

          await exif.close();

          return Position(
            latitude: latLong.latitude,
            longitude: latLong.longitude,
            timestamp: DateTime.now(), // We don't have this from EXIF
            accuracy: 0,
            altitude: altitude,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        }
        await exif.close();
      } catch (e) {
        debugPrint('⚠️ ExifManager: Error reading EXIF with native_exif: $e');
      }

      // If embedded data not found, try sidecar file
      debugPrint('📍 ExifManager: No embedded GPS data, checking sidecar file');
      final sidecarFile = File('$imagePath.location.json');
      if (await sidecarFile.exists()) {
        try {
          final jsonString = await sidecarFile.readAsString();
          final locationData = jsonDecode(jsonString) as Map<String, dynamic>;

          return Position(
            latitude: locationData['latitude'] as double,
            longitude: locationData['longitude'] as double,
            timestamp: DateTime.fromMillisecondsSinceEpoch(locationData['timestamp'] as int),
            accuracy: locationData['accuracy'] as double? ?? 0,
            altitude: locationData['altitude'] as double? ?? 0,
            heading: locationData['heading'] as double? ?? 0,
            speed: locationData['speed'] as double? ?? 0,
            speedAccuracy: locationData['speedAccuracy'] as double? ?? 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        } catch (e) {
          debugPrint('⚠️ ExifManager: Error reading location sidecar file: $e');
        }
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ ExifManager: Error getting location from image: $e');
      return null;
    }
  }
}
