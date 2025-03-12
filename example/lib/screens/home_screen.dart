import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';

// These imports will be created next
import 'camera_screen.dart';
import 'custom_display_screen.dart';
import 'custom_overlay_example.dart';
import 'inspectly_version.dart';
import 'limited_video_example.dart';
import 'simple_camera_screen.dart';

/// Home screen with examples list
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cameraly Examples'), backgroundColor: Theme.of(context).colorScheme.primaryContainer),
      body: ListView(
        children: [
          _buildExampleTile(
            context,
            title: 'Simple Camera (New API)',
            subtitle: 'Ultra-simple camera with automatic controller management',
            icon: Icons.auto_awesome,
            color: Colors.amber,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SimpleCameraScreen())),
          ),
          _buildExampleTile(
            context,
            title: 'Inspectly Photo Only',
            subtitle: 'Inspectly version',
            icon: Icons.check_circle,
            color: Colors.teal,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InspectlyVersionScreen())),
          ),
          _buildExampleTile(
            context,
            title: 'Photo Only Camera',
            subtitle: 'Camera with photo capture only',
            icon: Icons.camera_alt,
            color: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen(cameraMode: CameraMode.photoOnly))),
          ),

          _buildExampleTile(
            context,
            title: 'Video Only Camera',
            subtitle: 'Camera with video recording only',
            icon: Icons.videocam,
            color: Colors.red,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen(cameraMode: CameraMode.videoOnly))),
          ),
          _buildExampleTile(
            context,
            title: 'Limited Video Example',
            subtitle: 'Video recording with 15-second limit',
            icon: Icons.timer,
            color: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LimitedVideoExample())),
          ),
          _buildExampleTile(
            context,
            title: 'Photo & Video Camera',
            subtitle: 'Camera with both photo and video capabilities',
            icon: Icons.camera,
            color: Colors.purple,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen(cameraMode: CameraMode.both))),
          ),
          _buildExampleTile(
            context,
            title: 'Custom Display Camera',
            subtitle: 'Camera with customizable widgets and colored boxes',
            icon: Icons.palette,
            color: Colors.green,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomDisplayScreen())),
          ),
          _buildExampleTile(
            context,
            title: 'Custom Overlay Example',
            subtitle: 'Camera with a completely custom overlay implementation',
            icon: Icons.layers,
            color: Colors.indigo,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomOverlayExample())),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap, Color color = Colors.deepPurple}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shadowColor: color.withAlpha((0.3 * 255).round()),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(backgroundColor: color.withAlpha((0.2 * 255).round()), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right, color: color),
        onTap: onTap,
      ),
    );
  }
}
