import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../screens/image_view_screen.dart';
import '../screens/media_viewer_screen.dart';

/// A class that manages captured media (photos and videos).
class CameralyMediaManager extends ChangeNotifier {
  /// Creates a new [CameralyMediaManager] instance.
  CameralyMediaManager({
    List<XFile>? initialMedia,
    this.maxItems,
    this.customStoragePath,
    this.onMediaAdded,
    this.onMediaRemoved,
  }) : _media = initialMedia ?? [];

  /// The list of captured media files.
  final List<XFile> _media;

  /// The maximum number of media items to keep.
  /// If null, there is no limit.
  final int? maxItems;

  /// Custom storage path for saving captured media.
  /// If null, the app's temporary directory will be used.
  final String? customStoragePath;

  /// Callback when media is added.
  final Function(XFile)? onMediaAdded;

  /// Callback when media is removed.
  final Function(XFile)? onMediaRemoved;

  /// Map of video paths to corresponding thumbnail paths.
  final Map<String, String> _videoThumbnails = {};

  /// Gets the list of captured media files.
  List<XFile> get media => List.unmodifiable(_media);

  /// Gets the number of captured media files.
  int get count => _media.length;

  /// Gets whether there are any captured media files.
  bool get isEmpty => _media.isEmpty;

  /// Gets whether there are any captured media files.
  bool get isNotEmpty => _media.isNotEmpty;

  /// Gets the storage directory path where media will be saved.
  /// Will create the directory if it doesn't exist.
  Future<String> get storagePath async {
    if (customStoragePath != null) {
      final directory = Directory(customStoragePath!);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return customStoragePath!;
    }

    // Default: use app's temporary directory
    final tempDir = await getTemporaryDirectory();
    final String tempPath = path.join(tempDir.path, 'cameraly_captures');

    final directory = Directory(tempPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return tempPath;
  }

  /// Associates a thumbnail path with a video path.
  void setThumbnailForVideo(String videoPath, String thumbnailPath) {
    _videoThumbnails[videoPath] = thumbnailPath;
    // No need to call notifyListeners() here as this doesn't affect the UI directly
  }

  /// Gets the thumbnail path for a video, if available.
  String? getThumbnailForVideo(String videoPath) {
    return _videoThumbnails[videoPath];
  }

  /// Checks if a video has a thumbnail.
  bool hasVideoThumbnail(String videoPath) {
    return _videoThumbnails.containsKey(videoPath);
  }

  /// Adds a media file to the manager.
  ///
  /// If [maxItems] is set and the list is full, the oldest item will be removed.
  /// If a custom storage path is set, the file will be copied to that location.
  /// If the file is already in the media manager, it will not be added again.
  /// If [isVideo] is true, the file will be treated as a video (for correct mime type).
  /// Will call the [onMediaAdded] callback if provided.
  Future<void> addMedia(XFile file, {bool? isVideo}) async {
    // Determine if the file is a video based on extension or the isVideo parameter
    final bool isVideoFile = isVideo ?? file.path.toLowerCase().endsWith('.mp4') || file.path.toLowerCase().endsWith('.mov') || file.path.toLowerCase().endsWith('.avi');

    // If we have a max items limit and we're at the limit, remove the oldest item
    if (maxItems != null && _media.length >= maxItems!) {
      final removedFile = _media.removeAt(0);
      onMediaRemoved?.call(removedFile);
    }

    try {
      // If we have a custom storage path, copy the file there
      final XFile fileToAdd;
      if (customStoragePath != null) {
        // Get the destination path
        final String storageDirPath = await storagePath;

        // Extract the file name
        final String fileName = path.basename(file.path);

        // Create the new path
        final String newPath = path.join(storageDirPath, fileName);

        // Copy the file to the new location
        final File sourceFile = File(file.path);
        if (!await Directory(storageDirPath).exists()) {
          await Directory(storageDirPath).create(recursive: true);
        }

        // Only copy if source and destination are different
        if (file.path != newPath) {
          await sourceFile.copy(newPath);
          // Set appropriate mime type
          final String mimeType = isVideoFile ? 'video/mp4' : file.mimeType ?? 'image/jpeg';
          fileToAdd = XFile(newPath, mimeType: mimeType);
          debugPrint('📁 Copied media file to custom storage path: $newPath');
        } else {
          fileToAdd = file;
        }
      } else {
        // If the file doesn't have a mime type, set it based on isVideo
        if (file.mimeType == null) {
          final String mimeType = isVideoFile ? 'video/mp4' : 'image/jpeg';
          fileToAdd = XFile(file.path, mimeType: mimeType);
        } else {
          fileToAdd = file;
        }
      }

      _media.add(fileToAdd);
      onMediaAdded?.call(fileToAdd);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error adding media file: $e');
      // If there's an error with the custom path, fall back to adding the original file
      _media.add(file);
      onMediaAdded?.call(file);
      notifyListeners();
    }
  }

  /// Removes a media file from the manager.
  void removeMedia(XFile file) {
    final removed = _media.remove(file);
    if (removed) {
      // Remove any associated thumbnail
      if (hasVideoThumbnail(file.path)) {
        _videoThumbnails.remove(file.path);
      }
      onMediaRemoved?.call(file);
      notifyListeners();
    }
  }

  /// Removes a media file at the specified index.
  void removeMediaAt(int index) {
    if (index >= 0 && index < _media.length) {
      final file = _media.removeAt(index);
      // Remove any associated thumbnail
      if (hasVideoThumbnail(file.path)) {
        _videoThumbnails.remove(file.path);
      }
      onMediaRemoved?.call(file);
      notifyListeners();
    }
  }

  /// Clears all media files from the manager.
  void clearMedia() {
    _media.clear();
    _videoThumbnails.clear();
    notifyListeners();
  }

  /// Gets the most recent media files.
  ///
  /// If [count] is specified, returns at most that many items.
  /// Otherwise, returns all items.
  List<XFile> getRecentMedia({int? count}) {
    if (count == null || count >= _media.length) {
      return List.unmodifiable(_media);
    }
    return List.unmodifiable(_media.sublist(_media.length - count));
  }
}

/// A widget that displays a stack of media thumbnails.
class CameralyMediaStack extends StatelessWidget {
  /// Creates a new [CameralyMediaStack] widget.
  const CameralyMediaStack({
    required this.mediaManager,
    this.onTap,
    this.maxDisplayItems = 3,
    this.itemSize = 70,
    this.stackOffset = 5.0,
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
    this.borderRadius = 12.0,
    this.showCountBadge = true,
    this.countBadgeColor,
    this.showViewAllIndicator = true,
    this.viewAllIndicatorColor,
    this.viewAllText = 'View\nAll',
    super.key,
  });

