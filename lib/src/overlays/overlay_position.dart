import 'package:flutter/material.dart';

/// Defines the position of an overlay element within the camera preview.
enum OverlayPosition {
  /// Top-left corner of the camera preview.
  topLeft,

  /// Top-center of the camera preview.
  topCenter,

  /// Top-right corner of the camera preview.
  topRight,

  /// Center-left of the camera preview.
  centerLeft,

  /// Center of the camera preview.
  center,

  /// Center-right of the camera preview.
  centerRight,

  /// Bottom-left corner of the camera preview.
  bottomLeft,

  /// Bottom-center of the camera preview.
  bottomCenter,

  /// Bottom-right corner of the camera preview.
  bottomRight,
}

/// Extension on [OverlayPosition] to provide alignment and position utilities.
extension OverlayPositionExtension on OverlayPosition {
  /// Gets the corresponding [Alignment] for this position.
  Alignment get alignment {
    switch (this) {
      case OverlayPosition.topLeft:
        return Alignment.topLeft;
      case OverlayPosition.topCenter:
        return Alignment.topCenter;
      case OverlayPosition.topRight:
        return Alignment.topRight;
      case OverlayPosition.centerLeft:
        return Alignment.centerLeft;
      case OverlayPosition.center:
        return Alignment.center;
      case OverlayPosition.centerRight:
        return Alignment.centerRight;
      case OverlayPosition.bottomLeft:
        return Alignment.bottomLeft;
      case OverlayPosition.bottomCenter:
        return Alignment.bottomCenter;
      case OverlayPosition.bottomRight:
        return Alignment.bottomRight;
    }
  }

  /// Gets the position as a [Positioned] widget with the specified padding.
  Positioned positioned({
    required Widget child,
    double padding = 16.0,
  }) {
    switch (this) {
      case OverlayPosition.topLeft:
        return Positioned(
          top: padding,
          left: padding,
          child: child,
        );
      case OverlayPosition.topCenter:
        return Positioned(
          top: padding,
          left: 0,
          right: 0,
          child: Center(child: child),
        );
      case OverlayPosition.topRight:
        return Positioned(
          top: padding,
          right: padding,
          child: child,
        );
      case OverlayPosition.centerLeft:
        return Positioned(
          left: padding,
          top: 0,
          bottom: 0,
          child: Center(child: child),
        );
      case OverlayPosition.center:
        return Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: Center(child: child),
        );
      case OverlayPosition.centerRight:
        return Positioned(
          right: padding,
          top: 0,
          bottom: 0,
          child: Center(child: child),
        );
      case OverlayPosition.bottomLeft:
        return Positioned(
          bottom: padding,
          left: padding,
          child: child,
        );
      case OverlayPosition.bottomCenter:
        return Positioned(
          bottom: padding,
          left: 0,
          right: 0,
          child: Center(child: child),
        );
      case OverlayPosition.bottomRight:
        return Positioned(
          bottom: padding,
          right: padding,
          child: child,
        );
    }
  }
}
