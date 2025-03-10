import 'package:flutter/material.dart';

import '../cameraly_overlay_theme.dart';

class CameraControls extends StatelessWidget {
  const CameraControls({
    super.key,
    required this.isVideoMode,
    required this.isRecording,
    required this.showCaptureButton,
    required this.onModeChanged,
    required this.onCapture,
    required this.showModeToggle,
    this.theme,
  });

  final bool isVideoMode;
  final bool isRecording;
  final bool showCaptureButton;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onCapture;
  final bool showModeToggle;
  final CameralyOverlayTheme? theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isRecording && showModeToggle) ...[
          _buildModeToggle(),
          const SizedBox(height: 20),
        ],
        if (showCaptureButton) _buildCaptureButton(),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.4),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildModeButton(
            isSelected: !isVideoMode,
            icon: Icons.photo_camera,
            label: 'Photo',
            onTap: () => onModeChanged(false),
          ),
          const SizedBox(width: 8),
          _buildModeButton(
            isSelected: isVideoMode,
            icon: Icons.videocam,
            label: 'Video',
            onTap: () => onModeChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color.fromRGBO(255, 255, 255, 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white60,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: onCapture,
      child: Container(
        height: 90,
        width: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 5),
          color: isRecording ? Colors.red : Colors.transparent,
        ),
        child: Center(
          child: isRecording
              ? Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                )
              : Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      ),
    );
  }
}
