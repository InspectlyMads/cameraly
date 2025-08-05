import 'package:flutter/material.dart';
import 'package:cameraly/cameraly.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Test screen to demonstrate the automatic permission flow
class PermissionFlowTestScreen extends ConsumerStatefulWidget {
  const PermissionFlowTestScreen({super.key});

  @override
  ConsumerState<PermissionFlowTestScreen> createState() => _PermissionFlowTestScreenState();
}

class _PermissionFlowTestScreenState extends ConsumerState<PermissionFlowTestScreen> {
  CameraMode _selectedMode = CameraMode.photo;

  void _openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          initialMode: _selectedMode,
          onMediaCaptured: (MediaItem item) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Captured: ${item.path}'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Flow Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Test Automatic Permission Flow',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            
            // Mode selector
            const Text('Select Camera Mode:'),
            const SizedBox(height: 16),
            SegmentedButton<CameraMode>(
              segments: const [
                ButtonSegment(
                  value: CameraMode.photo,
                  label: Text('Photo'),
                  icon: Icon(Icons.camera_alt),
                ),
                ButtonSegment(
                  value: CameraMode.video,
                  label: Text('Video'),
                  icon: Icon(Icons.videocam),
                ),
              ],
              selected: {_selectedMode},
              onSelectionChanged: (Set<CameraMode> newSelection) {
                setState(() {
                  _selectedMode = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 40),
            
            // Open camera button
            ElevatedButton.icon(
              onPressed: _openCamera,
              icon: const Icon(Icons.camera),
              label: const Text('Open Camera'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permission Flow:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('1. Camera opens automatically'),
                      Text('2. If permissions not granted, requests automatically'),
                      Text('3. No manual "Grant Permission" button needed'),
                      Text('4. Only shows settings dialog if permanently denied'),
                      SizedBox(height: 8),
                      Text(
                        'Photo mode: Only camera permission',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      Text(
                        'Video mode: Camera + microphone permissions',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}