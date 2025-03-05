import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'overlay_example.dart';

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
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => CameraScreen(cameras: cameras)));
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
      backgroundColor: Colors.black,
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
                    child: const Text('Basic Camera Example'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OverlayExample()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.8),
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Overlay System Example'),
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

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  late CameraController _controller;
  bool _isFrontCamera = false;
  bool _isRecording = false;
  bool _isVideoMode = false;
  FlashMode _flashMode = FlashMode.auto;
  Offset? _focusPoint;
  bool _showFocusCircle = false;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  final bool _showZoomSlider = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // This will be called when the screen rotates
    if (mounted) {
      setState(() {
        // This empty setState will trigger a rebuild when the orientation changes
      });
    }
    super.didChangeMetrics();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(widget.cameras[_isFrontCamera ? 1 : 0], ResolutionPreset.max, enableAudio: true);

    try {
      await _controller.initialize();

      // Set flash mode only for back camera and photo mode
      if (!_isFrontCamera && !_isVideoMode) {
        await _controller.setFlashMode(_flashMode);
      } else {
        // Ensure flash is off for front camera or video mode
        await _controller.setFlashMode(FlashMode.off);
      }

      _minZoom = await _controller.getMinZoomLevel();
      _maxZoom = await _controller.getMaxZoomLevel();
      _currentZoom = _minZoom;
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _setZoom(double zoom) async {
    if (!_controller.value.isInitialized) return;

    try {
      await _controller.setZoomLevel(zoom);
      setState(() {
        _currentZoom = zoom;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error setting zoom: $e')));
      }
    }
  }

  Future<void> _handleTapToFocus(Offset normalizedPoint) async {
    if (!_controller.value.isInitialized) return;

    try {
      await _controller.setFocusPoint(normalizedPoint);
      await _controller.setExposurePoint(normalizedPoint);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error setting focus: $e')));
      }
    }
  }

  Future<void> _cycleFlashMode() async {
    if (!_controller.value.isInitialized || _isVideoMode || _isFrontCamera) return;

    final modes = [FlashMode.auto, FlashMode.always, FlashMode.off];
    final nextIndex = (modes.indexOf(_flashMode) + 1) % modes.length;
    final newMode = modes[nextIndex];

    try {
      await _controller.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Flash mode: ${_flashMode.toString().split('.').last}'), duration: const Duration(seconds: 1)));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error setting flash mode: $e')));
      }
    }
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      default:
        return Icons.flash_auto;
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
      // Ensure flash mode is set correctly before taking the picture
      if (!_isFrontCamera) {
        await _controller.setFlashMode(_flashMode);
      }

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
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final previewRatio = _controller.value.aspectRatio;

    return Scaffold(
      key: ValueKey<Orientation>(MediaQuery.of(context).orientation),
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTapUp: (TapUpDetails details) {
              if (!_controller.value.isInitialized) return;

              final size = MediaQuery.of(context).size;
              final previewSize = _controller.value.previewSize!;
              final cameraRatio = previewSize.width / previewSize.height;

              // Get the preview widget size and position
              final previewAspectRatio = isLandscape ? previewRatio : 1.0 / previewRatio;
              final previewWidth = isLandscape ? size.width : size.height * previewAspectRatio;
              final previewHeight = isLandscape ? size.width / previewAspectRatio : size.height;

              // Calculate the preview's position on screen
              final previewLeft = (size.width - previewWidth) / 2;
              final previewTop = (size.height - previewHeight) / 2;

              // Check if tap is within the preview bounds
              final tapPosition = details.globalPosition;
              if (tapPosition.dx >= previewLeft && tapPosition.dx <= previewLeft + previewWidth && tapPosition.dy >= previewTop && tapPosition.dy <= previewTop + previewHeight) {
                // Calculate normalized coordinates (0-1) for the camera controller
                double normalizedX;
                double normalizedY;

                if (isLandscape) {
                  // In landscape, map directly to the preview
                  normalizedX = (tapPosition.dx - previewLeft) / previewWidth;
                  normalizedY = (tapPosition.dy - previewTop) / previewHeight;
                } else {
                  // In portrait, we need to account for the rotated camera preview
                  // The camera is sideways, so we swap x and y
                  // For Android devices, we need to invert the X coordinate
                  normalizedX = (tapPosition.dy - previewTop) / previewHeight;
                  normalizedY = (tapPosition.dx - previewLeft) / previewWidth;

                  // Adjust based on camera orientation
                  final sensorOrientation = _controller.description.sensorOrientation;
                  if (sensorOrientation == 90) {
                    // Most Android devices
                    normalizedY = 1.0 - normalizedY;
                  } else if (sensorOrientation == 270) {
                    // Some devices
                    normalizedX = 1.0 - normalizedX;
                  }
                }

                // Adjust for front camera mirroring
                if (_isFrontCamera) {
                  normalizedX = 1.0 - normalizedX;
                }

                // Set focus point for display (in screen coordinates)
                setState(() {
                  _focusPoint = tapPosition;
                  _showFocusCircle = true;
                });

                // Set focus on camera (in normalized coordinates)
                _handleTapToFocus(Offset(normalizedX, normalizedY));

                // Hide focus circle after 2 seconds
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() {
                      _showFocusCircle = false;
                    });
                  }
                });
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Get the actual camera preview ratio
                      final previewRatio = _controller.value.aspectRatio;

                      // Calculate screen ratio
                      final screenRatio = constraints.maxWidth / constraints.maxHeight;

                      return ClipRect(
                        child: SizedBox.expand(
                          key: ValueKey<bool>(isLandscape),
                          child:
                              isLandscape
                                  ? FittedBox(
                                    fit: BoxFit.contain,
                                    child: SizedBox(width: constraints.maxWidth, height: constraints.maxWidth / previewRatio, child: Transform.scale(scaleX: _isFrontCamera ? -1.0 : 1.0, scaleY: 1.0, child: CameraPreview(_controller))),
                                  )
                                  : FittedBox(
                                    fit: BoxFit.contain,
                                    child: SizedBox(
                                      // In portrait mode, we need to use the inverse ratio
                                      // because the camera is sideways
                                      width: constraints.maxHeight * (1 / previewRatio),
                                      height: constraints.maxHeight,
                                      child: Transform.scale(scaleX: _isFrontCamera ? -1.0 : 1.0, scaleY: 1.0, child: CameraPreview(_controller)),
                                    ),
                                  ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Focus circle
          if (_showFocusCircle && _focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 20,
              top: _focusPoint!.dy - 20,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                tween: Tween(begin: 0.0, end: 1.0),
                builder:
                    (context, value, child) => Transform.scale(
                      scale: 2 - value,
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), shape: BoxShape.circle, color: Colors.white.withOpacity(0.3)),
                          child: const Center(child: Icon(Icons.center_focus_strong, color: Colors.white, size: 20)),
                        ),
                      ),
                    ),
              ),
            ),
          // Flash control
          if (!_isVideoMode && !_isFrontCamera)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: isLandscape ? 16 : null,
              right: isLandscape ? null : 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isRecording ? 0.0 : 1.0,
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      onPressed: _cycleFlashMode,
                      icon: Icon(_getFlashIcon(), color: _flashMode == FlashMode.off ? Colors.white60 : Colors.white),
                      iconSize: 28,
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: _flashMode == FlashMode.always ? Colors.amber.withOpacity(0.3) : Colors.transparent,
                        minimumSize: const Size(56, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Controls
          AnimatedPositioned(
            key: ValueKey<bool>(isLandscape),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: isLandscape ? 0 : 0,
            bottom: isLandscape ? 0 : 0,
            left: isLandscape ? null : 0,
            top: isLandscape ? 0 : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.only(left: isLandscape ? 0 : 20, right: isLandscape ? 0 : 20, bottom: isLandscape ? 16 : 20 + MediaQuery.of(context).padding.bottom, top: isLandscape ? 16 : 20 + MediaQuery.of(context).padding.top),
              width: isLandscape ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.width,
              height: isLandscape ? MediaQuery.of(context).size.height : null,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: isLandscape ? Alignment.centerRight : Alignment.bottomCenter,
                  end: isLandscape ? Alignment.centerLeft : Alignment.topCenter,
                  stops: isLandscape ? const [0.0, 0.3, 0.7, 1.0] : const [0.0, 0.15, 0.3, 0.5],
                  colors: [Colors.black.withOpacity(0.9), Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.3), Colors.transparent],
                ),
              ),
              child:
                  isLandscape
                      ? Stack(
                        alignment: Alignment.center,
                        children: [
                          if (!_isRecording)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: MediaQuery.of(context).size.height * 0.15,
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.only(
                                    // Adjust for status bar in landscape
                                    bottom: MediaQuery.of(context).padding.right,
                                  ),
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey<bool>(isLandscape),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    tween: Tween<double>(begin: 0, end: isLandscape ? -90 : 0),
                                    builder: (context, value, child) => Transform.rotate(angle: value * 3.14159 / 180, child: child!),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width > 900 ? 64 : 48),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          TextButton(
                                            onPressed:
                                                () => setState(() {
                                                  _isVideoMode = false;
                                                  // Update flash mode when switching to photo mode
                                                  if (!_isFrontCamera) {
                                                    _controller.setFlashMode(_flashMode);
                                                  }
                                                }),
                                            style: TextButton.styleFrom(foregroundColor: !_isVideoMode ? Colors.white : Colors.white70, padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width > 900 ? 24 : 16, vertical: 8)),
                                            child: Text('PHOTO', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 900 ? 18 : 14, fontWeight: !_isVideoMode ? FontWeight.bold : FontWeight.normal)),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => setState(() {
                                                  _isVideoMode = true;
                                                  // Turn off flash in video mode
                                                  _controller.setFlashMode(FlashMode.off);
                                                }),
                                            style: TextButton.styleFrom(foregroundColor: _isVideoMode ? Colors.white : Colors.white70, padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width > 900 ? 24 : 16, vertical: 8)),
                                            child: Text('VIDEO', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 900 ? 18 : 14, fontWeight: _isVideoMode ? FontWeight.bold : FontWeight.normal)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          AnimatedPositioned(
                            key: ValueKey<bool>(isLandscape),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                                  IconButton.filled(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery coming soon')));
                                    },
                                    icon: Icon(Icons.photo_library, size: MediaQuery.of(context).size.width > 900 ? 32 : 24),
                                    style: IconButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white, minimumSize: MediaQuery.of(context).size.width > 900 ? const Size(64, 64) : const Size(48, 48)),
                                  ),
                                  SizedBox(height: MediaQuery.of(context).size.width > 900 ? 24 : 16),
                                  GestureDetector(
                                    onTap: _isVideoMode ? _toggleRecording : _takePicture,
                                    child: Container(
                                      height: MediaQuery.of(context).size.width > 900 ? 90 : 70,
                                      width: MediaQuery.of(context).size.width > 900 ? 90 : 70,
                                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: MediaQuery.of(context).size.width > 900 ? 4 : 3), color: _isRecording ? Colors.red : Colors.transparent),
                                      child: Center(
                                        child:
                                            _isRecording
                                                ? Container(
                                                  width: MediaQuery.of(context).size.width > 900 ? 32 : 24,
                                                  height: MediaQuery.of(context).size.width > 900 ? 32 : 24,
                                                  decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.all(Radius.circular(4)), border: Border.all(color: Colors.white, width: 2)),
                                                )
                                                : Container(width: MediaQuery.of(context).size.width > 900 ? 70 : 54, height: MediaQuery.of(context).size.width > 900 ? 70 : 54, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: MediaQuery.of(context).size.width > 900 ? 24 : 16),
                                  IconButton.filled(
                                    onPressed: _switchCamera,
                                    icon: Icon(Icons.switch_camera, size: MediaQuery.of(context).size.width > 900 ? 32 : 24),
                                    style: IconButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white, minimumSize: MediaQuery.of(context).size.width > 900 ? const Size(64, 64) : const Size(48, 48)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                      : Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!_isRecording) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed:
                                      () => setState(() {
                                        _isVideoMode = false;
                                        // Update flash mode when switching to photo mode
                                        if (!_isFrontCamera) {
                                          _controller.setFlashMode(_flashMode);
                                        }
                                      }),
                                  style: TextButton.styleFrom(foregroundColor: !_isVideoMode ? Colors.white : Colors.white60),
                                  child: const Text('Photo'),
                                ),
                                const SizedBox(width: 20),
                                TextButton(
                                  onPressed:
                                      () => setState(() {
                                        _isVideoMode = true;
                                        // Turn off flash in video mode
                                        _controller.setFlashMode(FlashMode.off);
                                      }),
                                  style: TextButton.styleFrom(foregroundColor: _isVideoMode ? Colors.white : Colors.white60),
                                  child: const Text('Video'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton.filled(onPressed: _switchCamera, icon: const Icon(Icons.switch_camera), iconSize: 30, style: IconButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white)),
                              GestureDetector(
                                onTap: _isVideoMode ? _toggleRecording : _takePicture,
                                child: Container(
                                  height: 80,
                                  width: 80,
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), color: _isRecording ? Colors.red : Colors.transparent),
                                  child: Center(
                                    child:
                                        _isRecording
                                            ? Container(width: 30, height: 30, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(4))))
                                            : Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                                  ),
                                ),
                              ),
                              IconButton.filled(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery coming soon')));
                                },
                                icon: const Icon(Icons.photo_library),
                                iconSize: 30,
                                style: IconButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
