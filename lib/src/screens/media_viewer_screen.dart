import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A screen that displays captured media (photos and videos).
class MediaViewerScreen extends StatefulWidget {
  /// Creates a new [MediaViewerScreen].
  const MediaViewerScreen({
    required this.mediaFiles,
    this.initialIndex = 0,
    this.onDelete,
    this.onShare,
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
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoController() async {
    if (_isCurrentFileVideo) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(
        File(widget.mediaFiles[_currentIndex].path),
      );
      await _videoController!.initialize();
      setState(() {});
    }
  }

  bool get _isCurrentFileVideo {
    final path = widget.mediaFiles[_currentIndex].path.toLowerCase();
    return path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');
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
              final isVideo = file.path.toLowerCase().endsWith('.mp4') || file.path.toLowerCase().endsWith('.mov') || file.path.toLowerCase().endsWith('.avi');

              if (isVideo && index == _currentIndex) {
                if (_videoController?.value.isInitialized ?? false) {
                  return GestureDetector(
                    onTap: _togglePlayPause,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        if (!_isPlaying)
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(0, 0, 0, 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                      ],
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
              } else {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    File(file.path),
                    fit: BoxFit.contain,
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
                      color: index == _currentIndex ? Colors.white : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
