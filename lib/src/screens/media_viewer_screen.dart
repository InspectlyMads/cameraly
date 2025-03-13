import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../utils/media_manager.dart';

/// A screen that displays captured media (photos and videos).
class MediaViewerScreen extends StatefulWidget {
  /// Creates a new [MediaViewerScreen].
  const MediaViewerScreen({
    required this.mediaFiles,
    this.initialIndex = 0,
    this.onDelete,
    this.onShare,
    this.mediaManager,
    super.key,
  });

  /// The list of media files to display.
  final List<XFile> mediaFiles;

  /// The initial index to display.
  final int initialIndex;

  /// Callback when a media file is deleted.
  final void Function(XFile file)? onDelete;

  /// Callback when a media file is shared.
  final void Function(XFile file)? onShare;

  /// Optional media manager that can provide thumbnails for videos
  final CameralyMediaManager? mediaManager;

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initializeVideoController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (_videoController != null) {
      _videoController!.removeListener(_videoProgressListener);
      _videoController!.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeVideoController() async {
    if (!_isCurrentFileVideo) return;

    try {
      if (_videoController != null) {
        _videoController!.removeListener(_videoProgressListener);
        await _videoController!.dispose();
        _videoController = null;
      }

      // Get the file path
      final filePath = widget.mediaFiles[_currentIndex].path;

      // Validate the video file
      if (!await _isValidVideoFile(filePath)) {
        debugPrint('Invalid video file: $filePath');
        if (mounted) setState(() {}); // Trigger rebuild with null controller
        return;
      }

      // Create new video controller with valid file
      _videoController = VideoPlayerController.file(File(filePath));

      // Add listener before initialization to catch all events
      _videoController!.addListener(_videoProgressListener);

      // Initialize the controller
      await _videoController!.initialize();

      // Only update state if still mounted and file index hasn't changed
      if (mounted && _currentIndex < widget.mediaFiles.length) {
        setState(() {
          // If video was previously playing, auto-play the new video
          if (_isPlaying) {
            _videoController!.play();
          }
        });
      }
    } catch (e) {
      // Handle initialization errors
      debugPrint('Error initializing video controller: $e');
      if (mounted) {
        setState(() {
          _videoController = null;
        });
      }
    }
  }

  bool get _isCurrentFileVideo {
    if (_currentIndex < 0 || _currentIndex >= widget.mediaFiles.length) return false;

    final path = widget.mediaFiles[_currentIndex].path.toLowerCase();
    return _isVideoFile(path);
  }

  bool _isVideoFile(String path) {
    return path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi') || path.endsWith('.mkv') || path.endsWith('.webm') || path.endsWith('.wmv');
  }

  /// Checks if the file exists and is a valid video file
  Future<bool> _isValidVideoFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('Video file does not exist: $path');
        return false;
      }

      // Check if it's a video file extension
      if (!_isVideoFile(path.toLowerCase())) {
        debugPrint('File is not a recognized video format: $path');
        return false;
      }

      // Check file size (files under 100 bytes are likely invalid)
      final fileStats = await file.stat();
      if (fileStats.size < 100) {
        debugPrint('Video file is too small (likely invalid): $path');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking video file: $e');
      return false;
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isPlaying = false;
    });
    _initializeVideoController();
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _videoController!.play();
      } else {
        _videoController!.pause();
      }
    });
  }

  void _deleteCurrentMedia() {
    final file = widget.mediaFiles[_currentIndex];
    widget.onDelete?.call(file);
    if (widget.mediaFiles.length == 1) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        if (_currentIndex == widget.mediaFiles.length - 1) {
          _currentIndex--;
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _shareCurrentMedia() {
    final file = widget.mediaFiles[_currentIndex];
    widget.onShare?.call(file);
  }

  void _videoProgressListener() {
    if (mounted) setState(() {});
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.onShare != null)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _shareCurrentMedia,
            ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteCurrentMedia,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Media viewer
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.mediaFiles.length,
            itemBuilder: (context, index) {
              final file = widget.mediaFiles[index];
              final path = file.path.toLowerCase();
              final isVideo = path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');

              if (isVideo && index == _currentIndex) {
                if (_videoController?.value.isInitialized ?? false) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Video player
                      GestureDetector(
                        onTap: _togglePlayPause,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                      ),

                      // Play/pause button overlay
                      if (!_isPlaying)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              color: Colors.black.withOpacity(0.3),
                              child: Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Video progress bar and controls at the bottom
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress slider
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    // Current position
                                    Text(
                                      _formatDuration(_videoController!.value.position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),

                                    // Progress slider
                                    Expanded(
                                      child: SliderTheme(
                                        data: const SliderThemeData(
                                          trackHeight: 2,
                                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                                          overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                                          thumbColor: Colors.white,
                                          activeTrackColor: Colors.white,
                                          inactiveTrackColor: Colors.white24,
                                          overlayColor: Colors.white30,
                                        ),
                                        child: Slider(
                                          value: _videoController!.value.position.inMilliseconds.toDouble(),
                                          min: 0,
                                          max: _videoController!.value.duration.inMilliseconds.toDouble(),
                                          onChanged: (value) {
                                            final newPosition = Duration(milliseconds: value.toInt());
                                            _videoController!.seekTo(newPosition);
                                          },
                                        ),
                                      ),
                                    ),

                                    // Total duration
                                    Text(
                                      _formatDuration(_videoController!.value.duration),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Controls
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Rewind button
                                  IconButton(
                                    icon: const Icon(Icons.replay_10, color: Colors.white),
                                    onPressed: () {
                                      final newPosition = _videoController!.value.position - const Duration(seconds: 10);
                                      _videoController!.seekTo(newPosition);
                                    },
                                  ),

                                  // Play/pause button
                                  IconButton(
                                    icon: Icon(
                                      _isPlaying ? Icons.pause : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                    onPressed: _togglePlayPause,
                                  ),

                                  // Forward button
                                  IconButton(
                                    icon: const Icon(Icons.forward_10, color: Colors.white),
                                    onPressed: () {
                                      final newPosition = _videoController!.value.position + const Duration(seconds: 10);
                                      _videoController!.seekTo(newPosition);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Video controller failed to initialize or is still loading
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          _videoController == null ? 'Error loading video' : 'Preparing video...',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (_videoController == null)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              onPressed: () {
                                debugPrint('Retrying video initialization');
                                _initializeVideoController();
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                }
              } else if (isVideo) {
                // Video thumbnail for videos that aren't currently playing
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Try to use the thumbnail from media manager if available
                    widget.mediaManager != null && widget.mediaManager!.hasVideoThumbnail(file.path) && widget.mediaManager!.getThumbnailForVideo(file.path) != null
                        ? Image.file(
                            File(widget.mediaManager!.getThumbnailForVideo(file.path)!),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildVideoThumbnailFallback(file.path);
                            },
                          )
                        : _buildVideoThumbnailFallback(file.path),

                    // Play button overlay
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Regular image viewer
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    File(file.path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white70,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Unable to display this media',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),

          // Page indicator
          if (widget.mediaFiles.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.mediaFiles.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex ? Colors.white : Colors.white.withAlpha(128),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoThumbnailFallback(String path) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_outlined,
              color: Colors.white70,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Video will play when selected',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
