import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A screen that demonstrates video recording with a duration limit
class LimitedVideoExample extends StatefulWidget {
  const LimitedVideoExample({super.key});

  @override
  State<LimitedVideoExample> createState() => _LimitedVideoExampleState();
}

class _LimitedVideoExampleState extends State<LimitedVideoExample> {
  late CameralyController _controller;
  late CameralyMediaManager _mediaManager;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    // Create the media manager
    _mediaManager = CameralyMediaManager(maxItems: 30);

    // Get available cameras
    final cameras = await CameralyController.getAvailableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras available')));
      }
      return;
    }

    // Initialize the camera controller with video-only mode
    _controller = CameralyController(
      description: cameras.first,
      settings: const CaptureSettings(
        cameraMode: CameraMode.videoOnly,
        enableAudio: true, // Enable audio for video recording
      ),
    );

    try {
      await _controller.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to initialize camera: $e')));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleVideoRecorded(XFile videoFile) {
    _mediaManager.addMedia(videoFile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video saved: ${videoFile.path}')));
    }
  }

  void _handleMaxDurationReached(XFile videoFile) {
    _mediaManager.addMedia(videoFile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum duration reached (15 seconds)'), backgroundColor: Colors.orange));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Initializing Camera...')])));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Camera preview with default overlay
          CameralyPreview(
            controller: _controller,
            overlay: DefaultCameralyOverlay(
              controller: _controller,
              // Custom theme for video recording
              theme: const CameralyOverlayTheme(primaryColor: Colors.orange, secondaryColor: Colors.red, backgroundColor: Colors.black87, opacity: 0.8, buttonSize: 72.0, iconSize: 32.0),
              // Callbacks for media handling
              onPictureTaken: _handleVideoRecorded,
              onMediaSelected: (files) {
                for (final file in files) {
                  _mediaManager.addMedia(file);
                }
              },
              // Set maximum video duration to 15 seconds
              maxVideoDuration: const Duration(seconds: 15),
              onMaxDurationReached: () => _handleMaxDurationReached(XFile('')),
              // Show video-specific controls
              showFlashButton: true, // For torch mode
              showSwitchCameraButton: true,
              showGalleryButton: true,
              showZoomControls: true,
              // Add custom buttons that match the top-right style
              customRightButton: Container(
                decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: IconButton(onPressed: () => _controller.switchCamera(), icon: const Icon(Icons.switch_camera), iconSize: 28, color: Colors.white, padding: const EdgeInsets.all(12)),
              ),
              customLeftButton: ValueListenableBuilder<CameralyValue>(
                valueListenable: _controller,
                builder: (context, value, child) {
                  return Container(
                    decoration: BoxDecoration(color: value.isRecordingVideo ? Colors.grey.withOpacity(0.3) : Colors.black54, shape: BoxShape.circle),
                    child: IconButton(
                      onPressed:
                          value.isRecordingVideo
                              ? null
                              : () async {
                                final picker = ImagePicker();
                                final result = await picker.pickMedia();
                                if (result != null && mounted) {
                                  _mediaManager.addMedia(result);
                                }
                              },
                      icon: const Icon(Icons.photo_library),
                      iconSize: 28,
                      color: value.isRecordingVideo ? Colors.white60 : Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  );
                },
              ),
              // Add a custom progress indicator at the top
              topLeftWidget: Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: const Text('Maximum Duration: 15 seconds', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),

          // Media stack in the bottom-right corner
          Positioned(
            right: 16,
            bottom: 100,
            child: SafeArea(child: CameralyMediaStack(mediaManager: _mediaManager, itemSize: 60, maxDisplayItems: 3, borderColor: Colors.white, borderWidth: 2, borderRadius: 8, showCountBadge: true, countBadgeColor: Colors.orange)),
          ),
        ],
      ),
    );
  }
}
