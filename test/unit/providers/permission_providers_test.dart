import 'package:camera_test/providers/permission_providers.dart';
import 'package:camera_test/services/permission_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

// Mock implementation of PermissionService for testing
class MockPermissionService extends PermissionService {
  bool _cameraGranted = false;
  bool _microphoneGranted = false;
  Map<Permission, PermissionStatus>? _lastRequestResult;

  void setCameraPermission(bool granted) {
    _cameraGranted = granted;
  }

  void setMicrophonePermission(bool granted) {
    _microphoneGranted = granted;
  }

  void setRequestResult(Map<Permission, PermissionStatus> result) {
    _lastRequestResult = result;
  }

  @override
  Future<bool> hasCameraPermission() async {
    return _cameraGranted;
  }

  @override
  Future<bool> hasMicrophonePermission() async {
    return _microphoneGranted;
  }

  @override
  Future<bool> hasAllCameraPermissions() async {
    return _cameraGranted && _microphoneGranted;
  }

  @override
  Future<CameraPermissionStatus> getCameraPermissionStatus() async {
    return CameraPermissionStatus(
      camera: _cameraGranted ? PermissionStatus.granted : PermissionStatus.denied,
      microphone: _microphoneGranted ? PermissionStatus.granted : PermissionStatus.denied,
    );
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestCameraPermissions() async {
    if (_lastRequestResult != null) {
      // Update internal state based on mock result
      _cameraGranted = _lastRequestResult![Permission.camera]?.isGranted ?? false;
      _microphoneGranted = _lastRequestResult![Permission.microphone]?.isGranted ?? false;
      return _lastRequestResult!;
    }

    return {
      Permission.camera: _cameraGranted ? PermissionStatus.granted : PermissionStatus.denied,
      Permission.microphone: _microphoneGranted ? PermissionStatus.granted : PermissionStatus.denied,
    };
  }

  @override
  Future<bool> openAppSettings() async {
    return true; // Mock successful settings opening
  }
}

void main() {
  group('Permission Providers', () {
    late MockPermissionService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = MockPermissionService();
      container = ProviderContainer(
        overrides: [
          permissionServiceProvider.overrideWith((ref) => mockService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('cameraPermissionStatusProvider', () {
      test('returns correct status when permissions are granted', () async {
        // Arrange
        mockService.setCameraPermission(true);
        mockService.setMicrophonePermission(true);

        // Act
        final status = await container.read(cameraPermissionStatusProvider.future);

        // Assert
        expect(status.isGranted, isTrue);
        expect(status.camera, PermissionStatus.granted);
        expect(status.microphone, PermissionStatus.granted);
      });

      test('returns correct status when permissions are denied', () async {
        // Arrange
        mockService.setCameraPermission(false);
        mockService.setMicrophonePermission(false);

        // Act
        final status = await container.read(cameraPermissionStatusProvider.future);

        // Assert
        expect(status.isGranted, isFalse);
        expect(status.isDenied, isTrue);
        expect(status.camera, PermissionStatus.denied);
        expect(status.microphone, PermissionStatus.denied);
      });

      test('returns mixed status when only one permission is granted', () async {
        // Arrange
        mockService.setCameraPermission(true);
        mockService.setMicrophonePermission(false);

        // Act
        final status = await container.read(cameraPermissionStatusProvider.future);

        // Assert
        expect(status.isGranted, isFalse);
        expect(status.camera, PermissionStatus.granted);
        expect(status.microphone, PermissionStatus.denied);
      });
    });

    group('hasAllPermissionsProvider', () {
      test('returns true when all permissions are granted', () async {
        // Arrange
        mockService.setCameraPermission(true);
        mockService.setMicrophonePermission(true);

        // Act
        final hasAll = await container.read(hasAllPermissionsProvider.future);

        // Assert
        expect(hasAll, isTrue);
      });

      test('returns false when any permission is denied', () async {
        // Arrange
        mockService.setCameraPermission(true);
        mockService.setMicrophonePermission(false);

        // Act
        final hasAll = await container.read(hasAllPermissionsProvider.future);

        // Assert
        expect(hasAll, isFalse);
      });

      test('returns false when all permissions are denied', () async {
        // Arrange
        mockService.setCameraPermission(false);
        mockService.setMicrophonePermission(false);

        // Act
        final hasAll = await container.read(hasAllPermissionsProvider.future);

        // Assert
        expect(hasAll, isFalse);
      });
    });

    group('PermissionRequestNotifier', () {
      test('starts with empty data state', () {
        final notifier = container.read(permissionRequestProvider.notifier);
        final state = container.read(permissionRequestProvider);

        expect(state, isA<AsyncData>());
        expect(state.asData?.value, isEmpty);
      });

      test('requests permissions successfully', () async {
        // Arrange
        mockService.setRequestResult({
          Permission.camera: PermissionStatus.granted,
          Permission.microphone: PermissionStatus.granted,
        });

        final notifier = container.read(permissionRequestProvider.notifier);

        // Act
        await notifier.requestCameraPermissions();

        // Assert
        final state = container.read(permissionRequestProvider);
        expect(state, isA<AsyncData>());

        final result = state.asData!.value;
        expect(result[Permission.camera], PermissionStatus.granted);
        expect(result[Permission.microphone], PermissionStatus.granted);
      });

      test('handles permission denial correctly', () async {
        // Arrange
        mockService.setRequestResult({
          Permission.camera: PermissionStatus.denied,
          Permission.microphone: PermissionStatus.denied,
        });

        final notifier = container.read(permissionRequestProvider.notifier);

        // Act
        await notifier.requestCameraPermissions();

        // Assert
        final state = container.read(permissionRequestProvider);
        expect(state, isA<AsyncData>());

        final result = state.asData!.value;
        expect(result[Permission.camera], PermissionStatus.denied);
        expect(result[Permission.microphone], PermissionStatus.denied);
      });

      test('shows loading state during request', () async {
        // Arrange
        mockService.setRequestResult({
          Permission.camera: PermissionStatus.granted,
          Permission.microphone: PermissionStatus.granted,
        });

        final notifier = container.read(permissionRequestProvider.notifier);

        // Act - Start request but don't await
        final future = notifier.requestCameraPermissions();

        // Assert - Should be loading
        final loadingState = container.read(permissionRequestProvider);
        expect(loadingState, isA<AsyncLoading>());

        // Complete the request
        await future;

        // Should now have data
        final dataState = container.read(permissionRequestProvider);
        expect(dataState, isA<AsyncData>());
      });

      test('reset clears the state', () async {
        // Arrange - First make a request
        mockService.setRequestResult({
          Permission.camera: PermissionStatus.granted,
          Permission.microphone: PermissionStatus.granted,
        });

        final notifier = container.read(permissionRequestProvider.notifier);
        await notifier.requestCameraPermissions();

        // Verify we have data
        final stateWithData = container.read(permissionRequestProvider);
        expect(stateWithData.asData?.value, isNotEmpty);

        // Act - Reset
        notifier.reset();

        // Assert - Should be empty again
        final resetState = container.read(permissionRequestProvider);
        expect(resetState, isA<AsyncData>());
        expect(resetState.asData?.value, isEmpty);
      });

      test('handles errors during permission request', () async {
        // Arrange - Create a service that throws an error
        final errorService = _ErrorPermissionService();
        final errorContainer = ProviderContainer(
          overrides: [
            permissionServiceProvider.overrideWith((ref) => errorService),
          ],
        );

        final notifier = errorContainer.read(permissionRequestProvider.notifier);

        // Act
        await notifier.requestCameraPermissions();

        // Assert
        final state = errorContainer.read(permissionRequestProvider);
        expect(state, isA<AsyncError>());
        expect(state.asError?.error, isA<Exception>());

        errorContainer.dispose();
      });
    });
  });

  group('CameraPermissionStatus', () {
    test('isGranted is true only when both permissions are granted', () {
      final granted = CameraPermissionStatus(
        camera: PermissionStatus.granted,
        microphone: PermissionStatus.granted,
      );

      final cameraDenied = CameraPermissionStatus(
        camera: PermissionStatus.denied,
        microphone: PermissionStatus.granted,
      );

      final micDenied = CameraPermissionStatus(
        camera: PermissionStatus.granted,
        microphone: PermissionStatus.denied,
      );

      expect(granted.isGranted, isTrue);
      expect(cameraDenied.isGranted, isFalse);
      expect(micDenied.isGranted, isFalse);
    });

    test('isDenied is true when any permission is denied', () {
      final allGranted = CameraPermissionStatus(
        camera: PermissionStatus.granted,
        microphone: PermissionStatus.granted,
      );

      final cameraDenied = CameraPermissionStatus(
        camera: PermissionStatus.denied,
        microphone: PermissionStatus.granted,
      );

      expect(allGranted.isDenied, isFalse);
      expect(cameraDenied.isDenied, isTrue);
    });

    test('toString returns formatted string', () {
      final status = CameraPermissionStatus(
        camera: PermissionStatus.granted,
        microphone: PermissionStatus.denied,
      );

      final str = status.toString();
      expect(str, contains('camera: PermissionStatus.granted'));
      expect(str, contains('microphone: PermissionStatus.denied'));
    });
  });
}

// Helper class that throws errors for testing error handling
class _ErrorPermissionService extends PermissionService {
  @override
  Future<Map<Permission, PermissionStatus>> requestCameraPermissions() async {
    throw Exception('Permission request failed');
  }
}
