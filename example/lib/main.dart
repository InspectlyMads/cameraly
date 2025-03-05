import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:camera_android_camerax/camera_android_camerax.dart';
import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'image_rotation_helper.dart';
import 'video_limiter_example.dart';

// Function to check if the app is registered for permissions in iOS
Future<bool> isAppRegisteredForPermissions() async {
  if (Platform.isIOS) {
    try {
      // This will trigger iOS to register the app for permissions
      // even if we don't actually request them yet
      final cameraStatus = await Permission.camera.status;
      debugPrint('🔍 iOS permission status check: $cameraStatus');

      // Check if we're running on an iPad
      final bool isIPad = MediaQueryData.fromView(WidgetsBinding.instance.window).size.shortestSide > 600;
      debugPrint('🔍 Device is iPad: $isIPad');

      return true;
    } catch (e) {
      debugPrint('🔍 Error checking iOS permissions: $e');
      return false;
    }
  }
  return true; // Not iOS, so no issue
}

void main() async {
  // Set preferred orientations at app startup
  WidgetsFlutterBinding.ensureInitialized();
  // Remove orientation lock to allow all orientations
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

  // Check if the app is registered for permissions in iOS
  final isRegistered = await isAppRegisteredForPermissions();
  debugPrint('🚨 App registered for permissions: $isRegistered');

  // Request camera permissions at app startup - using a more direct approach
  debugPrint('🚨 REQUESTING PERMISSIONS AT APP STARTUP');

  if (Platform.isIOS) {
    // On iOS, we need to be more explicit about permission requests
    debugPrint('🚨 Running on iOS - using explicit permission request approach');

    // First, check if we can determine the status
    try {
      // Force a permission request dialog by directly requesting
      final cameraResult = await Permission.camera.request();
      debugPrint('🚨 iOS direct camera permission request result: $cameraResult');

      // Also request microphone permission
      final micResult = await Permission.microphone.request();
      debugPrint('🚨 iOS direct microphone permission request result: $micResult');

      // If permissions are denied, show instructions to enable in settings
      if (cameraResult.isDenied || cameraResult.isPermanentlyDenied) {
        debugPrint('🚨 Camera permission denied - will need to open settings');
        // We'll handle this in the UI
      }
    } catch (e) {
      debugPrint('🚨 Error requesting iOS permissions: $e');
    }
  } else {
    // Android permission flow
    final cameraStatus = await Permission.camera.status;
    debugPrint('🚨 Initial camera status: $cameraStatus');

    if (cameraStatus != PermissionStatus.granted) {
      final newStatus = await Permission.camera.request();
      debugPrint('🚨 After direct request, camera status: $newStatus');
    }

    final micStatus = await Permission.microphone.status;
    if (micStatus != PermissionStatus.granted) {
      final newMicStatus = await Permission.microphone.request();
      debugPrint('🚨 After direct request, microphone status: $newMicStatus');
    }
  }

  runApp(const CameralyApp());
}

// Helper function to request camera permissions
Future<bool> _requestCameraPermission() async {
  debugPrint('🔍 REQUESTING CAMERA PERMISSION');

  // Check current status first
  var status = await Permission.camera.status;
  debugPrint('🔍 Current camera permission status: $status');

  if (status.isDenied) {
    debugPrint('🔍 Camera permission is denied, requesting permission...');
    // Request camera permission
    status = await Permission.camera.request();
    debugPrint('🔍 After request, camera permission status: $status');
  }

  // Also request microphone permission for video recording
  var micStatus = await Permission.microphone.status;
  debugPrint('🔍 Current microphone permission status: $micStatus');

  if (micStatus.isDenied) {
    debugPrint('🔍 Microphone permission is denied, requesting permission...');
    micStatus = await Permission.microphone.request();
    debugPrint('🔍 After request, microphone permission status: $micStatus');
  }

  return status.isGranted;
}

class CameralyApp extends StatelessWidget {
  const CameralyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Cameraly Example', theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true), home: const HomeScreen());
  }
}

/// Home screen with examples list
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cameraly Examples')),
      body: ListView(
        children: [
          _buildExampleTile(context, title: 'Default Camera', subtitle: 'Basic camera with default overlay', icon: Icons.camera_alt, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen()))),
          _buildExampleTile(context, title: 'Video Limiter', subtitle: 'Camera with time-limited video recording', icon: Icons.timer, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VideoLimiterExample()))),
        ],
      ),
    );
  }

  Widget _buildExampleTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(leading: Icon(icon, color: Theme.of(context).primaryColor), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right), onTap: onTap),
    );
  }
}

