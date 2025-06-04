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

    // Use Container with proper sizing instead of AspectRatio to prevent stretching
    return Center(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: _videoControllers[index]!.value.size.width,
            height: _videoControllers[index]!.value.size.height,
            child: VideoPlayer(_videoControllers[index]!),
          ),
        ),
      ),
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
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      mediaItem.type == MediaType.photo ? Icons.photo : Icons.videocam,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mediaItem.fileName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fileType,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildInfoSection(
                        title: 'File Information',
                        icon: Icons.insert_drive_file,
                        children: [
                          _buildStyledInfoRow('Extension', mediaItem.fileExtension.toUpperCase()),
                          _buildStyledInfoRow('Size', fileSize),
                          _buildStyledInfoRow('Captured', _formatDate(captureDate)),
                          if (mediaItem.type == MediaType.video && mediaItem.videoDuration != null)
                            _buildStyledInfoRow('Duration', _formatDuration(mediaItem.videoDuration!)),
                        ],
                      ),
                      
                      // Orientation Information Section
                      if (mediaItem.orientationInfo != null) ...[
                        const SizedBox(height: 24),
                        _buildInfoSection(
                          title: 'Orientation Data',
                          icon: Icons.screen_rotation,
                          children: [
                            _buildStyledInfoRow('Device', '${mediaItem.orientationInfo!.deviceManufacturer} ${mediaItem.orientationInfo!.deviceModel}'),
                            _buildOrientationRow('Device Angle', mediaItem.orientationInfo!.deviceOrientation),
                            _buildOrientationRow('Camera Rotation', mediaItem.orientationInfo!.cameraRotation),
                            _buildOrientationRow('Sensor', mediaItem.orientationInfo!.sensorOrientation),
                            _buildAccuracyRow(mediaItem.orientationInfo!.accuracyScore),
                          ],
                        ),
                      ],
                      
                      // Additional Metadata Section
                      if (mediaItem.orientationInfo?.metadata.isNotEmpty ?? false) ...[
                        const SizedBox(height: 24),
                        _buildInfoSection(
                          title: 'Technical Details',
                          icon: Icons.info_outline,
                          children: [
                            ...mediaItem.orientationInfo!.metadata.entries.map(
                              (entry) => _buildStyledInfoRow(
                                _formatMetadataKey(entry.key),
                                entry.value.toString(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildStyledInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrientationRow(String label, int degrees) {
    final iconRotation = degrees * (3.14159 / 180); // Convert to radians
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Transform.rotate(
                  angle: iconRotation,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.phone_android,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$degrees°',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyRow(double accuracy) {
    final percentage = (accuracy * 100).toInt();
    final color = percentage > 80 
        ? Colors.green 
        : percentage > 50 
            ? Colors.orange 
            : Colors.red;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'Accuracy',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: accuracy,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMetadataKey(String key) {
    // Convert camelCase or snake_case to Title Case
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ')
        .trim();
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _initializeVideoForIndex(_currentIndex);
  }
}
