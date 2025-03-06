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
    try {
      // Check current camera status
      var cameraStatus = await Permission.camera.status;
      debugPrint('Current camera permission status: $cameraStatus');

      // Request camera permission if needed
      if (!cameraStatus.isGranted) {
        cameraStatus = await Permission.camera.request();
        debugPrint('After request, camera permission status: $cameraStatus');
      }

      // Handle microphone permission if required
      if (requireAudio) {
        var micStatus = await Permission.microphone.status;
        debugPrint('Current microphone permission status: $micStatus');

        if (!micStatus.isGranted) {
          micStatus = await Permission.microphone.request();
          debugPrint('After request, microphone permission status: $micStatus');
        }

        // Return true only if both permissions are granted
        return cameraStatus.isGranted && micStatus.isGranted;
      }

      return cameraStatus.isGranted;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  /// Checks camera and optionally microphone permissions.
  ///
  /// If [requireAudio] is true, both camera and microphone permissions will be checked.
  /// Returns true if all required permissions are granted, false otherwise.
  Future<bool> checkPermissions({bool requireAudio = false}) async {
    try {
      final cameraStatus = await Permission.camera.status;
      debugPrint('Checking camera permission status: $cameraStatus');

      if (!cameraStatus.isGranted) {
        return false;
      }

      if (requireAudio) {
        final microphoneStatus = await Permission.microphone.status;
        debugPrint('Checking microphone permission status: $microphoneStatus');

        if (!microphoneStatus.isGranted) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }

  /// Checks if permissions are permanently denied.
  ///
  /// If [requireAudio] is true, both camera and microphone permissions will be checked.
  /// Returns true if any required permission is permanently denied.
  Future<bool> isPermanentlyDenied({bool requireAudio = false}) async {
    final cameraStatus = await Permission.camera.status;
    if (cameraStatus == PermissionStatus.permanentlyDenied) {
      return true;
    }
    if (requireAudio) {
      final microphoneStatus = await Permission.microphone.status;
      if (microphoneStatus == PermissionStatus.permanentlyDenied) {
        return true;
      }
    }
    return false;
  }

  /// Opens the app settings page.
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Force permission request for cases where normal requests might not trigger the system dialog.
  ///
  /// This method is useful for handling edge cases where the standard permission request
  /// might not show the system dialog, particularly on some iOS versions.
  Future<bool> forcePermissionRequest({bool requireAudio = false}) async {
    try {
      // Directly request permissions without checking status first
      final cameraStatus = await Permission.camera.request();
      debugPrint('Direct camera permission request result: $cameraStatus');

      if (requireAudio) {
        // Also request microphone permission
        final micResult = await Permission.microphone.request();
        debugPrint('Direct microphone permission request result: $micResult');

        return cameraStatus.isGranted && micResult.isGranted;
      }

      return cameraStatus.isGranted;
    } catch (e) {
      debugPrint('Error forcing permission request: $e');
      return false;
    }
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
    this.backgroundColor = Colors.black,
    this.textColor = Colors.white,
    this.buttonColor,
    this.iconColor,
    this.isPermanentlyDenied = false,
    this.showContinueWithoutCameraButton = false,
    this.onContinueWithoutCameraPressed,
    super.key,
  });

  /// Callback when the retry button is pressed.
  final VoidCallback? onRetryPressed;

  /// Callback when the settings button is pressed.
  final VoidCallback? onSettingsPressed;

  /// Callback when the continue without camera button is pressed.
  final VoidCallback? onContinueWithoutCameraPressed;

  /// The title text to display.
  final String? title;

  /// The message text to display.
  final String? message;

  /// The text to display on the retry button.
  final String? retryButtonText;

  /// The text to display on the settings button.
  final String? settingsButtonText;

  /// The background color of the widget.
  final Color backgroundColor;

  /// The color of the text on the widget.
  final Color textColor;

  /// The color of the buttons on the widget.
  final Color? buttonColor;

  /// The color of the icon on the widget.
  final Color? iconColor;

  /// Whether the permission is permanently denied.
  final bool isPermanentlyDenied;

  /// Whether to show the "Continue Without Camera" button.
  final bool showContinueWithoutCameraButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveButtonColor = buttonColor ?? theme.primaryColor;
    final effectiveIconColor = iconColor ?? theme.colorScheme.error;

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
                  Icons.no_photography,
                  size: 64,
                  color: effectiveIconColor,
                ),
                const SizedBox(height: 16),
                Text(
                  title ?? (isPermanentlyDenied ? 'Camera Access Permanently Denied' : 'Camera Access Required'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message ?? (isPermanentlyDenied ? 'You have permanently denied camera access. Please enable it in your device settings.' : 'Please grant camera access to use this feature.'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isPermanentlyDenied ? onSettingsPressed : onRetryPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: effectiveButtonColor,
                    foregroundColor: backgroundColor,
                  ),
                  child: Text(isPermanentlyDenied ? (settingsButtonText ?? 'Open Settings') : (retryButtonText ?? 'Grant Permission')),
                ),
                if (!isPermanentlyDenied && onSettingsPressed != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onSettingsPressed,
                    style: TextButton.styleFrom(
                      foregroundColor: textColor,
                    ),
                    child: Text(settingsButtonText ?? 'Open Settings'),
                  ),
                ],
                if (showContinueWithoutCameraButton && onContinueWithoutCameraPressed != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onContinueWithoutCameraPressed,
                    style: TextButton.styleFrom(
                      foregroundColor: textColor.withAlpha((0.7 * 255).round()),
                    ),
                    child: const Text('Continue Without Camera'),
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

/// A widget that handles the permission flow and displays appropriate UI.
class CameralyPermissionFlow extends StatefulWidget {
  /// Creates a widget that handles the permission flow.
  const CameralyPermissionFlow({
    required this.child,
    required this.onPermissionGranted,
    this.onPermissionDenied,
    this.onPermissionPermanentlyDenied,
    this.onContinueWithoutCamera,
    this.requireAudio = false,
    this.permissionDeniedWidget,
    this.backgroundColor = Colors.black,
    this.textColor = Colors.white,
    this.buttonColor,
    this.iconColor,
    this.showContinueWithoutCameraButton = false,
    super.key,
  });

  /// The widget to display when permissions are granted.
  final Widget child;

  /// Callback when permissions are granted.
  final VoidCallback onPermissionGranted;

  /// Callback when permissions are denied.
  final VoidCallback? onPermissionDenied;

  /// Callback when permissions are permanently denied.
  final VoidCallback? onPermissionPermanentlyDenied;

  /// Callback when the user chooses to continue without camera.
  final VoidCallback? onContinueWithoutCamera;

  /// Whether to require microphone permission.
  final bool requireAudio;

  /// Custom widget to display when permissions are denied.
  final Widget? permissionDeniedWidget;

  /// The background color of the permission denied widget.
  final Color backgroundColor;

  /// The color of the text on the permission denied widget.
  final Color textColor;

  /// The color of the buttons on the permission denied widget.
  final Color? buttonColor;

  /// The color of the icon on the permission denied widget.
  final Color? iconColor;

  /// Whether to show the "Continue Without Camera" button.
  final bool showContinueWithoutCameraButton;

  @override
  State<CameralyPermissionFlow> createState() => _CameralyPermissionFlowState();
}

class _CameralyPermissionFlowState extends State<CameralyPermissionFlow> {
  final _permissionHandler = const CameralyPermissionHandler();
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _isPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isCheckingPermission = true;
    });

    // First check if permissions are permanently denied
    final isPermanentlyDenied = await _permissionHandler.isPermanentlyDenied(
      requireAudio: widget.requireAudio,
    );

    if (isPermanentlyDenied) {
      setState(() {
        _hasPermission = false;
        _isPermanentlyDenied = true;
        _isCheckingPermission = false;
      });
      widget.onPermissionPermanentlyDenied?.call();
      return;
    }

    // Then check if permissions are granted
    final hasPermission = await _permissionHandler.checkPermissions(
      requireAudio: widget.requireAudio,
    );

    if (hasPermission) {
      setState(() {
        _hasPermission = true;
        _isCheckingPermission = false;
      });
      widget.onPermissionGranted();
      return;
    }

    // If not, try to request permissions
    final permissionResult = await _permissionHandler.requestPermissions(
      requireAudio: widget.requireAudio,
    );

    setState(() {
      _hasPermission = permissionResult;
      _isCheckingPermission = false;
    });

    if (permissionResult) {
      widget.onPermissionGranted();
    } else {
      widget.onPermissionDenied?.call();
    }
  }

  Future<void> _retryPermissionRequest() async {
    // Use the force request method for more reliable permission dialogs
    final result = await _permissionHandler.forcePermissionRequest(
      requireAudio: widget.requireAudio,
    );

    setState(() {
      _hasPermission = result;
    });

    if (result) {
      widget.onPermissionGranted();
    } else {
      // Check if permissions are now permanently denied
      final isPermanentlyDenied = await _permissionHandler.isPermanentlyDenied(
        requireAudio: widget.requireAudio,
      );

      if (isPermanentlyDenied && mounted) {
        setState(() {
          _isPermanentlyDenied = true;
        });
        widget.onPermissionPermanentlyDenied?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return Container(
        color: widget.backgroundColor,
        child: Center(
          child: CircularProgressIndicator(
            color: widget.buttonColor ?? Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    if (_hasPermission) {
      return widget.child;
    }

    if (widget.permissionDeniedWidget != null) {
      return widget.permissionDeniedWidget!;
    }

    return CameralyPermissionDeniedWidget(
      onRetryPressed: _retryPermissionRequest,
      onSettingsPressed: () => _permissionHandler.openSettings(),
      onContinueWithoutCameraPressed: widget.showContinueWithoutCameraButton ? widget.onContinueWithoutCamera : null,
      isPermanentlyDenied: _isPermanentlyDenied,
      backgroundColor: widget.backgroundColor,
      textColor: widget.textColor,
      buttonColor: widget.buttonColor,
      iconColor: widget.iconColor,
      showContinueWithoutCameraButton: widget.showContinueWithoutCameraButton,
    );
  }
}
