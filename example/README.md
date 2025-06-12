# Cameraly Example

This example demonstrates how to use the Cameraly package in your Flutter application.

## Features Demonstrated

### Basic Camera Modes
- **Photo Mode**: Basic photo capture with default UI
- **Video Mode**: Video recording with default UI  
- **Combined Mode**: Switch between photo and video modes

### Custom UI Examples
- **Custom Gallery & Check Buttons**: Replace default buttons with custom widgets
- **Custom Side Widget**: Add custom widget to the left side
- **Fully Custom UI**: All UI elements customized

### Feature Examples
- **Without Location Metadata**: Disable GPS metadata capture
- **Minimal UI**: Hide gallery and check buttons

## Running the Example

1. Make sure you have Flutter installed
2. Clone the repository
3. Navigate to the example directory
4. Run `flutter pub get`
5. Run `flutter run`

## Permissions

The example app will request the following permissions:
- Camera (required for photo/video capture)
- Microphone (required for video recording)
- Location (optional, for GPS metadata)

## Code Examples

### Basic Usage

```dart
CameraScreen(
  initialMode: CameraMode.photo,
  onMediaCaptured: (media) {
    print('Captured: ${media.fileName}');
  },
)
```

### Custom UI

```dart
CameraScreen(
  initialMode: CameraMode.photo,
  customWidgets: CameraCustomWidgets(
    galleryButton: MyCustomGalleryButton(),
    checkButton: MyCustomCheckButton(),
  ),
)
```

### Disable Location Metadata

```dart
CameraScreen(
  initialMode: CameraMode.photo,
  captureLocationMetadata: false,
)
```