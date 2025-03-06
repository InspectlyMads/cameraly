import 'dart:io';

import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// A screen that demonstrates saving media to custom locations.
class PersistentStorageExample extends StatefulWidget {
  const PersistentStorageExample({super.key});

  @override
  State<PersistentStorageExample> createState() => _PersistentStorageExampleState();
}

class _PersistentStorageExampleState extends State<PersistentStorageExample> {
  late CameralyController _controller;
  late CameralyMediaManager _mediaManager;
  late String _savePath;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    // Create app-specific directory for saving media
    final appDir = await getApplicationDocumentsDirectory();
    _savePath = path.join(appDir.path, 'cameraly_media');
    await Directory(_savePath).create(recursive: true);

    // Create the media manager
    _mediaManager = CameralyMediaManager(
      maxItems: 30,
      onMediaAdded: (file) async {
        // Copy the file to our persistent storage
        final fileName = path.basename(file.path);
        final newPath = path.join(_savePath, fileName);
        await File(file.path).copy(newPath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to: $newPath'), duration: const Duration(seconds: 2)));
        }
      },
    );

    // Get available cameras
    final cameras = await CameralyController.getAvailableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras available')));
      }
      return;
    }

    // Initialize the camera controller
    _controller = CameralyController(description: cameras.first, settings: CaptureSettings(cameraMode: CameraMode.both));

    try {
      await _controller.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error initializing camera: $e')));
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Camera preview with default overlay
          CameralyPreview(
            controller: _controller,
            overlay: DefaultCameralyOverlay(
              controller: _controller,
              onPictureTaken: (file) => _mediaManager.addMedia(file),
              onMediaSelected: (files) {
                for (final file in files) {
                  _mediaManager.addMedia(file);
                }
              },
            ),
          ),

          // Media stack in the bottom-right corner
          Positioned(
            right: 16,
            bottom: 100,
            child: CameralyMediaStack(mediaManager: _mediaManager, itemSize: 60, maxDisplayItems: 3, borderColor: Colors.white, borderWidth: 2, borderRadius: 8, showCountBadge: true, countBadgeColor: Theme.of(context).primaryColor),
          ),

          // Storage path indicator
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Color.fromRGBO(0, 0, 0, 0.7), borderRadius: BorderRadius.circular(8)),
              child: Text('Storage Path: $_savePath', style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}
