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
    final cameraState = ref.watch(cameraControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: _buildCameraInterface(),
          ),
        ],
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
        return Stack(
          children: [
            Stack(
              children: [
                // Camera preview (standard approach)
                _buildCameraPreview(cameraState.controller!),

                // Orientation-specific UI overlay
                _buildOrientationSpecificUI(orientation, cameraState),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrientationSpecificUI(Orientation orientation, CameraState cameraState) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    // Recording UI requires special handling to ensure stop button visibility
    if (cameraState.isRecording) {
      final buttonSize = OrientationUIHelper.getCaptureButtonSize(
        orientation: orientation,
        screenSize: screenSize,
      );

      if (orientation == Orientation.landscape) {
        // Landscape: button on the right side, centered vertically
        return Container(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 16 + safeArea.right),
              child: SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: _buildVideoRecordButton(cameraState),
              ),
            ),
          ),
        );
      } else {
        // Portrait: button at the bottom center
        return Container(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 32 + safeArea.bottom),
              child: SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: _buildVideoRecordButton(cameraState),
              ),
            ),
          ),
        );
      }
    }

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
    final orientation = MediaQuery.of(context).orientation;
    final screenSize = MediaQuery.of(context).size;
    final cameraAspectRatio = controller.value.aspectRatio;

    // Invert aspect ratio for portrait orientation
    final adjustedAspectRatio = orientation == Orientation.portrait
        ? 1 / cameraAspectRatio // Invert for portrait
        : cameraAspectRatio; // Use as-is for landscape

    return Center(
      child: AspectRatio(
        aspectRatio: adjustedAspectRatio,
        child: camera.CameraPreview(controller),
      ),
    );
  }

  Widget _buildTopControls(Orientation orientation) {
    final safeArea = MediaQuery.of(context).padding;
    final cameraState = ref.watch(cameraControllerProvider);

    // Hide top controls during recording
    if (cameraState.isRecording) {
      return const Positioned(
        top: 0,
        left: 0,
        child: SizedBox.shrink(),
      );
    }

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

          // Right side controls - only show in portrait mode
          if (OrientationUIHelper.isPortrait(orientation)) _buildRightControlsColumn(),
        ],
      ),
    );
  }

  Widget _buildRightControlsColumn() {
    final cameraState = ref.watch(cameraControllerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Flash control
        _buildFlashControl(),

        const SizedBox(height: 8),

        // Camera switch - hide during recording
        if (!cameraState.isRecording) _buildCameraSwitchControl(),

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
    // Check both our state and the controller's state to be absolutely sure
    final bool isActuallyRecording = cameraState.isRecording || (cameraState.controller?.value.isRecordingVideo ?? false);

    // Always show video controls if we're currently recording OR in video modes
    // IMPORTANT: If recording, always show video button regardless of mode selection
    final bool shouldShowVideoControls = isActuallyRecording || cameraState.mode == CameraMode.video || (cameraState.mode == CameraMode.combined && _isVideoModeSelected);

    if (shouldShowVideoControls) {
      return _buildVideoRecordButton(cameraState);
    } else {
      return _buildPhotoButton();
    }
  }

  Widget _buildPhotoButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the available size from constraints
        final size = constraints.maxWidth.isFinite ? constraints.maxWidth : 80.0;

        return GestureDetector(
          onTapDown: (_) {
            HapticFeedback.lightImpact();
          },
          onTap: _takePhoto,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
              ),
              // Inner circle
              Container(
                width: size * 0.8,
                height: size * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoRecordButton(CameraState cameraState) {
    // Use the same logic as landscape controls for consistency
    final isRecording = cameraState.isRecording || (cameraState.controller?.value.isRecordingVideo ?? false);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the available size from constraints
        final size = constraints.maxWidth.isFinite ? constraints.maxWidth : 80.0;
        return GestureDetector(
          onTap: () {
            if (isRecording) {
              _stopVideoRecording();
            } else {
              _startVideoRecording();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRecording ? Colors.white : Colors.transparent,
              border: Border.all(
                color: isRecording ? Colors.white : Colors.red,
                width: 4,
              ),
              boxShadow: isRecording
                  ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isRecording ? size * 0.4 : size * 0.75,
                height: isRecording ? size * 0.4 : size * 0.75,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(isRecording ? 8 : size),
                ),
              ),
            ),
          ),
        );
      },
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModeToggleButton('PHOTO', !_isVideoModeSelected),
        const SizedBox(width: 16),
        _buildModeToggleButton('VIDEO', _isVideoModeSelected),
      ],
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
        // Right-side capture button + mode info below it
        _buildLandscapeRightControls(screenSize, safeArea, cameraState),

        // Left-side controls (flash + switch buttons only)
        _buildLandscapeLeftControls(screenSize, safeArea, cameraState),

        // Mode selector for combined mode (bottom-center)
        if (cameraState.mode == CameraMode.combined) _buildLandscapeModeSelector(screenSize, safeArea),
      ],
    );
  }

  Widget _buildLandscapeRightControls(Size screenSize, EdgeInsets safeArea, CameraState cameraState) {
    final buttonSize = OrientationUIHelper.getCaptureButtonSize(
      orientation: Orientation.landscape,
      screenSize: screenSize,
    );

    // Check both our state and the controller's state to be absolutely sure
    final bool isActuallyRecording = cameraState.isRecording || (cameraState.controller?.value.isRecordingVideo ?? false);

// When recording, show only the stop button centered on screen
    if (isActuallyRecording) {
      return Positioned(
        right: 16 + safeArea.right,
        top: 0,
        bottom: 0,
        child: Container(
          width: buttonSize,
          alignment: Alignment.center,
          child: _buildCaptureButton(cameraState),
        ),
      );
    }

    // Normal state with gallery, capture, and check buttons
    return Positioned(
      right: 16 + safeArea.right,
      top: 0,
      bottom: 0,
      child: SizedBox(
        width: buttonSize,
        child: Column(
          // Normal state with all 3 elements
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gallery button
            _buildGalleryButton(),

            // Capture button
            SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: _buildCaptureButton(cameraState),
            ),

            // Check FAB
            _buildCheckFab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLeftControls(Size screenSize, EdgeInsets safeArea, CameraState cameraState) {
    // Hide left controls during recording
    if (cameraState.isRecording) {
      return const SizedBox.shrink();
    }

    final galleryPosition = OrientationUIHelper.getGalleryButtonPosition(
      screenSize: screenSize,
      orientation: Orientation.landscape,
      safeArea: safeArea,
    );

    return Stack(
      children: [
        // Flash + Camera switch buttons (moved from top-right to left-center)
        Positioned(
          left: galleryPosition.dx,
          top: galleryPosition.dy - 60, // Position above where gallery was
          child: _buildRightControlsColumn(),
        ),
      ],
    );
  }

  Widget _buildLandscapeModeSelector(Size screenSize, EdgeInsets safeArea) {
    final cameraState = ref.watch(cameraControllerProvider);

    // Hide mode selector during recording
    if (cameraState.isRecording) {
      return const SizedBox.shrink();
    }

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
          // Gallery button - hide during recording
          if (!cameraState.isRecording) _buildGalleryButton() else const SizedBox(width: 60),

          // Main capture button (always show)
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: _buildCaptureButton(cameraState),
          ),

          // Check FAB - hide during recording
          if (!cameraState.isRecording) _buildCheckFab() else const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildPortraitModeSelector(Size screenSize, EdgeInsets safeArea) {
    final cameraState = ref.watch(cameraControllerProvider);

    // Hide mode selector during recording
    if (cameraState.isRecording) {
      return const SizedBox.shrink();
    }

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

  Widget _buildCheckFab() {
    return CircleAvatar(
      backgroundColor: Colors.green,
      radius: 30,
      child: IconButton(
        icon: const Icon(
          Icons.check,
          color: Colors.white,
          size: 24,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
