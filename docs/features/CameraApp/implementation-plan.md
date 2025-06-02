# Camera App MVP - Implementation Plan

## 📋 Quick Reference Documents
- **[Complete Dependencies Overview](./dependencies.md)** - All packages, versions, and installation commands
- **[Comprehensive Testing Strategy](./testing-strategy.md)** - Progressive testing implementation with orientation focus
- **[MVP Requirements](../../mvp.md)** - Original scope and objectives

## Project Overview

**Primary Objective:** Build a Flutter camera app to test and understand how the `camera` package handles orientation on various Android devices, specifically focusing on how captured photos and videos are oriented when saved.

**Success Criteria:**
- App successfully captures photos and videos in all device orientations
- Captured media displays correctly in both the app's gallery and device's native gallery
- Camera preview renders correctly across different orientations
- App handles camera lifecycle properly (background/foreground transitions)
- Comprehensive testing data collected across multiple Android devices

## High-Level Architecture

```
Main App
├── Home Screen (Navigation Hub)
├── Camera Screen (Core Functionality)
│   ├── Photo Mode
│   ├── Video Mode
│   └── Combined Mode
└── Gallery Screen (Verification)
```

## Key Components/Modules

### Core Dependencies
- `camera`: Primary camera functionality
- `path_provider`: File storage management
- `permission_handler`: Runtime permissions
- `video_player`: Video playback in gallery

### Main Screens
1. **HomeScreen** (`lib/screens/home_screen.dart`)
2. **CameraScreen** (`lib/screens/camera_screen.dart`)
3. **GalleryScreen** (`lib/screens/gallery_screen.dart`)

### Supporting Classes
- **CameraMode** (`lib/models/camera_mode.dart`): Enum for different capture modes
- **MediaItem** (`lib/models/media_item.dart`): Data model for captured media
- **PermissionService** (`lib/services/permission_service.dart`): Handle camera/mic permissions
- **StorageService** (`lib/services/storage_service.dart`): File management utilities

## Task Breakdown

### Phase 1: Foundation (Tasks 1-2)
- **Task 1:** Project setup and dependencies
- **Task 2:** Permission handling and app structure

### Phase 2: Core Camera Functionality (Tasks 3-4)
- **Task 3:** Home screen navigation
- **Task 4:** Basic camera screen with shared functionality

### Phase 3: Capture Modes (Tasks 5-7)
- **Task 5:** Photo capture implementation
- **Task 6:** Video recording implementation  
- **Task 7:** Combined photo/video mode

### Phase 4: Verification & Testing (Tasks 8-9)
- **Task 8:** Gallery screen for media verification
- **Task 9:** Comprehensive orientation testing

## Data Structures

### CameraMode Enum
```dart
enum CameraMode {
  photosOnly,
  videosOnly,
  photosAndVideos
}
```

### MediaItem Model
```dart
class MediaItem {
  final String path;
  final MediaType type;
  final DateTime capturedAt;
  final String orientation;
}
```

## Critical Orientation Considerations

1. **Camera Preview Rendering:** Ensure preview adapts correctly to device rotation
2. **Capture Metadata:** Verify EXIF/video metadata contains correct orientation info
3. **UI Overlay Positioning:** Camera controls must remain usable in all orientations
4. **Lifecycle Management:** Camera state preservation during app transitions

## Potential Challenges

1. **Device-Specific Quirks:** Different Android manufacturers may handle camera orientation differently
2. **Permission Complexity:** Modern Android permission models require careful handling
3. **Video Orientation:** Video metadata handling can be more complex than photos
4. **Memory Management:** Proper camera controller disposal to prevent memory leaks
5. **Testing Coverage:** Need access to multiple Android devices for comprehensive testing

## Testing Strategy

### Orientation Matrix Testing
For each capture mode, test all four orientations:
- Portrait Upright
- Landscape Left (USB port right)
- Landscape Right (USB port left)
- Portrait Upside Down

### Verification Points
1. In-app gallery display
2. Native device gallery display
3. Transfer to computer and verify with desktop image/video viewers

## Success Metrics

- [ ] App builds and runs on Android
- [ ] Camera permissions granted and handled gracefully
- [ ] All three camera modes functional
- [ ] Photos captured with correct EXIF orientation
- [ ] Videos captured with correct rotation metadata
- [ ] Media displays correctly in native gallery apps
- [ ] App handles lifecycle transitions without crashes
- [ ] Comprehensive test data collected from multiple devices

## Dependencies & Approvals Needed

**External Libraries:**
- `camera: ^0.10.5+5`: Core camera functionality
- `path_provider: ^2.1.1`: File system access
- `permission_handler: ^11.0.1`: Runtime permissions
- `video_player: ^2.8.1`: Video playback in gallery

**Device Access:**
- Multiple Android devices for testing (various manufacturers, OS versions)
- Access to device native gallery apps for verification

## Timeline Estimate

- **Phase 1:** 1-2 days
- **Phase 2:** 2-3 days  
- **Phase 3:** 3-4 days
- **Phase 4:** 2-3 days
- **Total:** 8-12 days

## Notes

This MVP is specifically designed as a Proof of Concept for orientation testing. The UI will be kept minimal and functional to focus on the core camera behavior rather than polished user experience. 