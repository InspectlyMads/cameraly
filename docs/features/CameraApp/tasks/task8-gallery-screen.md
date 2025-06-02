# Task 8: Gallery Screen for Media Verification

## Status: ⏳ Not Started

## Objective
Create a gallery screen for viewing captured photos and videos within the app, specifically designed to verify orientation correctness and provide detailed metadata for testing purposes.

## Subtasks

### 8.1 Gallery Layout Implementation
- [ ] Design grid-based media gallery layout
- [ ] Implement responsive grid that adapts to screen size
- [ ] Add navigation from camera screen and home screen
- [ ] Create native-style gallery header with back navigation
- [ ] Implement empty state when no media exists

### 8.2 Media Display Components
- [ ] Create photo thumbnail component with orientation handling
- [ ] Implement video thumbnail with play overlay
- [ ] Add media type indicators (photo/video icons)
- [ ] Display capture date/time information
- [ ] Show orientation metadata visually

### 8.3 Photo/Video Playback
- [ ] Implement full-screen photo viewer
- [ ] Add video player with native controls
- [ ] Support pinch-to-zoom for photos
- [ ] Handle orientation changes during media viewing
- [ ] Add swipe navigation between media items

### 8.4 Metadata Display for Testing
- [ ] Create detailed metadata overlay for testing
- [ ] Display EXIF orientation data for photos
- [ ] Show video rotation metadata
- [ ] Include device orientation at capture time
- [ ] Add camera settings and device information

### 8.5 File Management Features
- [ ] Implement delete functionality with confirmation
- [ ] Add share media capability
- [ ] Export to device gallery option
- [ ] Bulk selection and operations
- [ ] Storage usage display

## Detailed Implementation

### 8.1 Gallery Grid Layout
```dart
class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<MediaItem> _mediaItems = [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildNativeAppBar(),
      body: _mediaItems.isEmpty
          ? _buildEmptyState()
          : _buildMediaGrid(),
    );
  }
  
  Widget _buildMediaGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _mediaItems.length,
      itemBuilder: (context, index) {
        return MediaThumbnail(
          mediaItem: _mediaItems[index],
          onTap: () => _viewMedia(index),
        );
      },
    );
  }
}
```

### 8.2 Media Thumbnail Component
```dart
class MediaThumbnail extends StatelessWidget {
  final MediaItem mediaItem;
  final VoidCallback onTap;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMediaPreview(),
            _buildMediaTypeIndicator(),
            _buildOrientationIndicator(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMediaPreview() {
    if (mediaItem.type == MediaType.photo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          mediaItem.file,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return _buildVideoThumbnail();
    }
  }
  
  Widget _buildOrientationIndicator() {
    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _getOrientationText(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
```

### 8.3 Full-Screen Media Viewer
```dart
class MediaViewer extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final int initialIndex;
  
  @override
  _MediaViewerState createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  PageController _pageController;
  int _currentIndex;
  bool _showMetadata = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMediaPageView(),
          _buildViewerControls(),
          if (_showMetadata) _buildMetadataOverlay(),
        ],
      ),
    );
  }
  
  Widget _buildMediaPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      itemCount: widget.mediaItems.length,
      itemBuilder: (context, index) {
        final mediaItem = widget.mediaItems[index];
        if (mediaItem.type == MediaType.photo) {
          return InteractiveViewer(
            child: Image.file(mediaItem.file),
          );
        } else {
          return VideoPlayerWidget(mediaItem: mediaItem);
        }
      },
    );
  }
}
```

### 8.4 Metadata Overlay for Testing
```dart
class MetadataOverlay extends StatelessWidget {
  final MediaItem mediaItem;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetadataHeader(),
              SizedBox(height: 16),
              _buildOrientationData(),
              _buildCaptureData(),
              _buildDeviceData(),
              _buildFileData(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOrientationData() {
    return MetadataSection(
      title: 'Orientation Data',
      items: [
        MetadataItem('Device Orientation', mediaItem.deviceOrientation),
        MetadataItem('EXIF Orientation', _getExifOrientation()),
        MetadataItem('Capture Angle', _getCaptureAngle()),
        MetadataItem('Preview Rotation', _getPreviewRotation()),
      ],
    );
  }
}
```

