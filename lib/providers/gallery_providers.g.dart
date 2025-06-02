// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$photoItemsHash() => r'b4c25843acf56f0bb597f6cec0b56204f6870471';

/// See also [photoItems].
@ProviderFor(photoItems)
final photoItemsProvider = AutoDisposeProvider<List<MediaItem>>.internal(
  photoItems,
  name: r'photoItemsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$photoItemsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PhotoItemsRef = AutoDisposeProviderRef<List<MediaItem>>;
String _$videoItemsHash() => r'594a8cc4c36447130127795d814e22056fe83d56';

/// See also [videoItems].
@ProviderFor(videoItems)
final videoItemsProvider = AutoDisposeProvider<List<MediaItem>>.internal(
  videoItems,
  name: r'videoItemsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$videoItemsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VideoItemsRef = AutoDisposeProviderRef<List<MediaItem>>;
String _$totalMediaCountHash() => r'ee93cc9071508acbcd5711dbc7e49040c2efcaad';

/// See also [totalMediaCount].
@ProviderFor(totalMediaCount)
final totalMediaCountProvider = AutoDisposeProvider<int>.internal(
  totalMediaCount,
  name: r'totalMediaCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalMediaCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalMediaCountRef = AutoDisposeProviderRef<int>;
String _$totalStorageUsedHash() => r'a13b8fdf4d5e271d0583bc372789605785859de9';

/// See also [totalStorageUsed].
@ProviderFor(totalStorageUsed)
final totalStorageUsedProvider = AutoDisposeFutureProvider<int>.internal(
  totalStorageUsed,
  name: r'totalStorageUsedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalStorageUsedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalStorageUsedRef = AutoDisposeFutureProviderRef<int>;
String _$formattedStorageUsedHash() =>
    r'7fb75f6ba9f2b7ef7b763cf841ea0925ecefc687';

/// See also [formattedStorageUsed].
@ProviderFor(formattedStorageUsed)
final formattedStorageUsedProvider = AutoDisposeProvider<String>.internal(
  formattedStorageUsed,
  name: r'formattedStorageUsedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$formattedStorageUsedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FormattedStorageUsedRef = AutoDisposeProviderRef<String>;
String _$galleryHash() => r'26e9c4caa53563b1da63a370f86069627e303c68';

/// See also [Gallery].
@ProviderFor(Gallery)
final galleryProvider =
    AutoDisposeNotifierProvider<Gallery, GalleryState>.internal(
  Gallery.new,
  name: r'galleryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$galleryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Gallery = AutoDisposeNotifier<GalleryState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
