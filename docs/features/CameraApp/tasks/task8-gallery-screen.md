# Task 8: Advanced Gallery Screen with Riverpod State Management

## Status: ⏳ Not Started

## Objective
Create a sophisticated gallery screen using Riverpod state management for viewing captured photos and videos, specifically designed to verify orientation correctness and provide detailed metadata analysis for testing purposes.

## Subtasks

### 8.1 Riverpod Gallery State Management
- [ ] Design gallery providers for media management
- [ ] Implement media loading with async state handling
- [ ] Create orientation verification providers
- [ ] Add metadata analysis providers
- [ ] Implement gallery state persistence

### 8.2 Advanced Media Display with State Management
- [ ] Create media thumbnail provider with caching
- [ ] Implement orientation-aware media display
- [ ] Add metadata overlay provider
- [ ] Handle media loading states and errors
- [ ] Implement media type filtering

### 8.3 Orientation Verification Analytics
- [ ] Create orientation accuracy analysis provider
- [ ] Implement cross-app compatibility testing provider
- [ ] Add metadata validation providers
- [ ] Create orientation testing report generator
- [ ] Implement batch verification analysis

### 8.4 Gallery UI with Reactive State
- [ ] Build gallery screen with Consumer widgets
- [ ] Implement reactive media grid
- [ ] Add orientation-aware media viewer
- [ ] Create testing analytics dashboard
- [ ] Handle loading, error, and empty states

### 8.5 Advanced Testing Integration
- [ ] Integrate with testing data providers from previous tasks
- [ ] Create comprehensive media analysis
- [ ] Add orientation accuracy statistics
- [ ] Implement testing report generation
- [ ] Create automated verification workflows

## Detailed Implementation

### 8.1 Gallery State Management Architecture
```dart
// lib/providers/gallery_providers.dart
@riverpod
class GalleryController extends _$GalleryController {
  @override
  Future<GalleryState> build() async {
    // Initialize gallery state with media loading
    return _loadAllMedia();
  }
  
  Future<GalleryState> _loadAllMedia() async {
    try {
      final mediaItems = await ref.read(mediaStorageProvider).getAllMedia();
      final sortedMedia = _sortMediaByOrientationAccuracy(mediaItems);
      
      return GalleryState.loaded(
        mediaItems: sortedMedia,
        orientationStats: await _calculateOrientationStats(mediaItems),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      return GalleryState.error(e.toString());
    }
  }
  
  Future<void> refreshMedia() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadAllMedia());
  }
  
  Future<void> deleteMedia(String mediaId) async {
    // Delete media and update state
    await ref.read(mediaStorageProvider).deleteMedia(mediaId);
    await refreshMedia();
  }
}

@riverpod
Future<List<MediaItem>> filteredMedia(
  FilteredMediaRef ref,
  MediaFilter filter,
) async {
  final gallery = await ref.watch(galleryControllerProvider.future);
  return _filterMedia(gallery.mediaItems, filter);
}

@riverpod
class MediaViewer extends _$MediaViewer {
  @override
  MediaViewerState build(String mediaId) {
    final media = ref.watch(mediaItemProvider(mediaId));
    return MediaViewerState(
      currentMedia: media,
      metadata: null,
      orientationAnalysis: null,
    );
  }
  
  Future<void> analyzeOrientation() async {
    final currentMedia = state.currentMedia;
    if (currentMedia == null) return;
    
    final analysis = await ref.read(orientationAnalyzerProvider)
        .analyzeMedia(currentMedia);
    
    state = state.copyWith(orientationAnalysis: analysis);
  }
}
```

