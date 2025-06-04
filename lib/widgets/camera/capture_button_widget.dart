import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/camera_providers.dart';
import '../../models/media_item.dart';
import '../../utils/orientation_ui_helper.dart';
import '../../services/camera_service.dart';

class CaptureButtonWidget extends ConsumerStatefulWidget {
  final bool isVideoModeSelected;
  final Function(MediaItem) onMediaCaptured;
  
  const CaptureButtonWidget({
    super.key,
    required this.isVideoModeSelected,
    required this.onMediaCaptured,
  });

  @override
  ConsumerState<CaptureButtonWidget> createState() => _CaptureButtonWidgetState();
}

class _CaptureButtonWidgetState extends ConsumerState<CaptureButtonWidget> {
  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraControllerProvider);
    
    // Check both our state and the controller's state
    final bool isActuallyRecording = cameraState.isRecording || 
        (cameraState.controller?.value.isRecordingVideo ?? false);
    
    // Show video controls if recording OR in video modes
    final bool shouldShowVideoControls = isActuallyRecording || 
        cameraState.mode == CameraMode.video || 
        (cameraState.mode == CameraMode.combined && widget.isVideoModeSelected);
    
    if (shouldShowVideoControls) {
      return _VideoRecordButton(
        isRecording: isActuallyRecording,
        onStart: _startRecording,
        onStop: _stopRecording,
      );
    } else {
      return _PhotoCaptureButton(onTap: _takePicture);
    }
  }
  
  Future<void> _takePicture() async {
    HapticFeedback.lightImpact();
    try {
      final xFile = await ref.read(cameraControllerProvider.notifier).takePicture();
      if (xFile != null) {
        // Convert XFile path to MediaItem
        final mediaItem = await MediaItem.fromFile(File(xFile.path));
        if (mediaItem != null) {
          widget.onMediaCaptured(mediaItem);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    try {
      await ref.read(cameraControllerProvider.notifier).startVideoRecording();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _stopRecording() async {
    HapticFeedback.mediumImpact();
    try {
      final xFile = await ref.read(cameraControllerProvider.notifier).stopVideoRecording();
      if (xFile != null) {
        // Convert XFile path to MediaItem
        final mediaItem = await MediaItem.fromFile(File(xFile.path));
        if (mediaItem != null) {
          widget.onMediaCaptured(mediaItem);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

class _PhotoCaptureButton extends StatelessWidget {
  final VoidCallback onTap;
  
  const _PhotoCaptureButton({required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _VideoRecordButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onStart;
  final VoidCallback onStop;
  
  const _VideoRecordButton({
    required this.isRecording,
    required this.onStart,
    required this.onStop,
  });
  
  @override
  State<_VideoRecordButton> createState() => _VideoRecordButtonState();
}

class _VideoRecordButtonState extends State<_VideoRecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isRecording) {
      _animationController.forward();
    }
  }
  
  @override
  void didUpdateWidget(_VideoRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _animationController.forward();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _animationController.reverse();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isRecording ? widget.onStop : widget.onStart,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.isRecording ? Colors.red : Colors.white,
            width: 4,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(
                      widget.isRecording ? 8 : 100,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}