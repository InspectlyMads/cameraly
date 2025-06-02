// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$availableCamerasHash() => r'256b2b680b6ef3c5fe4415df16114118957564e0';

/// See also [availableCameras].
@ProviderFor(availableCameras)
final availableCamerasProvider =
    AutoDisposeFutureProvider<List<CameraDescription>>.internal(
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
    = AutoDisposeFutureProviderRef<List<CameraDescription>>;
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
    r'c713ef41d340357473036f6daffc5f529027720b';

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
String _$flashModeIconHash() => r'882151b0567e356ee891977831474955cedc6750';

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
String _$cameraControllerHash() => r'cd899a2567e2b62f373dfed8bb5a2b5ca3b19a93';

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
