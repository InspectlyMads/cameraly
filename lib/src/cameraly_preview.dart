import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'cameraly_controller.dart';
import 'cameraly_value.dart';

/// A widget that displays the camera preview.
class CameralyPreview extends StatelessWidget {
  /// Creates a new [CameralyPreview] widget.
  const CameralyPreview({
    required this.controller,
    this.child,
    super.key,
  });

  /// The controller for the camera.
  final CameralyController controller;

  /// Optional child widget to overlay on top of the camera preview.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        if (!value.isInitialized) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (value.permissionState == CameraPermissionState.denied) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.no_photography,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Camera permission is required',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => controller.initialize(),
                    child: const Text('Grant Permission'),
                  ),
                ],
              ),
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller.cameraController!),
            if (child != null) child,
            if (value.error != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    value.error!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
      child: child,
    );
  }
}
