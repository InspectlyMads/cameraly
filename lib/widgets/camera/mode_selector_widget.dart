import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/camera_providers.dart';
import '../../services/camera_service.dart';

class ModeSelectorWidget extends ConsumerWidget {
  final bool isVideoModeSelected;
  final ValueChanged<bool> onVideoModeChanged;
  
  const ModeSelectorWidget({
    super.key,
    required this.isVideoModeSelected,
    required this.onVideoModeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraControllerProvider);
    
    if (cameraState.mode == CameraMode.combined) {
      return _CombinedModeSelector(
        isVideoSelected: isVideoModeSelected,
        onChanged: onVideoModeChanged,
      );
    }
    
    return _buildModeInfo(cameraState);
  }
  
  Widget _buildModeInfo(CameraState state) {
    String modeText;
    switch (state.mode) {
      case CameraMode.photo:
        modeText = 'PHOTO';
        break;
      case CameraMode.video:
        modeText = 'VIDEO';
        break;
      case CameraMode.combined:
        modeText = isVideoModeSelected ? 'VIDEO' : 'PHOTO';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        modeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CombinedModeSelector extends StatelessWidget {
  final bool isVideoSelected;
  final ValueChanged<bool> onChanged;
  
  const _CombinedModeSelector({
    required this.isVideoSelected,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 160,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left: isVideoSelected ? 80 : 0,
            top: 0,
            bottom: 0,
            width: 80,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Row(
            children: [
              _buildModeOption(
                'PHOTO',
                !isVideoSelected,
                () => onChanged(false),
              ),
              _buildModeOption(
                'VIDEO',
                isVideoSelected,
                () => onChanged(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildModeOption(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(isSelected ? 1.0 : 0.6),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}