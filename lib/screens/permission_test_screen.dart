import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionTestScreen extends ConsumerStatefulWidget {
  const PermissionTestScreen({super.key});

  @override
  ConsumerState<PermissionTestScreen> createState() => _PermissionTestScreenState();
}

class _PermissionTestScreenState extends ConsumerState<PermissionTestScreen> {
  String _statusText = 'Checking permissions...';
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;
    final photosStatus = await Permission.photos.status;
    
    setState(() {
      _statusText = '''
Camera: ${_getStatusString(cameraStatus)}
Microphone: ${_getStatusString(microphoneStatus)}
Photos: ${_getStatusString(photosStatus)}
      ''';
    });
  }
  
  String _getStatusString(PermissionStatus status) {
    if (status.isGranted) return 'Granted ✅';
    if (status.isDenied) return 'Denied ❌';
    if (status.isPermanentlyDenied) return 'Permanently Denied 🚫';
    if (status.isRestricted) return 'Restricted ⚠️';
    if (status.isLimited) return 'Limited ⚠️';
    return 'Unknown ❓';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Permission Status:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Text(
                _statusText,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _statusText = 'Requesting permissions...';
                  });
                  
                  // Request permissions one by one for better debugging
                  final cameraResult = await Permission.camera.request();
                  debugPrint('Camera permission result: $cameraResult');
                  
                  final microphoneResult = await Permission.microphone.request();
                  debugPrint('Microphone permission result: $microphoneResult');
                  
                  final photosResult = await Permission.photos.request();
                  debugPrint('Photos permission result: $photosResult');
                  
                  await _checkPermissions();
                },
                child: const Text('Request All Permissions'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final opened = await openAppSettings();
                  debugPrint('App settings opened: $opened');
                },
                child: const Text('Open App Settings'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkPermissions,
                child: const Text('Refresh Status'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}