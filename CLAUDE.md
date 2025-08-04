# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cameraly is a comprehensive Flutter camera package with advanced features including orientation handling, metadata capture, custom UI, and smart permissions management. It provides both photo and video capture capabilities with extensive customization options.

## Development Commands

### Flutter Commands
```bash
# Install dependencies
flutter pub get

# Run code generation (for Riverpod providers)
flutter pub run build_runner build --delete-conflicting-outputs

# Analyze code quality
flutter analyze

# Run tests
flutter test

# Run a specific test file
flutter test test/cameraly_test.dart

# Run the example app
cd example
flutter run
```

### Building
```bash
# Build for iOS (from example directory)
cd example
flutter build ios --no-codesign

# Build for Android (from example directory)
cd example
flutter build apk
```

### Publishing
```bash
# Dry run before publishing
flutter pub publish --dry-run

# Publish to pub.dev
flutter pub publish
```

## Architecture Overview

### State Management
The package uses Riverpod for state management. Key providers are in:
- `lib/src/providers/camera_providers.dart` - Camera state, configuration, and controls
- `lib/src/providers/permission_providers.dart` - Permission state management

### Core Services
- **CameraService** (`lib/src/services/camera_service.dart`) - Main camera controller management
- **MediaService** (`lib/src/services/media_service.dart`) - Handles photo/video capture and saving
- **OrientationService** (`lib/src/services/orientation_service.dart`) - Critical service that ensures correct media orientation
- **PermissionService** (`lib/src/services/permission_service.dart`) - Smart permission handling with race condition prevention
- **MetadataService** (`lib/src/services/metadata_service.dart`) - EXIF data and GPS metadata handling

### UI Components
- **CameraScreen** (`lib/src/screens/camera_screen.dart`) - Main camera UI with customization support
- **CameraCustomWidgets** (`lib/src/models/camera_custom_widgets.dart`) - Allows UI customization

### Key Features Implementation
1. **Orientation Handling** - The OrientationService automatically corrects photo/video orientation using device sensors and EXIF data
2. **Permission Management** - Intelligent permission requests based on camera mode (photo/video/combined)
3. **Memory Management** - MemoryManager service handles cleanup and optimization
4. **Custom UI** - Full UI customization through CameraCustomWidgets

## Important Patterns

### Adding New Features
1. Create model classes in `lib/src/models/`
2. Add service logic in `lib/src/services/`
3. Create providers in `lib/src/providers/` if state management is needed
4. Export public APIs through `lib/cameraly.dart`

### Testing Guidelines
- Test files go in `test/` directory
- Focus on testing services and providers
- Use `flutter_test` package for widget testing

### Code Generation
This project uses Riverpod code generation. After modifying providers:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Platform-Specific Notes

### iOS
- Minimum iOS version: 11.0
- Requires Info.plist entries for camera, microphone, and location permissions
- Uses AVFoundation framework

### Android
- Minimum API level: 21
- Uses Camera2 API
- Requires manifest permissions for camera, audio, and location

## Common Tasks

### Running Example App
The example app demonstrates all features:
```bash
cd example
flutter pub get
flutter run
```

### Debugging
Enable debug logs in CameraScreen:
```dart
CameraScreen(
  enableDebugLogs: true,
  // other parameters
)
```

### Memory Issues
If encountering memory issues, check:
1. MemoryManager service is properly disposing resources
2. Camera controllers are disposed when screen is closed
3. Temporary files are cleaned up in MediaService

## Dependencies
Key dependencies to be aware of:
- `camera: ^0.11.0` - Core camera functionality
- `flutter_riverpod: ^2.5.1` - State management
- `permission_handler: ^12.0.0+1` - Permission handling
- `native_exif: ^0.5.0` - EXIF data manipulation
- `geolocator: ^13.0.2` - GPS location for metadata