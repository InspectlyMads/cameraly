import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

/// A screen that demonstrates how to create custom camera overlays
class CustomOverlayExample extends StatefulWidget {
  const CustomOverlayExample({super.key});

  @override
  State<CustomOverlayExample> createState() => _CustomOverlayExampleState();
}

class _CustomOverlayExampleState extends State<CustomOverlayExample> {
  bool _isRecording = false;
  bool _torchEnabled = false;
  String? _errorMessage;

  // Custom overlay widget that demonstrates various UI elements
  Widget _buildCustomOverlay(BuildContext context, CameralyController controller) {
    // We use the provided controller parameter directly

    return Stack(
      fit: StackFit.expand,
      children: [
        // Top bar with camera controls
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 50),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flash toggle button
                ValueListenableBuilder<CameralyValue>(
                  valueListenable: controller,
                  builder: (context, value, child) {
                    // Only show flash controls for photo mode or video mode with torch
                    final isPhotoMode = controller.settings.cameraMode == CameraMode.photoOnly;
                    if (!isPhotoMode && !_isRecording) {
                      return IconButton(
                        icon: Icon(_torchEnabled ? Icons.flashlight_on : Icons.flashlight_off, color: Colors.white),
                        onPressed: () async {
                          setState(() => _torchEnabled = !_torchEnabled);
                          await controller.setFlashMode(_torchEnabled ? FlashMode.torch : FlashMode.off);
                        },
                      );
                    }

                    if (isPhotoMode) {
                      return IconButton(
                        icon: Icon(
                          value.flashMode == FlashMode.off
                              ? Icons.flash_off
                              : value.flashMode == FlashMode.auto
                              ? Icons.flash_auto
                              : Icons.flash_on,
                          color: Colors.white,
                        ),
                        onPressed: controller.toggleFlash,
                      );
                    }

                    return const SizedBox.shrink(); // Hide during recording
                  },
                ),
                // Camera switch button
                IconButton(icon: const Icon(Icons.cameraswitch, color: Colors.white), onPressed: controller.switchCamera),
              ],
            ),
          ),
        ),

        // Center focus area indicator
        Center(child: Container(width: 80, height: 80, decoration: BoxDecoration(border: Border.all(color: Colors.white30, width: 1), borderRadius: BorderRadius.circular(8)))),

        // Bottom controls
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 50),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Custom mode toggle
                ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, value, child) {
                    final isPhotoMode = controller.settings.cameraMode == CameraMode.photoOnly;
                    return TextButton(
                      onPressed: () async {
                        // Use navigation to rebuild screen with different mode
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CustomOverlayExample()));
                      },
                      child: Text(isPhotoMode ? 'PHOTO' : 'VIDEO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
                // Capture/record button
                GestureDetector(
                  onTapDown: (_) async {
                    if (controller.settings.cameraMode == CameraMode.photoOnly) {
                      await controller.takePicture();
                    } else {
                      if (_isRecording) {
                        // Get the recorded video but handle it with onCapture instead
                        await controller.stopVideoRecording();
                        setState(() => _isRecording = false);
                      } else {
                        await controller.startVideoRecording();
                        setState(() => _isRecording = true);
                      }
                    }
                  },
                  child: ValueListenableBuilder(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      final isPhoto = controller.settings.cameraMode == CameraMode.photoOnly;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isPhoto ? 80 : 60,
                        height: isPhoto ? 80 : 60,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red : Colors.white,
                          shape: isPhoto ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: isPhoto ? null : BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: _isRecording ? const Icon(Icons.stop, color: Colors.white) : null,
                      );
                    },
                  ),
                ),
                // Zoom indicator
                ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, value, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                      child: Text('${value.zoomLevel.toStringAsFixed(1)}x', style: const TextStyle(color: Colors.white)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Recording indicator
        if (_isRecording)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    const Text('RECORDING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Handle errors
  void _handleError(String source, String message, {Object? error, bool isRecoverable = false}) {
    debugPrint('Camera error from $source: $message');
    debugPrint('Original error: $error');

    // Only update the error state in this example
    setState(() {
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show error screen if there's an error
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Camera Error: $_errorMessage'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Custom Overlay Example')),
      body: CameralyCamera(
        settings: CameraPreviewSettings(
          // Camera settings
          cameraMode: CameraMode.both,
          resolution: ResolutionPreset.high,
          flashMode: FlashMode.auto,

          // Use our custom overlay builder function directly
          customOverlay: _buildCustomOverlay,

          // Handle errors
          onError: _handleError,

          // Initialize callback - no longer need to save controller
          onInitialized: (controller) {
            debugPrint('Camera initialized');
          },

          // Use custom loading text
          loadingText: 'Preparing custom camera...',

          // Using our new backButtonBuilder property for a custom back button
          backButtonBuilder: (context, state) {
            return DefaultCameralyOverlay.createStyledBackButton(
              onPressed: () {
                if (state.isRecording) {
                  // Show confirmation dialog when recording
                  _showExitConfirmationDialog(context);
                } else {
                  Navigator.of(context).pop();
                }
              },
              icon: Icons.arrow_back_ios_new,
              backgroundColor: Colors.blueAccent.withOpacity(0.7),
              size: 50,
            );
          },
        ),
      ),
    );
  }

  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Recording in progress'),
            content: const Text('Do you want to stop recording and exit?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CANCEL')),
              TextButton(
                onPressed: () {
                  // Access the controller through a builder or finder since we don't store it anymore
                  final cameralyController = CameralyControllerProvider.of(context);
                  if (cameralyController != null) {
                    // Stop recording
                    cameralyController.stopVideoRecording();
                  }
                  // Exit
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(); // exit screen
                },
                child: const Text('STOP & EXIT'),
              ),
            ],
          ),
    );
  }
}
