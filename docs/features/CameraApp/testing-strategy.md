# Camera App Testing Strategy

## Test-Driven Development Approach (Cursor Rule Compliance)

### Testing During Implementation
Following **Cursor Rule 3**, we will create tests **as we implement each feature**, not after. This ensures:
- ✅ **Robust error handling** from the start
- ✅ **Test coverage** for core functionality 
- ✅ **Early bug detection** during development
- ✅ **Confidence in implementation** before moving to next feature

### Implementation + Test Workflow:
```
For each Task/Feature:
1. 📝 Implement core functionality
2. 🧪 Create unit tests for business logic
3. 🎯 Create widget tests for UI components  
4. 🔄 Run tests and fix issues
5. ✅ Mark task complete only when tests pass
```

### Test File Structure:
```
test/
├── unit/
│   ├── controllers/
│   ├── services/ 
│   ├── models/
│   └── providers/
├── widget/
│   ├── screens/
│   ├── overlays/
│   └── components/
└── integration/
    ├── camera_flow_test.dart
    ├── orientation_test.dart
    └── capture_test.dart
```

---

# Progressive "Test-as-You-Build" Camera App Testing Strategy

## Overview
This document outlines our testing approach for the Camera Test MVP, emphasizing orientation testing while maintaining code quality through progressive test implementation.

## Testing Philosophy
- **Test-as-You-Build**: Implement tests alongside each task, not after
- **Orientation-First**: Every test validates orientation behavior
- **Real Device Focus**: Prioritize testing on actual Android devices
- **Data-Driven**: Collect quantitative orientation accuracy data
- **Progressive Complexity**: Start simple, add sophistication incrementally

## Testing Pyramid for Camera App

### Unit Tests (Foundation - 60% of tests)
**Focus**: Individual functions, providers, and business logic
**Run Frequency**: Every commit
**Location**: `test/unit/`

### Widget Tests (Core - 30% of tests)  
**Focus**: UI components and user interactions
**Run Frequency**: Every feature completion
**Location**: `test/widget/`

### Integration Tests (Validation - 10% of tests)
**Focus**: Full app workflows and device-specific behavior
**Run Frequency**: Before releases and device testing
**Location**: `integration_test/`

## Testing Implementation by Task

### Task 1 - Project Setup & State Management
```dart
// test/unit/providers/test_providers_test.dart
testWidgets('Camera controller initializes correctly', (tester) async {
  final container = ProviderContainer();
  
  final controller = await container.read(
    orientationAwareCameraControllerProvider.future
  );
  
  expect(controller.isInitialized, isTrue);
  expect(controller.currentOrientation, isNotNull);
});

// test/unit/models/orientation_data_test.dart
group('OrientationData', () {
  test('serializes to JSON correctly', () {
    final orientation = OrientationData(
      deviceOrientation: DeviceOrientation.landscapeLeft,
      cameraRotation: 90,
      sensorOrientation: 270,
      deviceManufacturer: 'Samsung',
      deviceModel: 'Galaxy S21',
      timestamp: DateTime.now(),
    );
    
    final json = orientation.toJson();
    final restored = OrientationData.fromJson(json);
    
    expect(restored.deviceOrientation, equals(orientation.deviceOrientation));
    expect(restored.cameraRotation, equals(orientation.cameraRotation));
  });
});
```

### Task 2 - Permission Handling
```dart
// test/unit/providers/permission_providers_test.dart
group('Permission Provider Tests', () {
  testWidgets('Camera permission state updates correctly', (tester) async {
    final container = ProviderContainer(
      overrides: [
        permissionHandlerProvider.overrideWith(MockPermissionHandler()),
      ],
    );
    
    // Test permission request flow
    final permission = container.read(cameraPermissionProvider);
    expect(permission, isA<AsyncLoading>());
    
    await tester.pumpAndSettle();
    
    final result = await container.read(cameraPermissionProvider.future);
    expect(result.isGranted, isTrue);
  });
});

// test/widget/permission_screen_test.dart
testWidgets('Permission screen shows correct messages', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: PermissionScreen()),
    ),
  );
  
  expect(find.text('Camera Permission Required'), findsOneWidget);
  expect(find.byType(ElevatedButton), findsOneWidget);
});
```