/// The main camera screen that uses the Cameraly package with default overlay
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  late CameralyController _controller;
  bool _isInitialized = false;
  bool _hasPermission = false;
  final CameralyOverlayTheme _theme = const CameralyOverlayTheme(primaryColor: Colors.deepPurple, secondaryColor: Colors.red, backgroundColor: Colors.black54, opacity: 0.7);
  final List<XFile> _selectedMedia = [];
  bool _showGalleryView = false;

  // Animation controller for the media stack
  late AnimationController _stackAnimationController;
  late Animation<double> _stackAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _stackAnimationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _stackAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _stackAnimationController, curve: Curves.easeInOut))..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _stackAnimationController.reverse();
      }
    });

    // Initialize the orientation detection for image rotation
    ImageRotationHelper.initOrientationDetection();

    // Force permission request immediately on startup
    _forcePermissionRequest();
  }

  Future<void> _forcePermissionRequest() async {
    debugPrint('🚨 FORCING PERMISSION REQUEST ON STARTUP');

    // For iOS, we need to be more aggressive with permission requests
    if (Platform.isIOS) {
      debugPrint('🚨 iOS-specific permission handling');

      // First, try to directly access the camera to trigger the system permission dialog
      try {
        // This will force iOS to show the permission dialog if not shown before
        final cameras = await availableCameras();
        debugPrint('🚨 Available cameras: ${cameras.length}');

        // Now explicitly request the permission
        final cameraStatus = await Permission.camera.request();
        debugPrint('🚨 Direct camera permission request result: $cameraStatus');

        // Also request microphone permission
        final micStatus = await Permission.microphone.request();
        debugPrint('🚨 Direct microphone permission request result: $micStatus');

        // If permissions are still not showing up in settings
        if (cameraStatus.isPermanentlyDenied) {
          debugPrint('🚨 Camera permission is PERMANENTLY DENIED');
          if (mounted) {
            _showPermissionNotFoundDialog();
            return;
          }
        } else if (cameraStatus.isGranted) {
          debugPrint('🚨 Camera permission is GRANTED');
          setState(() {
            _hasPermission = true;
          });
          await _initCamera();
          return;
        }
      } catch (e) {
        debugPrint('🚨 Error during iOS permission request: $e');
      }
    } else {
      // Original Android code
      // Directly request camera permission without checking status first
      final cameraStatus = await Permission.camera.request();
      debugPrint('🚨 Direct camera permission request result: $cameraStatus');

      // Also request microphone permission
      final micStatus = await Permission.microphone.request();
      debugPrint('🚨 Direct microphone permission request result: $micStatus');

      // Check if permissions are permanently denied
      if (cameraStatus.isPermanentlyDenied) {
        debugPrint('🚨 Camera permission is PERMANENTLY DENIED');
        if (mounted) {
          _showPermanentlyDeniedDialog();
          return;
        }
      }
    }

    // Now proceed with normal flow
    _checkPermissionsAndInitCamera();
  }

  // Special dialog for when permissions aren't showing up in settings
  void _showPermissionNotFoundDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Issue'),
          content: const Text(
            'We\'re having trouble accessing the camera. The permission might not be showing up in your settings.\n\n'
            'Please try the following:\n'
            '1. Close the app completely\n'
            '2. Go to Settings > General > iPhone Storage\n'
            '3. Find this app and delete it\n'
            '4. Reinstall the app from the App Store\n'
            '5. When prompted, allow camera access',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _hasPermission = false;
                });
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
            'Camera permission has been permanently denied. '
            'Please open Settings and enable camera access for this app.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _hasPermission = false;
                });
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkPermissionsAndInitCamera() async {
    debugPrint('🔍 Starting permission check and camera initialization');

    // First check current permission status
    var cameraStatus = await Permission.camera.status;
    debugPrint('🔍 Initial camera permission status: $cameraStatus');

    // If not determined yet (first time), we need to request
    if (cameraStatus.isRestricted || cameraStatus.isDenied || cameraStatus.isLimited) {
      debugPrint('🔍 Need to request camera permission explicitly');

      // Force show the permission dialog
      final hasPermission = await _requestCameraPermission();

      debugPrint('🔍 Permission request result: $hasPermission');

      setState(() {
        _hasPermission = hasPermission;
      });

      if (hasPermission) {
        debugPrint('🔍 Permission granted, initializing camera');
        await _initCamera();
      } else {
        debugPrint('🔍 Permission denied after explicit request');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera permission is required to use this app')));
        }
      }
    } else if (cameraStatus.isGranted) {
      debugPrint('🔍 Permission already granted, initializing camera');
      setState(() {
        _hasPermission = true;
      });
      await _initCamera();
    } else {
      debugPrint('🔍 Unexpected permission status: $cameraStatus');
      // Handle other permission states like permanently denied
      setState(() {
        _hasPermission = false;
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      debugPrint('Starting camera initialization...');

      // Explicitly use CameraX on Android
      // This is important for better orientation handling
      if (Platform.isAndroid) {
        // Register the CameraX implementation
        debugPrint('Registering CameraX for Android');
        AndroidCameraCameraX.registerWith();
      } else {
        debugPrint('Running on iOS, no need to register CameraX');
      }

      // Get available cameras
      List<CameraDescription> cameras = [];
      try {
        cameras = await availableCameras();
        debugPrint('📱 Available cameras: ${cameras.length}');
        for (var i = 0; i < cameras.length; i++) {
          debugPrint('📱 Camera $i: ${cameras[i].name}, ${cameras[i].lensDirection}');
        }
      } catch (e) {
        debugPrint('📱 Error getting available cameras: $e');
      }

      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras available')));
        }
        return;
      }

      debugPrint('Initializing camera controller...');

      CameralyController? tempController;

      // Try to initialize with standard settings first
      try {
        debugPrint('Attempting to initialize camera with standard settings');
        tempController = await CameralyController.initializeForPhotos(settings: const PhotoSettings(resolution: ResolutionPreset.high, flashMode: FlashMode.auto));
        debugPrint('Camera initialized successfully with standard settings');
      } catch (e) {
        debugPrint('Error initializing camera with standard settings: $e');

        // If the error is related to flash capabilities, try again with flash off
        if (e.toString().contains('flash') || e.toString().contains('Flash')) {
          debugPrint('Flash capability error detected, retrying with flash disabled');
          try {
            tempController = await CameralyController.initializeForPhotos(settings: const PhotoSettings(resolution: ResolutionPreset.high, flashMode: FlashMode.off));
            debugPrint('Camera initialized successfully with flash disabled');
          } catch (retryError) {
            debugPrint('Retry with flash disabled also failed: $retryError');

            // If that also fails, try video-only initialization as a last resort
            try {
              debugPrint('Attempting video-only initialization as last resort');
              tempController = await CameralyController.initializeForVideos(settings: const VideoSettings(resolution: ResolutionPreset.high, enableAudio: false));
              debugPrint('Video-only initialization successful');
            } catch (videoError) {
              debugPrint('Video-only initialization also failed: $videoError');
            }
          }
        }
      }

      if (tempController == null) {
        debugPrint('Camera controller initialization returned null');

        // Check permissions as a diagnostic step
        final cameraStatus = await Permission.camera.status;
        debugPrint('Camera permission status: $cameraStatus');

        // Try to request permissions again if needed
        if (cameraStatus != PermissionStatus.granted) {
          debugPrint('Requesting camera permission again...');
          final newStatus = await Permission.camera.request();
          debugPrint('New camera permission status: $newStatus');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras available or initialization failed')));
        }
        return;
      }

      debugPrint('Camera controller initialized successfully');
      // Remove orientation lock to allow all orientations
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

      // If the underlying camera controller is available, try to set orientation
      if (tempController.cameraController != null) {
        debugPrint('Setting camera orientation...');
        try {
          // For Android with CameraX, we need to set the target rotation
          if (Platform.isAndroid) {
            // This is a CameraX specific setting that helps with orientation
            await tempController.cameraController!.setExposureOffset(0.0); // This is a dummy call to ensure controller is initialized
            debugPrint('Using CameraX on Android with explicit orientation handling');
          }
        } catch (e) {
          debugPrint('Error setting camera orientation: $e');
        }
      } else {
        debugPrint('Warning: controller.cameraController is null');
      }

      debugPrint('Setting state with initialized camera controller');
      setState(() {
        _controller = tempController!;
        _isInitialized = true;
      });
      debugPrint('Camera initialization complete');
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error initializing camera: $e')));
      }
    }
  }

  // Helper method to determine if the device is in landscape orientation
  bool _isLandscapeOrientation() {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape;
  }

  void _handleMediaSelected(List<XFile> mediaFiles) {
    setState(() {
      _selectedMedia.addAll(mediaFiles);
    });

    // Use a microtask to ensure the UI is laid out before starting the animation
    Future.microtask(() {
      if (mounted) {
        _stackAnimationController.reset();
        _stackAnimationController.forward();
      }
    });
  }

  void _navigateToGalleryView() {
    // Unlock orientation when viewing gallery
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    setState(() {
      _showGalleryView = true;
    });
  }

  @override
  void dispose() {
    // Dispose the orientation detection
    ImageRotationHelper.disposeOrientationDetection();

    // Dispose animation controller
    _stackAnimationController.dispose();

    // Dispose camera controller
    _controller.dispose();

    // Restore all orientations when leaving this screen
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Update camera orientation when device orientation changes
    if (_isInitialized) {
      // Comment out the orientation update to allow free rotation
      // _updateCameraOrientation();
    }

    if (_showGalleryView) {
      return _buildGalleryView();
    }

    return Scaffold(backgroundColor: Colors.black, body: !_hasPermission ? _buildPermissionDeniedView() : _buildCameraView());
  }

  Widget _buildPermissionDeniedView() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Camera Permission Required', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'This app needs camera access to take photos and videos.\n\n'
                'It appears that camera access has been denied. Please enable it in your device settings.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final status = await Permission.camera.status;
                if (status.isPermanentlyDenied) {
                  openAppSettings();
                } else {
                  final hasPermission = await _requestCameraPermission();
                  setState(() {
                    _hasPermission = hasPermission;
                  });
                  if (hasPermission) {
                    _initCamera();
                  }
                }
              },
              child: const Text('Grant Permission'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Show loading UI while camera initializes
        if (!_isInitialized)
          Container(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade700])),
            child: const SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 100, color: Colors.white),
                    SizedBox(height: 32),
                    Text('Cameraly', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 16),
                    Text('Loading camera...', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white70)),
                    SizedBox(height: 32),
                    CircularProgressIndicator(color: Colors.white),
                  ],
                ),
              ),
            ),
          ),

        // Camera preview (only shown when initialized)
        if (_isInitialized)
          CameralyPreview(
            controller: _controller,
            overlayType: CameralyOverlayType.defaultOverlay,
            defaultOverlay: DefaultCameralyOverlay(
              controller: _controller,
              theme: _theme,
              showGalleryButton: true,
              showFocusCircle: true,
              showZoomControls: true,
              // Only show flash button if flash is available
              showFlashButton: _controller.value.hasFlashCapability,
              allowMultipleSelection: true,
              onMediaSelected: _handleMediaSelected,
              onPictureTaken: onPictureTaken,
            ),
          ),

        // Media stack (only shown when there are selected media)
        Positioned(
          left: 20,
          top: 0,
          bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: () {
                if (_selectedMedia.isNotEmpty) {
                  setState(() {
                    _showGalleryView = true;
                  });
                }
              },
              child: AnimatedBuilder(
                animation: _stackAnimationController,
                builder: (context, child) {
                  // Only apply the scale animation if we have media
                  if (_selectedMedia.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Apply the scale animation
                  final scale = 1.0 + (_stackAnimation.value - 1.0);

                  return Transform.scale(scale: scale, alignment: Alignment.center, child: child);
                },
                child: _selectedMedia.isNotEmpty ? _buildMediaStack() : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaStack() {
    // Show at most 3 most recent images in the stack
    final recentMedia = _selectedMedia.length > 3 ? _selectedMedia.sublist(_selectedMedia.length - 3) : _selectedMedia;

    // Calculate the size of the stack based on the number of images
    // This ensures the widget has a fixed size before animation
    final double stackWidth = 70 + (recentMedia.length > 1 ? (recentMedia.length - 1) * 5.0 : 0);
    final double stackHeight = 70 + (recentMedia.length > 1 ? (recentMedia.length - 1) * 5.0 : 0);

    return SizedBox(
      width: stackWidth + 15, // Extra space for the "View All" label
      height: stackHeight,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)]),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Build the stack of images from back to front (reversed order)
            // This places older images at the bottom and newest on top
            for (int i = recentMedia.length - 1; i >= 0; i--)
              Positioned(
                left: -(recentMedia.length - 1 - i) * 5.0,
                top: -(recentMedia.length - 1 - i) * 5.0,
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, spreadRadius: 1, offset: const Offset(0, 2))],
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(10), child: _buildMediaThumbnail(recentMedia[i])),
                ),
              ),

            // Counter badge if there are more than 3 images
            if (_selectedMedia.length > 3)
              Positioned(
                top: -8,
                left: -8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, spreadRadius: 0)]),
                  child: Text('+${_selectedMedia.length - 3}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),

            // Tap indicator
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, spreadRadius: 0)]),
                  child: const Text('View\nAll', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Use the helper class for image rotation with context
  Future<File> _getRotatedImage(File imageFile) async {
    // Force rotation for landscape images on Android
    final bool shouldForceRotation = Platform.isAndroid;
    return ImageRotationHelper.getRotatedImage(imageFile, context, shouldForceRotation);
  }

  Widget _buildMediaThumbnail(XFile media) {
    final isVideo = media.path.toLowerCase().endsWith('.mp4') || media.path.toLowerCase().endsWith('.mov') || media.path.toLowerCase().endsWith('.avi');

    if (isVideo) {
      return Container(color: Colors.black, child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 30)));
    } else {
      // For images, we'll use a FutureBuilder to get a properly rotated image for gallery display
      return FutureBuilder<File>(
        future: ImageRotationHelper.getGalleryRotatedImage(File(media.path)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.hasError || !snapshot.hasData) {
            debugPrint('Error getting rotated image: ${snapshot.error}');
            return const Center(child: Icon(Icons.broken_image, color: Colors.white));
          }

          // Use the rotated image file with memory caching parameters
          final File rotatedFile = snapshot.data!;

          return Image.file(
            rotatedFile,
            fit: BoxFit.cover,
            // Add caching parameters to improve performance
            cacheWidth: 200, // Limit cached size for thumbnails
            cacheHeight: 200,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading image: $error');
              return const Center(child: Icon(Icons.broken_image, color: Colors.white));
            },
          );
        },
      );
    }
  }

  Widget _buildGalleryView() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Selected Media (${_selectedMedia.length})'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Lock orientation back to portrait when returning to camera
            SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

            setState(() {
              _showGalleryView = false;
            });
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _selectedMedia.isEmpty
                    ? const Center(child: Text('No media selected', style: TextStyle(color: Colors.white)))
                    : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: _selectedMedia.length,
                      itemBuilder: (context, index) {
                        final media = _selectedMedia[index];
                        final isVideo = media.path.toLowerCase().endsWith('.mp4') || media.path.toLowerCase().endsWith('.mov') || media.path.toLowerCase().endsWith('.avi');

                        return GestureDetector(
                          onTap: () {
                            // Unlock orientation for full screen preview
                            SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

                            // Show full screen preview
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => Scaffold(
                                      backgroundColor: Colors.black,
                                      appBar: AppBar(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        title: Text(media.name),
                                        leading: IconButton(
                                          icon: const Icon(Icons.arrow_back),
                                          onPressed: () {
                                            // Restore orientation settings when returning to gallery
                                            SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ),
                                      body: Center(
                                        child:
                                            isVideo
                                                ? const Icon(Icons.video_file, size: 100, color: Colors.white54)
                                                : FutureBuilder<File>(
                                                  future: ImageRotationHelper.getGalleryRotatedImage(File(media.path)),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                                      return const CircularProgressIndicator(color: Colors.white);
                                                    }

                                                    if (snapshot.hasError || !snapshot.hasData) {
                                                      return const Icon(Icons.broken_image, size: 100, color: Colors.white54);
                                                    }

                                                    // Use the rotated image file
                                                    final File rotatedFile = snapshot.data!;

                                                    return Image.file(rotatedFile, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.white54));
                                                  },
                                                ),
                                      ),
                                    ),
                              ),
                            );
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
                                child:
                                    isVideo
                                        ? const Icon(Icons.video_file, size: 50, color: Colors.white70)
                                        : ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: FutureBuilder<File>(
                                            future: ImageRotationHelper.getGalleryRotatedImage(File(media.path)),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
                                              }

                                              if (snapshot.hasError || !snapshot.hasData) {
                                                return const Icon(Icons.broken_image, size: 50, color: Colors.white70);
                                              }

                                              // Use the rotated image file
                                              final File rotatedFile = snapshot.data!;

                                              return Image.file(rotatedFile, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.white70));
                                            },
                                          ),
                                        ),
                              ),
                              if (isVideo)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                                    child: Icon(isVideo ? Icons.videocam : Icons.photo, size: 12, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  void onPictureTaken(XFile picture) {
    // Log more detailed information about the captured image
    debugPrint('📸 Picture taken: ${picture.path}');

    // Get device orientation at the time of capture
    final orientation = MediaQuery.of(context).orientation;
    debugPrint('📸 Device orientation at capture: $orientation');

    // Log camera controller orientation if available
    if (_controller.cameraController != null) {
      final lockedOrientation = _controller.cameraController!.value.lockedCaptureOrientation;
      debugPrint('📸 Camera locked orientation: $lockedOrientation');
    }

    // Use a microtask for all processing to avoid blocking the UI thread
    Future.microtask(() async {
      // Pre-process the image to ensure correct orientation before adding to gallery
      try {
        // Apply standard rotation for saving the image
        final File originalFile = File(picture.path);
        final File rotatedFile = await ImageRotationHelper.getRotatedImage(originalFile, context);

        // Create a new XFile from the rotated file
        final XFile processedPicture = XFile(rotatedFile.path);
        debugPrint('📸 Image processed: ${processedPicture.path}');

        // Add the processed picture to the selected media
        setState(() {
          _selectedMedia.add(processedPicture);
        });
      } catch (e) {
        debugPrint('📸 Error processing image: $e');
        // Fallback to original image if processing fails
        setState(() {
          _selectedMedia.add(picture);
        });
      }

      // Start the animation after state update
      _stackAnimationController.reset();
      _stackAnimationController.forward();
    });
  }

  // Update camera orientation based on device orientation
  void _updateCameraOrientation() {
    if (!_isInitialized || _controller.cameraController == null) return;

    try {
      // Don't lock the camera orientation anymore
      // if (_controller.cameraController?.value.lockedCaptureOrientation != DeviceOrientation.portraitUp) {
      //   _controller.cameraController?.lockCaptureOrientation(DeviceOrientation.portraitUp);
      //   debugPrint('Ensuring camera orientation is locked to portraitUp');
      // }
    } catch (e) {
      debugPrint('Error updating camera orientation: $e');
    }
  }
}

