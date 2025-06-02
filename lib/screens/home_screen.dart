import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CameraMode {
  photoOnly,
  videoOnly,
  combined,
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Test MVP'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Camera Orientation Testing',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Test how the camera package handles orientation on your device',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildModeCard(
                context,
                title: 'Photo Mode',
                description: 'Test photo capture orientation handling',
                icon: Icons.camera_alt,
                mode: CameraMode.photoOnly,
              ),
              const SizedBox(height: 16),
              _buildModeCard(
                context,
                title: 'Video Mode',
                description: 'Test video recording orientation handling',
                icon: Icons.videocam,
                mode: CameraMode.videoOnly,
              ),
              const SizedBox(height: 16),
              _buildModeCard(
                context,
                title: 'Combined Mode',
                description: 'Test both photo and video in one interface',
                icon: Icons.camera,
                mode: CameraMode.combined,
              ),
              const SizedBox(height: 32),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(height: 8),
                      Text(
                        'This app tests camera orientation handling across different Android devices. Captured media will be saved to app storage for verification.',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required CameraMode mode,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToCameraMode(context, mode),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCameraMode(BuildContext context, CameraMode mode) {
    // TODO: Navigate to camera screen with the selected mode
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${mode.name} mode selected - Camera screen coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
