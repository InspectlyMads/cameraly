# Task 3: Home Screen Navigation

## Status: ⏳ Not Started

## Objective
Create a simple, intuitive home screen that allows users to navigate to different camera modes and serves as the entry point for the orientation testing workflow.

## Subtasks

### 3.1 Design Home Screen Layout
- [ ] Create basic Scaffold with AppBar
- [ ] Design card-based layout for camera mode selection
- [ ] Add app branding/title: "Camera Orientation Test"
- [ ] Include brief description of the app's purpose
- [ ] Add navigation to gallery screen

### 3.2 Implement Camera Mode Selection
- [ ] Create list of camera mode cards
- [ ] Each card shows mode name, description, and icon
- [ ] Implement tap handlers for navigation to camera screen
- [ ] Pass selected CameraMode to camera screen
- [ ] Add visual feedback for card interactions

### 3.3 Add Permission Status Indicator
- [ ] Show current permission status on home screen
- [ ] Display permission request button if needed
- [ ] Add visual indicators (green checkmarks, red warnings)
- [ ] Handle permission state changes dynamically

### 3.4 Implement Navigation Logic
- [ ] Set up navigation to camera screen with mode parameter
- [ ] Add navigation to gallery screen
- [ ] Implement back navigation handling
- [ ] Add route guards for permission checks

### 3.5 Add Testing Information
- [ ] Include orientation testing instructions
- [ ] Show device information (model, Android version)
- [ ] Add testing checklist/progress indicator
- [ ] Include link to testing documentation

## Detailed Implementation

### 3.1 Home Screen UI Structure
```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Orientation Test'),
        actions: [
          IconButton(
            icon: Icon(Icons.photo_library),
            onPressed: () => Navigator.pushNamed(context, '/gallery'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPermissionStatus(),
          _buildAppDescription(),
          _buildCameraModeList(),
          _buildTestingInfo(),
        ],
      ),
    );
  }
}
```

### 3.2 Camera Mode Cards
```dart
class CameraModeCard extends StatelessWidget {
  final CameraMode mode;
  final VoidCallback onTap;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _getIcon(),
        title: Text(mode.displayName),
        subtitle: Text(_getDescription()),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
```

### 3.3 Permission Status Widget
```dart
class PermissionStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getStatusColor(),
      child: ListTile(
        leading: Icon(_getStatusIcon()),
        title: Text('Camera & Microphone Permissions'),
        subtitle: Text(_getStatusText()),
        trailing: _needsAction() ? ElevatedButton(...) : null,
      ),
    );
  }
}
```

## Files to Create
- `lib/screens/home_screen.dart`
- `lib/widgets/camera_mode_card.dart`
- `lib/widgets/permission_status_card.dart`
- `lib/widgets/testing_info_card.dart`
- `lib/widgets/device_info_card.dart`

## Files to Modify
- `lib/main.dart` (add home screen route)

## UI/UX Considerations

### Visual Design
- Use Material Design 3 components
- Implement consistent spacing and typography
- Use intuitive icons for each camera mode
- Apply appropriate color coding for permission status

### User Experience
- Clear navigation paths
- Informative descriptions for each mode
- Easy access to gallery for verification
- Helpful guidance for first-time users

### Accessibility
- Proper semantic labels for screen readers
- Sufficient color contrast
- Touch target sizes meet minimum requirements
- Support for keyboard navigation

## Camera Mode Descriptions
- **Photos Only**: "Test photo orientation in all device rotations"
- **Videos Only**: "Test video orientation and rotation metadata"
- **Photos & Videos**: "Combined mode similar to standard camera apps"

## Acceptance Criteria
- [ ] Home screen displays all camera modes clearly
- [ ] Navigation to camera screen works with correct mode parameter
- [ ] Permission status is accurately displayed and updated
- [ ] Gallery navigation is easily accessible
- [ ] App purpose and testing instructions are clear
- [ ] UI follows Material Design guidelines
- [ ] Screen is responsive and works in portrait/landscape
- [ ] All interactive elements provide visual feedback

## Testing Points
- [ ] Test navigation to each camera mode
- [ ] Verify permission status updates correctly
- [ ] Test gallery navigation
- [ ] Verify UI responsiveness on different screen sizes
- [ ] Test accessibility features
- [ ] Verify back navigation behavior

## Notes
- Keep the interface simple and focused on testing
- Ensure easy access to captured media for verification
- Consider adding a "Quick Test All Modes" option for efficiency
- Include device information to help with testing documentation

## Estimated Time: 3-4 hours

## Next Task: Task 4 - Basic Camera Screen with Shared Functionality 