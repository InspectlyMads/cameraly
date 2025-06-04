import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/camera_providers.dart';
import '../services/camera_service.dart';
import '../widgets/camera/camera_preview_widget.dart';
import '../widgets/camera/capture_button_widget.dart';
import '../widgets/camera/mode_selector_widget.dart';
import '../widgets/camera/camera_controls_overlay.dart';
import '../widgets/camera/video_recording_overlay.dart';
import '../models/media_item.dart';

/// Simplified CameraScreen using extracted components
/// This demonstrates how the original 1000+ line file can be reduced
/// to under 200 lines by using properly extracted widgets
class CameraScreenSimple extends ConsumerStatefulWidget {
  const CameraScreenSimple({super.key});

  @override
  ConsumerState<CameraScreenSimple> createState() => _CameraScreenSimpleState();
}

class _CameraScreenSimpleState extends ConsumerState<CameraScreenSimple> {
  bool _isVideoModeSelected = false;
  List<MediaItem> _capturedMedia = [];

  @override
  void initState() {
    super.initState();
    // Initialize camera when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraControllerProvider.notifier).initializeCamera();
    });
  }

  void _handleMediaCaptured(MediaItem mediaItem) {
    setState(() {
      _capturedMedia.add(mediaItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraControllerProvider);
    final orientation = MediaQuery.of(context).orientation;

    // Show loading screen
    if (!cameraState.isInitialized || cameraState.controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview layer
          const CameraPreviewWidget(),

          // Controls overlay (flash, camera switch, close button)
          CameraControlsOverlay(
            isVideoModeSelected: _isVideoModeSelected,
          ),

          // Video recording indicator
          if (cameraState.isRecording) const VideoRecordingOverlay(),

          // Bottom controls
          _buildBottomControls(cameraState, orientation),
        ],
      ),
    );
  }

  Widget _buildBottomControls(CameraState cameraState, Orientation orientation) {
    final safeArea = MediaQuery.of(context).padding;
    final size = MediaQuery.of(context).size;
    
    // Different layout for portrait vs landscape
    if (orientation == Orientation.portrait) {
      return _buildPortraitControls(cameraState, safeArea, size);
    } else {
      return _buildLandscapeControls(cameraState, safeArea, size);
    }
  }

  Widget _buildPortraitControls(CameraState cameraState, EdgeInsets safeArea, Size size) {
    return Positioned(
      bottom: 32 + safeArea.bottom,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode selector (photo/video toggle)
          if (!cameraState.isRecording)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: ModeSelectorWidget(
                isVideoModeSelected: _isVideoModeSelected,
                onVideoModeChanged: (selected) {
                  setState(() {
                    _isVideoModeSelected = selected;
                  });
                },
              ),
            ),

          // Main controls row
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
                width: 80,
                height: 80,
                child: CaptureButtonWidget(
                  isVideoModeSelected: _isVideoModeSelected,
                  onMediaCaptured: _handleMediaCaptured,
                ),
              ),

              // Placeholder for balance
              if (!cameraState.isRecording)
                const SizedBox(width: 60)
              else
                const SizedBox(width: 60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeControls(CameraState cameraState, EdgeInsets safeArea, Size size) {
    return Stack(
      children: [
        // Left side - mode selector
        if (!cameraState.isRecording)
          Positioned(
            left: 32 + safeArea.left,
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

        // Right side - capture button
        Positioned(
          right: 32 + safeArea.right,
          top: 0,
          bottom: 0,
          child: Center(
            child: SizedBox(
              width: 60,
              height: 60,
              child: CaptureButtonWidget(
                isVideoModeSelected: _isVideoModeSelected,
                onMediaCaptured: _handleMediaCaptured,
              ),
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
}