### 8.2 Orientation Verification Providers
```dart
// lib/providers/orientation_verification_providers.dart
@riverpod
class OrientationAnalyzer extends _$OrientationAnalyzer {
  @override
  Future<OrientationAnalysisState> build() async {
    return OrientationAnalysisState.initial();
  }
  
  Future<MediaOrientationAnalysis> analyzeMedia(MediaItem media) async {
    try {
      // Extract EXIF/metadata from media file
      final metadata = await _extractMediaMetadata(media);
      
      // Verify orientation accuracy
      final orientationAccuracy = await _verifyOrientationAccuracy(
        media, 
        metadata
      );
      
      // Test cross-app compatibility
      final compatibilityResults = await _testCrossAppCompatibility(media);
      
      // Generate recommendations
      final recommendations = _generateOrientationRecommendations(
        orientationAccuracy,
        compatibilityResults,
      );
      
      return MediaOrientationAnalysis(
        mediaItem: media,
        metadata: metadata,
        orientationAccuracy: orientationAccuracy,
        compatibilityResults: compatibilityResults,
        recommendations: recommendations,
        analyzedAt: DateTime.now(),
      );
      
    } catch (e) {
      throw OrientationAnalysisException('Failed to analyze media: $e');
    }
  }
  
  Future<GalleryOrientationReport> generateGalleryReport() async {
    final allMedia = await ref.read(galleryControllerProvider.future);
    
    final analyses = <MediaOrientationAnalysis>[];
    for (final media in allMedia.mediaItems) {
      analyses.add(await analyzeMedia(media));
    }
    
    return GalleryOrientationReport(
      totalMediaItems: analyses.length,
      orientationAccuracy: _calculateOverallAccuracy(analyses),
      deviceBreakdown: _generateDeviceBreakdown(analyses),
      orientationBreakdown: _generateOrientationBreakdown(analyses),
      compatibilityScore: _calculateCompatibilityScore(analyses),
      recommendations: _generateGlobalRecommendations(analyses),
      generatedAt: DateTime.now(),
    );
  }
}

@riverpod
Future<OrientationAccuracyStats> orientationAccuracyStats(
  OrientationAccuracyStatsRef ref,
) async {
  final testingData = await ref.watch(testingDataControllerProvider.future);
  return _calculateAccuracyStats(testingData);
}

@riverpod
Future<CrossAppCompatibilityReport> crossAppCompatibility(
  CrossAppCompatibilityRef ref,
) async {
  final gallery = await ref.watch(galleryControllerProvider.future);
  return await _testAllMediaCompatibility(gallery.mediaItems);
}
```

### 8.3 Gallery UI with Reactive State
```dart
// lib/screens/gallery_screen.dart
class GalleryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryState = ref.watch(galleryControllerProvider);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildNativeAppBar(context, ref),
      body: galleryState.when(
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error, ref),
        data: (gallery) => _buildGalleryContent(context, ref, gallery),
      ),
    );
  }
  
  Widget _buildGalleryContent(
    BuildContext context, 
    WidgetRef ref, 
    GalleryState gallery,
  ) {
    return Column(
      children: [
        _buildOrientationStatsHeader(context, ref, gallery),
        Expanded(
          child: _buildMediaGrid(context, ref, gallery),
        ),
        _buildGalleryActions(context, ref),
      ],
    );
  }
  
  Widget _buildOrientationStatsHeader(
    BuildContext context, 
    WidgetRef ref, 
    GalleryState gallery,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(bottom: BorderSide(color: Colors.grey[700]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                'Total Media', 
                '${gallery.mediaItems.length}',
                Icons.photo_library,
              ),
              _buildStatCard(
                'Accuracy', 
                '${(gallery.orientationStats.accuracy * 100).toStringAsFixed(1)}%',
                Icons.check_circle,
                color: _getAccuracyColor(gallery.orientationStats.accuracy),
              ),
              _buildStatCard(
                'Devices Tested', 
                '${gallery.orientationStats.uniqueDevices}',
                Icons.devices,
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildOrientationBreakdown(gallery.orientationStats),
        ],
      ),
    );
  }
  
  Widget _buildMediaGrid(
    BuildContext context, 
    WidgetRef ref, 
    GalleryState gallery,
  ) {
    return GridView.builder(
      padding: EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: gallery.mediaItems.length,
      itemBuilder: (context, index) {
        final media = gallery.mediaItems[index];
        return OrientationAwareMediaThumbnail(
          mediaItem: media,
          onTap: () => _viewMedia(context, ref, media),
        );
      },
    );
  }
}
```

