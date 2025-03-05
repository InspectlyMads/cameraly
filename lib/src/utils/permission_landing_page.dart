import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../cameraly_controller.dart';
import '../cameraly_value.dart';

/// A widget that displays when camera permissions are denied or restricted.
class CameralyPermissionLandingPage extends StatefulWidget {
  /// Creates a permission landing page.
  const CameralyPermissionLandingPage({
    required this.controller,
    this.customWidget,
    this.title,
    this.message,
    this.retryButtonText,
    this.settingsButtonText,
    this.backgroundColor = Colors.black,
    this.textColor = Colors.white,
    this.buttonColor,
    this.iconColor,
    super.key,
  });

  /// The controller for the camera.
  final CameralyController controller;

  /// Optional custom widget to display instead of the default UI.
  final Widget? customWidget;

  /// The title text to display.
  final String? title;

  /// The message text to display.
  final String? message;

  /// The text to display on the retry button.
  final String? retryButtonText;

  /// The text to display on the settings button.
  final String? settingsButtonText;

  /// The background color of the landing page.
  final Color backgroundColor;

  /// The color of the text on the landing page.
  final Color textColor;

  /// The color of the buttons on the landing page.
  final Color? buttonColor;

  /// The color of the icon on the landing page.
  final Color? iconColor;

  @override
  State<CameralyPermissionLandingPage> createState() => _CameralyPermissionLandingPageState();
}

class _CameralyPermissionLandingPageState extends State<CameralyPermissionLandingPage> {
  bool _isCheckingPermission = false;
  PermissionStatus _cameraPermissionStatus = PermissionStatus.denied;
  PermissionStatus _microphonePermissionStatus = PermissionStatus.denied;
  bool _requiresAudio = false;

  @override
  void initState() {
    super.initState();
    _requiresAudio = widget.controller.settings.enableAudio;
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    setState(() {
      _isCheckingPermission = true;
    });

    final cameraStatus = await Permission.camera.status;
    PermissionStatus microphoneStatus = PermissionStatus.granted;

    if (_requiresAudio) {
      microphoneStatus = await Permission.microphone.status;
    }

    setState(() {
      _cameraPermissionStatus = cameraStatus;
      _microphonePermissionStatus = microphoneStatus;
      _isCheckingPermission = false;
    });
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isCheckingPermission = true;
    });

    try {
      await widget.controller.initialize();
      // If we get here, permissions were granted and initialization succeeded
    } catch (e) {
      // If initialization failed, check the permission status again
      await _checkPermissionStatus();
    } finally {
      setState(() {
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  String get _getTitle {
    if (_cameraPermissionStatus == PermissionStatus.permanentlyDenied) {
      return widget.title ?? 'Camera Access Permanently Denied';
    }
    if (_requiresAudio && _microphonePermissionStatus == PermissionStatus.permanentlyDenied) {
      return widget.title ?? 'Microphone Access Permanently Denied';
    }
    return widget.title ?? 'Camera Access Required';
  }

  String get _getMessage {
    if (_cameraPermissionStatus == PermissionStatus.permanentlyDenied) {
      return widget.message ?? 'You have permanently denied camera access. Please enable it in your device settings.';
    }
    if (_requiresAudio && _microphonePermissionStatus == PermissionStatus.permanentlyDenied) {
      return widget.message ?? 'You have permanently denied microphone access. Please enable it in your device settings.';
    }
    if (_requiresAudio) {
      return widget.message ?? 'Please grant camera and microphone access to use this feature.';
    }
    return widget.message ?? 'Please grant camera access to use this feature.';
  }

  bool get _showSettingsButton {
    return _cameraPermissionStatus == PermissionStatus.permanentlyDenied || (_requiresAudio && _microphonePermissionStatus == PermissionStatus.permanentlyDenied);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.customWidget != null) {
      return widget.customWidget!;
    }

    final theme = Theme.of(context);
    final effectiveButtonColor = widget.buttonColor ?? theme.primaryColor;
    final effectiveIconColor = widget.iconColor ?? widget.textColor;

    return Container(
      color: widget.backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isCheckingPermission
              ? CircularProgressIndicator(color: effectiveButtonColor)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.no_photography,
                      size: 64,
                      color: effectiveIconColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: widget.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _showSettingsButton ? _openSettings : _requestPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: effectiveButtonColor,
                        foregroundColor: widget.backgroundColor,
                      ),
                      child: Text(_showSettingsButton ? (widget.settingsButtonText ?? 'Open Settings') : (widget.retryButtonText ?? 'Grant Permission')),
                    ),
                    if (!_showSettingsButton) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          // Notify the controller that the user has chosen to continue without permission
                          widget.controller.value = widget.controller.value.copyWith(
                            permissionState: CameraPermissionState.deniedButContinued,
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: widget.textColor.withAlpha(
                            (0.7 * 255).round(),
                          ),
                        ),
                        child: const Text('Continue Without Camera'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
