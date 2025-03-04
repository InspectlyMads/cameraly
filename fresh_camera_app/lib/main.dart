import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Cameraly Example', theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true), home: const LandingPage());
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  Future<void> _requestCameraAccess(BuildContext context) async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => CameraScreen(cameras: cameras)));
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera permission is required to use this app'), duration: Duration(seconds: 3)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade700])),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 100, color: Colors.white),
                  const SizedBox(height: 32),
                  const Text('Welcome to Cameraly', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  const Text('Take amazing photos with our powerful camera features', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white70)),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () => _requestCameraAccess(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Get Started'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CameraApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const CameraApp({required this.cameras, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Camera App', theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true), home: CameraScreen(cameras: cameras));
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({required this.cameras, super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isFrontCamera = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(widget.cameras[_isFrontCamera ? 1 : 0], ResolutionPreset.max, enableAudio: true);

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _switchCamera() async {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    await _initializeCamera();
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized) {
      return;
    }

    try {
      final image = await _controller.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final savedPath = path.join(directory.path, 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await image.saveTo(savedPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Picture saved to: $savedPath')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (!_controller.value.isInitialized) {
      return;
    }

    try {
      if (_isRecording) {
        final video = await _controller.stopVideoRecording();
        setState(() => _isRecording = false);

        final directory = await getApplicationDocumentsDirectory();
        final savedPath = path.join(directory.path, 'video_${DateTime.now().millisecondsSinceEpoch}.mp4');
        await video.saveTo(savedPath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video saved to: $savedPath')));
        }
      } else {
        await _controller.startVideoRecording();
        setState(() => _isRecording = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Camera App'), actions: [IconButton(icon: const Icon(Icons.switch_camera), onPressed: _switchCamera)]),
      body: Column(
        children: [
          Expanded(child: AspectRatio(aspectRatio: _controller.value.aspectRatio, child: CameraPreview(_controller))),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [IconButton.filled(onPressed: _takePicture, icon: const Icon(Icons.camera), iconSize: 32), IconButton.filled(onPressed: _toggleRecording, icon: Icon(_isRecording ? Icons.stop : Icons.videocam), iconSize: 32)],
            ),
          ),
        ],
      ),
    );
  }
}
