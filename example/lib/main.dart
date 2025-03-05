import 'dart:async';
import 'dart:io';

import 'package:cameraly/cameraly.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'video_limiter_example.dart';

void main() {
  runApp(const CameralyApp());
}

class CameralyApp extends StatelessWidget {
  const CameralyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Cameraly Example', theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true), home: const HomeScreen());
  }
}

/// Home screen with examples list
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cameraly Examples')),
      body: ListView(
        children: [
          _buildExampleTile(context, title: 'Default Camera', subtitle: 'Basic camera with default overlay', icon: Icons.camera_alt, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen()))),
          _buildExampleTile(context, title: 'Video Limiter', subtitle: 'Camera with time-limited video recording', icon: Icons.timer, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VideoLimiterExample()))),
        ],
      ),
    );
  }

  Widget _buildExampleTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(leading: Icon(icon, color: Theme.of(context).primaryColor), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right), onTap: onTap),
    );
  }
}

/// The main camera screen that uses the Cameraly package with default overlay
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  late CameralyController _controller;
  bool _isInitialized = false;
  final CameralyOverlayTheme _theme = const CameralyOverlayTheme(primaryColor: Colors.deepPurple, secondaryColor: Colors.red, backgroundColor: Colors.black54, opacity: 0.7);
  final List<XFile> _selectedMedia = [];
  bool _showGalleryView = false;

  // Animation controller for the media stack
  late AnimationController _stackAnimationController;
  late Animation<double> _stackAnimation;

  @override
  void initState() {
    super.initState();
    _initCamera();

    // Initialize animation controller
    _stackAnimationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _stackAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _stackAnimationController, curve: Curves.easeInOut))..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _stackAnimationController.reverse();
      }
    });
  }

  Future<void> _initCamera() async {
    try {
      // Initialize the camera with photo only mode using the specialized method
      final controller = await CameralyController.initializeForPhotos(
        settings: const PhotoSettings(
          resolution: ResolutionPreset.max,
          flashMode: FlashMode.auto,
          // CameraMode.photoOnly is already the default for PhotoSettings
        ),
      );

      if (controller == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras available or initialization failed')));
        }
        return;
      }

      _controller = controller;

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error initializing camera: $e')));
      }
    }
  }

  void _handleMediaSelected(List<XFile> mediaFiles) {
    setState(() {
      _selectedMedia.addAll(mediaFiles);
    });

    // Use a microtask to ensure the UI is laid out before starting the animation
    Future.microtask(() {
      if (mounted) {
        _stackAnimationController.reset();
        _stackAnimationController.forward();
      }
    });
  }

  void _navigateToGalleryView() {
    setState(() {
      _showGalleryView = true;
    });
  }

  @override
  void dispose() {
    _stackAnimationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showGalleryView) {
      return _buildGalleryView();
    }

    return Scaffold(backgroundColor: Colors.black, body: _buildCameraView());
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Show loading UI while camera initializes
        if (!_isInitialized)
          Container(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade700])),
            child: const SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 100, color: Colors.white),
                    SizedBox(height: 32),
                    Text('Cameraly', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 16),
                    Text('Loading camera...', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white70)),
                    SizedBox(height: 32),
                    CircularProgressIndicator(color: Colors.white),
                  ],
                ),
              ),
            ),
          ),

        // Camera preview (only shown when initialized)
        if (_isInitialized)
          CameralyPreview(
            controller: _controller,
            overlayType: CameralyOverlayType.defaultOverlay,
            defaultOverlay: DefaultCameralyOverlay(
              controller: _controller,
              theme: _theme,
              showGalleryButton: true,
              showFocusCircle: true,
              showZoomControls: true,
              allowMultipleSelection: true,
              onMediaSelected: _handleMediaSelected,
              onPictureTaken: onPictureTaken,
            ),
          ),

        // Media stack (only shown when there are selected media)
        Positioned(
          left: 20,
          top: 0,
          bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: () {
                if (_selectedMedia.isNotEmpty) {
                  setState(() {
                    _showGalleryView = true;
                  });
                }
              },
              child: AnimatedBuilder(
                animation: _stackAnimationController,
                builder: (context, child) {
                  // Only apply the scale animation if we have media
                  if (_selectedMedia.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Apply the scale animation
                  final scale = 1.0 + (_stackAnimation.value - 1.0);

                  return Transform.scale(scale: scale, alignment: Alignment.center, child: child);
                },
                child: _selectedMedia.isNotEmpty ? _buildMediaStack() : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaStack() {
    // Show at most 3 most recent images in the stack
    final recentMedia = _selectedMedia.length > 3 ? _selectedMedia.sublist(_selectedMedia.length - 3) : _selectedMedia;

    // Calculate the size of the stack based on the number of images
    // This ensures the widget has a fixed size before animation
    final double stackWidth = 70 + (recentMedia.length > 1 ? (recentMedia.length - 1) * 5.0 : 0);
    final double stackHeight = 70 + (recentMedia.length > 1 ? (recentMedia.length - 1) * 5.0 : 0);

    return SizedBox(
      width: stackWidth + 15, // Extra space for the "View All" label
      height: stackHeight,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)]),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Build the stack of images from back to front (reversed order)
            // This places older images at the bottom and newest on top
            for (int i = recentMedia.length - 1; i >= 0; i--)
              Positioned(
                left: -(recentMedia.length - 1 - i) * 5.0,
                top: -(recentMedia.length - 1 - i) * 5.0,
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, spreadRadius: 1, offset: const Offset(0, 2))],
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(10), child: _buildMediaThumbnail(recentMedia[i])),
                ),
              ),

            // Counter badge if there are more than 3 images
            if (_selectedMedia.length > 3)
              Positioned(
                top: -8,
                left: -8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, spreadRadius: 0)]),
                  child: Text('+${_selectedMedia.length - 3}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),

            // Tap indicator
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, spreadRadius: 0)]),
                  child: const Text('View\nAll', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaThumbnail(XFile media) {
    final isVideo = media.path.toLowerCase().endsWith('.mp4') || media.path.toLowerCase().endsWith('.mov') || media.path.toLowerCase().endsWith('.avi');

    if (isVideo) {
      return Container(color: Colors.black, child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 30)));
    } else {
      return Image.file(File(media.path), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white)));
    }
  }

  Widget _buildGalleryView() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Selected Media (${_selectedMedia.length})'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _showGalleryView = false;
            });
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _selectedMedia.isEmpty
                    ? const Center(child: Text('No media selected', style: TextStyle(color: Colors.white)))
                    : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: _selectedMedia.length,
                      itemBuilder: (context, index) {
                        final media = _selectedMedia[index];
                        final isVideo = media.path.toLowerCase().endsWith('.mp4') || media.path.toLowerCase().endsWith('.mov') || media.path.toLowerCase().endsWith('.avi');

                        return GestureDetector(
                          onTap: () {
                            // Show full screen preview
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => Scaffold(
                                      backgroundColor: Colors.black,
                                      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(media.name)),
                                      body: Center(
                                        child:
                                            isVideo
                                                ? const Icon(Icons.video_file, size: 100, color: Colors.white54)
                                                : Image.file(File(media.path), fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.white54)),
                                      ),
                                    ),
                              ),
                            );
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
                                child:
                                    isVideo
                                        ? const Icon(Icons.video_file, size: 50, color: Colors.white70)
                                        : ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(File(media.path), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.white70)),
                                        ),
                              ),
                              if (isVideo)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.videocam, size: 16, color: Colors.white)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  void onPictureTaken(XFile picture) {
    setState(() {
      _selectedMedia.add(picture);
    });

    // Use a microtask to ensure the UI is laid out before starting the animation
    Future.microtask(() {
      if (mounted) {
        _stackAnimationController.reset();
        _stackAnimationController.forward();
      }
    });

    // Snackbar removed - now handled by the DefaultCameralyOverlay only when needed
  }
}

