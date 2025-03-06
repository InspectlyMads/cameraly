# Changelog

All notable changes to the Cameraly package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-03-06

### Added
- Initial release of Cameraly
- Core camera functionality:
  - Camera preview widget with responsive layout
  - Photo capture with customizable settings
  - Video recording with quality options and duration limits
  - Front/back camera switching
  - Flash mode control (auto, on, off, torch)
  - Tap-to-focus with visual indicator
  - Zoom control with pinch gesture
  - Exposure adjustment
- Permission handling:
  - Built-in camera permission request flow
  - Permission denied UI with customization options
- Overlay system:
  - Default camera overlay with customizable controls
  - Support for custom overlays
  - Flexible widget positioning
  - Theme customization
- Media management:
  - Built-in media stack display
  - Custom storage location support
  - Gallery integration
- Platform-specific implementations:
  - Android configuration and optimizations
  - iOS configuration and optimizations
- Comprehensive example application:
  - Basic camera implementation
  - Photo-only mode with custom UI
  - Video recording with duration limits
  - Custom overlay examples
  - Persistent storage example
  - Display customization demo

### Documentation
- Detailed README with setup instructions
- API documentation with examples
- Quick start guide
- Project structure documentation
- Example app documentation

### Known Issues
- UI Inconsistency: When using custom left/right buttons, the switch camera and gallery buttons in the top-right corner have a brighter background color compared to the zoom and flash buttons. This will be addressed in a future update.
- Bottom Overlay Visibility: The bottom overlay widget is automatically hidden during recording. This behavior should be controlled by the developer instead of being a default behavior. Will be made configurable in a future update.
- Camera Switch: The camera switch (lens swap) button is currently non-functional. This is a known issue that will be fixed in an upcoming update.
- Image Orientation: On some Android devices (e.g., Pixel 8), images captured in landscape orientation are rotated 90 degrees. This orientation issue will be fixed in an upcoming update.
- Media Stack Display: The visual stack of recently captured images/videos is currently non-functional. This feature will be re-enabled in an upcoming update.

### Limitations
- Video Recording: Currently no support for pause/resume during video recording
- Flash Modes: Torch mode is only available during video recording
- Gallery Integration: Limited to displaying recent captures, no editing capabilities
- Platform Support: Currently only supports Android and iOS (no web or desktop support)
- Media Display: Recent captures stack temporarily disabled, will be re-enabled with improvements
