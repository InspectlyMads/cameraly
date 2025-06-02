import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../providers/gallery_providers.dart';
import '../services/media_service.dart';
import '../widgets/media_grid_item.dart';
import '../widgets/media_viewer.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final Set<MediaItem> _selectedItems = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode ? Text('${_selectedItems.length} selected') : const Text('Gallery'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
        actions: _buildAppBarActions(galleryState),
        elevation: 0,
      ),
      body: _buildBody(galleryState),
      floatingActionButton: _isSelectionMode ? _buildSelectionFAB() : null,
    );
  }

  List<Widget> _buildAppBarActions(GalleryState galleryState) {
    if (_isSelectionMode) {
      return [
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: () => _selectAll(galleryState.mediaItems),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _selectedItems.isNotEmpty ? _deleteSelected : null,
        ),
      ];
    } else {
      return [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.read(galleryProvider.notifier).refreshMedia(),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, galleryState),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear_all',
              child: Text('Clear All Media'),
            ),
            const PopupMenuItem(
              value: 'storage_info',
              child: Text('Storage Info'),
            ),
          ],
        ),
      ];
    }
  }

  Widget _buildBody(GalleryState galleryState) {
    if (galleryState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading media...'),
          ],
        ),
      );
    }

    if (galleryState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                galleryState.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(galleryProvider.notifier).clearError();
                  ref.read(galleryProvider.notifier).refreshMedia();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (galleryState.mediaItems.isEmpty) {
      return _buildEmptyState();
    }

    return _buildMediaGrid(galleryState.mediaItems);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Media Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture some photos or videos with the camera to see them here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go to Camera'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid(List<MediaItem> mediaItems) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: mediaItems.length,
        itemBuilder: (context, index) {
          final mediaItem = mediaItems[index];
          final isSelected = _selectedItems.contains(mediaItem);

          return MediaGridItem(
            mediaItem: mediaItem,
            isSelected: isSelected,
            isSelectionMode: _isSelectionMode,
            onTap: () => _handleMediaItemTap(mediaItem),
            onLongPress: () => _handleMediaItemLongPress(mediaItem),
          );
        },
      ),
    );
  }

  Widget? _buildSelectionFAB() {
    if (_selectedItems.isEmpty) return null;

    return FloatingActionButton(
      onPressed: _deleteSelected,
      backgroundColor: Colors.red,
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  void _handleMediaItemTap(MediaItem mediaItem) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedItems.contains(mediaItem)) {
          _selectedItems.remove(mediaItem);
        } else {
          _selectedItems.add(mediaItem);
        }

        if (_selectedItems.isEmpty) {
          _isSelectionMode = false;
        }
      });
    } else {
      _openMediaViewer(mediaItem);
    }
  }

  void _handleMediaItemLongPress(MediaItem mediaItem) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedItems.add(mediaItem);
      });
    }
  }

  void _selectAll(List<MediaItem> mediaItems) {
    setState(() {
      _selectedItems.clear();
      _selectedItems.addAll(mediaItems);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }

  void _deleteSelected() {
    if (_selectedItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: Text(
          'Are you sure you want to delete ${_selectedItems.length} ${_selectedItems.length == 1 ? 'item' : 'items'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(galleryProvider.notifier).deleteMediaItems(_selectedItems.toList());
              _exitSelectionMode();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, GalleryState galleryState) {
    switch (action) {
      case 'clear_all':
        _clearAllMedia(galleryState);
        break;
      case 'storage_info':
        _showStorageInfo();
        break;
    }
  }

  void _clearAllMedia(GalleryState galleryState) {
    if (galleryState.mediaItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Media'),
        content: const Text(
          'Are you sure you want to delete all captured media? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(galleryProvider.notifier).clearAllMedia();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showStorageInfo() {
    final totalCount = ref.read(totalMediaCountProvider);
    final photoCount = ref.read(photoItemsProvider).length;
    final videoCount = ref.read(videoItemsProvider).length;
    final storageUsed = ref.read(formattedStorageUsedProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Items: $totalCount'),
            Text('Photos: $photoCount'),
            Text('Videos: $videoCount'),
            const SizedBox(height: 8),
            Text('Storage Used: $storageUsed'),
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

  void _openMediaViewer(MediaItem mediaItem) {
    final galleryState = ref.read(galleryProvider);
    final mediaItems = galleryState.mediaItems;
    final currentIndex = mediaItems.indexOf(mediaItem);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaViewer(
          mediaItems: mediaItems,
          initialIndex: currentIndex,
        ),
      ),
    );
  }
}
