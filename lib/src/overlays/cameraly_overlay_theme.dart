import 'package:flutter/material.dart';

/// Theme class for styling camera overlays.
class CameralyOverlayTheme {
  /// Creates a theme for camera overlays.
  const CameralyOverlayTheme({
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.red,
    this.backgroundColor = Colors.black,
    this.opacity = 0.7,
    this.labelStyle = const TextStyle(color: Colors.white, fontSize: 14),
    this.iconSize = 24.0,
    this.buttonSize = 64.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
  });

  /// The primary color used for buttons and controls.
  final Color primaryColor;

  /// The secondary color used for recording state.
  final Color secondaryColor;

  /// The background color for controls.
  final Color backgroundColor;

  /// The opacity for control backgrounds.
  final double opacity;

  /// The text style for labels.
  final TextStyle labelStyle;

  /// The size of icons in the overlay.
  final double iconSize;

  /// The size of buttons in the overlay.
  final double buttonSize;

  /// The border radius for rectangular controls.
  final BorderRadius borderRadius;

  /// Creates a copy of this theme with the given fields replaced.
  CameralyOverlayTheme copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    double? opacity,
    TextStyle? labelStyle,
    double? iconSize,
    double? buttonSize,
    BorderRadius? borderRadius,
  }) {
    return CameralyOverlayTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      opacity: opacity ?? this.opacity,
      labelStyle: labelStyle ?? this.labelStyle,
      iconSize: iconSize ?? this.iconSize,
      buttonSize: buttonSize ?? this.buttonSize,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  /// Creates a theme by merging this theme with another.
  CameralyOverlayTheme merge(CameralyOverlayTheme? other) {
    if (other == null) return this;
    return copyWith(
      primaryColor: other.primaryColor,
      secondaryColor: other.secondaryColor,
      backgroundColor: other.backgroundColor,
      opacity: other.opacity,
      labelStyle: other.labelStyle,
      iconSize: other.iconSize,
      buttonSize: other.buttonSize,
      borderRadius: other.borderRadius,
    );
  }

  /// Creates a theme from the app's theme.
  static CameralyOverlayTheme fromContext(BuildContext context) {
    final theme = Theme.of(context);
    return CameralyOverlayTheme(
      primaryColor: theme.colorScheme.primary,
      secondaryColor: theme.colorScheme.error,
      backgroundColor: Colors.black,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.white) ?? const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CameralyOverlayTheme &&
          runtimeType == other.runtimeType &&
          primaryColor == other.primaryColor &&
          secondaryColor == other.secondaryColor &&
          backgroundColor == other.backgroundColor &&
          opacity == other.opacity &&
          labelStyle == other.labelStyle &&
          iconSize == other.iconSize &&
          buttonSize == other.buttonSize &&
          borderRadius == other.borderRadius;

  @override
  int get hashCode => primaryColor.hashCode ^ secondaryColor.hashCode ^ backgroundColor.hashCode ^ opacity.hashCode ^ labelStyle.hashCode ^ iconSize.hashCode ^ buttonSize.hashCode ^ borderRadius.hashCode;
}
