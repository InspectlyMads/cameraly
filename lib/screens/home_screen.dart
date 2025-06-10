import 'package:cameraly/cameraly.dart' hide permissionRequestProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/permission_providers.dart';
import 'gallery_screen.dart';
import 'permission_test_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionRequest = ref.watch(permissionRequestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Test'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Camera Orientation Testing',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Test how camera captures work across different device orientations',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),

              Text(
                'Camera Modes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Camera mode cards
              _buildCameraModeCard(
                context: context,
                ref: ref,
                title: 'Photo Mode',
                description: 'Test photo capture with orientation data',
                icon: Icons.camera_alt,
                color: Colors.blue,
                mode: CameraMode.photo,
              ),
              const SizedBox(height: 16),

              _buildCameraModeCard(
                context: context,
                ref: ref,
                title: 'Video Mode',
                description: 'Test video recording with orientation data',
                icon: Icons.videocam,
                color: Colors.red,
                mode: CameraMode.video,
              ),
              const SizedBox(height: 16),

              _buildCameraModeCard(
                context: context,
                ref: ref,
                title: 'Combined Mode',
                description: 'Switch between photo and video in one interface',
                icon: Icons.camera,
                color: Colors.green,
                mode: CameraMode.combined,
              ),

              const SizedBox(height: 32),

              // Permission status section
              _buildPermissionStatus(context, ref, permissionRequest),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraModeCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required CameraMode mode,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _navigateToCameraMode(context, ref, mode),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionStatus(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<Permission, PermissionStatus>> permissionRequest,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Permissions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Permission status display
            permissionRequest.when(
              data: (permissions) {
                if (permissions.isEmpty) {
                  return const Text('Tap a camera mode to check permissions');
                }

                return Column(
                  children: permissions.entries.map((entry) {
                    final permission = entry.key;
                    final status = entry.value;
                    final isGranted = status == PermissionStatus.granted;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isGranted ? Icons.check_circle : Icons.cancel,
                            color: isGranted ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            permission == Permission.camera ? 'Camera' : 'Microphone',
                            style: TextStyle(
                              color: isGranted ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Checking permissions...'),
                ],
              ),
              error: (error, _) => Text(
                'Error checking permissions: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),

            const SizedBox(height: 12),

            // Grant permissions button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(permissionRequestProvider.notifier).requestCameraPermissions();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Grant Permissions'),
              ),
            ),
            const SizedBox(height: 8),
            // Debug permissions button (iOS)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PermissionTestScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bug_report),
                label: const Text('Debug Permissions (iOS)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToCameraMode(
    BuildContext context,
    WidgetRef ref,
    CameraMode mode,
  ) async {
    // Check permissions first
    final hasPermissions = await ref.read(permissionRequestProvider.notifier).checkPermissions();

    if (!hasPermissions) {
      // Request permissions
      final permissionNotifier = ref.read(permissionRequestProvider.notifier);
      await permissionNotifier.requestCameraPermissions();

      // Add a small delay to ensure permissions are fully processed
      await Future.delayed(const Duration(milliseconds: 150));

      // Check again
      final stillHasPermissions = await ref.read(permissionRequestProvider.notifier).checkPermissions();

      if (!stillHasPermissions) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera and microphone permissions are required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Navigate to camera screen
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            initialMode: mode,
            showGridButton: true,
            onMediaCaptured: (media) {
              // Media is already saved by the camera service
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${media.isVideo ? 'Video' : 'Photo'} saved to gallery'),
                ),
              );
            },
            onGalleryPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GalleryScreen(),
                ),
              );
            },
            onCheckPressed: () {
              Navigator.pop(context);
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ),
      );
    }
  }
}
