import 'package:camera/camera.dart' as camera;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/camera_providers.dart';
import '../providers/gallery_providers.dart';
import '../providers/permission_providers.dart';
import '../screens/gallery_screen.dart';
import '../services/camera_service.dart';
import '../utils/orientation_ui_helper.dart';

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
  bool _hasInitializationFailed = false;

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
    setState(() {
      _hasInitializationFailed = false;
    });

    final cameraController = ref.read(cameraControllerProvider.notifier);
    await cameraController.switchMode(widget.initialMode);
    await cameraController.initializeCamera();

    // Check if initialization failed due to permissions
    final cameraState = ref.read(cameraControllerProvider);
    if (cameraState.errorMessage != null && cameraState.errorMessage!.contains('permissions')) {
      setState(() {
        _hasInitializationFailed = true;
      });
    }
  }

  /// Retry initialization after permission grant
  Future<void> _retryInitialization() async {
    // Add a small delay to ensure permissions are fully processed
    await Future.delayed(const Duration(milliseconds: 200));
    await _initializeWithMode();
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
      return const Center(child: CircularProgressIndicator());
    }

    if (cameraState.errorMessage != null) {
      return _buildErrorState(cameraState.errorMessage!);
    }

    if (!cameraState.isInitialized || cameraState.controller == null) {
      return _buildPermissionOrInitializationState();
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        return AnimatedSwitcher(
          duration: OrientationUIHelper.getOrientationTransitionDuration(),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: Stack(
            key: ValueKey(orientation),
            children: [
              // Camera preview (standard approach)
              _buildCameraPreview(cameraState.controller!),

              // Orientation-specific UI overlay
              _buildOrientationSpecificUI(orientation, cameraState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrientationSpecificUI(Orientation orientation, CameraState cameraState) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    return Stack(
      children: [
        // Top controls (same for both orientations)
        _buildTopControls(orientation),

        // Orientation-specific layout
        if (OrientationUIHelper.isLandscape(orientation)) _buildLandscapeUI(screenSize, safeArea, cameraState) else _buildPortraitUI(screenSize, safeArea, cameraState),
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

  Widget _buildTopControls(Orientation orientation) {
    final safeArea = MediaQuery.of(context).padding;

    return Positioned(
      top: 16 + safeArea.top,
      left: 16 + safeArea.left,
      right: 16 + safeArea.right,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Right side controls column (flash, camera switch, future buttons)
          _buildRightControlsColumn(),
        ],
      ),
    );
  }

  Widget _buildRightControlsColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Flash control
        _buildFlashControl(),

        const SizedBox(height: 8),

        // Camera switch
        _buildCameraSwitchControl(),

        // Space reserved for future buttons
        // const SizedBox(height: 8),
        // _buildFutureControl(),
      ],
    );
  }

  Widget _buildFlashControl() {
    final hasFlash = ref.watch(cameraHasFlashProvider);
    final cameraState = ref.watch(cameraControllerProvider);
    final flashDisplayName = ref.watch(flashModeDisplayNameProvider);

    if (!hasFlash) {
      return const SizedBox(width: 48, height: 48); // Placeholder to maintain layout
    }

    // Get proper flash icon based on mode and state
    IconData flashIcon;
    if (cameraState.mode == CameraMode.video) {
      // Video mode: Off/Torch
      flashIcon = cameraState.videoFlashMode == VideoFlashMode.torch ? Icons.flashlight_on : Icons.flashlight_off;
    } else {
      // Photo mode: Off/Auto/On
      switch (cameraState.photoFlashMode) {
        case PhotoFlashMode.off:
          flashIcon = Icons.flash_off;
          break;
        case PhotoFlashMode.auto:
          flashIcon = Icons.flash_auto;
          break;
        case PhotoFlashMode.on:
          flashIcon = Icons.flash_on;
          break;
      }
    }

    return CircleAvatar(
      backgroundColor: Colors.black54,
      child: IconButton(
        icon: Icon(
          flashIcon,
          color: Colors.white,
          size: 20,
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
    final cameraState = ref.watch(cameraControllerProvider);

    if (!canSwitch) {
      return const SizedBox(width: 48, height: 48); // Placeholder to maintain layout
    }

    return CircleAvatar(
      backgroundColor: Colors.black54,
      child: cameraState.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : IconButton(
              icon: Icon(
                Icons.flip_camera_ios, // Better camera switch icon
                color: Colors.white,
                size: 20,
              ),
              onPressed: () async {
                await ref.read(cameraControllerProvider.notifier).switchCamera();

                // Show feedback
                if (mounted) {
                  final newDirection = ref.read(cameraControllerProvider).lensDirection;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched to ${newDirection.name} camera'),
                      duration: const Duration(milliseconds: 1500),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
    );
  }

  Widget _buildBottomControls() {
    final cameraState = ref.watch(cameraControllerProvider);
    final safeArea = MediaQuery.of(context).padding;

    return Positioned(
      bottom: 32 + safeArea.bottom,
      left: safeArea.left,
      right: safeArea.right,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery/Preview placeholder
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GalleryScreen(),
                ),
              );
            },
            child: Container(
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
    final cameraState = ref.watch(cameraControllerProvider);
    final permissionRequest = ref.watch(permissionRequestProvider);

    // Show different states based on the situation
    if (_hasInitializationFailed || (cameraState.errorMessage != null && cameraState.errorMessage!.contains('permissions'))) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please grant camera and microphone permissions to continue.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final permissionNotifier = ref.read(permissionRequestProvider.notifier);
                await permissionNotifier.requestCameraPermissions();
                await _retryInitialization();
              },
              child: const Text('Grant Permissions'),
            ),
          ],
        ),
      );
    }

    // Default initialization state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Initializing Camera',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Setting up camera preview...',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),

          // Retry button if initialization is taking too long
          TextButton(
            onPressed: () async {
              await _retryInitialization();
            },
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white70),
            ),
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
        // Refresh gallery to show new photo
        ref.read(galleryProvider.notifier).refreshMedia();

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
      // Get current orientation and lock to it during recording
      final currentOrientation = MediaQuery.of(context).orientation;
      if (currentOrientation == Orientation.portrait) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }

      // Haptic feedback
      HapticFeedback.mediumImpact();

      await cameraController.startVideoRecording();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording started - ${currentOrientation.name} locked'),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Restore orientation freedom on error
      await SystemChrome.setPreferredOrientations([]);

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

      // Restore orientation freedom after recording
      await SystemChrome.setPreferredOrientations([]);

      if (videoFile != null && mounted) {
        // Refresh gallery to show new video
        ref.read(galleryProvider.notifier).refreshMedia();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video saved!'),
            duration: Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Restore orientation freedom on error
      await SystemChrome.setPreferredOrientations([]);

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

  Widget _buildLandscapeUI(Size screenSize, EdgeInsets safeArea, CameraState cameraState) {
    return Stack(
      children: [
        // Right-side capture button
        _buildLandscapeCaptureButton(screenSize, safeArea, cameraState),

        // Left-side controls (gallery, mode info)
        _buildLandscapeLeftControls(screenSize, safeArea, cameraState),

        // Mode selector for combined mode (bottom-center)
        if (cameraState.mode == CameraMode.combined) _buildLandscapeModeSelector(screenSize, safeArea),
      ],
    );
  }

  Widget _buildPortraitUI(Size screenSize, EdgeInsets safeArea, CameraState cameraState) {
    return Stack(
      children: [
        // Bottom controls row
        _buildPortraitBottomControls(screenSize, safeArea, cameraState),

        // Mode selector for combined mode (above bottom controls)
        if (cameraState.mode == CameraMode.combined) _buildPortraitModeSelector(screenSize, safeArea),
      ],
    );
  }

  Widget _buildLandscapeCaptureButton(Size screenSize, EdgeInsets safeArea, CameraState cameraState) {
    final position = OrientationUIHelper.getCaptureButtonPosition(
      screenSize: screenSize,
      orientation: Orientation.landscape,
      safeArea: safeArea,
    );

    final buttonSize = OrientationUIHelper.getCaptureButtonSize(
      orientation: Orientation.landscape,
      screenSize: screenSize,
    );

    return Positioned(
      right: 16 + safeArea.right,
      top: position.dy - (buttonSize / 2),
      child: SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: _buildCaptureButton(cameraState),
      ),
    );
  }

  Widget _buildLandscapeLeftControls(Size screenSize, EdgeInsets safeArea, CameraState cameraState) {
    final galleryPosition = OrientationUIHelper.getGalleryButtonPosition(
      screenSize: screenSize,
      orientation: Orientation.landscape,
      safeArea: safeArea,
    );

    final modeInfoPosition = OrientationUIHelper.getModeInfoPosition(
      screenSize: screenSize,
      orientation: Orientation.landscape,
      safeArea: safeArea,
    );

    return Stack(
      children: [
        // Gallery button
        Positioned(
          left: galleryPosition.dx,
          top: galleryPosition.dy,
          child: _buildGalleryButton(),
        ),

        // Mode info
        Positioned(
          left: modeInfoPosition.dx,
          top: modeInfoPosition.dy,
          child: _buildModeInfo(cameraState),
        ),
      ],
    );
  }

  Widget _buildLandscapeModeSelector(Size screenSize, EdgeInsets safeArea) {
    final position = OrientationUIHelper.getModeSelectorPosition(
      screenSize: screenSize,
      orientation: Orientation.landscape,
      safeArea: safeArea,
    );

    return Positioned(
      left: position.dx - 80, // Center the 160px wide selector
      bottom: safeArea.bottom + 16,
      child: _buildModeSelector(),
    );
  }

  Widget _buildPortraitBottomControls(Size screenSize, EdgeInsets safeArea, CameraState cameraState) {
    final buttonSize = OrientationUIHelper.getCaptureButtonSize(
      orientation: Orientation.portrait,
      screenSize: screenSize,
    );

    return Positioned(
      bottom: 32 + safeArea.bottom,
      left: safeArea.left,
      right: safeArea.right,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          _buildGalleryButton(),

          // Main capture button
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: _buildCaptureButton(cameraState),
          ),

          // Mode info
          _buildModeInfo(cameraState),
        ],
      ),
    );
  }

  Widget _buildPortraitModeSelector(Size screenSize, EdgeInsets safeArea) {
    return Positioned(
      bottom: 140 + safeArea.bottom,
      left: 0,
      right: 0,
      child: Center(
        child: _buildModeSelector(),
      ),
    );
  }

  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const GalleryScreen(),
          ),
        );
      },
      child: Container(
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
    );
  }
}
