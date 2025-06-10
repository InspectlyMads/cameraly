import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/media_item.dart';
import '../services/media_service.dart';

part 'gallery_providers.g.dart';

// ignore_for_file: deprecated_member_use_from_same_package

// Service provider
final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService();
});

// Main gallery state provider
@riverpod
class Gallery extends _$Gallery {
  @override
  GalleryState build() {
    // Schedule refresh for next frame to avoid accessing uninitialized state
    Future.microtask(() => refreshMedia());
    return const GalleryState();
  }

  /// Refresh media from storage
  Future<void> refreshMedia() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final mediaService = ref.read(mediaServiceProvider);
      final mediaItems = await mediaService.discoverMediaFiles();

      // Get metadata for all items
      final List<MediaItem> itemsWithMetadata = [];
      for (final item in mediaItems) {
        final itemWithMetadata = await mediaService.getMediaMetadata(item);
        itemsWithMetadata.add(itemWithMetadata);
      }

      state = state.copyWith(
        mediaItems: itemsWithMetadata,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load media: $e',
      );
    }
  }

  /// Delete a media item
  Future<void> deleteMediaItem(MediaItem mediaItem) async {
    try {
      final mediaService = ref.read(mediaServiceProvider);
      final success = await mediaService.deleteMediaFile(mediaItem);

      if (success) {
        // Remove from current state
        final updatedItems = state.mediaItems.where((item) => item.path != mediaItem.path).toList();
        state = state.copyWith(mediaItems: updatedItems);
      } else {
        state = state.copyWith(errorMessage: 'Failed to delete media file');
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error deleting media: $e');
    }
  }

  /// Delete multiple media items
  Future<void> deleteMediaItems(List<MediaItem> mediaItems) async {
    if (mediaItems.isEmpty) return;

    try {
      final mediaService = ref.read(mediaServiceProvider);
      final deletedCount = await mediaService.deleteMediaFiles(mediaItems);

      if (deletedCount > 0) {
        // Remove deleted items from current state
        final deletedPaths = mediaItems.map((item) => item.path).toSet();
        final updatedItems = state.mediaItems.where((item) => !deletedPaths.contains(item.path)).toList();
        state = state.copyWith(mediaItems: updatedItems);

        if (deletedCount < mediaItems.length) {
          state = state.copyWith(errorMessage: 'Some files could not be deleted');
        }
      } else {
        state = state.copyWith(errorMessage: 'Failed to delete media files');
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error deleting media: $e');
    }
  }

  /// Select a media item
  void selectMediaItem(MediaItem? mediaItem) {
    state = state.copyWith(selectedItem: mediaItem);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Clear all media (for testing)
  Future<void> clearAllMedia() async {
    try {
      final mediaService = ref.read(mediaServiceProvider);
      await mediaService.clearAllMedia();
      state = state.copyWith(mediaItems: []);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error clearing media: $e');
    }
  }
}

// Convenience providers
@riverpod
List<MediaItem> photoItems(PhotoItemsRef ref) {
  final galleryState = ref.watch(galleryProvider);
  return galleryState.mediaItems.where((item) => item.type == MediaType.photo).toList();
}

@riverpod
List<MediaItem> videoItems(VideoItemsRef ref) {
  final galleryState = ref.watch(galleryProvider);
  return galleryState.mediaItems.where((item) => item.type == MediaType.video).toList();
}

@riverpod
int totalMediaCount(TotalMediaCountRef ref) {
  final galleryState = ref.watch(galleryProvider);
  return galleryState.mediaItems.length;
}

@riverpod
Future<int> totalStorageUsed(TotalStorageUsedRef ref) async {
  final mediaService = ref.read(mediaServiceProvider);
  return await mediaService.getTotalStorageUsed();
}

@riverpod
String formattedStorageUsed(FormattedStorageUsedRef ref) {
  final storageAsync = ref.watch(totalStorageUsedProvider);
  final mediaService = ref.read(mediaServiceProvider);

  return storageAsync.when(
    data: (storage) => mediaService.formatStorageSize(storage),
    loading: () => 'Calculating...',
    error: (_, __) => 'Unknown',
  );
}
