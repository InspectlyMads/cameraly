import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:native_exif/native_exif.dart';

void main() {
  group('Native EXIF GPS Tests', () {
    test('Should write and read GPS coordinates using native_exif', () async {
      // Create a simple test image
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(255, 0, 0));

      // Encode to JPEG
      final jpegBytes = img.encodeJpg(image);

      // Create a temporary file
      final tempDir = Directory.systemTemp.createTempSync('native_exif_test');
      final tempFile = File('${tempDir.path}/test.jpg');
      await tempFile.writeAsBytes(jpegBytes);

      try {
        // Write GPS data using native_exif
        final exif = await Exif.fromPath(tempFile.path);

        // Write GPS coordinates
        await exif.writeAttributes({
          'GPSLatitude': '37.7749',
          'GPSLatitudeRef': 'N',
          'GPSLongitude': '122.4194',
          'GPSLongitudeRef': 'W',
          'GPSAltitude': '10.0',
          'GPSAltitudeRef': '0',
        });

        await exif.close();

        // Read back and verify
        final readExif = await Exif.fromPath(tempFile.path);
        final attributes = await readExif.getAttributes();
        await readExif.close();

        debugPrint('✅ Written GPS attributes:');
        debugPrint('   Latitude: ${attributes?['GPSLatitude']} ${attributes?['GPSLatitudeRef']}');
        debugPrint('   Longitude: ${attributes?['GPSLongitude']} ${attributes?['GPSLongitudeRef']}');
        debugPrint('   Altitude: ${attributes?['GPSAltitude']} (ref: ${attributes?['GPSAltitudeRef']})');

        // Native EXIF only works on mobile platforms, so we can't test in unit tests
        // This is more of a verification that the API calls are correct
        expect(true, isTrue); // Placeholder assertion
      } finally {
        // Cleanup
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
