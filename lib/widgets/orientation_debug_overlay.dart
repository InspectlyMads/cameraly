import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/camera_providers.dart';

/// Debug overlay to show orientation information
class OrientationDebugOverlay extends ConsumerWidget {
  final bool showDebugInfo;

  const OrientationDebugOverlay({
    super.key,
    this.showDebugInfo = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showDebugInfo) {
      return const SizedBox.shrink();
    }

    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Positioned(
      top: 100,
      left: 16,
      right: isLandscape ? null : 16,
      child: Container(
        width: isLandscape ? 350 : null, // Fixed width in landscape
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Consumer(
          builder: (context, ref, child) {
            final cameraService = ref.read(cameraServiceProvider);
            final debugInfo = cameraService.getOrientationDebugInfo();
            
            // Get camera state for additional info
            final cameraState = ref.watch(cameraControllerProvider);
            final sensorOrientation = cameraState.controller?.description.sensorOrientation ?? 0;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Orientation Debug Info',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDebugRow('Device', '${debugInfo['deviceInfo']?['manufacturer']} ${debugInfo['deviceInfo']?['model']}'),
                _buildDebugRow('OS Version', debugInfo['deviceInfo']?['osVersion'] ?? 'Unknown'),
                _buildDebugRow('Camera Sensor', '$sensorOrientation°'),
                _buildDebugRow('Device Orientation', '${debugInfo['calculatedOrientation']}°'),
                _buildDebugRow('Final Rotation', 'Will be calculated on capture'),
                _buildDebugRow('Accuracy Score', '${((debugInfo['accuracyScore'] ?? 0) * 100).toStringAsFixed(0)}%'),
                if (debugInfo['lastAccelerometer'] != null)
                  _buildDebugRow(
                    'Accelerometer',
                    'X: ${debugInfo['lastAccelerometer']['x'].toStringAsFixed(2)}, '
                    'Y: ${debugInfo['lastAccelerometer']['y'].toStringAsFixed(2)}, '
                    'Z: ${debugInfo['lastAccelerometer']['z'].toStringAsFixed(2)}',
                  ),
                if (debugInfo['lastGyroscope'] != null)
                  _buildDebugRow(
                    'Gyroscope',
                    'X: ${debugInfo['lastGyroscope']['x'].toStringAsFixed(2)}, '
                    'Y: ${debugInfo['lastGyroscope']['y'].toStringAsFixed(2)}, '
                    'Z: ${debugInfo['lastGyroscope']['z'].toStringAsFixed(2)}',
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}