import 'package:camera_test/providers/camera_providers.dart';
import 'package:camera_test/providers/permission_providers.dart';
import 'package:camera_test/services/permission_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

// Mock permission service that simulates race condition behavior
class RaceConditionPermissionService extends PermissionService {
  bool _cameraGranted = false;
  bool _microphoneGranted = false;
  int _checkCount = 0;
  final int _racyChecksBeforeGrant;

  RaceConditionPermissionService({
    int racyChecksBeforeGrant = 2,
  }) : _racyChecksBeforeGrant = racyChecksBeforeGrant;

  void grantPermissions() {
    _cameraGranted = true;
    _microphoneGranted = true;
    _checkCount = 0; // Reset count when permissions are granted
  }

  @override
  Future<bool> hasCameraPermission() async {
    await Future.delayed(const Duration(milliseconds: 10)); // Simulate system delay
    return _cameraGranted;
  }

  @override
  Future<bool> hasMicrophonePermission() async {
    await Future.delayed(const Duration(milliseconds: 10)); // Simulate system delay
    return _microphoneGranted;
  }

  @override
  Future<bool> hasAllCameraPermissions() async {
    _checkCount++;

    // Simulate race condition: first few checks return false even after grant
    if (_cameraGranted && _microphoneGranted && _checkCount <= _racyChecksBeforeGrant) {
      return false; // Simulate race condition
    }

    final camera = await hasCameraPermission();
    final mic = await hasMicrophonePermission();
    return camera && mic;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestCameraPermissions() async {
    // Simulate permission dialog and grant
    await Future.delayed(const Duration(milliseconds: 50));
    grantPermissions();

    return {
      Permission.camera: PermissionStatus.granted,
      Permission.microphone: PermissionStatus.granted,
    };
  }

  @override
  Future<CameraPermissionStatus> getCameraPermissionStatus() async {
    final camera = await hasCameraPermission();
    final mic = await hasMicrophonePermission();

    return CameraPermissionStatus(
      camera: camera ? PermissionStatus.granted : PermissionStatus.denied,
      microphone: mic ? PermissionStatus.granted : PermissionStatus.denied,
    );
  }

  int get checkCount => _checkCount;
}

void main() {
  group('Permission Race Condition Tests', () {
    late RaceConditionPermissionService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = RaceConditionPermissionService(racyChecksBeforeGrant: 2);
      container = ProviderContainer(
        overrides: [
          permissionServiceProvider.overrideWith((ref) => mockService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('hasAllCameraPermissionsWithRetry should handle race condition', () async {
      // Arrange - Grant permissions but simulate race condition
      mockService.grantPermissions();

      // Act - Use retry method
      final hasPermissions = await mockService.hasAllCameraPermissionsWithRetry(
        maxAttempts: 3,
        delay: const Duration(milliseconds: 50),
      );

      // Assert - Should eventually return true despite race condition
      expect(hasPermissions, isTrue);
      expect(mockService.checkCount, greaterThan(2)); // Should have retried
    });

    test('hasAllCameraPermissionsWithRetry should fail if never granted', () async {
      // Arrange - Don't grant permissions

      // Act - Use retry method
      final hasPermissions = await mockService.hasAllCameraPermissionsWithRetry(
        maxAttempts: 3,
        delay: const Duration(milliseconds: 10),
      );

      // Assert - Should return false
      expect(hasPermissions, isFalse);
      expect(mockService.checkCount, equals(3)); // Should have tried 3 times
    });

    test('camera initialization should handle permission race condition', () async {
      // Arrange - Start with no permissions
      expect(await mockService.hasAllCameraPermissions(), isFalse);

      // Grant permissions (simulating user action)
      mockService.grantPermissions();

      // Act - Try to initialize camera (this would normally fail due to race condition)
      final cameraController = container.read(cameraControllerProvider.notifier);
      await cameraController.initializeCamera();

      // Assert - Should handle race condition and succeed
      final state = container.read(cameraControllerProvider);

      // Note: Since we don't have a full camera setup in tests,
      // we expect it to fail with "No cameras found" rather than permission error
      expect(state.errorMessage, isNot(contains('permissions')));
      expect(mockService.checkCount, greaterThan(1)); // Should have retried
    });

    test('permission request flow should work with delays', () async {
      // Arrange
      final permissionNotifier = container.read(permissionRequestProvider.notifier);

      // Act - Request permissions
      await permissionNotifier.requestCameraPermissions();

      // Small delay to simulate navigation timing
      await Future.delayed(const Duration(milliseconds: 100));

      // Check permissions with retry
      final hasPermissions = await mockService.hasAllCameraPermissionsWithRetry();

      // Assert
      expect(hasPermissions, isTrue);

      final requestState = container.read(permissionRequestProvider);
      expect(requestState, isA<AsyncData>());

      final result = requestState.asData!.value;
      expect(result[Permission.camera], PermissionStatus.granted);
      expect(result[Permission.microphone], PermissionStatus.granted);
    });

    test('retry mechanism with different attempt counts', () async {
      // Test with 1 attempt (should fail due to race condition)
      mockService.grantPermissions();

      final oneAttempt = await mockService.hasAllCameraPermissionsWithRetry(
        maxAttempts: 1,
        delay: const Duration(milliseconds: 10),
      );

      expect(oneAttempt, isFalse); // Race condition not resolved with 1 attempt

      // Reset and test with 5 attempts (should succeed)
      mockService.grantPermissions();

      final fiveAttempts = await mockService.hasAllCameraPermissionsWithRetry(
        maxAttempts: 5,
        delay: const Duration(milliseconds: 10),
      );

      expect(fiveAttempts, isTrue); // Should succeed with more attempts
    });
  });
}
