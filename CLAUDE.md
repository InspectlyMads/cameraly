# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Build
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app (requires macOS)
- `flutter build appbundle` - Build Android App Bundle for Play Store
- `flutter pub run build_runner build` - Generate code for Riverpod providers and JSON serialization

### Development
- `flutter run` - Run app in debug mode
- `flutter pub get` - Install dependencies
- `flutter clean` - Clean build artifacts and regenerate platform files

### Testing
- `flutter test` - Run all tests
- `flutter test test/unit/` - Run unit tests only
- `flutter test test/widget/` - Run widget tests only
- `flutter test test/integration/` - Run integration tests only
- `flutter test <specific_test_file>` - Run a single test file

### Code Quality
- `flutter analyze` - Run static analysis with flutter_lints

## Architecture

This is a camera application built to test Flutter's camera package orientation handling across different Android devices. Key architectural patterns:

### State Management
Uses Flutter Riverpod with code generation for reactive state management. Providers are organized by feature:
- `camera_providers.dart` - Camera state and operations
- `gallery_providers.dart` - Media gallery management
- `permission_providers.dart` - Permission handling with race condition protection

### Service Layer
Core functionality is abstracted into services:
- `CameraService` - Low-level camera operations and orientation handling
- `CameraUIService` - UI-specific camera helpers (flash modes, camera info)
- `MediaService` - File system operations for photos/videos
- `PermissionService` - Runtime permission management

### UI Architecture
After significant refactoring, the UI follows a modular widget approach:
- Screens are lightweight coordinators (~195 lines for camera screen)
- Complex UI logic is extracted into focused, reusable widgets
- Orientation-specific layouts adapt UI based on device orientation
- Camera preview maintains correct aspect ratio matching captured content

### Key Technical Decisions
1. **Orientation Handling**: Custom implementation to ensure photos/videos have correct orientation metadata regardless of device
2. **Flash Modes**: Context-aware flash options (Photo: Off/Auto/On, Video: Off/Torch)
3. **Permission Race Conditions**: Implemented careful state management to prevent initialization races
4. **Preview Aspect Ratio**: Dynamic calculation to match camera output exactly

## Development Guidelines

### Feature Implementation
When implementing new features (per Cursor rules):
1. Create implementation plan at `/docs/features/[FeatureName]/implementation-plan.md`
2. Break down complex tasks into manageable steps
3. Document permanent feature details separately from temporary task notes

### Code Style
- Follow existing patterns for state management with Riverpod
- Extract complex UI logic into separate widgets
- Use services for business logic, keep widgets focused on presentation
- Maintain comprehensive error handling with user-friendly messages

### Testing Approach
- Write unit tests for models and business logic
- Create widget tests for UI components
- Use integration tests for complex user workflows
- Test orientation handling across different device configurations