### 8.4 Orientation-Aware Media Thumbnail
```dart
// lib/widgets/orientation_aware_media_thumbnail.dart
class OrientationAwareMediaThumbnail extends ConsumerWidget {
  final MediaItem mediaItem;
  final VoidCallback onTap;
  
  const OrientationAwareMediaThumbnail({
    required this.mediaItem,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orientationAnalysis = ref.watch(
      mediaOrientationAnalysisProvider(mediaItem.id)
    );
    
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
            _buildOrientationIndicators(orientationAnalysis),
            _buildMediaTypeIndicator(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrientationIndicators(
    AsyncValue<MediaOrientationAnalysis> analysis,
  ) {
    return Positioned(
      top: 4,
      left: 4,
      child: analysis.when(
        loading: () => _buildLoadingIndicator(),
        error: (error, stack) => _buildErrorIndicator(),
        data: (analysis) => _buildOrientationAccuracyBadge(analysis),
      ),
    );
  }
  
  Widget _buildOrientationAccuracyBadge(MediaOrientationAnalysis analysis) {
    final accuracy = analysis.orientationAccuracy.overallScore;
    final color = _getAccuracyColor(accuracy);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            accuracy > 0.95 ? Icons.check_circle : 
            accuracy > 0.8 ? Icons.warning : Icons.error,
            color: Colors.white,
            size: 12,
          ),
          SizedBox(width: 2),
          Text(
            '${(accuracy * 100).toInt()}%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 8.5 Advanced Media Viewer with Analytics
```dart
// lib/screens/media_viewer_screen.dart
class MediaViewerScreen extends ConsumerWidget {
  final String mediaId;
  
  const MediaViewerScreen({required this.mediaId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaViewer = ref.watch(mediaViewerProvider(mediaId));
    final orientationAnalysis = ref.watch(
      mediaOrientationAnalysisProvider(mediaId)
    );
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMediaDisplay(context, ref, mediaViewer),
          _buildMediaControls(context, ref),
          _buildMetadataOverlay(context, ref, orientationAnalysis),
        ],
      ),
    );
  }
  
  Widget _buildMetadataOverlay(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<MediaOrientationAnalysis> analysis,
  ) {
    return analysis.when(
      loading: () => _buildAnalysisLoadingState(),
      error: (error, stack) => _buildAnalysisErrorState(error),
      data: (analysis) => OrientationMetadataOverlay(analysis: analysis),
    );
  }
}

class OrientationMetadataOverlay extends StatefulWidget {
  final MediaOrientationAnalysis analysis;
  
  @override
  _OrientationMetadataOverlayState createState() => 
      _OrientationMetadataOverlayState();
}

class _OrientationMetadataOverlayState extends State<OrientationMetadataOverlay> {
  bool _showDetails = false;
  
  @override
  Widget build(BuildContext context) {
    if (!_showDetails) {
      return _buildCompactOverlay();
    }
    
    return _buildDetailedOverlay();
  }
  
