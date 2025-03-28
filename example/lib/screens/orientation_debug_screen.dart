import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A screen for debugging camera orientation handling
class OrientationDebugScreen extends StatefulWidget {
  const OrientationDebugScreen({super.key});

  @override
  State<OrientationDebugScreen> createState() => _OrientationDebugScreenState();
}

class _OrientationDebugScreenState extends State<OrientationDebugScreen> with WidgetsBindingObserver {
  CameralyController? _controller;
  List<String> _logs = [];
  bool _debugOverlayVisible = true;
  String _currentState = 'Uninitialized';
  int _orientationChangeCount = 0;
  DateTime? _lastOrientationChange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    setState(() {
      _orientationChangeCount++;
      _lastOrientationChange = DateTime.now();
      _addLog("📏 Metrics changed - possible orientation change");
    });

    // Give the camera time to update then log the orientation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_controller != null && mounted) {
        _controller!.printCurrentOrientation(context);
      }
    });
  }

  Future<void> _initializeCamera() async {
    _addLog("🎬 Initializing camera");

    try {
      // Get available cameras
      final cameras = await CameralyController.getAvailableCameras();
      if (cameras.isEmpty) {
        _addLog("❌ No cameras available");
        return;
      }

      // Create controller with the first camera
      final controller = CameralyController(description: cameras[0], settings: const CaptureSettings(resolution: ResolutionPreset.high, cameraMode: CameraMode.both, enableAudio: true));

      // Initialize the controller
      await controller.initialize();

      if (mounted) {
        setState(() {
          _controller = controller;
          _currentState = "Ready";
          _addLog("✅ Camera initialized successfully");
        });
      }
    } catch (e) {
      _addLog("❌ Error initializing camera: $e");
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _logs.add("[$timestamp] $message");
      // Keep only the last 30 logs
      if (_logs.length > 30) {
        _logs = _logs.sublist(_logs.length - 30);
      }
    });
  }

  void _forceOrientationChange(DeviceOrientation orientation) {
    _addLog("🔄 Setting orientation to: $orientation");
    SystemChrome.setPreferredOrientations([orientation]);
  }

  void _resetOrientations() {
    _addLog("🔄 Resetting to all orientations");
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  void _toggleDebugOverlay() {
    setState(() {
      _debugOverlayVisible = !_debugOverlayVisible;
    });
  }

  void _switchCamera() async {
    _addLog("🔄 Switching camera");
    try {
      final newController = await _controller?.switchCamera();
      if (newController != null && mounted) {
        setState(() {
          _controller?.dispose();
          _controller = newController;
          _addLog("✅ Camera switched successfully");
        });
      } else {
        _addLog("⚠️ Switch camera returned null");
      }
    } catch (e) {
      _addLog("❌ Error switching camera: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orientation Debug'), actions: [IconButton(icon: Icon(_debugOverlayVisible ? Icons.visibility_off : Icons.visibility), onPressed: _toggleDebugOverlay, tooltip: 'Toggle debug overlay')]),
      body: Stack(
        children: [
          // Camera preview
          if (_controller != null)
            Positioned.fill(
              child: CameralyPreview(
                controller: _controller!,
                overlay: CameralyPreview.defaultOverlay(
                  showCaptureButton: true,
                  showFlashButton: true,
                  showSwitchCameraButton: true,
                  showGalleryButton: false,
                  onCapture: (file) {
                    _addLog("📸 Captured: ${file.path}");
                  },
                  onSwitchCamera: _switchCamera,
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Debug overlay
          if (_debugOverlayVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 200,
                color: Colors.black.withOpacity(0.7),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _orientationButton(DeviceOrientation.portraitUp, Icons.stay_current_portrait),
                        _orientationButton(DeviceOrientation.landscapeLeft, Icons.stay_current_landscape),
                        _orientationButton(DeviceOrientation.landscapeRight, Icons.stay_current_landscape, flipIcon: true),
                        _orientationButton(DeviceOrientation.portraitDown, Icons.stay_current_portrait, flipIcon: true),
                        ElevatedButton(onPressed: _resetOrientations, child: const Icon(Icons.screen_rotation)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(children: [Text('State: $_currentState', style: const TextStyle(color: Colors.white)), const Spacer(), Text('Changes: $_orientationChangeCount', style: const TextStyle(color: Colors.white))]),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.builder(
                        reverse: true,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final reversedIndex = _logs.length - 1 - index;
                          return Text(_logs[reversedIndex], style: const TextStyle(color: Colors.white, fontSize: 12));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _orientationButton(DeviceOrientation orientation, IconData icon, {bool flipIcon = false}) {
    return ElevatedButton(onPressed: () => _forceOrientationChange(orientation), child: Transform.rotate(angle: flipIcon ? 3.14 : 0, child: Icon(icon)));
  }
}
