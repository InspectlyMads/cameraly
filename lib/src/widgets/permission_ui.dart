import 'package:flutter/material.dart';

import '../utils/permission_manager.dart';

/// A widget that displays various permission-related UIs based on the current permission state
class CameralyPermissionUI extends StatelessWidget {
  /// Creates a [CameralyPermissionUI] widget
  const CameralyPermissionUI({
    required this.permissionManager,
    required this.child,
    this.backgroundColor = Colors.black,
    this.textColor = Colors.white,
    this.buttonColor,
    this.iconColor,
    super.key,
  });

  /// The permission manager to use
  final CameralyPermissionManager permissionManager;

  /// The child widget to display when permissions are granted
  final Widget child;

  /// The background color of the permission UI
  final Color backgroundColor;

  /// The text color to use in the permission UI
  final Color textColor;

  /// The color to use for buttons in the permission UI
  final Color? buttonColor;

  /// The color to use for icons in the permission UI
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    // Listen for changes in the permission manager
    return AnimatedBuilder(
      animation: permissionManager,
      builder: (context, _) {
        // If we don't need to show the permission UI, show the child
        if (!permissionManager.showPermissionUI) {
          return child;
        }

        // Handle different permission states
        if (permissionManager.cameraPermissionState == PermissionState.permanentlyDenied) {
          return _PermanentlyDeniedUI(
            permissionManager: permissionManager,
            backgroundColor: backgroundColor,
            textColor: textColor,
            buttonColor: buttonColor ?? Theme.of(context).primaryColor,
            iconColor: iconColor ?? Colors.red,
            isCamera: true,
          );
        }

        if (permissionManager.cameraPermissionState == PermissionState.denied) {
          return _DeniedPermissionUI(
            permissionManager: permissionManager,
            backgroundColor: backgroundColor,
            textColor: textColor,
            buttonColor: buttonColor ?? Theme.of(context).primaryColor,
            iconColor: iconColor ?? Colors.orange,
            isCamera: true,
          );
        }

        // Check if microphone is needed based on camera mode
        final needsMicrophone = permissionManager.needsMicrophonePermission();

        // If camera is granted but microphone is required and permanently denied
        if (permissionManager.cameraPermissionState == PermissionState.granted && needsMicrophone && permissionManager.microphonePermissionState == PermissionState.permanentlyDenied) {
          return _PermanentlyDeniedUI(
            permissionManager: permissionManager,
            backgroundColor: backgroundColor,
            textColor: textColor,
            buttonColor: buttonColor ?? Theme.of(context).primaryColor,
            iconColor: iconColor ?? Colors.red,
            isCamera: false,
          );
        }

        // If camera is granted but microphone is required and denied
        if (permissionManager.cameraPermissionState == PermissionState.granted && needsMicrophone && permissionManager.microphonePermissionState == PermissionState.denied) {
          return _DeniedPermissionUI(
            permissionManager: permissionManager,
            backgroundColor: backgroundColor,
            textColor: textColor,
            buttonColor: buttonColor ?? Theme.of(context).primaryColor,
            iconColor: iconColor ?? Colors.orange,
            isCamera: false,
            canContinueWithoutMic: true,
          );
        }

        // Default to showing the permission request UI
        return _InitialPermissionRequestUI(
          permissionManager: permissionManager,
          backgroundColor: backgroundColor,
          textColor: textColor,
          buttonColor: buttonColor ?? Theme.of(context).primaryColor,
          iconColor: iconColor ?? Theme.of(context).primaryColor,
        );
      },
    );
  }
}

/// UI for the initial permission request
class _InitialPermissionRequestUI extends StatelessWidget {
  const _InitialPermissionRequestUI({
    required this.permissionManager,
    required this.backgroundColor,
    required this.textColor,
    required this.buttonColor,
    required this.iconColor,
  });

  final CameralyPermissionManager permissionManager;
  final Color backgroundColor;
  final Color textColor;
  final Color buttonColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final needsMicrophone = permissionManager.needsMicrophonePermission();

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  needsMicrophone ? Icons.videocam : Icons.camera_alt,
                  size: 64,
                  color: iconColor,
                ),
                const SizedBox(height: 16),
                Text(
                  needsMicrophone ? 'Camera & Microphone Access' : 'Camera Access Required',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: textColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  needsMicrophone ? 'Please allow access to your camera and microphone to enable video recording with audio.' : 'Please allow access to your camera to take photos.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => permissionManager.requestPermissions(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: backgroundColor,
                  ),
                  child: const Text('Grant Permission'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// UI for when permissions are denied but can be requested again
class _DeniedPermissionUI extends StatelessWidget {
  const _DeniedPermissionUI({
    required this.permissionManager,
    required this.backgroundColor,
    required this.textColor,
    required this.buttonColor,
    required this.iconColor,
    required this.isCamera,
    this.canContinueWithoutMic = false,
  });

  final CameralyPermissionManager permissionManager;
  final Color backgroundColor;
  final Color textColor;
  final Color buttonColor;
  final Color iconColor;
  final bool isCamera;
  final bool canContinueWithoutMic;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCamera ? Icons.no_photography : Icons.mic_off,
                  size: 64,
                  color: iconColor,
                ),
                const SizedBox(height: 16),
                Text(
                  isCamera ? 'Camera Access Denied' : 'Microphone Access Denied',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: textColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isCamera ? 'The camera is needed to take photos and videos. Please grant camera access to use this feature.' : 'The microphone is needed to record audio with your videos. Please grant microphone access for full functionality.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => isCamera ? permissionManager.requestCameraPermission() : permissionManager.requestMicrophonePermission(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: backgroundColor,
                  ),
                  child: Text(isCamera ? 'Grant Camera Access' : 'Grant Microphone Access'),
                ),
                if (canContinueWithoutMic) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => permissionManager.dismissPermissionUI(),
                    style: TextButton.styleFrom(
                      foregroundColor: textColor.withAlpha(179),
                    ),
                    child: const Text('Continue Without Microphone'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// UI for when permissions are permanently denied
class _PermanentlyDeniedUI extends StatelessWidget {
  const _PermanentlyDeniedUI({
    required this.permissionManager,
    required this.backgroundColor,
    required this.textColor,
    required this.buttonColor,
    required this.iconColor,
    required this.isCamera,
  });

  final CameralyPermissionManager permissionManager;
  final Color backgroundColor;
  final Color textColor;
  final Color buttonColor;
  final Color iconColor;
  final bool isCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCamera ? Icons.no_photography : Icons.mic_off,
                  size: 64,
                  color: iconColor,
                ),
                const SizedBox(height: 16),
                Text(
                  isCamera ? 'Camera Access Permanently Denied' : 'Microphone Access Permanently Denied',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: textColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isCamera
                      ? 'You have permanently denied camera access. Please enable it in your device settings to use this feature.'
                      : 'You have permanently denied microphone access. Please enable it in your device settings for full functionality.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await permissionManager.openSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: backgroundColor,
                  ),
                  child: const Text('Open Settings'),
                ),
                if (!isCamera) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => permissionManager.dismissPermissionUI(),
                    style: TextButton.styleFrom(
                      foregroundColor: textColor.withAlpha(179),
                    ),
                    child: const Text('Continue Without Microphone'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
