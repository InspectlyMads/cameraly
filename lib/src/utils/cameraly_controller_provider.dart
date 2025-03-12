import 'package:flutter/widgets.dart';

import '../cameraly_controller.dart';

/// An InheritedWidget that provides access to a [CameralyController] for its descendants.
///
/// This allows widgets lower in the tree to access the controller without having
/// it explicitly passed to them.
class CameralyControllerProvider extends InheritedWidget {
  /// Creates a [CameralyControllerProvider].
  const CameralyControllerProvider({
    required this.controller,
    required super.child,
    super.key,
  });

  /// The [CameralyController] that will be available to descendants.
  final CameralyController controller;

  /// Returns the [CameralyController] from the closest [CameralyControllerProvider]
  /// ancestor, or null if none exists.
  ///
  /// This is a convenience method that can be used by descendants to obtain the controller.
  static CameralyController? of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<CameralyControllerProvider>();
    return provider?.controller;
  }

  @override
  bool updateShouldNotify(CameralyControllerProvider oldWidget) {
    return controller != oldWidget.controller;
  }
}
