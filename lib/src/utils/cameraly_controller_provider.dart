import 'package:cameraly/cameraly.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// A widget that provides access to a [CameralyController] to its descendants.
///
/// This is useful for sharing a controller between multiple widgets in a subtree.
class CameralyControllerProvider extends InheritedWidget {
  /// Creates a [CameralyControllerProvider] widget.
  const CameralyControllerProvider({
    required this.controller,
    required super.child,
    super.key,
  });

  /// The controller instance to provide to descendants.
  final CameralyController controller;

  /// Gets the controller from the closest [CameralyControllerProvider] ancestor.
  static CameralyController? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CameralyControllerProvider>()?.controller;
  }

  @override
  bool updateShouldNotify(CameralyControllerProvider oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// A modern Provider-based implementation for camera state management
/// that enables more efficient rebuilds
class CameralyProvider extends StatelessWidget {
  /// Creates a Provider wrapper for camera state
  const CameralyProvider({
    required this.controller,
    required this.child,
    this.autoDispose = false,
    super.key,
  });

  /// The camera controller
  final CameralyController controller;

  /// The child widget
  final Widget child;

  /// Whether to auto-dispose the controller when provider is removed
  final bool autoDispose;

  @override
  Widget build(BuildContext context) {
    // Use MultiProvider to provide multiple camera-related values
    return MultiProvider(
      providers: [
        // Provide the controller itself
        Provider<CameralyController>.value(value: controller),

        // Provide the camera value for more granular rebuilds
        ChangeNotifierProvider<ValueNotifier<CameralyValue>>.value(
          value: controller,
        ),

        // Provide direct access to CameralyValue with ValueListenable
        ProxyProvider<ValueNotifier<CameralyValue>, CameralyValue>(
          update: (_, notifier, __) => notifier.value,
        ),

        // Wrap with existing InheritedWidget for backward compatibility
        Provider<CameralyControllerProvider>(
          create: (_) => CameralyControllerProvider(
            controller: controller,
            child: Container(), // Placeholder, not used
          ),
          dispose: autoDispose ? (_, __) => controller.dispose() : null,
        ),
      ],
      child: child,
    );
  }
}

/// Extension methods for easy camera state access
extension CameralyContextExtension on BuildContext {
  /// Get the camera controller from context
  CameralyController get cameraController => read<CameralyController>();

  /// Get the current camera value
  CameralyValue get cameraValue => read<CameralyValue>();

  /// Watch only the camera initialization state for selective rebuilds
  bool get isInitialized => select<CameralyValue, bool>((value) => value.isInitialized);

  /// Watch only the camera recording state for selective rebuilds
  bool get isRecording => select<CameralyValue, bool>((value) => value.isRecordingVideo);

  /// Watch only the flash mode for selective rebuilds
  FlashMode get flashMode => select<CameralyValue, FlashMode>((value) => value.flashMode);

  /// Watch only the front/back camera state for selective rebuilds
  bool get isFrontCamera => select<CameralyValue, bool>((value) => value.isFrontCamera);
}

/// A widget that only rebuilds when specific camera properties change
class CameralyConsumer extends StatelessWidget {
  /// Creates a widget that efficiently rebuilds only when needed camera properties change
  const CameralyConsumer({
    required this.builder,
    this.listenToInitialization = true,
    this.listenToRecording = false,
    this.listenToFlashMode = false,
    this.listenToCameraDirection = false,
    this.listenToOrientation = false,
    this.listenToZoom = false,
    this.listenToAll = false,
    super.key,
  });

  /// Builder function that receives camera state
  final Widget Function(BuildContext context, CameralyValue value, CameralyController controller) builder;

  /// Whether to listen to camera initialization changes
  final bool listenToInitialization;

  /// Whether to listen to recording state changes
  final bool listenToRecording;

  /// Whether to listen to flash mode changes
  final bool listenToFlashMode;

  /// Whether to listen to camera direction changes (front/back)
  final bool listenToCameraDirection;

  /// Whether to listen to orientation changes
  final bool listenToOrientation;

  /// Whether to listen to zoom level changes
  final bool listenToZoom;

  /// Whether to listen to all camera state changes
  final bool listenToAll;

  @override
  Widget build(BuildContext context) {
    // If listening to all properties, use a simple Consumer
    if (listenToAll) {
      return Consumer<CameralyValue>(
        builder: (context, value, _) {
          final controller = context.read<CameralyController>();
          return builder(context, value, controller);
        },
      );
    }

    // Use Selector widgets for more granular rebuilds
    Widget result = Builder(
      builder: (context) {
        final controller = context.read<CameralyController>();
        final value = context.read<CameralyValue>();
        return builder(context, value, controller);
      },
    );

    // Wrap with selectors based on which properties to watch
    if (listenToZoom) {
      result = Selector<CameralyValue, double>(
        selector: (_, value) => value.zoomLevel,
        builder: (context, _, child) => child!,
        child: result,
      );
    }

    if (listenToOrientation) {
      result = Selector<CameralyValue, DeviceOrientation>(
        selector: (_, value) => value.deviceOrientation,
        builder: (context, _, child) => child!,
        child: result,
      );
    }

    if (listenToCameraDirection) {
      result = Selector<CameralyValue, bool>(
        selector: (_, value) => value.isFrontCamera,
        builder: (context, _, child) => child!,
        child: result,
      );
    }

    if (listenToFlashMode) {
      result = Selector<CameralyValue, FlashMode>(
        selector: (_, value) => value.flashMode,
        builder: (context, _, child) => child!,
        child: result,
      );
    }

    if (listenToRecording) {
      result = Selector<CameralyValue, bool>(
        selector: (_, value) => value.isRecordingVideo,
        builder: (context, _, child) => child!,
        child: result,
      );
    }

    if (listenToInitialization) {
      result = Selector<CameralyValue, bool>(
        selector: (_, value) => value.isInitialized,
        builder: (context, _, child) => child!,
        child: result,
      );
    }

    return result;
  }
}
