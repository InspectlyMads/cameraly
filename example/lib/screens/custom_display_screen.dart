import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A screen that demonstrates the customizable widgets with colored boxes.
class CustomDisplayScreen extends StatefulWidget {
  const CustomDisplayScreen({super.key});

  @override
  State<CustomDisplayScreen> createState() => _CustomDisplayScreenState();
}

class _CustomDisplayScreenState extends State<CustomDisplayScreen> {
  String? _errorMessage;

  void _handleError(String source, String message, {Object? error, bool isRecoverable = false}) {
    debugPrint('Camera error from $source: $message');
    debugPrint('Original error: $error');

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
      appBar: AppBar(title: const Text('Custom Display')),
      body: CameralyCamera(
        settings: CameraPreviewSettings(
          // Camera settings
          cameraMode: CameraMode.both,
          resolution: ResolutionPreset.high,
          flashMode: FlashMode.auto,

          // Error handling
          onError: _handleError,

          // Media settings
          maxMediaItems: 30,

          // Loading widget
          loadingText: 'Initializing Custom Camera...',

          // Overlay configuration
          showOverlay: true,
          showFlashButton: true,
          showSwitchCameraButton: true,
          showCaptureButton: true,
          showGalleryButton: true,
          showMediaStack: true,
          showZoomControls: true,

          // Add custom buttons with haptic feedback
          customLeftButton: GestureDetector(
            onTap: () {
              // Light impact haptic feedback
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Light Impact Haptic Feedback'), duration: Duration(milliseconds: 500)));
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(244, 67, 54, 0.7), // Red
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('Light\nHaptic', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
            ),
          ),
          customRightButton: GestureDetector(
            onTap: () {
              // Medium impact haptic feedback
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medium Impact Haptic Feedback'), duration: Duration(milliseconds: 500)));
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(33, 150, 243, 0.7), // Blue
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('Medium\nHaptic', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
            ),
          ),

          // Add custom widgets with haptic feedback to demonstrate positions
          topLeftWidget: GestureDetector(
            onTap: () {
              // Heavy impact haptic feedback
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Heavy Impact Haptic Feedback'), duration: Duration(milliseconds: 500)));
            },
            child: Container(
              width: 120,
              height: 60,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(33, 150, 243, 0.7), // Blue
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('Heavy Haptic', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
          ),
          centerLeftWidget: GestureDetector(
            onTap: () {
              // Selection click haptic feedback
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selection Click Haptic Feedback'), duration: Duration(milliseconds: 500)));
            },
            child: Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(76, 175, 80, 0.7), // Green
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('Selection\nHaptic', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
          ),
          bottomOverlayWidget: GestureDetector(
            onTap: () {
              // General vibration haptic feedback
              HapticFeedback.vibrate();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vibration Haptic Feedback'), duration: Duration(milliseconds: 500)));
            },
            child: Container(
              width: double.infinity,
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(156, 39, 176, 0.7), // Purple
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('Vibration Haptic', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
          ),
        ),
      ),
    );
  }
}
