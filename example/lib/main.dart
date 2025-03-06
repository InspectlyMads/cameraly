import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() async {
  // Set preferred orientations at app startup
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app - let Cameraly handle permissions
  runApp(const CameralyApp());
}

class CameralyApp extends StatelessWidget {
  const CameralyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Cameraly Example', theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true), home: const HomeScreen());
  }
}
