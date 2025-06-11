# Permission Handling in Cameraly

## Overview

Cameraly implements intelligent permission handling that only requests the permissions actually needed based on the camera mode being used.

## Mode-Specific Permissions

### Photo Mode
- **Required Permission**: Camera only
- **Not Required**: Microphone permission
- **Rationale**: Photo capture doesn't require audio recording

### Video Mode
- **Required Permissions**: Camera AND Microphone
- **Rationale**: Video recording requires both video and audio capture

### Combined Mode
- **Required Permissions**: Camera AND Microphone
- **Rationale**: User can switch to video mode, so both permissions are needed upfront

## Implementation Details

### Permission Service Methods

The `PermissionService` class provides mode-aware permission methods:

```dart
// Check permissions based on mode
Future<bool> hasRequiredPermissionsForMode(CameraMode mode)

// Request permissions based on mode
Future<bool> requestPermissionsForMode(CameraMode mode)
```

### Camera Provider Integration

The camera provider automatically:
1. Checks only the required permissions for the current mode
2. Shows appropriate error messages based on what's missing
3. Only requests permissions that are actually needed

### UI Adaptation

The camera screen adapts its permission UI based on mode:
- Photo mode: "Camera Permission Required"
- Video/Combined modes: "Camera & Microphone Required"

## Benefits

1. **Better User Experience**: Users aren't asked for microphone permission when they only want to take photos
2. **Privacy-Conscious**: Only requests permissions that are actually needed
3. **Clear Communication**: Error messages clearly indicate which permissions are needed and why

## Testing

To test the permission behavior:

1. Reset app permissions in iOS Settings
2. Open the example app
3. Try "Photo Mode" - should only ask for camera permission
4. Reset permissions again
5. Try "Video Mode" - should ask for both camera and microphone permissions

## Platform Notes

### iOS
- Permissions are requested one at a time for better user experience
- Clear usage descriptions in Info.plist explain why each permission is needed

### Android
- Both permissions can be requested together
- Manifest includes appropriate permission declarations