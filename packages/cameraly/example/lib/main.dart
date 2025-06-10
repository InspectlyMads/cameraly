import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
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
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(
                      initialMode: CameraMode.photo,
                      showGridButton: true,
                      onMediaCaptured: (media) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Captured: ${media.path}'),
                          ),
                        );
                      },
                      onGalleryPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gallery button pressed'),
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
              },
              child: const Text('Open Camera (Photo Mode)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(
                      initialMode: CameraMode.video,
                      showGridButton: true,
                      onMediaCaptured: (media) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Captured video: ${media.path}'),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              child: const Text('Open Camera (Video Mode)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(
                      initialMode: CameraMode.combined,
                      showGridButton: true,
                      showDebugInfo: true,
                      onMediaCaptured: (media) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Captured: ${media.path}'),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              child: const Text('Open Camera (Combined Mode with Debug)'),
            ),
          ],
        ),
      ),
    );
  }
}