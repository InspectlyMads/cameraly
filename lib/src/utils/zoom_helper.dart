import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class ZoomHelper {
  static Future<ZoomCapabilities> getDeviceZoomCapabilities() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      final model = androidInfo.model.toLowerCase();
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      
      // Check for specific Pixel models
      if (manufacturer.contains('google')) {
        if (model.contains('pixel 8 pro') || model.contains('pixel 9 pro')) {
          // Pixel Pro models have ultra-wide, main, and telephoto
          return const ZoomCapabilities(
            minZoom: 0.5,
            maxZoom: 30.0,
            hasUltraWide: true,
            hasTelephoto: true,
            presetZooms: [0.5, 1.0, 2.0, 5.0],
          );
        } else if (model.contains('pixel 8') || model.contains('pixel 9')) {
          // Regular Pixel models have ultra-wide and main
          return const ZoomCapabilities(
            minZoom: 0.5,
            maxZoom: 8.0,
            hasUltraWide: true,
            hasTelephoto: false,
            presetZooms: [0.5, 1.0, 2.0],
          );
        } else if (model.contains('pixel 7') || model.contains('pixel 6')) {
          // Older Pixels
          return const ZoomCapabilities(
            minZoom: 0.6,
            maxZoom: 8.0,
            hasUltraWide: true,
            hasTelephoto: false,
            presetZooms: [0.6, 1.0, 2.0],
          );
        }
      }
      
      // Check for Samsung devices
      if (manufacturer.contains('samsung')) {
        if (model.contains('ultra')) {
          return const ZoomCapabilities(
            minZoom: 0.5,
            maxZoom: 100.0,
            hasUltraWide: true,
            hasTelephoto: true,
            presetZooms: [0.5, 1.0, 3.0, 10.0],
          );
        }
      }
    }
    
    // Default capabilities for unknown devices
    return const ZoomCapabilities(
      minZoom: 1.0,
      maxZoom: 8.0,
      hasUltraWide: false,
      hasTelephoto: false,
      presetZooms: [1.0, 2.0],
    );
  }
}

class ZoomCapabilities {
  final double minZoom;
  final double maxZoom;
  final bool hasUltraWide;
  final bool hasTelephoto;
  final List<double> presetZooms;
  
  const ZoomCapabilities({
    required this.minZoom,
    required this.maxZoom,
    required this.hasUltraWide,
    required this.hasTelephoto,
    required this.presetZooms,
  });
}