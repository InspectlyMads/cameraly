import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/media_item.dart';

class MediaGridItem extends StatefulWidget {
  final MediaItem mediaItem;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MediaGridItem({
    super.key,
    required this.mediaItem,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<MediaGridItem> createState() => _MediaGridItemState();
}

class _MediaGridItemState extends State<MediaGridItem> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaItem.type == MediaType.video) {
      _initializeVideoController();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoController() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.mediaItem.path));
      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video controller: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: widget.isSelected ? Border.all(color: Theme.of(context).primaryColor, width: 3) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildMediaContent(),
              _buildOverlay(),
              if (widget.isSelectionMode) _buildSelectionOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    if (widget.mediaItem.type == MediaType.photo) {
      return _buildPhotoContent();
    } else {
      return _buildVideoContent();
    }
  }

  Widget _buildPhotoContent() {
    return Image.file(
      File(widget.mediaItem.path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(
            Icons.broken_image,
            color: Colors.grey,
            size: 32,
          ),
        );
      },
    );
  }

  Widget _buildVideoContent() {
    if (_isVideoInitialized && _videoController != null) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    } else {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.play_circle_outline,
            color: Colors.white,
            size: 32,
          ),
        ),
      );
    }
  }

  Widget _buildOverlay() {
    return Positioned(
      bottom: 4,
      left: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              widget.mediaItem.type == MediaType.photo ? Icons.photo : Icons.videocam,
              color: Colors.white,
              size: 16,
            ),
            if (widget.mediaItem.type == MediaType.video) _buildVideoDuration(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoDuration() {
    if (widget.mediaItem.videoDuration != null) {
      final duration = widget.mediaItem.videoDuration!;
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return Text(
        '$minutes:${seconds.toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (_isVideoInitialized && _videoController != null) {
      final duration = _videoController!.value.duration;
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return Text(
        '$minutes:${seconds.toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSelectionOverlay() {
    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isSelected ? Theme.of(context).primaryColor : Colors.white.withValues(alpha: 0.7),
          border: Border.all(
            color: widget.isSelected ? Theme.of(context).primaryColor : Colors.grey,
            width: 2,
          ),
        ),
        child: widget.isSelected
            ? Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              )
            : null,
      ),
    );
  }
}
