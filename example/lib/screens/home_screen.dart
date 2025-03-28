import 'package:cameraly/cameraly.dart';
import 'package:cameraly_example/screens/camera_screen.dart';
import 'package:cameraly_example/screens/custom_display_screen.dart';
import 'package:cameraly_example/screens/custom_overlay_example.dart';
import 'package:cameraly_example/screens/limited_video_example.dart';
import 'package:cameraly_example/screens/orientation_debug_screen.dart';
import 'package:cameraly_example/screens/simple_camera_screen.dart';
import 'package:flutter/material.dart';

import 'inspectly_limited_video_version.dart';
import 'inspectly_version.dart';

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
            title: 'Inspectly Photo Only',
            subtitle: 'Inspectly version with simplified High-level API',
            icon: Icons.check_circle,
            color: Colors.teal,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InspectlyVersionScreen())),
          ),
          _buildExampleTile(
            context,
            title: 'Inspectly Limited Video',
            subtitle: 'Inspectly-style video with 15-second time limit',
            icon: Icons.videocam,
            color: Colors.teal.shade700,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InspectlyLimitedVideoScreen())),
          ),

          _buildExampleTile(
            context,
            title: 'Simple Camera (High-level API)',
            subtitle: 'Ultra-simple camera with automatic controller management',
            icon: Icons.auto_awesome,
            color: Colors.amber,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SimpleCameraScreen())),
          ),

          _buildExampleTile(
            context,
            title: 'Photo Only Camera',
            subtitle: 'Camera with photo capture only (with enhanced permission handling)',
            icon: Icons.camera_alt,
            color: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen(cameraMode: CameraMode.photoOnly))),
          ),
          _buildExampleTile(
            context,
            title: 'Video Only Camera',
            subtitle: 'Camera with video recording only (with enhanced permission handling)',
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
            subtitle: 'Camera with both photo and video capabilities (with enhanced permission handling)',
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
          _buildExampleTile(
            context,
            title: 'Orientation Debug',
            subtitle: 'Test camera behavior during orientation changes',
            icon: Icons.screen_rotation,
            color: Colors.deepOrange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrientationDebugScreen())),
          ),

          const Divider(height: 40, thickness: 2),

          const Padding(padding: EdgeInsets.all(16.0), child: Text('Legacy Examples (Without Enhanced Permission Handling)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54))),
          _buildExampleTile(
            context,
            title: 'Legacy Simple Camera',
            subtitle: 'Simple camera without enhanced permission handling',
            icon: Icons.auto_awesome,
            color: Colors.amber,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SimpleCameraScreen(useEnhanced: false))),
          ),
          _buildExampleTile(
            context,
            title: 'Legacy Photo Only Camera',
            subtitle: 'Uses original permission handling approach',
            icon: Icons.camera_alt,
            color: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen(cameraMode: CameraMode.photoOnly, useEnhanced: false))),
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