### Task 3 - Home Screen
```dart
// test/widget/home_screen_test.dart
testWidgets('Home screen navigates to camera modes', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: HomeScreen()),
    ),
  );
  
  // Test navigation to different camera modes
  await tester.tap(find.text('Photo Mode'));
  await tester.pumpAndSettle();
  
  expect(find.byType(CameraScreen), findsOneWidget);
});

// test/integration/app_navigation_test.dart
testWidgets('Full app navigation flow', (tester) async {
  app.main();
  await tester.pumpAndSettle();
  
  // Test complete navigation flow
  await tester.tap(find.text('Photo Mode'));
  await tester.pumpAndSettle();
  
  // Verify camera screen loads
  expect(find.byType(CameraPreview), findsOneWidget);
});
```

### Task 4 - Advanced Camera System (Critical Orientation Testing)
```dart
// test/unit/controllers/orientation_aware_cameraly.dart
group('OrientationAwareCameraController', () {
  testWidgets('Detects orientation changes correctly', (tester) async {
    final mockSensors = MockSensorsService();
    final container = ProviderContainer(
      overrides: [
        sensorsServiceProvider.overrideWith((_) => mockSensors),
      ],
    );
    
    final controller = container.read(
      orientationAwareCameraControllerProvider.notifier
    );
    
    // Simulate device rotation
    mockSensors.simulateRotation(DeviceOrientation.landscapeLeft);
    await tester.pump(Duration(milliseconds: 500));
    
    final state = await container.read(
      orientationAwareCameraControllerProvider.future
    );
    
    expect(state.currentOrientation.deviceOrientation, 
           equals(DeviceOrientation.landscapeLeft));
  });
  
  test('Applies manufacturer-specific corrections', () {
    final samsung = DeviceInfo(manufacturer: 'Samsung', model: 'Galaxy S21');
    final correction = OrientationCorrection.forDevice(samsung);
    
    expect(correction.rotationOffset, equals(90));
    expect(correction.requiresTransformMatrix, isTrue);
  });
});

// test/widget/camera_preview_test.dart
testWidgets('Camera preview handles orientation changes', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: OrientationAwareCameraPreview(),
        ),
      ),
    ),
  );
  
  // Test orientation change handling
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/device_orientation',
    const StandardMessageCodec().encodeMessage('landscapeLeft'),
    (data) {},
  );
  
  await tester.pumpAndSettle();
  
  // Verify preview adjusts correctly
  expect(find.byType(Transform), findsOneWidget);
});
```

### Task 5 - Photo Capture with Orientation Testing
```dart
// test/unit/features/photo_capture_test.dart
group('OrientationAwarePhotoCapture', () {
  testWidgets('Captures photos with correct orientation metadata', (tester) async {
    final mockCamera = MockCameraController();
    final container = ProviderContainer(
      overrides: [
        cameraControllerProvider.overrideWith((_) => mockCamera),
      ],
    );
    
    final capturer = container.read(photoCapturerProvider);
    
    // Test capture in different orientations
    for (final orientation in DeviceOrientation.values) {
      mockCamera.simulateOrientation(orientation);
      
      final result = await capturer.capturePhoto();
      
      expect(result.isSuccess, isTrue);
      expect(result.orientationData.deviceOrientation, equals(orientation));
      expect(result.metadata.exifOrientation, isNotNull);
      
      // Verify EXIF data is correct
      final exifData = await ExifReader.read(result.filePath);
      expect(exifData.orientation, equals(_getExpectedExifOrientation(orientation)));
    }
  });
});

// test/integration/photo_capture_integration_test.dart
testWidgets('Photo capture integration test', (tester) async {
  app.main();
  await tester.pumpAndSettle();
  
  // Navigate to photo mode
  await tester.tap(find.text('Photo Mode'));
  await tester.pumpAndSettle();
  
  // Capture photo
  await tester.tap(find.byIcon(Icons.camera));
  await tester.pumpAndSettle();
  
  // Verify photo was captured and analyzed
  await tester.pump(Duration(seconds: 2));
  expect(find.text('Photo captured'), findsOneWidget);
});
```

