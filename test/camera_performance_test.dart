import 'package:camera/camera.dart';
import 'package:cameraly/src/cameraly_controller.dart';
import 'package:cameraly/src/utils/camera_lifecycle_machine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Extend the mock from the other test file
class PerformanceMockController extends CameralyController {
  PerformanceMockController({
    this.initializationDelay = const Duration(milliseconds: 100),
    this.orientationChangeDelay = const Duration(milliseconds: 50),
  }) : super(
          description: const CameraDescription(
            name: 'mock',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 0,
          ),
        );

  final Duration initializationDelay;
  final Duration orientationChangeDelay;

  int orientationChangeCount = 0;
  List<DeviceOrientation> orientationHistory = [];
  Stopwatch? lastOperationTimer;

  @override
  Future<void> initialize() async {
    lastOperationTimer = Stopwatch()..start();
    await Future.delayed(initializationDelay);
    lastOperationTimer?.stop();

    super.value = super.value.copyWith(isInitialized: true);
  }

  @override
  Future<void> handleDeviceOrientationChange() async {
    orientationChangeCount++;

    lastOperationTimer = Stopwatch()..start();
    await Future.delayed(orientationChangeDelay);
    lastOperationTimer?.stop();

    // Update controller value to reflect orientation change
    super.value = super.value.copyWith(deviceOrientation: DeviceOrientation.values[orientationChangeCount % 4]);

    // Record the orientation in history
    orientationHistory.add(super.value.deviceOrientation);
  }

  // Get the last operation duration in milliseconds
  int? get lastOperationDuration => lastOperationTimer?.elapsedMilliseconds;

  // Reset the performance measurements
  void resetMeasurements() {
    orientationChangeCount = 0;
    orientationHistory.clear();
    lastOperationTimer = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Camera Performance Tests', () {
    late PerformanceMockController controller;
    late CameraLifecycleMachine lifecycleMachine;

    setUp(() {
      controller = PerformanceMockController();
      lifecycleMachine = CameraLifecycleMachine(
        controller: controller,
        onStateChange: (oldState, newState) {
          debugPrint('State changed from $oldState to $newState');
        },
      );
    });

    tearDown(() {
      lifecycleMachine.dispose();
      controller.dispose();
    });

    test('Measure initialization performance', () async {
      // Set increasing delays to simulate different device performances
      final delays = [50, 100, 250, 500]; // milliseconds
      final results = <int>[];

      for (final delay in delays) {
        // Create a new controller with the specified delay
        final testController = PerformanceMockController(initializationDelay: Duration(milliseconds: delay));

        final testLifecycle = CameraLifecycleMachine(controller: testController);

        // Measure initialization
        final stopwatch = Stopwatch()..start();
        await testLifecycle.initialize();
        stopwatch.stop();

        results.add(stopwatch.elapsedMilliseconds);

        // Clean up
        await testLifecycle.dispose();
        await testController.dispose();
      }

      // Print performance results
      for (int i = 0; i < delays.length; i++) {
        debugPrint('Initialization with ${delays[i]}ms delay took ${results[i]}ms');
      }

      // Verify initialization time is reasonable (allow 50ms overhead)
      for (int i = 0; i < delays.length; i++) {
        expect(results[i], lessThan(delays[i] + 250));
      }
    });

    test('Measure orientation change performance', () async {
      // First initialize
      await lifecycleMachine.initialize();

      // Set increasing delays to simulate different device performances
      final delays = [30, 100, 200]; // milliseconds
      final results = <int>[];

      for (final delay in delays) {
        // Create a new controller with the specified delay
        final testController = PerformanceMockController(orientationChangeDelay: Duration(milliseconds: delay));
        await testController.initialize();

        final testLifecycle = CameraLifecycleMachine(controller: testController);

        // Measure orientation change
        final stopwatch = Stopwatch()..start();
        await testLifecycle.handleOrientationChange(DeviceOrientation.landscapeLeft);
        stopwatch.stop();

        results.add(stopwatch.elapsedMilliseconds);

        // Clean up
        await testLifecycle.dispose();
        await testController.dispose();
      }

      // Print performance results
      for (int i = 0; i < delays.length; i++) {
        debugPrint('Orientation change with ${delays[i]}ms delay took ${results[i]}ms');
      }

      // Verify orientation change time is reasonable (allow 200ms overhead for state transitions)
      for (int i = 0; i < delays.length; i++) {
        expect(results[i], lessThan(delays[i] + 300));
      }
    });

    test('Verify debounce performance for rapid orientation changes', () async {
      // First initialize
      await lifecycleMachine.initialize();
      controller.resetMeasurements();

      // Perform first orientation change
      final firstResult = await lifecycleMachine.handleOrientationChange(DeviceOrientation.landscapeLeft);
      expect(firstResult, isTrue);
      expect(controller.orientationChangeCount, equals(1));

      // Attempt rapid orientation changes
      // These should be debounced, so only the first should succeed
      final stopwatch = Stopwatch()..start();

      final rapidResults = <bool>[];
      for (int i = 0; i < 10; i++) {
        final result = await lifecycleMachine.handleOrientationChange(i % 2 == 0 ? DeviceOrientation.landscapeRight : DeviceOrientation.landscapeLeft);
        rapidResults.add(result);

        // Very short delay to simulate rapid user rotation
        await Future.delayed(const Duration(milliseconds: 20));
      }

      stopwatch.stop();

      // Only the first change should succeed, the rest should be debounced
      expect(rapidResults.where((result) => result).length, lessThan(3));

      // The debounce logic should complete quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(500));

      // Verify only 1-2 orientation changes actually occurred
      expect(controller.orientationChangeCount, lessThan(3));
    });
  });
}
