# Changelog

## [0.1.0] - 2025-01-06

### Added
- Initial release of Cameraly package
- Complete camera functionality with photo and video capture
- Orientation handling for correct photo/video orientation
- Comprehensive metadata capture (GPS, device sensors, camera settings)
- EXIF metadata writing for photos
- Custom UI widget support
- Grid overlay with rule of thirds
- Zoom controls with pinch-to-zoom and slider
- Tap-to-focus functionality
- Flash modes for photo (off/auto/on) and video (off/torch)
- Camera switching between front and back
- Video recording with optional duration limits
- Recording timer display with countdown
- Platform-specific camera preview mirroring for Android selfie mode
- Mode-specific permission handling (photo mode only requires camera permission)

### Features
- **Camera Modes**: Photo, Video, and Combined modes
- **Orientation Support**: Automatic orientation detection and correction
- **Metadata Capture**: GPS location, altitude, speed, camera settings
- **Custom UI**: Replace any UI element with custom widgets
- **Smart Permissions**: Only requests microphone for video modes
- **Platform Optimizations**: Android selfie preview mirroring
- **Video Controls**: Duration limits with countdown timer
- **Zoom Controls**: Smooth zoom with visual feedback
- **Focus Control**: Tap anywhere to focus with animated indicator

### Platform Support
- iOS 12.0+
- Android 21+
- Full support for portrait and landscape orientations
- Optimized for phones and tablets