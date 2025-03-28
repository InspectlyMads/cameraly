import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cameraly/src/cameraly_controller.dart';
import 'package:cameraly/src/cameraly_preview.dart';
import 'package:cameraly/src/utils/camera_lifecycle_machine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Create a mock camera controller to use in tests
class MockCameraController extends CameralyController {
  MockCameraController()
      : super(
          description: const CameraDescription(
            name: 'mock',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 0,
          ),
        );

  bool initialized = false;
  bool disposeCalled = false;
  bool handleOrientationChangeCalled = false;
  DeviceOrientation? lastSetOrientation;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 100));
    initialized = true;
    super.value = super.value.copyWith(isInitialized: true);
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
    return super.dispose();
  }

  @override
  Future<void> handleDeviceOrientationChange() async {
    handleOrientationChangeCalled = true;
    await Future.delayed(const Duration(milliseconds: 50));
    return;
  }

  @override
  Future<void> setDeviceOrientation(DeviceOrientation orientation) async {
    lastSetOrientation = orientation;
    return;
  }

  void reset() {
    initialized = false;
    disposeCalled = false;
    handleOrientationChangeCalled = false;
    lastSetOrientation = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CameraLifecycleMachine Tests', () {
    late MockCameraController mockController;
    late CameraLifecycleMachine lifecycleMachine;

    setUp(() {
      mockController = MockCameraController();
      lifecycleMachine = CameraLifecycleMachine(
        controller: mockController,
        onStateChange: (oldState, newState) {
          debugPrint('State changed from $oldState to $newState');
        },
        onError: (message, error) {
          debugPrint('Error: $message');
        },
      );
    });

    tearDown(() {
      lifecycleMachine.dispose();
      mockController.dispose();
    });

    test('Initial state should be uninitialized', () {
      expect(lifecycleMachine.currentState, equals(CameraLifecycleState.uninitialized));
    });

    test('Initialize should change state to ready when successful', () async {
      expect(lifecycleMachine.currentState, equals(CameraLifecycleState.uninitialized));

      // Start initialization
      final future = lifecycleMachine.initialize();

      // State should change to initializing immediately
      expect(lifecycleMachine.currentState, equals(CameraLifecycleState.initializing));

      // Wait for initialization to complete
      final result = await future;

      // Verify state changed to ready
      expect(result, isTrue);
      expect(lifecycleMachine.currentState, equals(CameraLifecycleState.ready));
      expect(mockController.initialized, isTrue);
    });

    test('Orientation change should work correctly', () async {
      // First initialize
      await lifecycleMachine.initialize();
      expect(lifecycleMachine.currentState, equals(CameraLifecycleState.ready));

      // Reset tracking for clarity
      mockController.handleOrientationChangeCalled = false;

      // Change orientation
      final result = await lifecycleMachine.handleOrientationChange(DeviceOrientation.landscapeLeft);

      // Verify orientation change was called
      expect(result, isTrue);
      expect(mockController.handleOrientationChangeCalled, isTrue);

      // State should return to ready
      expect(lifecycleMachine.currentState, equals(CameraLifecycleState.ready));
    });

    test('Rapid orientation changes should be debounced', () async {
      // First initialize
      await lifecycleMachine.initialize();
      expect(lifecycleMachine.currentState, equals(CameraLifecycleState.ready));

      // Change orientation
      final result1 = await lifecycleMachine.handleOrientationChange(DeviceOrientation.landscapeLeft);
      expect(result1, isTrue);

      // Reset tracking
      mockController.handleOrientationChangeCalled = false;

      // Try another change immediately - should be ignored
      final result2 = await lifecycleMachine.handleOrientationChange(DeviceOrientation.landscapeRight);
      expect(result2, isFalse);
      expect(mockController.handleOrientationChangeCalled, isFalse);
    });

    test('App lifecycle changes should be handled correctly', () async {
      // First initialize
      await lifecycleMachine.initialize();
      expect(lifecycleMachine.currentState, equals(CameraLifecycleState.ready));

      // App goes to background
      await lifecycleMachine.handleAppLifecycleChange(AppLifecycleState.inactive);
      expect(lifecycleMachine.currentState, equals(CameraLifecycleState.suspended));

      // App comes back to foreground
      final result = await lifecycleMachine.handleAppLifecycleChange(AppLifecycleState.resumed);
      expect(result, isTrue);
      expect(lifecycleMachine.currentState, equals(CameraLifecycleState.ready));
    });
  });

  group('Integration Tests', () {
    testWidgets('CameraPreview should handle orientation changes gracefully', (WidgetTester tester) async {
      // Skip on web platform
      if (!Platform.isAndroid && !Platform.isIOS) {
        return;
      }

      final mockController = MockCameraController();
      await mockController.initialize();

      // Build our widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameralyPreview(
              controller: mockController,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate orientation change
      await tester.binding.setSurfaceSize(const Size(800, 600)); // Landscape
      mockController.handleOrientationChangeCalled = false;

      // Trigger frame metric change
      tester.binding.handleMetricsChanged();
      await tester.pumpAndSettle();

      // Verify orientation change was handled
      expect(mockController.handleOrientationChangeCalled, isTrue);

      // Simulate another orientation change
      await tester.binding.setSurfaceSize(const Size(600, 800)); // Portrait
      mockController.handleOrientationChangeCalled = false;

      // Trigger frame metric change
      tester.binding.handleMetricsChanged();
      await tester.pumpAndSettle();

      // Verify orientation change was handled
      expect(mockController.handleOrientationChangeCalled, isTrue);
    });
  });
}
