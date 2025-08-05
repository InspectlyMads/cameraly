import 'dart:io';
import 'package:flutter/material.dart';
import '../localization/cameraly_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissionType { camera, microphone, gallery, cameraAndMicrophone }

class CameralyPermissionDialog extends StatelessWidget {
  final PermissionType permissionType;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onDismiss;
  final VoidCallback? onContinueWithoutMic;
  final VoidCallback? onRequestPermission;
  final bool allowWithoutMic;
  final bool showRequestButton;

  const CameralyPermissionDialog({
    super.key,
    required this.permissionType,
    this.onOpenSettings,
    this.onDismiss,
    this.onContinueWithoutMic,
    this.onRequestPermission,
    this.allowWithoutMic = false,
    this.showRequestButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = CameralyLocalizations.instance;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // OS back button pressed, return 'dismissed' to navigate back
          Navigator.of(context).pop('dismissed');
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getPermissionIcon(),
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getTitle(localizations),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getMessage(localizations),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (Platform.isIOS) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                localizations.permissionWarningIOS,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dialogTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.permissionHowToEnable,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _buildInstructions(context, localizations),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (showRequestButton && onRequestPermission != null) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onRequestPermission!();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.check),
                        label: Text(localizations.buttonGrantPermissions),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ElevatedButton.icon(
                      onPressed: onOpenSettings ?? () => openAppSettings(),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: showRequestButton ? null : Theme.of(context).primaryColor,
                        foregroundColor: showRequestButton ? null : Theme.of(context).colorScheme.onPrimary,
                      ),
                      icon: const Icon(Icons.settings),
                      label: Text(localizations.permissionOpenSettings),
                    ),
                    if (permissionType == PermissionType.microphone && 
                        allowWithoutMic && 
                        onContinueWithoutMic != null) ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onContinueWithoutMic!();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                        icon: const Icon(Icons.mic_off),
                        label: Text(localizations.permissionContinueWithoutMic),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).pop('dismissed');
                },
                icon: const Icon(Icons.close),
                iconSize: 20,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.withValues(alpha: 0.1),
                  foregroundColor: Colors.grey.shade600,
                  minimumSize: const Size(32, 32),
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPermissionIcon() {
    switch (permissionType) {
      case PermissionType.camera:
        return Icons.camera_alt;
      case PermissionType.microphone:
        return Icons.mic_off;
      case PermissionType.gallery:
        return Icons.photo;
      case PermissionType.cameraAndMicrophone:
        return Icons.perm_camera_mic;
    }
  }

  String _getTitle(CameralyLocalizations localizations) {
    switch (permissionType) {
      case PermissionType.camera:
        return localizations.permissionCameraRequired;
      case PermissionType.microphone:
        return localizations.permissionMicrophoneRequired;
      case PermissionType.gallery:
        return localizations.permissionGalleryRequired;
      case PermissionType.cameraAndMicrophone:
        return localizations.permissionCameraAndMicrophoneRequired;
    }
  }

  String _getMessage(CameralyLocalizations localizations) {
    switch (permissionType) {
      case PermissionType.camera:
        return localizations.permissionCameraMessage;
      case PermissionType.microphone:
        return localizations.permissionMicrophoneMessage;
      case PermissionType.gallery:
        return localizations.permissionGalleryMessage;
      case PermissionType.cameraAndMicrophone:
        return localizations.permissionCameraAndMicrophoneMessage;
    }
  }

  Widget _buildInstructions(BuildContext context, CameralyLocalizations localizations) {
    List<String> steps = [];

    switch (permissionType) {
      case PermissionType.camera:
        steps = Platform.isAndroid 
            ? localizations.permissionStepsCameraAndroid
            : localizations.permissionStepsCameraIOS;
        break;
      case PermissionType.microphone:
        steps = Platform.isAndroid
            ? localizations.permissionStepsMicrophoneAndroid
            : localizations.permissionStepsMicrophoneIOS;
        break;
      case PermissionType.gallery:
        steps = Platform.isAndroid
            ? localizations.permissionStepsGalleryAndroid
            : localizations.permissionStepsGalleryIOS;
        break;
      case PermissionType.cameraAndMicrophone:
        steps = Platform.isAndroid
            ? localizations.permissionStepsCameraAndMicrophoneAndroid
            : localizations.permissionStepsCameraAndMicrophoneIOS;
        break;
    }

    if (steps.isEmpty) {
      return Text(
        localizations.permissionGenericInstructions,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        int index = entry.key;
        String step = entry.value;

        return Padding(
          padding: EdgeInsets.only(bottom: index < steps.length - 1 ? 4 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${index + 1}. ",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Expanded(
                child: Text(
                  step,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Helper function to show the dialog
Future<String?> showCameralyPermissionDialog({
  required BuildContext context,
  required PermissionType permissionType,
  VoidCallback? onOpenSettings,
  VoidCallback? onDismiss,
  VoidCallback? onContinueWithoutMic,
  VoidCallback? onRequestPermission,
  bool allowWithoutMic = false,
  bool showRequestButton = true,
}) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => CameralyPermissionDialog(
      permissionType: permissionType,
      onOpenSettings: onOpenSettings,
      onDismiss: onDismiss,
      onContinueWithoutMic: onContinueWithoutMic,
      onRequestPermission: onRequestPermission,
      allowWithoutMic: allowWithoutMic,
      showRequestButton: showRequestButton,
    ),
  );
}