### Task 6 - Video Recording with Orientation Validation
```dart
// test/unit/features/video_recording_test.dart
group('OrientationAwareVideoRecording', () {
  testWidgets('Records video with orientation tracking', (tester) async {
    final container = ProviderContainer();
    final recorder = container.read(videoRecorderProvider);
    
    // Start recording in portrait
    await recorder.startRecording();
    expect(recorder.isRecording, isTrue);
    
    // Simulate orientation change during recording
    container.read(deviceOrientationProvider.notifier)
        .updateOrientation(DeviceOrientation.landscapeLeft);
    
    await tester.pump(Duration(seconds: 2));
    
    // Stop recording
    final result = await recorder.stopRecording();
    
    expect(result.orientationChanges.length, equals(1));
    expect(result.metadata.hasOrientationTracking, isTrue);
  });
});
```

### Task 7 - Combined Mode Testing
```dart
// test/unit/features/combined_mode_test.dart
group('CombinedModeController', () {
  testWidgets('Switches between photo and video modes correctly', (tester) async {
    final container = ProviderContainer();
    final controller = container.read(combinedModeControllerProvider.notifier);
    
    // Test mode switching
    await controller.switchToPhotoMode();
    expect(controller.currentMode, equals(CameraMode.photo));
    
    await controller.switchToVideoMode();
    expect(controller.currentMode, equals(CameraMode.video));
    
    // Verify orientation state is preserved
    final orientationData = await container.read(
      deviceOrientationProvider.future
    );
    expect(orientationData, isNotNull);
  });
});
```

### Task 8 - Gallery with Orientation Verification
```dart
// test/unit/providers/gallery_providers_test.dart
group('Gallery Providers', () {
  testWidgets('Loads media with orientation analysis', (tester) async {
    final mockStorage = MockMediaStorage();
    mockStorage.addTestMedia([
      MediaItem.photo('test1.jpg', orientation: DeviceOrientation.portrait),
      MediaItem.video('test2.mp4', orientation: DeviceOrientation.landscapeLeft),
    ]);
    
    final container = ProviderContainer(
      overrides: [
        mediaStorageProvider.overrideWith((_) => mockStorage),
      ],
    );
    
    final gallery = await container.read(galleryControllerProvider.future);
    
    expect(gallery.mediaItems.length, equals(2));
    expect(gallery.orientationStats.accuracy, greaterThan(0.8));
  });
});

// test/widget/gallery_screen_test.dart
testWidgets('Gallery displays orientation accuracy badges', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: GalleryScreen()),
    ),
  );
  
  await tester.pumpAndSettle();
  
  // Verify orientation accuracy indicators
  expect(find.byType(OrientationAccuracyBadge), findsAtLeastNWidgets(1));
  expect(find.textContaining('%'), findsAtLeastNWidgets(1));
});
```

### Task 9 - Comprehensive Testing Analytics
```dart
// test/unit/analytics/testing_analytics_test.dart
group('Testing Analytics', () {
  testWidgets('Generates comprehensive reports', (tester) async {
    final container = ProviderContainer();
    final analytics = container.read(testingAnalyticsControllerProvider.notifier);
    
    final report = await analytics.generateComprehensiveReport(
      timeRange: Duration(days: 7),
    );
    
    expect(report.totalTests, greaterThan(0));
    expect(report.overallStatistics.successRate, isA<double>());
    expect(report.deviceAnalysis, isNotEmpty);
    expect(report.orientationAnalysis, isNotEmpty);
  });
  
  test('ML model training with sufficient data', () async {
    final mlService = MLOrientationService();
    
    // Mock sufficient training data
    final trainingData = List.generate(150, (i) => TestResult.mock());
    
    final model = await mlService.trainModelWithLatestData();
    
    expect(model.accuracy, greaterThan(0.7));
    expect(model.trainingDataSize, equals(150));
  });
});
```

## Orientation-Specific Testing Protocols

### Real Device Testing Matrix
```dart
// test/device_testing/orientation_device_tests.dart
class OrientationDeviceTests {
  static const testMatrix = [
    DeviceTestCase('Samsung Galaxy S21', [
      OrientationTest(DeviceOrientation.portrait, expectedAccuracy: 0.95),
      OrientationTest(DeviceOrientation.landscapeLeft, expectedAccuracy: 0.90),
      OrientationTest(DeviceOrientation.landscapeRight, expectedAccuracy: 0.90),
    ]),
    DeviceTestCase('Google Pixel 6', [
      OrientationTest(DeviceOrientation.portrait, expectedAccuracy: 0.98),
      OrientationTest(DeviceOrientation.landscapeLeft, expectedAccuracy: 0.95),
    ]),
  ];
  
  Future<void> runFullDeviceTestSuite() async {
    for (final testCase in testMatrix) {
      await _runDeviceTests(testCase);
    }
  }
}
```