  Widget _buildDetailedOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrientationAnalysisSection(),
              SizedBox(height: 16),
              _buildMetadataSection(),
              SizedBox(height: 16),
              _buildCompatibilitySection(),
              SizedBox(height: 16),
              _buildRecommendationsSection(),
              SizedBox(height: 16),
              _buildTestingDataSection(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOrientationAnalysisSection() {
    final analysis = widget.analysis;
    
    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Orientation Analysis',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            _buildAccuracyMeter(analysis.orientationAccuracy),
            SizedBox(height: 12),
            _buildOrientationDetails(analysis),
          ],
        ),
      ),
    );
  }
}
```

## Files to Create
- `lib/providers/gallery_providers.dart`
- `lib/providers/orientation_verification_providers.dart`
- `lib/providers/media_analysis_providers.dart`
- `lib/screens/gallery_screen.dart`
- `lib/screens/media_viewer_screen.dart`
- `lib/widgets/orientation_aware_media_thumbnail.dart`
- `lib/widgets/orientation_metadata_overlay.dart`
- `lib/widgets/gallery_stats_widgets.dart`
- `lib/models/gallery_state.dart`
- `lib/models/media_orientation_analysis.dart`

## Files to Modify
- `lib/providers/testing_providers.dart` (integrate gallery analytics)
- `lib/main.dart` (add gallery routes)
- `lib/screens/camera_screen.dart` (add gallery navigation)

## Riverpod Integration Benefits

### State Management Advantages
- **Reactive Media Loading**: Automatic UI updates when media changes
- **Cached Analysis**: Orientation analysis results cached efficiently
- **Global Testing Data**: Shared analytics across screens
- **Error Handling**: Centralized error management
- **Performance**: Optimized rebuilds for large media collections

### Provider Dependencies
```dart
// Gallery dependencies
galleryControllerProvider
  ↓ depends on
mediaStorageProvider + testingDataControllerProvider
  ↓ provides to
orientationAnalyzerProvider + mediaViewerProvider
```

## Testing Integration with Riverpod

### Provider Testing
```dart
// Test gallery provider functionality
testWidgets('Gallery loads media correctly', (tester) async {
  final container = ProviderContainer(
    overrides: [
      mediaStorageProvider.overrideWith(MockMediaStorage()),
    ],
  );
  
  final gallery = await container.read(galleryControllerProvider.future);
  expect(gallery.mediaItems.length, equals(expectedCount));
});
```

### Orientation Testing Analytics
```dart
@riverpod
Future<OrientationTestingReport> orientationTestingReport(
  OrientationTestingReportRef ref,
) async {
  final allAnalyses = await ref.watch(allMediaAnalysesProvider.future);
  
  return OrientationTestingReport(
    totalTests: allAnalyses.length,
    successRate: _calculateSuccessRate(allAnalyses),
    deviceBreakdown: _groupByDevice(allAnalyses),
    orientationBreakdown: _groupByOrientation(allAnalyses),
    timeSeriesData: _generateTimeSeriesData(allAnalyses),
    recommendations: _generateTestingRecommendations(allAnalyses),
  );
}
```

## Acceptance Criteria
- [ ] Gallery screen uses Riverpod providers for all state management
- [ ] Media loading and display is reactive and efficient
- [ ] Orientation verification analytics are comprehensive and accurate
- [ ] UI automatically updates when testing data changes
- [ ] All media operations (load, delete, analyze) work through providers
- [ ] Error states are handled gracefully throughout
- [ ] Orientation analysis results are cached and persisted
- [ ] Gallery integrates seamlessly with testing data from other tasks
- [ ] Performance remains smooth with large media collections
- [ ] Testing analytics provide actionable insights

## Enhanced Testing Requirements
- **Provider Integration**: All functionality accessible through Riverpod
- **State Persistence**: Gallery state and analysis results persist across app lifecycle
- **Real-time Updates**: UI reflects changes immediately
- **Testing Analytics**: Comprehensive orientation analysis and reporting
- **Performance**: Smooth operation with 100+ media items

## Notes
- Gallery serves as the primary validation tool for orientation testing
- Riverpod enables sophisticated caching and dependency management
- State management makes testing and debugging much easier
- Analytics providers can be reused across different screens
- Real-time orientation analysis provides immediate feedback

## Estimated Time: 5-6 hours

## Next Task: Task 9 - Comprehensive Orientation Testing 