/// Example demonstrating how to save photos and videos to persistent storage
class PersistentStorageExample extends StatefulWidget {
  const PersistentStorageExample({super.key});

  @override
  State<PersistentStorageExample> createState() => _PersistentStorageExampleState();
}

class _PersistentStorageExampleState extends State<PersistentStorageExample> {
  late CameralyController _controller;
  bool _isInitialized = false;
  String? _customDirectory;
  String _customFilename = '';
  bool _useCustomDirectory = false;
  bool _useCustomFilename = false;
  List<String> _savedFiles = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
    _createCustomDirectory();
  }

  Future<void> _createCustomDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final customDir = Directory('${appDir.path}/cameraly_custom');

    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }

    setState(() {
      _customDirectory = customDir.path;
    });
  }

  Future<void> _initCamera() async {
    try {
      final controller = await CameralyController.initializeCamera(settings: const CaptureSettings(resolution: ResolutionPreset.high, cameraMode: CameraMode.both));

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

  Future<void> _loadSavedFiles() async {
    final directory = _useCustomDirectory && _customDirectory != null ? Directory(_customDirectory!) : await getApplicationDocumentsDirectory();

    final files = await directory.list().toList();
    final mediaFiles = files.whereType<File>().where((file) => file.path.endsWith('.jpg') || file.path.endsWith('.mp4')).map((file) => file.path).toList();

    setState(() {
      _savedFiles = mediaFiles;
    });
  }

  Future<void> _takePictureToStorage() async {
    try {
      // Take picture using standard method
      final tempFile = await _controller.takePicture();

      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final name = (_useCustomFilename && _customFilename.isNotEmpty) ? _customFilename : 'photo_$timestamp';

      // Determine target directory
      final String targetPath;
      if (_useCustomDirectory && _customDirectory != null) {
        targetPath = _customDirectory!;
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        targetPath = appDir.path;
      }

      // Create full path with filename and extension
      final String targetFilePath = '$targetPath/$name.jpg';

      // Copy the file to the new location
      final bytes = await tempFile.readAsBytes();
      final File savedFile = File(targetFilePath);
      await savedFile.writeAsBytes(bytes);

      // Create XFile from the saved file
      final file = XFile(targetFilePath);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [const Text('Picture saved to persistent storage'), const SizedBox(height: 4), Text('Path: ${file.path}', style: const TextStyle(fontSize: 12))],
          ),
          duration: const Duration(seconds: 5),
        ),
      );

      _loadSavedFiles();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _toggleVideoRecording() async {
    if (_controller.value.isRecordingVideo) {
      try {
        // Stop recording using standard method
        final tempFile = await _controller.stopVideoRecording();

        // Generate filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final name = (_useCustomFilename && _customFilename.isNotEmpty) ? _customFilename : 'video_$timestamp';

        // Determine target directory
        final String targetPath;
        if (_useCustomDirectory && _customDirectory != null) {
          targetPath = _customDirectory!;
        } else {
          final appDir = await getApplicationDocumentsDirectory();
          targetPath = appDir.path;
        }

        // Create full path with filename and extension
        final String targetFilePath = '$targetPath/$name.mp4';

        // Copy the file to the new location
        final bytes = await tempFile.readAsBytes();
        final File savedFile = File(targetFilePath);
        await savedFile.writeAsBytes(bytes);

        // Create XFile from the saved file
        final file = XFile(targetFilePath);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [const Text('Video saved to persistent storage'), const SizedBox(height: 4), Text('Path: ${file.path}', style: const TextStyle(fontSize: 12))],
            ),
            duration: const Duration(seconds: 5),
          ),
        );

        _loadSavedFiles();
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      try {
        await _controller.startVideoRecording();
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Persistent Storage Example'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSavedFiles, tooltip: 'Refresh saved files')]),
      body: Column(
        children: [
          // Camera preview
          Expanded(flex: 3, child: _isInitialized ? CameralyPreview(controller: _controller, overlayType: CameralyOverlayType.none) : const Center(child: CircularProgressIndicator())),

          // Controls
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Custom directory toggle
                  SwitchListTile(
                    title: const Text('Use custom directory', style: TextStyle(color: Colors.white)),
                    subtitle: Text(_customDirectory ?? 'Default directory', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    value: _useCustomDirectory,
                    onChanged: (value) => setState(() => _useCustomDirectory = value),
                    activeColor: Theme.of(context).primaryColor,
                  ),

                  // Custom filename toggle and input
                  SwitchListTile(
                    title: const Text('Use custom filename', style: TextStyle(color: Colors.white)),
                    value: _useCustomFilename,
                    onChanged: (value) => setState(() => _useCustomFilename = value),
                    activeColor: Theme.of(context).primaryColor,
                  ),

                  if (_useCustomFilename)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: const InputDecoration(hintText: 'Enter filename (without extension)', hintStyle: TextStyle(color: Colors.white54), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30))),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) => setState(() => _customFilename = value),
                      ),
                    ),

                  const Spacer(),

                  // Capture buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Photo button
                      ElevatedButton.icon(
                        onPressed: _takePictureToStorage,
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Take Photo'),
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                      ),

                      // Video button
                      ElevatedButton.icon(
                        onPressed: _toggleVideoRecording,
                        icon: Icon(_controller.value.isRecordingVideo ? Icons.stop : Icons.videocam),
                        label: Text(_controller.value.isRecordingVideo ? 'Stop Recording' : 'Record Video'),
                        style: ElevatedButton.styleFrom(backgroundColor: _controller.value.isRecordingVideo ? Colors.red : Theme.of(context).primaryColor, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Saved files list
          if (_savedFiles.isNotEmpty)
            Container(
              height: 100,
              color: Colors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(left: 16, top: 8), child: Text('Saved Files:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _savedFiles.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final path = _savedFiles[index];
                        final isVideo = path.endsWith('.mp4');

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              Container(
                                width: 80,
                                decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
                                child:
                                    isVideo
                                        ? const Icon(Icons.videocam, size: 40, color: Colors.white70)
                                        : Image.file(File(path), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.white70)),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                                  child: Icon(isVideo ? Icons.videocam : Icons.photo, size: 12, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