## Test Data Management

### Mock Data Generation
```dart
// test/helpers/mock_data_generator.dart
class MockDataGenerator {
  static List<OrientationTestResult> generateTestResults(int count) {
    return List.generate(count, (i) => OrientationTestResult(
      testId: 'test_$i',
      deviceOrientation: DeviceOrientation.values[i % 4],
      accuracy: 0.8 + (Random().nextDouble() * 0.2),
      timestamp: DateTime.now().subtract(Duration(hours: i)),
    ));
  }
  
  static MediaItem createMockPhoto({
    required DeviceOrientation orientation,
    double accuracyScore = 0.95,
  }) {
    return MediaItem.photo(
      'mock_photo_${orientation.name}.jpg',
      orientation: orientation,
      metadata: PhotoMetadata(
        exifOrientation: _getExifOrientation(orientation),
        accuracyScore: accuracyScore,
      ),
    );
  }
}
```

## Continuous Integration Testing

### GitHub Actions Workflow
```yaml
# .github/workflows/test.yml
name: Test Suite
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Generate code
        run: dart run build_runner build
      
      - name: Run unit tests
        run: flutter test test/unit/
      
      - name: Run widget tests
        run: flutter test test/widget/
      
      - name: Run integration tests
        run: flutter test integration_test/
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

## Testing Commands & Scripts

### Development Testing Commands
```bash
# Run all tests
flutter test

# Run unit tests only
flutter test test/unit/

# Run widget tests only
flutter test test/widget/

# Run integration tests
flutter test integration_test/

# Run tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run orientation-specific tests
flutter test test/orientation/

# Run device-specific tests (requires device)
flutter test integration_test/device_tests/
```

### Test Organization
```
test/
├── unit/
│   ├── providers/
│   ├── models/
│   ├── services/
│   └── utils/
├── widget/
│   ├── screens/
│   ├── widgets/
│   └── components/
├── integration/
│   ├── app_flow_test.dart
│   ├── camera_integration_test.dart
│   └── orientation_integration_test.dart
├── device_testing/
│   ├── samsung_tests.dart
│   ├── pixel_tests.dart
│   └── generic_android_tests.dart
├── helpers/
│   ├── mock_data_generator.dart
│   ├── test_helpers.dart
│   └── orientation_test_utils.dart
└── mocks/
    ├── mock_camera_controller.dart
    ├── mock_sensors_service.dart
    └── mock_storage_service.dart
```

## Testing Success Metrics

### Code Coverage Targets
- **Unit Tests**: 90%+ coverage
- **Widget Tests**: 80%+ coverage
- **Integration Tests**: Critical paths covered
- **Overall**: 85%+ total coverage

### Orientation Accuracy Targets
- **Portrait Mode**: 95%+ accuracy
- **Landscape Modes**: 90%+ accuracy
- **Cross-device**: 85%+ average accuracy
- **Error Rate**: <5% orientation failures

## Implementation Schedule

### Progressive Testing Implementation
1. **Task 1**: Set up testing infrastructure and basic provider tests
2. **Task 2**: Add permission handling tests
3. **Task 3**: Widget tests for navigation
4. **Task 4**: Critical orientation detection tests
5. **Task 5**: Photo capture and EXIF validation tests
6. **Task 6**: Video recording orientation tests
7. **Task 7**: Combined mode testing
8. **Task 8**: Gallery and verification tests
9. **Task 9**: Comprehensive analytics and ML testing

### Testing Milestones
- [ ] Basic test infrastructure (after Task 1)
- [ ] Core orientation tests (after Task 4)
- [ ] Capture validation tests (after Tasks 5-6)
- [ ] Full integration tests (after Task 8)
- [ ] Performance and analytics tests (after Task 9)

This comprehensive testing strategy ensures that orientation accuracy is validated at every step while maintaining high code quality and reliability. 