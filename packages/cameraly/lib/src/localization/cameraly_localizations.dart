/// Localization class for all strings used in the Cameraly package
/// Users can override these strings by providing their own implementation
class CameralyLocalizations {
  // Camera modes
  String get modePhoto => 'Photo';
  String get modeVideo => 'Video';
  
  // Flash modes
  String get flashOff => 'Off';
  String get flashAuto => 'Auto';
  String get flashOn => 'On';
  String get flashTorch => 'Torch';
  
  // Permissions
  String get permissionCameraRequired => 'Camera permission is required';
  String get permissionMicrophoneRequired => 'Microphone permission is required';
  String get permissionCameraAndMicrophoneRequired => 'Camera and microphone permissions are required';
  String get permissionLocationRequired => 'Location permission is required for geotagging';
  String get permissionDenied => 'Permission denied';
  String get permissionPermanentlyDenied => 'Permission permanently denied. Please enable in settings.';
  
  // Errors
  String get errorCameraNotFound => 'No camera found on this device';
  String get errorCameraInitializationFailed => 'Failed to initialize camera';
  String get errorRecordingFailed => 'Recording failed';
  String get errorCaptureFailed => 'Failed to capture photo';
  String get errorStorageFull => 'Not enough storage space';
  String get errorUnknown => 'An unexpected error occurred';
  String get errorCameraDisconnected => 'Camera disconnected. Attempting to reconnect...';
  
  // UI Elements
  String get buttonTakePhoto => 'Take Photo';
  String get buttonStartRecording => 'Start Recording';
  String get buttonStopRecording => 'Stop Recording';
  String get buttonSwitchCamera => 'Switch Camera';
  String get buttonGrid => 'Grid';
  String get buttonFlash => 'Flash';
  String get buttonZoom => 'Zoom';
  String get buttonRetry => 'Retry';
  String get buttonGoBack => 'Go Back';
  String get buttonGrantPermissions => 'Grant Permissions';
  String get buttonRequestPermissions => 'Request Permissions';
  
  // Recording
  String recordingDuration(String duration) => duration;
  String recordingCountdown(int seconds) => '$seconds';
  
  // Timer
  String get timerOff => 'Off';
  String timerSeconds(int seconds) => '${seconds}s';
  String photoTimerCountdown(int seconds) => '$seconds';
  
  // Zoom
  String zoomLevel(double zoom) => '${zoom.toStringAsFixed(1)}x';
  
  // Aspect ratios
  String get aspectRatio4_3 => '4:3';
  String get aspectRatio16_9 => '16:9';
  String get aspectRatio1_1 => '1:1';
  String get aspectRatioFull => 'Full';
  
  // Quality
  String get qualityLow => 'Low';
  String get qualityMedium => 'Medium';
  String get qualityHigh => 'High';
  String get qualityMax => 'Max';
  String get qualityHD => 'HD';
  String get qualityFullHD => 'Full HD';
  String get qualityUHD => '4K';
  
  // Accessibility
  String get accessibilityCaptureButton => 'Capture button';
  String get accessibilityFlashButton => 'Flash mode button';
  String get accessibilityGridButton => 'Grid overlay button';
  String get accessibilitySwitchCameraButton => 'Switch camera button';
  String get accessibilityZoomSlider => 'Zoom slider';
  String get accessibilityModeSelector => 'Camera mode selector';
  
  // Status messages
  String get statusInitializing => 'Initializing camera...';
  String get statusInitializingCamera => 'Initializing Camera';
  String get statusSettingUpCamera => 'Setting up camera preview...';
  String get statusReady => 'Camera ready';
  String get statusRecording => 'Recording...';
  String get statusProcessing => 'Processing...';
  String get statusSaving => 'Saving...';
  String get statusNotEnoughStorage => 'Not enough storage space available';
  
  // Dialogs
  String get dialogStopRecordingTitle => 'Stop Recording?';
  String get dialogStopRecordingMessage => 'You are currently recording. Do you want to stop and discard the video?';
  String get dialogContinueRecording => 'Continue Recording';
  String get dialogStopAndDiscard => 'Stop & Discard';
  
  // Default instance
  static CameralyLocalizations _instance = CameralyLocalizations();
  
  /// Get the current localization instance
  static CameralyLocalizations get instance => _instance;
  
  /// Set a custom localization instance
  static void setInstance(CameralyLocalizations localizations) {
    _instance = localizations;
  }
}

/// Convenience function to access localizations
CameralyLocalizations get cameralyL10n => CameralyLocalizations.instance;