  /// The media manager that provides the media files.
  final CameralyMediaManager mediaManager;

  /// Callback when the stack is tapped.
  final VoidCallback? onTap;

  /// The maximum number of items to display in the stack.
  final int maxDisplayItems;

  /// The size of each item in the stack.
  final double itemSize;

  /// The offset between stacked items.
  final double stackOffset;

  /// The color of the border around each item.
  final Color borderColor;

  /// The width of the border around each item.
  final double borderWidth;

  /// The radius of the border around each item.
  final double borderRadius;

  /// Whether to show a badge with the count of additional items.
  final bool showCountBadge;

  /// The color of the count badge.
  final Color? countBadgeColor;

  /// Whether to show an indicator to view all items.
  final bool showViewAllIndicator;

  /// The color of the view all indicator.
  final Color? viewAllIndicatorColor;

  /// The text to display in the view all indicator.
  final String viewAllText;

  @override
  Widget build(BuildContext context) {
    // If there are no media items, don't show anything
    if (mediaManager.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get the most recent items to display
    final recentMedia = mediaManager.getRecentMedia(count: maxDisplayItems);

    // Calculate the size of the stack based on the number of images
    final double stackWidth = itemSize + (recentMedia.length > 1 ? (recentMedia.length - 1) * stackOffset : 0);
    final double stackHeight = itemSize + (recentMedia.length > 1 ? (recentMedia.length - 1) * stackOffset : 0);

    final theme = Theme.of(context);
    final effectiveCountBadgeColor = countBadgeColor ?? theme.primaryColor;
    final effectiveViewAllIndicatorColor = viewAllIndicatorColor ?? theme.primaryColor;

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          // Open the media viewer
          final mediaFiles = mediaManager.media;
          final path = mediaFiles.last.path.toLowerCase();
          final isVideo = path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');

          if (isVideo || mediaFiles.length > 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MediaViewerScreen(
                  mediaFiles: mediaFiles,
                  initialIndex: mediaFiles.length - 1,
                  onDelete: (file) => mediaManager.removeMedia(file),
                ),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ImageViewScreen(
                  imageFile: mediaFiles.last,
                  onDelete: (file) => mediaManager.removeMedia(file),
                ),
              ),
            );
          }
        }
      },
      child: SizedBox(
        width: stackWidth + 15, // Extra space for the "View All" label
        height: stackHeight,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(76),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Build the stack of images from back to front (reversed order)
              for (int i = recentMedia.length - 1; i >= 0; i--)
                Positioned(
                  left: -(recentMedia.length - 1 - i) * stackOffset,
                  top: -(recentMedia.length - 1 - i) * stackOffset,
                  child: Container(
                    height: itemSize,
                    width: itemSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(color: borderColor, width: borderWidth),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51),
                          blurRadius: 4,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(borderRadius - borderWidth),
                      child: _buildMediaThumbnail(recentMedia[i]),
                    ),
                  ),
                ),

              // Counter badge if there are more items than we're showing
              if (showCountBadge && mediaManager.count > maxDisplayItems)
                Positioned(
                  top: -8,
                  left: -8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: effectiveCountBadgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(76),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      '+${mediaManager.count - maxDisplayItems}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

              // View all indicator
              if (showViewAllIndicator && mediaManager.count > 1)
                Positioned(
                  right: -10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: effectiveViewAllIndicatorColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(76),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        viewAllText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaThumbnail(XFile file) {
    final path = file.path;
    final isVideo = path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');

    return Stack(
      fit: StackFit.expand,
      children: [
        // Image thumbnail with error handling
        isVideo
            ? _buildVideoThumbnail(path)
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade900,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),

        // Video indicator overlay gradient
        if (isVideo)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withAlpha(128),
                ],
              ),
            ),
          ),

        // Video label indicator
        if (isVideo)
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(179),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 10,
                  ),
                  SizedBox(width: 2),
                  Text(
                    'VIDEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Dedicated widget for video thumbnails
  Widget _buildVideoThumbnail(String path) {
    // Check if we have a thumbnail for this video
    final thumbnailPath = mediaManager.hasVideoThumbnail(path) ? mediaManager.getThumbnailForVideo(path) : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Try to load the thumbnail if available, otherwise try to load the first frame
        if (thumbnailPath != null)
          Image.file(
            File(thumbnailPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to trying the video file itself
              return _buildVideoThumbnailFallback(path);
            },
          )
        else
          _buildVideoThumbnailFallback(path),

        // Gradient overlay for better visibility of icons
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withAlpha(128),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Fallback widget when dedicated thumbnail is not available
  Widget _buildVideoThumbnailFallback(String path) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback video thumbnail UI when image loading fails
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam,
                  color: Colors.white.withAlpha(204),
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  'VIDEO',
                  style: TextStyle(
                    color: Colors.white.withAlpha(230),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A widget that displays a gallery of captured media.
class CameralyGalleryView extends StatelessWidget {
  /// Creates a new [CameralyGalleryView] widget.
  const CameralyGalleryView({
    required this.mediaManager,
    this.onClose,
    this.onDelete,
    this.backgroundColor = Colors.black,
    this.appBarColor,
    this.appBarTextColor = Colors.white,
    this.gridSpacing = 2.0,
    this.gridCrossAxisCount = 3,
    this.emptyStateWidget,
    super.key,
  });

  /// The media manager that provides the media files.
  final CameralyMediaManager mediaManager;

  /// Callback when the gallery is closed.
  final VoidCallback? onClose;

  /// Callback when a media item is deleted.
  final Function(XFile)? onDelete;

  /// The background color of the gallery.
  final Color backgroundColor;

  /// The color of the app bar.
  final Color? appBarColor;

  /// The color of the app bar text.
  final Color appBarTextColor;

  /// The spacing between grid items.
  final double gridSpacing;

  /// The number of columns in the grid.
  final int gridCrossAxisCount;

  /// Widget to display when there are no media items.
  final Widget? emptyStateWidget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Gallery',
          style: TextStyle(color: appBarTextColor),
        ),
        backgroundColor: appBarColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appBarTextColor),
          onPressed: () {
            if (onClose != null) {
              onClose!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          if (mediaManager.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete, color: appBarTextColor),
              onPressed: () {
                _showDeleteAllDialog(context);
              },
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: mediaManager,
        builder: (context, _) {
          if (mediaManager.isEmpty) {
            return emptyStateWidget ??
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library,
                        size: 64,
                        color: Colors.white.withAlpha(128),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No media captured yet',
                        style: TextStyle(
                          color: Colors.white.withAlpha(179),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCrossAxisCount,
              crossAxisSpacing: gridSpacing,
              mainAxisSpacing: gridSpacing,
            ),
            itemCount: mediaManager.count,
            itemBuilder: (context, index) {
              final file = mediaManager.media[index];
              return GestureDetector(
                onTap: () {
                  _showMediaPreview(context, file, index);
                },
                child: _buildGridItem(file),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGridItem(XFile file) {
    final path = file.path;
    final isVideo = path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');

    return Stack(
      fit: StackFit.expand,
      children: [
        // Media thumbnail with error handling
        isVideo
            ? _buildVideoThumbnail(path)
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade900,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildVideoThumbnail(String path) {
    // Check if we have a thumbnail for this video
    final thumbnailPath = mediaManager.hasVideoThumbnail(path) ? mediaManager.getThumbnailForVideo(path) : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Try to load the thumbnail if available, otherwise try to load the first frame
        if (thumbnailPath != null)
          Image.file(
            File(thumbnailPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to trying the video file itself
              return _buildVideoThumbnailFallback(path);
            },
          )
        else
          _buildVideoThumbnailFallback(path),

        // Gradient overlay for better visibility of icons
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withAlpha(128),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoThumbnailFallback(String path) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback video thumbnail UI when image loading fails
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam,
                  color: Colors.white.withAlpha(204),
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  'VIDEO',
                  style: TextStyle(
                    color: Colors.white.withAlpha(230),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMediaPreview(BuildContext context, XFile file, int index) {
    // Use the existing MediaViewerScreen for all media types
    // This provides consistent UI and proper video playback
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaViewerScreen(
          mediaFiles: mediaManager.media,
          initialIndex: index,
          mediaManager: mediaManager,
          onDelete: (file) {
            mediaManager.removeMedia(file);
            if (onDelete != null) {
              onDelete!(file);
            }
          },
          // // Optional share callback can be added here if needed
          // onShare: (file) {
          //   // Implement share functionality
          // },
        ),
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Media'),
        content: const Text('Are you sure you want to delete all captured media?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              mediaManager.clearMedia();
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
