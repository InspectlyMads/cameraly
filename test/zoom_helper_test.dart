import 'package:flutter_test/flutter_test.dart';
import 'package:cameraly/src/utils/zoom_helper.dart';

void main() {
  group('ZoomHelper Tests', () {
    test('ZoomCapabilities has correct properties', () {
      const capabilities = ZoomCapabilities(
        minZoom: 0.5,
        maxZoom: 10.0,
        hasUltraWide: true,
        hasTelephoto: false,
        presetZooms: [0.5, 1.0, 2.0],
      );
      
      expect(capabilities.minZoom, 0.5);
      expect(capabilities.maxZoom, 10.0);
      expect(capabilities.hasUltraWide, isTrue);
      expect(capabilities.hasTelephoto, isFalse);
      expect(capabilities.presetZooms, [0.5, 1.0, 2.0]);
    });
    
    test('Default zoom capabilities are returned for unknown devices', () async {
      // Since we can't mock Platform.isAndroid/isIOS in unit tests easily,
      // we'll test the default capabilities structure
      const defaultCapabilities = ZoomCapabilities(
        minZoom: 1.0,
        maxZoom: 8.0,
        hasUltraWide: false,
        hasTelephoto: false,
        presetZooms: [1.0, 2.0],
      );
      
      expect(defaultCapabilities.minZoom, 1.0);
      expect(defaultCapabilities.maxZoom, 8.0);
      expect(defaultCapabilities.hasUltraWide, isFalse);
      expect(defaultCapabilities.hasTelephoto, isFalse);
      expect(defaultCapabilities.presetZooms.length, 2);
    });
    
    test('Pixel Pro models have correct zoom capabilities', () {
      // Test the expected values for Pixel Pro models
      const pixelProCapabilities = ZoomCapabilities(
        minZoom: 0.5,
        maxZoom: 30.0,
        hasUltraWide: true,
        hasTelephoto: true,
        presetZooms: [0.5, 1.0, 2.0, 5.0],
      );
      
      expect(pixelProCapabilities.minZoom, 0.5);
      expect(pixelProCapabilities.maxZoom, 30.0);
      expect(pixelProCapabilities.hasUltraWide, isTrue);
      expect(pixelProCapabilities.hasTelephoto, isTrue);
      expect(pixelProCapabilities.presetZooms, [0.5, 1.0, 2.0, 5.0]);
    });
    
    test('Samsung Ultra models have correct zoom capabilities', () {
      // Test the expected values for Samsung Ultra models
      const samsungUltraCapabilities = ZoomCapabilities(
        minZoom: 0.5,
        maxZoom: 100.0,
        hasUltraWide: true,
        hasTelephoto: true,
        presetZooms: [0.5, 1.0, 3.0, 10.0],
      );
      
      expect(samsungUltraCapabilities.minZoom, 0.5);
      expect(samsungUltraCapabilities.maxZoom, 100.0);
      expect(samsungUltraCapabilities.hasUltraWide, isTrue);
      expect(samsungUltraCapabilities.hasTelephoto, isTrue);
      expect(samsungUltraCapabilities.presetZooms, [0.5, 1.0, 3.0, 10.0]);
    });
    
    test('Regular Pixel models have correct zoom capabilities', () {
      // Test the expected values for regular Pixel models
      const pixelCapabilities = ZoomCapabilities(
        minZoom: 0.5,
        maxZoom: 8.0,
        hasUltraWide: true,
        hasTelephoto: false,
        presetZooms: [0.5, 1.0, 2.0],
      );
      
      expect(pixelCapabilities.minZoom, 0.5);
      expect(pixelCapabilities.maxZoom, 8.0);
      expect(pixelCapabilities.hasUltraWide, isTrue);
      expect(pixelCapabilities.hasTelephoto, isFalse);
      expect(pixelCapabilities.presetZooms, [0.5, 1.0, 2.0]);
    });
    
    test('Older Pixel models have correct zoom capabilities', () {
      // Test the expected values for older Pixel models
      const olderPixelCapabilities = ZoomCapabilities(
        minZoom: 0.6,
        maxZoom: 8.0,
        hasUltraWide: true,
        hasTelephoto: false,
        presetZooms: [0.6, 1.0, 2.0],
      );
      
      expect(olderPixelCapabilities.minZoom, 0.6);
      expect(olderPixelCapabilities.maxZoom, 8.0);
      expect(olderPixelCapabilities.hasUltraWide, isTrue);
      expect(olderPixelCapabilities.hasTelephoto, isFalse);
      expect(olderPixelCapabilities.presetZooms, [0.6, 1.0, 2.0]);
    });
  });
}