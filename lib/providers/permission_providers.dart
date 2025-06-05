import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/permission_service.dart';

// Service provider
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

// Permission status providers
final cameraPermissionStatusProvider = FutureProvider<CameraPermissionStatus>((ref) async {
  final service = ref.watch(permissionServiceProvider);
  return await service.getCameraPermissionStatus();
});

final hasAllPermissionsProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(permissionServiceProvider);
  return await service.hasAllCameraPermissions();
});

// Permission request provider
final permissionRequestProvider = StateNotifierProvider<PermissionRequestNotifier, AsyncValue<Map<Permission, PermissionStatus>>>((ref) {
  final service = ref.watch(permissionServiceProvider);
  return PermissionRequestNotifier(service);
});

class PermissionRequestNotifier extends StateNotifier<AsyncValue<Map<Permission, PermissionStatus>>> {
  final PermissionService _permissionService;

  PermissionRequestNotifier(this._permissionService) : super(const AsyncValue.data({}));

  Future<void> requestCameraPermissions() async {
    state = const AsyncValue.loading();

    try {
      final result = await _permissionService.requestCameraPermissions();
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> openAppSettings() async {
    try {
      await _permissionService.openAppSettingsScreen();
    } catch (error) {
      // Handle error if needed, but don't update state
      // as opening settings is a side effect
    }
  }

  void reset() {
    state = const AsyncValue.data({});
  }
}
