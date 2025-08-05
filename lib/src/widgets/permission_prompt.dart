import 'package:flutter/material.dart';
import '../localization/cameraly_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'permission_dialog.dart' show PermissionType;

enum PermissionPromptType { initial, denied, permanentlyDenied }

/// A streamlined permission prompt that appears as a bottom sheet or overlay
class CameralyPermissionPrompt extends StatelessWidget {
  final PermissionType permissionType;
  final PermissionPromptType promptType;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onDismiss;

  const CameralyPermissionPrompt({
    super.key,
    required this.permissionType,
    required this.promptType,
    this.onOpenSettings,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = CameralyLocalizations.instance;
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPermissionIcon(),
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTitle(localizations),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMessage(localizations),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Action button
            if (promptType == PermissionPromptType.permanentlyDenied) ...[
              ElevatedButton.icon(
                onPressed: () {
                  onOpenSettings?.call();
                  openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.settings),
                label: Text(localizations.permissionOpenSettings),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss?.call();
                },
                child: Text(localizations.buttonCancel),
              ),
            ] else ...[
              // Show loading indicator for automatic permission request
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 16),
              Text(
                localizations.permissionRequesting,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
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
        return Icons.mic;
      case PermissionType.gallery:
        return Icons.photo_library;
      case PermissionType.cameraAndMicrophone:
        return Icons.perm_camera_mic;
    }
  }

  String _getTitle(CameralyLocalizations localizations) {
    if (promptType == PermissionPromptType.permanentlyDenied) {
      return localizations.permissionPermanentlyDenied;
    }
    
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
    if (promptType == PermissionPromptType.permanentlyDenied) {
      return localizations.permissionPermanentlyDeniedMessage;
    }
    
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
}

/// Shows a permission prompt as a modal bottom sheet
Future<void> showCameralyPermissionPrompt({
  required BuildContext context,
  required PermissionType permissionType,
  required PermissionPromptType promptType,
  VoidCallback? onOpenSettings,
  VoidCallback? onDismiss,
}) {
  return showModalBottomSheet(
    context: context,
    isDismissible: promptType == PermissionPromptType.permanentlyDenied,
    enableDrag: promptType == PermissionPromptType.permanentlyDenied,
    backgroundColor: Colors.transparent,
    builder: (context) => CameralyPermissionPrompt(
      permissionType: permissionType,
      promptType: promptType,
      onOpenSettings: onOpenSettings,
      onDismiss: onDismiss,
    ),
  );
}