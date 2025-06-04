import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart' as camera;
import '../../providers/camera_providers.dart';
import '../../controllers/flash_controller.dart';
import '../../utils/orientation_ui_helper.dart';
import '../../services/camera_service.dart';

class CameraControlsOverlay extends ConsumerWidget {
  final bool isVideoModeSelected;
  
  const CameraControlsOverlay({
    super.key,
    required this.isVideoModeSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orientation = MediaQuery.of(context).orientation;
    final safeArea = MediaQuery.of(context).padding;
    final cameraState = ref.watch(cameraControllerProvider);
    
    // Hide controls during recording
    if (cameraState.isRecording) {
      return const SizedBox.shrink();
    }
    
    return Stack(
      children: [
        // Close button (top-left)
        Positioned(
          top: 16 + safeArea.top,
          left: 16 + safeArea.left,
          child: _buildCloseButton(context),
        ),
        
        // Right side controls (flash, camera switch) - only in portrait
        if (OrientationUIHelper.isPortrait(orientation))
          Positioned(
            top: 16 + safeArea.top,
            right: 16 + safeArea.right,
            child: _buildRightControls(ref, cameraState),
          ),
      ],
    );
  }
  
  Widget _buildCloseButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(
          Icons.close,
          color: Colors.white,
          size: 24,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
  
  Widget _buildRightControls(WidgetRef ref, CameraState cameraState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Flash control
        _FlashControlButton(isVideoModeSelected: isVideoModeSelected),
        
        const SizedBox(height: 8),
        
        // Camera switch
        _CameraSwitchButton(),
      ],
    );
  }
}

class _FlashControlButton extends ConsumerWidget {
  final bool isVideoModeSelected;
  
  const _FlashControlButton({required this.isVideoModeSelected});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraControllerProvider);
    
    final flashMode = FlashController.getCurrentFlashMode(
      cameraState,
      isVideoModeSelected,
    );
    
    final icon = FlashController.getIcon(
      isVideoModeSelected ? CameraMode.video : cameraState.mode,
      flashMode,
    );
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        onPressed: () => FlashController.cycle(ref, isVideoModeSelected),
      ),
    );
  }
}

class _CameraSwitchButton extends ConsumerWidget {
  const _CameraSwitchButton();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraControllerProvider);
    final hasFrontCamera = ref.watch(availableCamerasProvider).value?.any(
      (cam) => cam.lensDirection == camera.CameraLensDirection.front,
    ) ?? false;
    
    if (!hasFrontCamera) {
      return const SizedBox.shrink();
    }
    
    final isFrontCamera = cameraState.controller?.description.lensDirection == 
        camera.CameraLensDirection.front;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          isFrontCamera ? Icons.camera_front : Icons.camera_rear,
          color: Colors.white,
          size: 24,
        ),
        onPressed: () => ref.read(cameraControllerProvider.notifier).switchCamera(),
      ),
    );
  }
}