import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cameraly Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cameraly Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Basic Camera Modes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Test Permissions Button
          _ExampleCard(
            title: 'Test Permissions',
            description: 'Debug: Test permission requests',
            onTap: () async {
              final cameraStatus = await Permission.camera.status;
              final micStatus = await Permission.microphone.status;
              final locationStatus = await Permission.location.status;
              
              // Show current status first
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Permission Status'),
                    content: Text(
                      'Camera: ${cameraStatus.name}\n'
                      'Microphone: ${micStatus.name}\n'
                      'Location: ${locationStatus.name}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          
          // Reset Permissions (iOS Simulator only)
          _ExampleCard(
            title: 'Photo Mode (Fresh Permissions)',
            description: 'Test photo mode with no prior permissions',
            onTap: () => _openCamera(
              context,
              mode: CameraMode.photo,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Photo Mode
          _ExampleCard(
            title: 'Photo Mode',
            description: 'Basic photo capture with default UI',
            onTap: () => _openCamera(
              context,
              mode: CameraMode.photo,
            ),
          ),
          
          // Video Mode
          _ExampleCard(
            title: 'Video Mode',
            description: 'Video recording with default UI',
            onTap: () => _openCamera(
              context,
              mode: CameraMode.video,
            ),
          ),
          
          // Video Mode with Duration Limit
          _ExampleCard(
            title: 'Video Mode (10s limit)',
            description: 'Video recording with 10 second duration limit',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CameraScreen(
                  initialMode: CameraMode.video,
                  videoDurationLimit: 10,
                  onMediaCaptured: (media) {
                    // Video captured successfully
                  },
                  onError: (error) {
                    // Handle error silently
                  },
                ),
              ),
            ),
          ),
          
          // Video Mode with Short Duration Limit
          _ExampleCard(
            title: 'Video Mode (15s limit)',
            description: 'Video recording with 15 second duration limit',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CameraScreen(
                  initialMode: CameraMode.video,
                  videoDurationLimit: 15,
                  onMediaCaptured: (media) {
                    // Video captured successfully
                  },
                  onError: (error) {
                    // Handle error silently
                  },
                ),
              ),
            ),
          ),
          
          // Combined Mode
          _ExampleCard(
            title: 'Combined Mode',
            description: 'Switch between photo and video',
            onTap: () => _openCamera(
              context,
              mode: CameraMode.combined,
              showGrid: true,
            ),
          ),
          
          const SizedBox(height: 32),
          const Text(
            'Custom UI Examples',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Custom Buttons
          _ExampleCard(
            title: 'Custom Gallery & Check Buttons',
            description: 'Replace default buttons with custom widgets',
            onTap: () => _openCameraWithCustomButtons(context),
          ),
          
          // Custom Side Widget
          _ExampleCard(
            title: 'Custom Side Widget',
            description: 'Add custom widget to the left side',
            onTap: () => _openCameraWithSideWidget(context),
          ),
          
          // Fully Custom UI
          _ExampleCard(
            title: 'Fully Custom UI',
            description: 'All UI elements customized',
            onTap: () => _openCameraFullyCustom(context),
          ),
          
          const SizedBox(height: 32),
          const Text(
            'Feature Examples',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Photo Timer
          _ExampleCard(
            title: 'Photo Timer (3s)',
            description: 'Photo with 3 second countdown',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CameraScreen(
                  initialMode: CameraMode.photo,
                  settings: const CameraSettings(
                    photoTimerSeconds: 3,
                  ),
                  onMediaCaptured: (media) {
                    // Photo captured
                  },
                ),
              ),
            ),
          ),
          
          // High Quality
          _ExampleCard(
            title: 'Max Quality Photo',
            description: 'Maximum resolution photos',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CameraScreen(
                  initialMode: CameraMode.photo,
                  settings: const CameraSettings(
                    photoQuality: PhotoQuality.max,
                  ),
                  onMediaCaptured: (media) {
                    // Photo captured
                  },
                ),
              ),
            ),
          ),
          
          // Square Aspect Ratio
          _ExampleCard(
            title: 'Square Photos (1:1)',
            description: 'Instagram-style square photos',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CameraScreen(
                  initialMode: CameraMode.photo,
                  settings: const CameraSettings(
                    aspectRatio: CameraAspectRatio.ratio_1_1,
                  ),
                  onMediaCaptured: (media) {
                    // Photo captured
                  },
                ),
              ),
            ),
          ),
          
          // Without Location
          _ExampleCard(
            title: 'Without Location Metadata',
            description: 'Disable GPS metadata capture',
            onTap: () => _openCamera(
              context,
              mode: CameraMode.photo,
              captureLocation: false,
            ),
          ),
          
          // Hidden Gallery/Check
          _ExampleCard(
            title: 'Minimal UI',
            description: 'Hide gallery and check buttons',
            onTap: () => _openCamera(
              context,
              mode: CameraMode.photo,
              showGallery: false,
              showCheck: false,
            ),
          ),
        ],
      ),
    );
  }

  void _openCamera(
    BuildContext context, {
    required CameraMode mode,
    bool showGrid = false,
    bool captureLocation = true,
    bool showGallery = true,
    bool showCheck = true,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          initialMode: mode,
          showGridButton: showGrid,
          captureLocationMetadata: captureLocation,
          showGalleryButton: showGallery,
          showCheckButton: showCheck,
          onMediaCaptured: (media) {
            // Media captured successfully
          },
          onGalleryPressed: () {
            // Handle gallery button tap
          },
          onError: (error) {
            // Handle error silently
          },
        ),
      ),
    );
  }

  void _openCameraWithCustomButtons(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          initialMode: CameraMode.photo,
          customWidgets: CameraCustomWidgets(
            galleryButton: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.collections,
                color: Colors.white,
                size: 30,
              ),
            ),
            checkButton: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.done_all,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          onMediaCaptured: (media) {
            // Media captured successfully
          },
          onGalleryPressed: () {
            // Handle gallery button tap
          },
        ),
      ),
    );
  }

  void _openCameraWithSideWidget(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          initialMode: CameraMode.photo,
          customWidgets: CameraCustomWidgets(
            leftSideWidget: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_vintage, color: Colors.white),
                    onPressed: () {
                      // Handle filter button tap
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.timer, color: Colors.white),
                    onPressed: () {
                      // Handle timer button tap
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      // Handle settings button tap
                    },
                  ),
                ],
              ),
            ),
          ),
          onMediaCaptured: (media) {
            // Media captured successfully
          },
        ),
      ),
    );
  }

  void _openCameraFullyCustom(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          initialMode: CameraMode.photo,
          showGridButton: true,
          customWidgets: CameraCustomWidgets(
            // Custom gallery button
            galleryButton: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.photo_library_outlined, color: Colors.white),
            ),
            
            // Custom check button
            checkButton: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(Icons.check_circle_outline, color: Colors.white),
            ),
            
            // Custom flash control
            flashControl: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.amber.shade600,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flash_on, color: Colors.white, size: 24),
            ),
            
            // Custom left side widget
            leftSideWidget: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_1, color: Colors.white, size: 24),
                  SizedBox(height: 8),
                  Icon(Icons.filter_2, color: Colors.white, size: 24),
                  SizedBox(height: 8),
                  Icon(Icons.filter_3, color: Colors.white, size: 24),
                ],
              ),
            ),
          ),
          onMediaCaptured: (media) {
            // Media captured successfully
          },
          onGalleryPressed: () {
            // Handle gallery button tap
          },
        ),
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ExampleCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}