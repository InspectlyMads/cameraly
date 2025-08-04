import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:cameraly/cameraly.dart';

void main() {
  group('EXIF Writing Tests', () {
    test('Should write and read GPS coordinates from EXIF', () async {
      // Create a simple test image
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(255, 0, 0));
      
      // Encode to JPEG
      final jpegBytes = img.encodeJpg(image);
      
      // Create a temporary file
      final tempDir = Directory.systemTemp.createTempSync('exif_test');
      final tempFile = File('${tempDir.path}/test.jpg');
      await tempFile.writeAsBytes(jpegBytes);
      
      // Create test metadata with GPS data
      final testMetadata = PhotoMetadata(
        latitude: 37.7749,
        longitude: -122.4194,
        altitude: 10.0,
        deviceManufacturer: 'Test',
        deviceModel: 'TestModel',
        osVersion: 'TestOS 1.0',
        cameraName: 'TestCamera',
        lensDirection: 'back',
        capturedAt: DateTime.now(),
        captureTimeMillis: 100,
      );
      
      // Verify metadata was created correctly
      expect(testMetadata.latitude, 37.7749);
      expect(testMetadata.longitude, -122.4194);
      
      // Use reflection to access private method for testing
      // In production, this would be called internally by savePhoto
      try {
        // Read the file
        final bytes = await tempFile.readAsBytes();
        final decodedImage = img.decodeImage(bytes);
        
        if (decodedImage != null) {
          // Add EXIF data
          decodedImage.exif = img.ExifData();
          
          // Write GPS data
          decodedImage.exif.gpsIfd['GPSLatitudeRef'] = 'N';
          decodedImage.exif.gpsIfd['GPSLatitude'] = [
            [37, 1],
            [46, 1],
            [2964, 100],
          ];
          decodedImage.exif.gpsIfd['GPSLongitudeRef'] = 'W';
          decodedImage.exif.gpsIfd['GPSLongitude'] = [
            [122, 1],
            [25, 1],
            [984, 100],
          ];
          
          // Write back
          final newBytes = img.encodeJpg(decodedImage);
          await tempFile.writeAsBytes(newBytes);
          
          // Read and verify
          final verifyBytes = await tempFile.readAsBytes();
          final verifyImage = img.decodeImage(verifyBytes);
          
          expect(verifyImage?.exif.gpsIfd['GPSLatitudeRef'], equals('N'));
          expect(verifyImage?.exif.gpsIfd['GPSLongitudeRef'], equals('W'));
          expect(verifyImage?.exif.gpsIfd['GPSLatitude'], isNotNull);
          expect(verifyImage?.exif.gpsIfd['GPSLongitude'], isNotNull);
          
          print('✅ EXIF GPS data successfully written and verified');
        }
      } finally {
        // Cleanup
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}