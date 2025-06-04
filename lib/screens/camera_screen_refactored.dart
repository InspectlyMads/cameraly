import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

import '../providers/camera_providers.dart';
import '../providers/permission_providers.dart';
import '../services/camera_service.dart';
import '../models/media_item.dart';
import '../models/orientation_data.dart';
import '../widgets/camera/camera_preview_widget.dart';
import '../widgets/camera/capture_button_widget.dart';
import '../widgets/camera/mode_selector_widget.dart';
import '../widgets/camera/camera_controls_overlay.dart';
import '../utils/orientation_ui_helper.dart';

class CameraScreenRefactored extends ConsumerStatefulWidget {
  const CameraScreenRefactored({super.key});

  @override
  ConsumerState<CameraScreenRefactored> createState() => _CameraScreenRefactoredState();
}

class _CameraScreenRefactoredState extends ConsumerState<CameraScreenRefactored> {
  bool _isVideoModeSelected = false;
  List<MediaItem> _capturedMedia = [];
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _orientationTimestamp;

  @override
  void initState() {
    super.initState();
    _initializePermissions();
    _startOrientationTracking();
  }

  Future<void> _initializePermissions() async {
    await ref.read(permissionRequestProvider.notifier).requestCameraPermissions();
  }

  void _startOrientationTracking() {
    // Orientation tracking removed - not implemented in providers
    // TODO: Implement orientation tracking if needed
  }

  @override
  void dispose() {
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _handleModeChange(CameraMode mode) {
    ref.read(cameraControllerProvider.notifier).switchMode(mode);
    if (mode != CameraMode.combined) {
      _isVideoModeSelected = mode == CameraMode.video;
    }
  }

  void _handleMediaCaptured(MediaItem mediaItem) {
    setState(() {
      _capturedMedia.add(mediaItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cameraPermission = ref.watch(cameraPermissionStatusProvider);
    final hasAllPermissions = ref.watch(hasAllPermissionsProvider);
    final cameraState = ref.watch(cameraControllerProvider);
    final orientation = MediaQuery.of(context).orientation;
    final size = MediaQuery.of(context).size;

    // Permission check
    final hasPermissions = hasAllPermissions.valueOrNull ?? false;
    if (!hasPermissions) {
      return _buildPermissionScreen();
    }

    // Error state
    if (cameraState.errorMessage != null) {
      return _buildErrorScreen(cameraState.errorMessage!);
    }

    // Loading state
    if (!cameraState.isInitialized || cameraState.controller == null) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          const CameraPreviewWidget(),
          
          // Controls overlay
          CameraControlsOverlay(
            isVideoModeSelected: _isVideoModeSelected,
          ),
          
          // Recording indicator
          if (cameraState.isRecording) _buildRecordingIndicator(),
          
          // Bottom controls based on orientation
          if (orientation == Orientation.portrait)
            _buildPortraitBottomControls(size, cameraState)
          else
            _buildLandscapeControls(size, cameraState),
        ],
      ),
    );
  }

  Widget _buildPermissionScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Camera permissions required',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializePermissions,
              child: const Text('Grant Permissions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              error,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(cameraControllerProvider.notifier).initializeCamera();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Recording',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitBottomControls(Size size, CameraState cameraState) {
    final safeArea = MediaQuery.of(context).padding;
    final buttonSize = OrientationUIHelper.getCaptureButtonSize(
      orientation: Orientation.portrait,
      screenSize: size,
    );

    return Positioned(
      bottom: 32 + safeArea.bottom,
      left: safeArea.left,
      right: safeArea.right,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode selector
          if (!cameraState.isRecording)
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: ModeSelectorWidget(
                isVideoModeSelected: _isVideoModeSelected,
                onVideoModeChanged: (selected) {
                  setState(() {
                    _isVideoModeSelected = selected;
                  });
                },
              ),
            ),
          
          // Bottom controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery button
              if (!cameraState.isRecording)
                _buildGalleryButton()
              else
                const SizedBox(width: 60),
              
              // Capture button
              SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: CaptureButtonWidget(
                  isVideoModeSelected: _isVideoModeSelected,
                  onMediaCaptured: _handleMediaCaptured,
                ),
              ),
              
              // Mode switcher
              if (!cameraState.isRecording)
                _buildModeSwitcher(cameraState)
              else
                const SizedBox(width: 60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeControls(Size size, CameraState cameraState) {
    final safeArea = MediaQuery.of(context).padding;
    final buttonSize = OrientationUIHelper.getCaptureButtonSize(
      orientation: Orientation.landscape,
      screenSize: size,
    );

    return Stack(
      children: [
        // Right side - capture button and gallery
        Positioned(
          right: 16 + safeArea.right,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: buttonSize,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!cameraState.isRecording) _buildGalleryButton(),
                
                SizedBox(
                  width: buttonSize,
                  height: buttonSize,
                  child: CaptureButtonWidget(
                    isVideoModeSelected: _isVideoModeSelected,
                    onMediaCaptured: _handleMediaCaptured,
                  ),
                ),
                
                if (!cameraState.isRecording) _buildModeSwitcher(cameraState),
              ],
            ),
          ),
        ),
        
        // Left side - mode selector
        if (!cameraState.isRecording)
          Positioned(
            left: 16 + safeArea.left,
            top: 0,
            bottom: 0,
            child: Center(
              child: ModeSelectorWidget(
                isVideoModeSelected: _isVideoModeSelected,
                onVideoModeChanged: (selected) {
                  setState(() {
                    _isVideoModeSelected = selected;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGalleryButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pushNamed(context, '/gallery');
          },
          child: _capturedMedia.isEmpty
              ? const Icon(Icons.photo_library, color: Colors.white, size: 30)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _capturedMedia.last.type == MediaType.photo
                      ? Image.file(
                          File(_capturedMedia.last.path),
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.videocam, color: Colors.white, size: 30),
                ),
        ),
      ),
    );
  }

  Widget _buildModeSwitcher(CameraState cameraState) {
    return IconButton(
      icon: Icon(
        _getModeSwitcherIcon(cameraState.mode),
        color: Colors.white,
        size: 30,
      ),
      onPressed: () {
        final nextMode = _getNextMode(cameraState.mode);
        _handleModeChange(nextMode);
      },
    );
  }

  IconData _getModeSwitcherIcon(CameraMode mode) {
    switch (mode) {
      case CameraMode.photo:
        return Icons.videocam;
      case CameraMode.video:
        return Icons.switch_camera;
      case CameraMode.combined:
        return Icons.camera_alt;
    }
  }

  CameraMode _getNextMode(CameraMode current) {
    switch (current) {
      case CameraMode.photo:
        return CameraMode.video;
      case CameraMode.video:
        return CameraMode.combined;
      case CameraMode.combined:
        return CameraMode.photo;
    }
  }
}