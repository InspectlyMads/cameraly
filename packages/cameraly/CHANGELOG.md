# Changelog

## [1.0.1] - 2025-01-06

### Fixed
- Fixed "Not enough storage space" error when taking photos rapidly
- Added capture throttling to prevent multiple simultaneous captures
- Improved storage space checking (reduced from 50MB to 5MB for photos)
- Added visual feedback when photo capture is in progress
- Better handling of storage checks on iOS
- Fixed video recording continuing after leaving the screen
- Added confirmation dialog when navigating back during recording (both system back and app bar back button)
- Video recording now stops when app goes to background
- Proper cleanup of recording state on screen disposal
- WillPopScope ensures back navigation is intercepted during recording

## [1.0.0] - 2025-01-06

### Added
- Initial stable release of Cameraly package
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
- **Custom UI**: Replace UI elements with custom widgets (except capture button)
- **Smart Permissions**: Only requests microphone for video modes
- **Platform Optimizations**: Android selfie preview mirroring
- **Video Controls**: Duration limits with countdown timer
- **Zoom Controls**: Smooth zoom with visual feedback
- **Focus Control**: Tap anywhere to focus with animated indicator
- **Quality Settings**: Photo and video quality presets
- **Photo Timer**: 3, 5, 10 second countdown timer
- **Aspect Ratios**: 4:3, 16:9, 1:1, and full sensor
- **Error Recovery**: Storage checks, camera reconnection handling
- **Haptic Feedback**: Configurable haptic and sound feedback
- **Memory Management**: Automatic cleanup and optimization
- **Localization Support**: Override all UI strings with custom translations

### Localization
- Complete localization support for all UI strings
- Easy integration with existing localization solutions (easy_localization, etc.)
- Default English strings with override capability
- Support for dynamic strings with parameters

### Memory Management
- Automatic periodic cleanup of old media files
- Configurable retention policies (age and file count)
- Memory usage monitoring and statistics
- Stream-based file operations for large images
- Proper disposal of services and subscriptions

### Platform Support
- iOS 12.0+
- Android 21+
- Full support for portrait and landscape orientations
- Optimized for phones and tablets