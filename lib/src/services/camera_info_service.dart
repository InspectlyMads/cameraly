import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraInfoService {
  static const String _logTag = 'CameraInfoService';
  
  /// Analyze camera characteristics to determine physical capabilities
  static CameraCharacteristics analyzeCameras(List<CameraDescription> cameras) {

    
    // Group cameras by lens direction
    final backCameras = cameras.where((c) => c.lensDirection == CameraLensDirection.back).toList();
    final frontCameras = cameras.where((c) => c.lensDirection == CameraLensDirection.front).toList();
    

    
    // Analyze back cameras (main camera system)
    bool hasUltraWide = false;
    bool hasTelephoto = false;
    double estimatedMaxZoom = 2.0; // Default minimum zoom
    
    if (backCameras.length >= 3) {
      // 3+ back cameras almost certainly means ultra-wide + main + telephoto
      hasUltraWide = true;
      hasTelephoto = true;
      estimatedMaxZoom = 30.0; // Pro models can do 30x Super Res Zoom
    } else if (backCameras.length >= 2) {
      // 2 back cameras usually means ultra-wide + main
      hasUltraWide = true;
      estimatedMaxZoom = 8.0; // Digital zoom capability
    } else if (backCameras.length == 1) {
      // Single back camera, limited zoom
      estimatedMaxZoom = 4.0;
    }
    
    // Log camera names for debugging
    for (int i = 0; i < cameras.length; i++) {
      final camera = cameras[i];



      
      // Try to infer camera type from name (some devices include hints)
      final nameLower = camera.name.toLowerCase();
      if (nameLower.contains('wide') || nameLower.contains('0.5') || nameLower.contains('0.6')) {
        hasUltraWide = true;
      }
      if (nameLower.contains('tele') || nameLower.contains('zoom')) {
        hasTelephoto = true;
        estimatedMaxZoom = 10.0;
      }
    }
    
    return CameraCharacteristics(
      totalCameras: cameras.length,
      backCameras: backCameras.length,
      frontCameras: frontCameras.length,
      hasUltraWide: hasUltraWide,
      hasTelephoto: hasTelephoto,
      estimatedMinZoom: hasUltraWide ? 0.5 : 1.0,
      estimatedMaxZoom: estimatedMaxZoom,
    );
  }
  
  /// Get recommended zoom presets based on camera analysis
  static List<double> getRecommendedPresets(CameraCharacteristics characteristics, double maxZoom) {
    final presets = <double>[];
    
    // Add ultra-wide if available
    if (characteristics.hasUltraWide) {
      presets.add(0.5);
    }
    
    // Always add 1x
    presets.add(1.0);
    
    // Add 2x if we have decent zoom capability
    if (maxZoom >= 2.0) {
      presets.add(2.0);
    }
    
    // Add telephoto presets if available
    if (characteristics.hasTelephoto && maxZoom >= 5.0) {
      presets.add(5.0);
      
      // Only add higher zoom if actually supported
      if (maxZoom >= 10.0) {
        presets.add(10.0);
      }
    }
    
    return presets;
  }
}

class CameraCharacteristics {
  final int totalCameras;
  final int backCameras;
  final int frontCameras;
  final bool hasUltraWide;
  final bool hasTelephoto;
  final double estimatedMinZoom;
  final double estimatedMaxZoom;
  
  const CameraCharacteristics({
    required this.totalCameras,
    required this.backCameras,
    required this.frontCameras,
    required this.hasUltraWide,
    required this.hasTelephoto,
    required this.estimatedMinZoom,
    required this.estimatedMaxZoom,
  });
}