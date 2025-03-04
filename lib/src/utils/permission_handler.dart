import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles camera and microphone permissions for the Cameraly package.
class CameralyPermissionHandler {
  /// Creates a new [CameralyPermissionHandler] instance.
  const CameralyPermissionHandler();

  /// Requests camera and optionally microphone permissions.
  ///
  /// If [requireAudio] is true, both camera and microphone permissions will be requested.
  /// Returns true if all required permissions are granted, false otherwise.
  Future<bool> requestPermissions({bool requireAudio = false}) async {
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus != PermissionStatus.granted) {
      return false;
    }

    if (requireAudio) {
      final microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  /// Checks camera and optionally microphone permissions.
  ///
  /// If [requireAudio] is true, both camera and microphone permissions will be checked.
  /// Returns true if all required permissions are granted, false otherwise.
  Future<bool> checkPermissions({bool requireAudio = false}) async {
    final cameraStatus = await Permission.camera.status;
    if (cameraStatus != PermissionStatus.granted) {
      return false;
    }
    if (requireAudio) {
      final microphoneStatus = await Permission.microphone.status;
      if (microphoneStatus != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  /// Opens the app settings page.
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}

/// A widget that displays when camera permissions are not granted.
class CameralyPermissionDeniedWidget extends StatelessWidget {
  /// Creates a widget that displays when camera permissions are not granted.
  const CameralyPermissionDeniedWidget({
    this.onRetryPressed,
    this.onSettingsPressed,
    this.title,
    this.message,
    this.retryButtonText,
    this.settingsButtonText,
    super.key,
  });

  /// Callback when the retry button is pressed.
  final VoidCallback? onRetryPressed;

  /// Callback when the settings button is pressed.
  final VoidCallback? onSettingsPressed;

  /// The title text to display.
  final String? title;

  /// The message text to display.
  final String? message;

  /// The text to display on the retry button.
  final String? retryButtonText;

  /// The text to display on the settings button.
  final String? settingsButtonText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_photography,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Camera Access Required',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Please grant camera access to use this feature.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (onRetryPressed != null)
              ElevatedButton(
                onPressed: onRetryPressed,
                child: Text(retryButtonText ?? 'Try Again'),
              ),
            if (onRetryPressed != null && onSettingsPressed != null) const SizedBox(height: 8),
            if (onSettingsPressed != null)
              TextButton(
                onPressed: onSettingsPressed,
                child: Text(settingsButtonText ?? 'Open Settings'),
              ),
          ],
        ),
      ),
    );
  }
}
