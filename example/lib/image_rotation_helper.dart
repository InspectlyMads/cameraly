import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ImageRotationHelper {
  // Cache for the current device orientation
  static ImageOrientation? _cachedOrientation;
  static StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Initialize the orientation detection
  static void initOrientationDetection() {
    if (_accelerometerSubscription != null) return;

    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (event.z < -5.0) {
        // Device is facing up in portrait
        _cachedOrientation = ImageOrientation.portraitUp;
      } else if (event.x > 5.0) {
        // Device is in landscape right
        _cachedOrientation = ImageOrientation.landscapeRight;
      } else if (event.x < -5.0) {
        // Device is in landscape left
        _cachedOrientation = ImageOrientation.landscapeLeft;
      } else if (event.z > 5.0) {
        // Device is facing down or upside down
        _cachedOrientation = ImageOrientation.portraitDown;
      }
    });
  }

  // Dispose the orientation detection
  static void disposeOrientationDetection() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  // Get the current device orientation
  static Future<ImageOrientation> getCurrentOrientation() async {
    if (_cachedOrientation == null) {
      // If we don't have a cached orientation, get it from the accelerometer
      final completer = Completer<ImageOrientation>();

      // Declare the subscription variable before using it
      late StreamSubscription<AccelerometerEvent> subscription;

      subscription = accelerometerEvents.listen((AccelerometerEvent event) {
        ImageOrientation orientation;

        if (event.z < -5.0) {
          orientation = ImageOrientation.portraitUp;
        } else if (event.x > 5.0) {
          orientation = ImageOrientation.landscapeRight;
        } else if (event.x < -5.0) {
          orientation = ImageOrientation.landscapeLeft;
        } else if (event.z > 5.0) {
          orientation = ImageOrientation.portraitDown;
        } else {
          // Default to portrait if values are ambiguous
          orientation = ImageOrientation.portraitUp;
        }

        if (!completer.isCompleted) {
          completer.complete(orientation);
        }
        subscription.cancel();
      });

      // Set a timeout in case we don't get accelerometer data
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!completer.isCompleted) {
          completer.complete(ImageOrientation.portraitUp);
        }
      });

      return completer.future;
    }

    return _cachedOrientation!;
  }

  // Main method to rotate an image based on device orientation
  static Future<File> getRotatedImage(File imageFile, [BuildContext? context, bool forceRotation = false]) async {
    debugPrint('🔄 Starting image rotation for: ${imageFile.path}');

    try {
      // First apply EXIF rotation to handle metadata-based orientation
      final File exifRotatedImage = await FlutterExifRotation.rotateImage(path: imageFile.path);
      debugPrint('🔄 EXIF rotation applied');

      // Get the dimensions to determine if we need additional rotation
      final Uint8List imageBytes = await exifRotatedImage.readAsBytes();
      final img.Image? decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        debugPrint('🔄 Failed to decode image');
        return exifRotatedImage;
      }

      final bool isLandscape = decodedImage.width > decodedImage.height;
      debugPrint('🔄 Image dimensions: ${decodedImage.width}x${decodedImage.height}');
      debugPrint('🔄 Is image landscape: $isLandscape');
      debugPrint('🔄 Platform is Android: ${Platform.isAndroid}');

      // For Android, we'll use a simpler approach - always rotate landscape images
      if (Platform.isAndroid && isLandscape) {
        debugPrint('🔄 Android device with landscape image - applying fixed rotation');

        // Try 180 degrees rotation for Android landscape images
        debugPrint('🔄 Applying 180 degree rotation');
        img.Image rotatedImage = img.copyRotate(decodedImage, angle: 180.0);

        // Save the rotated image to a new file
        final Directory tempDir = await getTemporaryDirectory();
        final String tempPath = '${tempDir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File rotatedFile = File(tempPath);

        await rotatedFile.writeAsBytes(img.encodeJpg(rotatedImage, quality: 90));
        debugPrint('🔄 Fixed rotation completed: $tempPath');
        debugPrint('🔄 Rotated image dimensions: ${rotatedImage.width}x${rotatedImage.height}');

        return rotatedFile;
      }

      // For iOS or non-landscape images, just return the EXIF-rotated image
      debugPrint('🔄 No additional rotation needed');
      return exifRotatedImage;
    } catch (e) {
      debugPrint('🔄 Error in image rotation: $e');
      return imageFile; // Return original if rotation fails
    }
  }

  // Special method for gallery display that always rotates landscape images on Android
  static Future<File> getGalleryRotatedImage(File imageFile) async {
    debugPrint('🖼️ Preparing image for gallery display: ${imageFile.path}');

    try {
      // First apply EXIF rotation
      final File exifRotatedImage = await FlutterExifRotation.rotateImage(path: imageFile.path);

      // Get the dimensions
      final Uint8List imageBytes = await exifRotatedImage.readAsBytes();
      final img.Image? decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        debugPrint('🖼️ Failed to decode image for gallery');
        return exifRotatedImage;
      }

      final bool isLandscape = decodedImage.width > decodedImage.height;
      debugPrint('🖼️ Gallery image dimensions: ${decodedImage.width}x${decodedImage.height}');
      debugPrint('🖼️ Is gallery image landscape: $isLandscape');
      debugPrint('🖼️ Platform is Android: ${Platform.isAndroid}');

      // For Android landscape images in gallery view, try 180 degree rotation
      if (Platform.isAndroid && isLandscape) {
        debugPrint('🖼️ Rotating landscape image for Android gallery display');
        debugPrint('🖼️ Applying 180 degree rotation');

        // Rotate 180 degrees for gallery display
        img.Image rotatedImage = img.copyRotate(decodedImage, angle: 180.0);

        final Directory tempDir = await getTemporaryDirectory();
        final String tempPath = '${tempDir.path}/gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File rotatedFile = File(tempPath);

        await rotatedFile.writeAsBytes(img.encodeJpg(rotatedImage, quality: 90));
        debugPrint('🖼️ Gallery rotation completed');
        debugPrint('🖼️ Rotated gallery image dimensions: ${rotatedImage.width}x${rotatedImage.height}');

        return rotatedFile;
      }

      return exifRotatedImage;
    } catch (e) {
      debugPrint('🖼️ Error preparing image for gallery: $e');
      return imageFile;
    }
  }
}

// Enum to represent device orientation
enum ImageOrientation { portraitUp, portraitDown, landscapeLeft, landscapeRight }
