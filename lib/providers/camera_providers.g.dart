// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$availableCamerasHash() => r'a1ea977666160b93776fc02ed3e83e0f441dc8e3';

/// See also [availableCameras].
@ProviderFor(availableCameras)
final availableCamerasProvider =
    AutoDisposeFutureProvider<List<camera.CameraDescription>>.internal(
  availableCameras,
  name: r'availableCamerasProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableCamerasHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableCamerasRef
    = AutoDisposeFutureProviderRef<List<camera.CameraDescription>>;
String _$cameraHasFlashHash() => r'03d099abd2b8716b0cd1d801ba2878ed7d5137c6';

/// See also [cameraHasFlash].
@ProviderFor(cameraHasFlash)
final cameraHasFlashProvider = AutoDisposeProvider<bool>.internal(
  cameraHasFlash,
  name: r'cameraHasFlashProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cameraHasFlashHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CameraHasFlashRef = AutoDisposeProviderRef<bool>;
String _$canSwitchCameraHash() => r'2f3f062514b74e6494c5170d160d1300e414a6d2';

/// See also [canSwitchCamera].
@ProviderFor(canSwitchCamera)
final canSwitchCameraProvider = AutoDisposeProvider<bool>.internal(
  canSwitchCamera,
  name: r'canSwitchCameraProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$canSwitchCameraHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanSwitchCameraRef = AutoDisposeProviderRef<bool>;
String _$flashModeDisplayNameHash() =>
    r'3b8cf1afdeb7efe14d76450ed0efec894acf92cb';

/// See also [flashModeDisplayName].
@ProviderFor(flashModeDisplayName)
final flashModeDisplayNameProvider = AutoDisposeProvider<String>.internal(
  flashModeDisplayName,
  name: r'flashModeDisplayNameProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$flashModeDisplayNameHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FlashModeDisplayNameRef = AutoDisposeProviderRef<String>;
String _$flashModeIconHash() => r'951c4bb5bfc5ea009fb5119d80fbfd84e8388031';

/// See also [flashModeIcon].
@ProviderFor(flashModeIcon)
final flashModeIconProvider = AutoDisposeProvider<String>.internal(
  flashModeIcon,
  name: r'flashModeIconProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$flashModeIconHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FlashModeIconRef = AutoDisposeProviderRef<String>;
String _$cameraControllerHash() => r'9ea91360f8bcee82687c14125aec443af10694d0';

/// See also [CameraController].
@ProviderFor(CameraController)
final cameraControllerProvider =
    AutoDisposeNotifierProvider<CameraController, CameraState>.internal(
  CameraController.new,
  name: r'cameraControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cameraControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CameraController = AutoDisposeNotifier<CameraState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
