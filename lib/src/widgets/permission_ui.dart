import 'dart:io';

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
            child: Card(
              color: backgroundColor.withOpacity(0.8),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: buttonColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        needsMicrophone ? Icons.videocam : Icons.camera_alt,
                        size: 64,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      needsMicrophone ? 'Camera & Microphone Access' : 'Camera Access Required',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      needsMicrophone ? 'Please allow access to your camera and microphone to enable video recording with audio.' : 'Please allow access to your camera to take photos.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: buttonColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: buttonColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Why we need this:',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            needsMicrophone ? 'Camera access is needed to take photos and videos. Microphone access is required to record audio with your videos.' : 'Camera access is needed to take photos.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: textColor,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => permissionManager.requestPermissions(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: backgroundColor,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(needsMicrophone ? 'Grant Permissions' : 'Grant Camera Permission'),
                    ),
                  ],
                ),
              ),
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
            child: Card(
              color: backgroundColor.withOpacity(0.8),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: iconColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCamera ? Icons.no_photography : Icons.mic_off,
                        size: 64,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isCamera ? 'Camera Access Denied' : 'Microphone Access Denied',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isCamera ? 'The camera is needed to take photos and videos. Please grant camera access to use this feature.' : 'The microphone is needed to record audio with your videos. Please grant microphone access for full functionality.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => isCamera ? permissionManager.requestCameraPermission() : permissionManager.requestMicrophonePermission(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: backgroundColor,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(isCamera ? Icons.camera_alt : Icons.mic),
                      label: Text(isCamera ? 'Grant Camera Permission' : 'Grant Microphone Permission'),
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

  String get _permissionSettingInstructions {
    if (isCamera) {
      if (Platform.isAndroid) {
        return 'To enable the camera permission:\n'
            '1. Open device Settings\n'
            '2. Go to Apps or Application Manager\n'
            '3. Find this app\n'
            '4. Tap Permissions\n'
            '5. Enable Camera';
      } else if (Platform.isIOS) {
        return 'To enable the camera permission:\n'
            '1. Open device Settings\n'
            '2. Scroll down and find this app\n'
            '3. Tap on the app name\n'
            '4. Enable Camera access';
      }
    } else {
      if (Platform.isAndroid) {
        return 'To enable the microphone permission:\n'
            '1. Open device Settings\n'
            '2. Go to Apps or Application Manager\n'
            '3. Find this app\n'
            '4. Tap Permissions\n'
            '5. Enable Microphone';
      } else if (Platform.isIOS) {
        return 'To enable the microphone permission:\n'
            '1. Open device Settings\n'
            '2. Scroll down and find this app\n'
            '3. Tap on the app name\n'
            '4. Enable Microphone access';
      }
    }
    return 'Please enable the required permission in your device settings.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: backgroundColor.withOpacity(0.8),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: iconColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCamera ? Icons.no_photography : Icons.mic_off,
                          size: 64,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isCamera ? 'Camera Permission Required' : 'Microphone Permission Required',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isCamera ? 'You\'ve denied camera access. This permission is needed to take photos and videos.' : 'You\'ve denied microphone access. This permission is needed to record audio with your videos.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textColor,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How to enable:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _permissionSettingInstructions,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: textColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await permissionManager.openSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: backgroundColor,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Settings'),
                      ),
                      if (!isCamera) ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => permissionManager.dismissPermissionUI(),
                          style: TextButton.styleFrom(
                            foregroundColor: textColor.withAlpha(179),
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text('Continue Without Microphone'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