## Files to Create
- `lib/screens/gallery_screen.dart`
- `lib/screens/media_viewer_screen.dart`
- `lib/widgets/media_thumbnail.dart`
- `lib/widgets/metadata_overlay.dart`
- `lib/widgets/video_player_widget.dart`
- `lib/services/media_metadata_service.dart`
- `lib/utils/exif_reader.dart`

## Files to Modify
- `lib/main.dart` (add gallery route)
- `lib/screens/home_screen.dart` (add gallery navigation)
- `lib/screens/camera_screen.dart` (add gallery access)

## Orientation Verification Features

### Visual Orientation Indicators
- Color-coded orientation badges on thumbnails
- Clear text labels: "Portrait", "Landscape L", "Landscape R", "Upside Down"
- Visual rotation indicators showing capture angle
- Comparison with expected vs actual orientation

### EXIF/Metadata Analysis
- Display raw EXIF orientation values
- Show video rotation matrix data
- Compare device orientation vs media metadata
- Highlight mismatches for debugging

### Testing Workflow Integration
- Quick access to recently captured media
- Batch orientation verification
- Export test results functionality
- Integration with testing documentation

## Native Gallery Integration

### Share to System Gallery
```dart
Future<void> _shareToSystemGallery(MediaItem mediaItem) async {
  try {
    await GallerySaver.saveImage(mediaItem.path);
    _showSuccessMessage('Saved to device gallery');
  } catch (e) {
    _showErrorMessage('Failed to save: $e');
  }
}
```

### Open in External Apps
```dart
Future<void> _openInExternalApp(MediaItem mediaItem) async {
  try {
    await OpenFile.open(mediaItem.path);
  } catch (e) {
    _showErrorMessage('No compatible app found');
  }
}
```

## Acceptance Criteria
- [ ] Gallery displays all captured photos and videos
- [ ] Media thumbnails show correct orientation
- [ ] Full-screen viewer handles orientation properly
- [ ] Video playback works with correct rotation
- [ ] Metadata overlay shows accurate orientation data
- [ ] Delete functionality works without errors
- [ ] Share to system gallery preserves orientation
- [ ] UI remains responsive with large media collections
- [ ] Orientation verification is visually clear
- [ ] Testing workflow is efficient and intuitive

## Testing Points
- [ ] Test gallery with mixed photo/video content
- [ ] Verify thumbnail generation for all orientations
- [ ] Test full-screen viewing in all device orientations
- [ ] Verify video playback orientation
- [ ] Test metadata accuracy for all capture scenarios
- [ ] Verify file operations (delete, share, export)
- [ ] Test performance with large number of media files
- [ ] Verify UI responsiveness during media loading
- [ ] Test navigation between media items
- [ ] Verify empty state handling

## Performance Considerations
- Efficient thumbnail generation and caching
- Lazy loading for large media collections
- Optimized video thumbnail extraction
- Memory management for full-screen viewing
- Background processing for metadata extraction

## User Experience Requirements
- Smooth scrolling in media grid
- Quick thumbnail loading
- Intuitive navigation gestures
- Clear visual feedback for operations
- Consistent with system gallery patterns

## Testing Integration Features
- Export orientation test results
- Generate testing reports
- Batch verification tools
- Integration with external analysis tools
- Test data preservation across app sessions

## Notes
- Gallery serves dual purpose: user functionality and testing verification
- Focus on making orientation issues immediately visible
- Ensure metadata display is comprehensive for debugging
- Consider adding automated orientation verification
- Document any discrepancies found during testing

## Estimated Time: 4-5 hours

## Next Task: Task 9 - Comprehensive Orientation Testing 