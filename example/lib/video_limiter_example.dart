import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

/// Example demonstrating the VideoLimiterOverlay for time-limited video recording.
class VideoLimiterExample extends StatefulWidget {
  /// Creates a new [VideoLimiterExample] instance.
  const VideoLimiterExample({super.key});

  @override
  State<VideoLimiterExample> createState() => _VideoLimiterExampleState();
}

class _VideoLimiterExampleState extends State<VideoLimiterExample> {
  late CameralyController _controller;
  bool _isInitialized = false;
  Duration _maxDuration = const Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // Initialize the controller optimized for video recording
      final controller = await CameralyController.initializeForVideos(
        settings: const VideoSettings(
          resolution: ResolutionPreset.high,
          cameraMode: CameraMode.both, // Allow both photo and video
        ),
      );

      if (controller != null) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error initializing camera: $e')));
      }
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _changeDuration(Duration duration) {
    setState(() {
      _maxDuration = duration;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Limiter Example'),
        actions: [
          PopupMenuButton<Duration>(
            tooltip: 'Set maximum duration',
            icon: const Icon(Icons.timer),
            onSelected: _changeDuration,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: Duration(seconds: 10), child: Text('10 seconds')),
                  const PopupMenuItem(value: Duration(seconds: 30), child: Text('30 seconds')),
                  const PopupMenuItem(value: Duration(minutes: 1), child: Text('1 minute')),
                ],
          ),
        ],
      ),
      body:
          _isInitialized
              ? CameralyPreview(
                controller: _controller,
                overlayType: CameralyOverlayType.custom,
                customOverlay: VideoLimiterOverlay(
                  controller: _controller,
                  maxDuration: _maxDuration,
                  theme: CameralyOverlayTheme(primaryColor: Theme.of(context).primaryColor, secondaryColor: Colors.red, backgroundColor: Colors.black.withAlpha(128)),
                  onMaxDurationReached: (videoFile) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Text('Maximum recording duration of ${_formatDuration(_maxDuration)} reached'), const SizedBox(height: 4), Text('Video saved to: ${videoFile.path}', style: const TextStyle(fontSize: 12))],
                        ),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  },
                ),
              )
              : const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Initializing camera...')])),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