/// Example demonstrating how to save photos and videos to persistent storage
class PersistentStorageExample extends StatefulWidget {
  const PersistentStorageExample({super.key});

  @override
  State<PersistentStorageExample> createState() => _PersistentStorageExampleState();
}

class _PersistentStorageExampleState extends State<PersistentStorageExample> {
  late CameralyController _controller;
  bool _isInitialized = false;
  bool _hasPermission = false;
  String? _customDirectory;
  String _customFilename = '';
  bool _useCustomDirectory = false;
  bool _useCustomFilename = false;
  List<String> _savedFiles = [];

  // Use the helper class for image rotation
  Future<File> _getRotatedImage(File imageFile) async {
    // Force rotation for landscape images on Android
    final bool shouldForceRotation = Platform.isAndroid;
    return ImageRotationHelper.getRotatedImage(imageFile, context, shouldForceRotation);
  }

  @override
  void initState() {
    super.initState();

    // Initialize the orientation detection for image rotation
    ImageRotationHelper.initOrientationDetection();

    // Remove orientation lock to allow all orientations
    // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    _createCustomDirectory();

    // Force permission request immediately on startup
    _forcePermissionRequest();
  }

  Future<void> _forcePermissionRequest() async {
    debugPrint('🚨 FORCING PERMISSION REQUEST ON STARTUP');

    // For iOS, we need to be more aggressive with permission requests
    if (Platform.isIOS) {
      debugPrint('🚨 iOS-specific permission handling');

      // First, try to directly access the camera to trigger the system permission dialog
      try {
        // This will force iOS to show the permission dialog if not shown before
        final cameras = await availableCameras();
        debugPrint('🚨 Available cameras: ${cameras.length}');

        // Now explicitly request the permission
        final cameraStatus = await Permission.camera.request();
        debugPrint('🚨 Direct camera permission request result: $cameraStatus');

        // Also request microphone permission
        final micStatus = await Permission.microphone.request();
        debugPrint('🚨 Direct microphone permission request result: $micStatus');

        // If permissions are still not showing up in settings
        if (cameraStatus.isPermanentlyDenied) {
          debugPrint('🚨 Camera permission is PERMANENTLY DENIED');
          if (mounted) {
            _showPermissionNotFoundDialog();
            return;
          }
        } else if (cameraStatus.isGranted) {
          debugPrint('🚨 Camera permission is GRANTED');
          setState(() {
            _hasPermission = true;
          });
          await _initCamera();
          return;
        }
      } catch (e) {
        debugPrint('🚨 Error during iOS permission request: $e');
      }
    } else {
      // Original code
      // Directly request camera permission without checking status first
      final cameraStatus = await Permission.camera.request();
      debugPrint('🚨 Direct camera permission request result: $cameraStatus');

      // Also request microphone permission
      final micStatus = await Permission.microphone.request();
      debugPrint('🚨 Direct microphone permission request result: $micStatus');

      // Check if permissions are permanently denied
      if (cameraStatus.isPermanentlyDenied) {
        debugPrint('🚨 Camera permission is PERMANENTLY DENIED');
        if (mounted) {
          _showPermanentlyDeniedDialog();
          return;
        }
      }
    }

    // Now proceed with normal flow
    _checkPermissionsAndInitCamera();
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
            'Camera permission has been permanently denied. '
            'Please open Settings and enable camera access for this app.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _hasPermission = false;
                });
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Special dialog for when permissions aren't showing up in settings
  void _showPermissionNotFoundDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Issue'),
          content: const Text(
            'We\'re having trouble accessing the camera. The permission might not be showing up in your settings.\n\n'
            'Please try the following:\n'
            '1. Close the app completely\n'
            '2. Go to Settings > General > iPhone Storage\n'
            '3. Find this app and delete it\n'
            '4. Reinstall the app from the App Store\n'
            '5. When prompted, allow camera access',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _hasPermission = false;
                });
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkPermissionsAndInitCamera() async {
    debugPrint('🔍 Starting permission check and camera initialization');

    // First check current permission status
    var cameraStatus = await Permission.camera.status;
    debugPrint('🔍 Initial camera permission status: $cameraStatus');

    // If not determined yet (first time), we need to request
    if (cameraStatus.isRestricted || cameraStatus.isDenied || cameraStatus.isLimited) {
      debugPrint('🔍 Need to request camera permission explicitly');

      // Force show the permission dialog
      final hasPermission = await _requestCameraPermission();

      debugPrint('🔍 Permission request result: $hasPermission');

      setState(() {
        _hasPermission = hasPermission;
      });

      if (hasPermission) {
        debugPrint('🔍 Permission granted, initializing camera');
        await _initCamera();
      } else {
        debugPrint('🔍 Permission denied after explicit request');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera permission is required to use this app')));
        }
      }
    } else if (cameraStatus.isGranted) {
      debugPrint('🔍 Permission already granted, initializing camera');
      setState(() {
        _hasPermission = true;
      });
      await _initCamera();
    } else {
      debugPrint('🔍 Unexpected permission status: $cameraStatus');
      // Handle other permission states like permanently denied
      setState(() {
        _hasPermission = false;
      });
    }
  }

  Future<void> _createCustomDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final customDir = Directory('${appDir.path}/cameraly_custom');

    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }

    setState(() {
      _customDirectory = customDir.path;
    });
  }

  Future<void> _initCamera() async {
    try {
      debugPrint('Starting camera initialization...');

      // Explicitly use CameraX on Android
      // This is important for better orientation handling
      if (Platform.isAndroid) {
        // Register the CameraX implementation
        debugPrint('Registering CameraX for Android');
        AndroidCameraCameraX.registerWith();
      } else {
        debugPrint('Running on iOS, no need to register CameraX');
      }

      // Get available cameras
      List<CameraDescription> cameras = [];
      try {
        cameras = await availableCameras();
        debugPrint('📱 Available cameras: ${cameras.length}');
        for (var i = 0; i < cameras.length; i++) {
          debugPrint('📱 Camera $i: ${cameras[i].name}, ${cameras[i].lensDirection}');
        }
      } catch (e) {
        debugPrint('📱 Error getting available cameras: $e');
      }

      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras available')));
        }
        return;
      }

      debugPrint('Initializing camera controller...');

      CameralyController? tempController;

      // Try to initialize with standard settings first
      try {
        debugPrint('Attempting to initialize camera with standard settings');
        tempController = await CameralyController.initializeForPhotos(settings: const PhotoSettings(resolution: ResolutionPreset.high, flashMode: FlashMode.auto));
        debugPrint('Camera initialized successfully with standard settings');
      } catch (e) {
        debugPrint('Error initializing camera with standard settings: $e');

        // If the error is related to flash capabilities, try again with flash off
        if (e.toString().contains('flash') || e.toString().contains('Flash')) {
          debugPrint('Flash capability error detected, retrying with flash disabled');
          try {
            tempController = await CameralyController.initializeForPhotos(settings: const PhotoSettings(resolution: ResolutionPreset.high, flashMode: FlashMode.off));
            debugPrint('Camera initialized successfully with flash disabled');
          } catch (retryError) {
            debugPrint('Retry with flash disabled also failed: $retryError');

            // If that also fails, try video-only initialization as a last resort
            try {
              debugPrint('Attempting video-only initialization as last resort');
              tempController = await CameralyController.initializeForVideos(settings: const VideoSettings(resolution: ResolutionPreset.high, enableAudio: false));
              debugPrint('Video-only initialization successful');
            } catch (videoError) {
              debugPrint('Video-only initialization also failed: $videoError');
            }
          }
        }
      }

      if (tempController == null) {
        debugPrint('Camera controller initialization returned null');

        // Check permissions as a diagnostic step
        final cameraStatus = await Permission.camera.status;
        debugPrint('Camera permission status: $cameraStatus');

        // Try to request permissions again if needed
        if (cameraStatus != PermissionStatus.granted) {
          debugPrint('Requesting camera permission again...');
          final newStatus = await Permission.camera.request();
          debugPrint('New camera permission status: $newStatus');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cameras available or initialization failed')));
        }
        return;
      }

      debugPrint('Camera controller initialized successfully');
      // Remove orientation lock to allow all orientations
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

      // If the underlying camera controller is available, try to set orientation
      if (tempController.cameraController != null) {
        debugPrint('Setting camera orientation...');
        try {
          // For Android with CameraX, we need to set the target rotation
          if (Platform.isAndroid) {
            // This is a CameraX specific setting that helps with orientation
            await tempController.cameraController!.setExposureOffset(0.0); // This is a dummy call to ensure controller is initialized
            debugPrint('Using CameraX on Android with explicit orientation handling');
          }
        } catch (e) {
          debugPrint('Error setting camera orientation: $e');
        }
      } else {
        debugPrint('Warning: controller.cameraController is null');
      }

      debugPrint('Setting state with initialized camera controller');
      setState(() {
        _controller = tempController!;
        _isInitialized = true;
      });
      debugPrint('Camera initialization complete');
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error initializing camera: $e')));
      }
    }
  }

  Future<void> _loadSavedFiles() async {
    final directory = _useCustomDirectory && _customDirectory != null ? Directory(_customDirectory!) : await getApplicationDocumentsDirectory();

    final files = await directory.list().toList();
    final mediaFiles = files.whereType<File>().where((file) => file.path.endsWith('.jpg') || file.path.endsWith('.mp4')).map((file) => file.path).toList();

    setState(() {
      _savedFiles = mediaFiles;
    });
  }

  Future<void> _takePictureToStorage({String? customFilename}) async {
    try {
      // Take the picture
      final XFile imageFile = await _controller.takePicture();
      debugPrint('Picture taken: ${imageFile.path}');

      // Log orientation information
      final orientation = MediaQuery.of(context).orientation;
      final deviceOrientation = orientation == Orientation.landscape ? 'landscape' : 'portrait';
      debugPrint('Current device orientation: $deviceOrientation');

      // Log locked orientation if available
      final lockedOrientation = _controller.cameraController?.value.lockedCaptureOrientation;
      debugPrint('Locked capture orientation: $lockedOrientation');

      // Create a temporary file from the XFile
      final tempFile = File(imageFile.path);

      // Generate a filename based on timestamp or use the custom filename
      final String filename = customFilename ?? 'cameraly_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Determine the target directory (custom or app documents)
      final Directory targetDir = _customDirectory != null ? Directory(_customDirectory as String) : await getApplicationDocumentsDirectory();

      // Create the full path for the saved file
      final String targetPath = path.join(targetDir.path, filename);

      // Copy the file to the target path
      final bytes = await tempFile.readAsBytes();
      final File savedFile = await File(targetPath).writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Picture saved to: ${savedFile.path}')));

        // Update the saved files list and reload saved files
        setState(() {
          _savedFiles.add(savedFile.path);
        });

        // Reload saved files
        _loadSavedFiles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving picture: $e')));
      }
    }
  }

  Future<void> _toggleVideoRecording() async {
    if (_controller.value.isRecordingVideo) {
      try {
        // Stop recording using standard method
        final tempFile = await _controller.stopVideoRecording();

        // Generate filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final name = (_useCustomFilename && _customFilename.isNotEmpty) ? _customFilename : 'video_$timestamp';

        // Determine target directory
        final String targetPath;
        if (_useCustomDirectory && _customDirectory != null) {
          targetPath = _customDirectory!;
        } else {
          final appDir = await getApplicationDocumentsDirectory();
          targetPath = appDir.path;
        }

        // Create full path with filename and extension
        final String targetFilePath = '$targetPath/$name.mp4';

        // Copy the file to the new location
        final bytes = await tempFile.readAsBytes();
        final File savedFile = File(targetFilePath);
        await savedFile.writeAsBytes(bytes);

        // Create XFile from the saved file
        final file = XFile(targetFilePath);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [const Text('Video saved to persistent storage'), const SizedBox(height: 4), Text('Path: ${file.path}', style: const TextStyle(fontSize: 12))],
            ),
            duration: const Duration(seconds: 5),
          ),
        );

        _loadSavedFiles();
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      try {
        await _controller.startVideoRecording();
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    // Dispose the orientation detection
    ImageRotationHelper.disposeOrientationDetection();

    // Dispose camera controller
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Persistent Storage Example'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSavedFiles, tooltip: 'Refresh saved files')]),
      body:
          !_hasPermission
              ? _buildPermissionDeniedView()
              : Column(
                children: [
                  // Camera preview
                  Expanded(flex: 3, child: _isInitialized ? CameralyPreview(controller: _controller, overlayType: CameralyOverlayType.none) : const Center(child: CircularProgressIndicator())),

                  // Controls
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: Colors.black87,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Custom directory toggle
                          SwitchListTile(
                            title: const Text('Use custom directory', style: TextStyle(color: Colors.white)),
                            subtitle: Text(_customDirectory ?? 'Default directory', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            value: _useCustomDirectory,
                            onChanged: (value) => setState(() => _useCustomDirectory = value),
                            activeColor: Theme.of(context).primaryColor,
                          ),

                          // Custom filename toggle and input
                          SwitchListTile(
                            title: const Text('Use custom filename', style: TextStyle(color: Colors.white)),
                            value: _useCustomFilename,
                            onChanged: (value) => setState(() => _useCustomFilename = value),
                            activeColor: Theme.of(context).primaryColor,
                          ),

                          if (_useCustomFilename)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: TextField(
                                decoration: const InputDecoration(hintText: 'Enter filename (without extension)', hintStyle: TextStyle(color: Colors.white54), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30))),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (value) => setState(() => _customFilename = value),
                              ),
                            ),

                          const Spacer(),

                          // Capture buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Photo button
                              ElevatedButton.icon(onPressed: () => _takePictureToStorage(customFilename: _customFilename), icon: const Icon(Icons.photo_camera), label: const Text('Take Photo')),

                              // Video button
                              ElevatedButton.icon(
                                onPressed: _toggleVideoRecording,
                                icon: Icon(_controller.value.isRecordingVideo ? Icons.stop : Icons.videocam),
                                label: Text(_controller.value.isRecordingVideo ? 'Stop Recording' : 'Record Video'),
                                style: ElevatedButton.styleFrom(backgroundColor: _controller.value.isRecordingVideo ? Colors.red : Theme.of(context).primaryColor, foregroundColor: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Saved files list
                  if (_savedFiles.isNotEmpty)
                    Container(
                      height: 100,
                      color: Colors.black,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(padding: EdgeInsets.only(left: 16, top: 8), child: Text('Saved Files:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _savedFiles.length,
                              padding: const EdgeInsets.all(8),
                              itemBuilder: (context, index) {
                                final path = _savedFiles[index];
                                final isVideo = path.endsWith('.mp4');

                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
                                        child:
                                            isVideo
                                                ? const Icon(Icons.videocam, size: 40, color: Colors.white70)
                                                : ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: FutureBuilder<File>(
                                                    future: ImageRotationHelper.getGalleryRotatedImage(File(path)),
                                                    builder: (context, snapshot) {
                                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                                        return const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
                                                      }

                                                      if (snapshot.hasError || !snapshot.hasData) {
                                                        return const Icon(Icons.broken_image, size: 40, color: Colors.white70);
                                                      }

                                                      // Use the rotated image file
                                                      final File rotatedFile = snapshot.data!;

                                                      return Image.file(rotatedFile, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.white70));
                                                    },
                                                  ),
                                                ),
                                      ),
                                      if (isVideo)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                                            child: Icon(isVideo ? Icons.videocam : Icons.photo, size: 12, color: Colors.white),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Camera Permission Required', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'This app needs camera access to take photos and videos.\n\n'
                'It appears that camera access has been denied. Please enable it in your device settings.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final status = await Permission.camera.status;
                if (status.isPermanentlyDenied) {
                  openAppSettings();
                } else {
                  final hasPermission = await _requestCameraPermission();
                  setState(() {
                    _hasPermission = hasPermission;
                  });
                  if (hasPermission) {
                    _initCamera();
                  }
                }
              },
              child: const Text('Grant Permission'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
