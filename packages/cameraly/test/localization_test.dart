import 'package:flutter_test/flutter_test.dart';
import 'package:cameraly/cameraly.dart';

class TestLocalizations extends CameralyLocalizations {
  @override
  String get modePhoto => 'TEST_PHOTO';
  
  @override
  String get modeVideo => 'TEST_VIDEO';
  
  @override
  String get flashOff => 'TEST_FLASH_OFF';
  
  @override
  String recordingDuration(String duration) => 'TEST_DURATION_$duration';
  
  @override
  String zoomLevel(double zoom) => 'TEST_ZOOM_${zoom}x';
}

void main() {
  group('Localization Tests', () {
    test('Default localization returns correct English strings', () {
      final l10n = CameralyLocalizations();
      
      expect(l10n.modePhoto, 'Photo');
      expect(l10n.modeVideo, 'Video');
      expect(l10n.flashOff, 'Off');
      expect(l10n.flashAuto, 'Auto');
      expect(l10n.flashOn, 'On');
      expect(l10n.buttonTakePhoto, 'Take Photo');
      expect(l10n.permissionCameraRequired, 'Camera permission is required');
      expect(l10n.errorCameraNotFound, 'No camera found on this device');
    });
    
    test('Dynamic string methods work correctly', () {
      final l10n = CameralyLocalizations();
      
      expect(l10n.recordingDuration('01:23'), '01:23');
      expect(l10n.recordingCountdown(5), '5');
      expect(l10n.zoomLevel(2.5), '2.5x');
      expect(l10n.timerSeconds(10), '10s');
      expect(l10n.photoTimerCountdown(3), '3');
    });
    
    test('Custom localization can be set and retrieved', () {
      // Store original instance
      final original = CameralyLocalizations.instance;
      
      try {
        // Set custom localization
        final custom = TestLocalizations();
        CameralyLocalizations.setInstance(custom);
        
        // Verify instance is updated
        expect(CameralyLocalizations.instance, same(custom));
        expect(cameralyL10n, same(custom));
        
        // Verify custom strings are returned
        expect(cameralyL10n.modePhoto, 'TEST_PHOTO');
        expect(cameralyL10n.modeVideo, 'TEST_VIDEO');
        expect(cameralyL10n.flashOff, 'TEST_FLASH_OFF');
        expect(cameralyL10n.recordingDuration('02:45'), 'TEST_DURATION_02:45');
        expect(cameralyL10n.zoomLevel(3.0), 'TEST_ZOOM_3.0x');
      } finally {
        // Restore original instance
        CameralyLocalizations.setInstance(original);
      }
    });
    
    test('All localization properties are accessible', () {
      final l10n = CameralyLocalizations();
      
      // Camera modes
      expect(l10n.modePhoto, isNotEmpty);
      expect(l10n.modeVideo, isNotEmpty);
      
      // Flash modes
      expect(l10n.flashOff, isNotEmpty);
      expect(l10n.flashAuto, isNotEmpty);
      expect(l10n.flashOn, isNotEmpty);
      expect(l10n.flashTorch, isNotEmpty);
      
      // Permissions
      expect(l10n.permissionCameraRequired, isNotEmpty);
      expect(l10n.permissionMicrophoneRequired, isNotEmpty);
      expect(l10n.permissionCameraAndMicrophoneRequired, isNotEmpty);
      expect(l10n.permissionLocationRequired, isNotEmpty);
      
      // Errors
      expect(l10n.errorCameraNotFound, isNotEmpty);
      expect(l10n.errorCameraInitializationFailed, isNotEmpty);
      expect(l10n.errorRecordingFailed, isNotEmpty);
      expect(l10n.errorCaptureFailed, isNotEmpty);
      expect(l10n.errorStorageFull, isNotEmpty);
      
      // UI Elements
      expect(l10n.buttonTakePhoto, isNotEmpty);
      expect(l10n.buttonStartRecording, isNotEmpty);
      expect(l10n.buttonStopRecording, isNotEmpty);
      expect(l10n.buttonSwitchCamera, isNotEmpty);
      expect(l10n.buttonRetry, isNotEmpty);
      expect(l10n.buttonGoBack, isNotEmpty);
      
      // Status messages
      expect(l10n.statusInitializing, isNotEmpty);
      expect(l10n.statusReady, isNotEmpty);
      expect(l10n.statusRecording, isNotEmpty);
      
      // Quality
      expect(l10n.qualityLow, isNotEmpty);
      expect(l10n.qualityMedium, isNotEmpty);
      expect(l10n.qualityHigh, isNotEmpty);
      expect(l10n.qualityMax, isNotEmpty);
    });
  });
}