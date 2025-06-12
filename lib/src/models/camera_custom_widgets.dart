import 'package:flutter/material.dart';

/// Configuration for custom widgets in the camera screen
class CameraCustomWidgets {
  /// Custom widget for the gallery button
  final Widget? galleryButton;
  
  /// Custom widget for the check/confirm button
  final Widget? checkButton;
  
  /// Custom widget for the left side of the camera screen
  /// (displayed on the left in portrait mode, top in landscape mode)
  final Widget? leftSideWidget;
  
  /// Custom widget for the right side of the camera screen
  /// (displayed on the right in portrait mode, bottom in landscape mode)
  final Widget? rightSideWidget;
  
  /// Custom widget for the mode switcher
  final Widget? modeSwitcher;
  
  /// Custom widget for flash control
  final Widget? flashControl;
  
  /// Custom widget for camera switcher (front/back)
  final Widget? cameraSwitcher;
  
  /// Custom widget for grid toggle button
  final Widget? gridToggle;

  const CameraCustomWidgets({
    this.galleryButton,
    this.checkButton,
    this.leftSideWidget,
    this.rightSideWidget,
    this.modeSwitcher,
    this.flashControl,
    this.cameraSwitcher,
    this.gridToggle,
  });
  
  /// Create a copy with updated values
  CameraCustomWidgets copyWith({
    Widget? galleryButton,
    Widget? checkButton,
    Widget? leftSideWidget,
    Widget? rightSideWidget,
    Widget? modeSwitcher,
    Widget? flashControl,
    Widget? cameraSwitcher,
    Widget? gridToggle,
  }) {
    return CameraCustomWidgets(
      galleryButton: galleryButton ?? this.galleryButton,
      checkButton: checkButton ?? this.checkButton,
      leftSideWidget: leftSideWidget ?? this.leftSideWidget,
      rightSideWidget: rightSideWidget ?? this.rightSideWidget,
      modeSwitcher: modeSwitcher ?? this.modeSwitcher,
      flashControl: flashControl ?? this.flashControl,
      cameraSwitcher: cameraSwitcher ?? this.cameraSwitcher,
      gridToggle: gridToggle ?? this.gridToggle,
    );
  }
}

/// Builder function type for custom widgets that need context
typedef CameraWidgetBuilder = Widget Function(BuildContext context);

/// Configuration for custom widget builders (when widgets need runtime context)
class CameraCustomWidgetBuilders {
  /// Builder for the gallery button
  final CameraWidgetBuilder? galleryButtonBuilder;
  
  /// Builder for the check/confirm button
  final CameraWidgetBuilder? checkButtonBuilder;
  
  /// Builder for the left side widget
  final CameraWidgetBuilder? leftSideWidgetBuilder;
  
  /// Builder for the right side widget
  final CameraWidgetBuilder? rightSideWidgetBuilder;
  
  /// Builder for the mode switcher
  final CameraWidgetBuilder? modeSwitcherBuilder;
  
  /// Builder for flash control
  final CameraWidgetBuilder? flashControlBuilder;
  
  /// Builder for camera switcher
  final CameraWidgetBuilder? cameraSwitcherBuilder;
  
  /// Builder for grid toggle
  final CameraWidgetBuilder? gridToggleBuilder;

  const CameraCustomWidgetBuilders({
    this.galleryButtonBuilder,
    this.checkButtonBuilder,
    this.leftSideWidgetBuilder,
    this.rightSideWidgetBuilder,
    this.modeSwitcherBuilder,
    this.flashControlBuilder,
    this.cameraSwitcherBuilder,
    this.gridToggleBuilder,
  });
}