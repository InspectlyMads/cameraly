# Cameraly v1.0 Roadmap

## Current Status ✅

### Core Features
- ✅ Photo and video capture
- ✅ Orientation handling (all devices)
- ✅ Permission management (mode-specific)
- ✅ Flash modes (context-aware)
- ✅ Zoom controls (pinch + slider)
- ✅ Tap to focus
- ✅ Grid overlay
- ✅ Custom UI support
- ✅ Video duration limits
- ✅ Recording timer/countdown
- ✅ Metadata capture (GPS, EXIF)
- ✅ Android selfie mirroring

### Architecture
- ✅ Service-oriented design
- ✅ Riverpod state management
- ✅ Error handling
- ✅ Permission race condition protection

## Required for v1.0 🚀

### 1. Package Metadata & Publishing
- [ ] Update pubspec.yaml with:
  - Proper description
  - Homepage URL
  - Repository URL
  - Issue tracker URL
  - Documentation URL
  - Screenshots
- [ ] Add example screenshots to README
- [ ] Create animated GIF demos
- [ ] Add pub.dev badges

### 2. Testing Coverage
- [ ] Unit tests for:
  - All service classes
  - Providers
  - Models
  - Utilities
- [ ] Widget tests for:
  - Camera screen states
  - Custom widget integration
  - Orientation changes
- [ ] Integration tests for:
  - Full capture flow
  - Permission handling
  - Mode switching

### 3. Documentation
- [ ] API documentation for all public classes/methods
- [ ] Complete example app showing all features
- [ ] Migration guide from camera package
- [ ] Troubleshooting guide
- [ ] Platform-specific setup guide

### 4. Essential Missing Features
- [ ] **Image/Video Quality Settings**
  ```dart
  CameraScreen(
    photoQuality: PhotoQuality.high, // low, medium, high, max
    videoQuality: VideoQuality.FHD,   // HD, FHD, UHD
  )
  ```

- [ ] **Aspect Ratio Options**
  ```dart
  CameraScreen(
    aspectRatio: CameraAspectRatio.ratio_16_9, // 4:3, 16:9, 1:1, full
  )
  ```

- [ ] **Photo Timer**
  ```dart
  CameraScreen(
    photoTimerSeconds: 3, // 3, 5, 10 seconds
  )
  ```

- [ ] **Exposure Control**
  ```dart
  // Exposure compensation slider (-2 to +2)
  onExposureChanged: (double value) { }
  ```

### 5. Platform Optimization
- [ ] iOS-specific:
  - [ ] Support for ProRAW (iPhone 12 Pro+)
  - [ ] Support for Cinematic mode
  - [ ] Night mode detection
- [ ] Android-specific:
  - [ ] Support for Camera2 API advanced features
  - [ ] Night mode detection
  - [ ] Pro mode controls

### 6. Accessibility
- [ ] Screen reader support
- [ ] Semantic labels for all controls
- [ ] High contrast mode support
- [ ] Haptic feedback options

### 7. Error Recovery
- [ ] Graceful handling of:
  - [ ] Camera disconnection
  - [ ] Storage full
  - [ ] Permission revoked mid-use
  - [ ] App backgrounding during recording
- [ ] Retry mechanisms for recoverable errors
- [ ] User-friendly error messages

### 8. Performance & Memory
- [ ] Memory leak testing
- [ ] Performance profiling
- [ ] Optimization for older devices
- [ ] Proper cleanup on dispose

### 9. Additional UI/UX
- [ ] Loading states for all operations
- [ ] Smooth transitions between modes
- [ ] Animation for capture feedback
- [ ] Better visual feedback for focus

### 10. Package Features
- [ ] Export configuration class
  ```dart
  CameralyConfig(
    enableLogging: true,
    crashReporting: false,
    defaultQuality: Quality.high,
  )
  ```

## Nice to Have (v1.1+) 🎯

- Burst mode for photos
- HDR support
- Manual focus mode
- White balance control
- ISO control
- Shutter speed control
- RAW photo support
- Video stabilization options
- Slow motion video
- Time-lapse video
- QR/Barcode scanning
- Face detection
- Image filters/effects
- Video trimming
- Multi-camera support (wide + tele simultaneously)

## Breaking Changes to Consider

Before v1.0, we should finalize:
1. API naming conventions
2. Model class structures
3. Provider organization
4. Error handling approach
5. Callback signatures

## Release Checklist

- [ ] All tests passing
- [ ] Documentation complete
- [ ] Example app polished
- [ ] Performance benchmarked
- [ ] Memory leaks verified
- [ ] Accessibility tested
- [ ] Security review done
- [ ] License verified
- [ ] CHANGELOG updated
- [ ] Version tagged