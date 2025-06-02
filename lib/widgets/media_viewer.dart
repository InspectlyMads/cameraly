import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/media_item.dart';

class MediaViewer extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final int initialIndex;

  const MediaViewer({
    super.key,
    required this.mediaItems,
    this.initialIndex = 0,
  });

  // Factory constructor for single item (backward compatibility)
  factory MediaViewer.single({
    Key? key,
    required MediaItem mediaItem,
  }) {
    return MediaViewer(
      key: key,
      mediaItems: [mediaItem],
      initialIndex: 0,
    );
  }

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _videoInitialized = {};
  final Map<int, bool> _videoPlaying = {};
  bool _showControls = true;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex.clamp(0, widget.mediaItems.length - 1);
    _pageController = PageController(initialPage: _currentIndex);

    // Initialize video controller for current item if it's a video
    _initializeVideoForIndex(_currentIndex);

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initializeVideoForIndex(int index) async {
    try {
      final mediaItem = widget.mediaItems[index];
      if (mediaItem.type == MediaType.video) {
        _videoControllers[index] = VideoPlayerController.file(File(mediaItem.path));
        await _videoControllers[index]!.initialize();

        _videoControllers[index]!.addListener(() {
          if (mounted) {
            setState(() {
              _videoPlaying[index] = _videoControllers[index]!.value.isPlaying;
            });
          }
        });

        if (mounted) {
          setState(() {
            _videoInitialized[index] = true;
          });
        }
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
          if (widget.mediaItems[_currentIndex].type == MediaType.video && _showControls) _buildVideoControls(),
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
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: widget.mediaItems.length,
        itemBuilder: (context, index) {
          final mediaItem = widget.mediaItems[index];
          return mediaItem.type == MediaType.photo ? _buildPhotoViewer(mediaItem) : _buildVideoViewer(index);
        },
      ),
    );
  }

  Widget _buildPhotoViewer(MediaItem mediaItem) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: Image.file(
        File(mediaItem.path),
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

  Widget _buildVideoViewer(int index) {
    if (!(_videoInitialized[index] ?? false) || _videoControllers[index] == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return AspectRatio(
      aspectRatio: _videoControllers[index]!.value.aspectRatio,
      child: VideoPlayer(_videoControllers[index]!),
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
    if (!(_videoInitialized[_currentIndex] ?? false) || _videoControllers[_currentIndex] == null) {
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
              _videoControllers[_currentIndex]!,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Theme.of(context).primaryColor,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.grey[800]!,
              ),
            ),
            const SizedBox(height: 16),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.replay,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: _restartVideo,
                ),
                IconButton(
                  icon: Icon(
                    (_videoPlaying[_currentIndex] ?? false) ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: _toggleVideoPlayback,
                ),
                _buildTimeDisplay(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDisplay() {
    if (!(_videoInitialized[_currentIndex] ?? false) || _videoControllers[_currentIndex] == null) {
      return const SizedBox.shrink();
    }

    final position = _videoControllers[_currentIndex]!.value.position;
    final duration = _videoControllers[_currentIndex]!.value.duration;

    return Text(
      '${_formatDuration(position)} / ${_formatDuration(duration)}',
      style: const TextStyle(color: Colors.white),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleVideoPlayback() {
    if (_videoControllers[_currentIndex] == null) return;

    if (_videoControllers[_currentIndex]!.value.isPlaying) {
      _videoControllers[_currentIndex]!.pause();
    } else {
      _videoControllers[_currentIndex]!.play();
    }
  }

  void _restartVideo() {
    if (_videoControllers[_currentIndex] == null) return;

    _videoControllers[_currentIndex]!.seekTo(Duration.zero);
    _videoControllers[_currentIndex]!.play();
  }

  void _showMediaInfo() {
    final mediaItem = widget.mediaItems[_currentIndex];
    final captureDate = mediaItem.capturedAt;
    final fileSize = mediaItem.fileSizeFormatted;
    final fileType = mediaItem.type == MediaType.photo ? 'Photo' : 'Video';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Media Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Type', fileType),
            _buildInfoRow('File Name', mediaItem.fileName),
            _buildInfoRow('Extension', mediaItem.fileExtension.toUpperCase()),
            _buildInfoRow('Size', fileSize),
            _buildInfoRow('Captured', _formatDate(captureDate)),
            if (mediaItem.type == MediaType.video && mediaItem.videoDuration != null) _buildInfoRow('Duration', _formatDuration(mediaItem.videoDuration!)),
            if (mediaItem.orientationData != null) _buildInfoRow('Orientation', mediaItem.orientationData!),
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

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _initializeVideoForIndex(_currentIndex);
  }
}
