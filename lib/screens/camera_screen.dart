import 'package:camera/camera.dart' as camera;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/camera_providers.dart';
import '../providers/permission_providers.dart';
import '../services/camera_service.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final CameraMode initialMode;

  const CameraScreen({
    super.key,
    required this.initialMode,
  });

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize camera with the specified mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithMode();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = ref.read(cameraControllerProvider.notifier);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App is going to background, dispose camera to free resources
        break;
      case AppLifecycleState.resumed:
        // App is back in foreground, reinitialize camera
        _initializeWithMode();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _initializeWithMode() async {
    final cameraController = ref.read(cameraControllerProvider.notifier);
    await cameraController.switchMode(widget.initialMode);
    await cameraController.initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildCameraInterface(),
      ),
    );
  }

  Widget _buildCameraInterface() {
    final cameraState = ref.watch(cameraControllerProvider);

    if (cameraState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (cameraState.errorMessage != null) {
      return _buildErrorState(cameraState.errorMessage!);
    }

    if (!cameraState.isInitialized || cameraState.controller == null) {
      return _buildPermissionOrInitializationState();
    }

    return Stack(
      children: [
        // Camera preview
        _buildCameraPreview(cameraState.controller!),

        // Top controls
        _buildTopControls(),

        // Bottom controls
        _buildBottomControls(),

        // Mode selector for combined mode
        if (cameraState.mode == CameraMode.combined) _buildModeSelector(),
      ],
    );
  }

  Widget _buildCameraPreview(camera.CameraController controller) {
    return Positioned.fill(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: camera.CameraPreview(controller),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Flash control
          _buildFlashControl(),

          // Camera switch
          _buildCameraSwitchControl(),
        ],
      ),
    );
  }

  Widget _buildFlashControl() {
    final hasFlash = ref.watch(cameraHasFlashProvider);
    final flashIcon = ref.watch(flashModeIconProvider);
    final flashDisplayName = ref.watch(flashModeDisplayNameProvider);

    if (!hasFlash) {
      return const SizedBox(width: 48); // Placeholder to maintain layout
    }

    return CircleAvatar(
      backgroundColor: Colors.black54,
      child: IconButton(
        icon: Text(
          flashIcon,
          style: const TextStyle(fontSize: 20),
        ),
        onPressed: () {
          ref.read(cameraControllerProvider.notifier).cycleFlashMode();

          // Show flash mode change feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Flash: $flashDisplayName'),
              duration: const Duration(milliseconds: 1500),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraSwitchControl() {
    final canSwitch = ref.watch(canSwitchCameraProvider);

    if (!canSwitch) {
      return const SizedBox(width: 48); // Placeholder to maintain layout
    }

    return CircleAvatar(
      backgroundColor: Colors.black54,
      child: IconButton(
        icon: const Icon(Icons.cameraswitch, color: Colors.white),
        onPressed: () {
          ref.read(cameraControllerProvider.notifier).switchCamera();
        },
      ),
    );
  }

  Widget _buildBottomControls() {
    final cameraState = ref.watch(cameraControllerProvider);

    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery/Preview placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.photo_library,
              color: Colors.white,
              size: 24,
            ),
          ),

          // Main capture button
          _buildCaptureButton(cameraState),

          // Mode info
          _buildModeInfo(cameraState),
        ],
      ),
    );
  }

  Widget _buildCaptureButton(CameraState cameraState) {
    if (cameraState.mode == CameraMode.video || (cameraState.mode == CameraMode.combined && _isVideoModeSelected)) {
      return _buildVideoRecordButton(cameraState);
    } else {
      return _buildPhotoButton();
    }
  }

  Widget _buildPhotoButton() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!, width: 4),
        ),
        child: const Icon(
          Icons.camera_alt,
          color: Colors.black,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildVideoRecordButton(CameraState cameraState) {
    final isRecording = cameraState.isRecording;

    return GestureDetector(
      onTap: isRecording ? _stopVideoRecording : _startVideoRecording,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording ? Colors.red : Colors.white,
          border: Border.all(
            color: isRecording ? Colors.red[800]! : Colors.grey[300]!,
            width: 4,
          ),
        ),
        child: Icon(
          isRecording ? Icons.stop : Icons.videocam,
          color: isRecording ? Colors.white : Colors.black,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildModeInfo(CameraState cameraState) {
    String modeText;
    switch (cameraState.mode) {
      case CameraMode.photo:
        modeText = 'PHOTO';
        break;
      case CameraMode.video:
        modeText = 'VIDEO';
        break;
      case CameraMode.combined:
        modeText = _isVideoModeSelected ? 'VIDEO' : 'PHOTO';
        break;
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            modeText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (cameraState.isRecording) ...[
            const SizedBox(height: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Combined mode state
  bool _isVideoModeSelected = false;

  Widget _buildModeSelector() {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildModeToggleButton('PHOTO', !_isVideoModeSelected),
          const SizedBox(width: 16),
          _buildModeToggleButton('VIDEO', _isVideoModeSelected),
        ],
      ),
    );
  }

  Widget _buildModeToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isVideoModeSelected = label == 'VIDEO';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow : Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(cameraControllerProvider.notifier).clearError();
                _initializeWithMode();
              },
              child: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionOrInitializationState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt,
            size: 64,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          const Text(
            'Camera Initialization',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Setting up camera...',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final permissionNotifier = ref.read(permissionRequestProvider.notifier);
              await permissionNotifier.requestCameraPermissions();
              await _initializeWithMode();
            },
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }

  // Camera action methods
  Future<void> _takePhoto() async {
    final cameraController = ref.read(cameraControllerProvider.notifier);

    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      final imageFile = await cameraController.takePicture();

      if (imageFile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo captured!'),
            duration: Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _startVideoRecording() async {
    final cameraController = ref.read(cameraControllerProvider.notifier);

    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      await cameraController.startVideoRecording();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording started'),
            duration: Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _stopVideoRecording() async {
    final cameraController = ref.read(cameraControllerProvider.notifier);

    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      final videoFile = await cameraController.stopVideoRecording();

      if (videoFile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video saved!'),
            duration: Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
