import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/media_item.dart';

class MediaViewer extends StatefulWidget {
  final MediaItem mediaItem;

  const MediaViewer({
    super.key,
    required this.mediaItem,
  });

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    if (widget.mediaItem.type == MediaType.video) {
      _initializeVideoController();
    }

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initializeVideoController() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.mediaItem.path));
      await _videoController!.initialize();

      _videoController!.addListener(() {
        if (mounted) {
          setState(() {
            _isVideoPlaying = _videoController!.value.isPlaying;
          });
        }
      });

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Media content
          Center(
            child: _buildMediaContent(),
          ),

          // Controls overlay
          if (_showControls) _buildControlsOverlay(),

          // Video controls for videos
          if (widget.mediaItem.type == MediaType.video && _showControls) _buildVideoControls(),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: widget.mediaItem.type == MediaType.photo ? _buildPhotoViewer() : _buildVideoViewer(),
    );
  }

  Widget _buildPhotoViewer() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: Image.file(
        File(widget.mediaItem.path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Unable to load image',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoViewer() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            _buildInfoButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoButton() {
    return IconButton(
      icon: const Icon(Icons.info_outline, color: Colors.white),
      onPressed: _showMediaInfo,
    );
  }

  Widget _buildVideoControls() {
    if (!_isVideoInitialized || _videoController == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Theme.of(context).primaryColor,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.white30,
              ),
            ),
            const SizedBox(height: 8),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isVideoPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: _toggleVideoPlayback,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(
                    Icons.replay,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: _restartVideo,
                ),
              ],
            ),

            // Time display
            _buildTimeDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDisplay() {
    if (!_isVideoInitialized || _videoController == null) {
      return const SizedBox.shrink();
    }

    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;

    return Text(
      '${_formatDuration(position)} / ${_formatDuration(duration)}',
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleVideoPlayback() {
    if (_videoController == null) return;

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
  }

  void _restartVideo() {
    if (_videoController == null) return;

    _videoController!.seekTo(Duration.zero);
    _videoController!.play();
  }

  void _showMediaInfo() {
    final captureDate = widget.mediaItem.capturedAt;
    final fileSize = widget.mediaItem.fileSizeFormatted;
    final fileType = widget.mediaItem.type == MediaType.photo ? 'Photo' : 'Video';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Media Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Type', fileType),
            _buildInfoRow('File Name', widget.mediaItem.fileName),
            _buildInfoRow('Extension', widget.mediaItem.fileExtension.toUpperCase()),
            _buildInfoRow('Size', fileSize),
            _buildInfoRow('Captured', _formatDate(captureDate)),
            if (widget.mediaItem.type == MediaType.video && widget.mediaItem.videoDuration != null) _buildInfoRow('Duration', _formatDuration(widget.mediaItem.videoDuration!)),
            if (widget.mediaItem.orientationData != null) _buildInfoRow('Orientation', widget.mediaItem.orientationData!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
