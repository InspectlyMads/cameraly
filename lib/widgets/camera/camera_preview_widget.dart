import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart' as camera;
import '../../providers/camera_providers.dart';
import '../../utils/camera_preview_utils.dart';

class CameraPreviewWidget extends ConsumerWidget {
  const CameraPreviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraControllerProvider);
    final controller = cameraState.controller;
    
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final deviceRatio = size.width / size.height;
        final orientation = MediaQuery.of(context).orientation;
        
        // Get adjusted aspect ratio for proper preview display
        // Calculate adjusted aspect ratio based on orientation
        final previewAspectRatio = controller.value.aspectRatio;
        final adjustedAspectRatio = orientation == Orientation.portrait
            ? previewAspectRatio
            : 1 / previewAspectRatio;

        return Center(
          child: AspectRatio(
            aspectRatio: adjustedAspectRatio,
            child: camera.CameraPreview(controller),
          ),
        );
      },
    );
  }
}