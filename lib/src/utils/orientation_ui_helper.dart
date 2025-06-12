import 'package:flutter/material.dart';

class OrientationUIHelper {
  static bool isLandscape(Orientation orientation) {
    return orientation == Orientation.landscape;
  }

  static bool isPortrait(Orientation orientation) {
    return orientation == Orientation.portrait;
  }

  /// Calculate optimal capture button position based on orientation
  static Offset getCaptureButtonPosition({
    required Size screenSize,
    required Orientation orientation,
    required EdgeInsets safeArea,
  }) {
    if (isLandscape(orientation)) {
      // Right-center for landscape (optimized for right-hand thumb)
      return Offset(
        screenSize.width - 80 - safeArea.right - 16, // 80px button + 16px margin
        screenSize.height / 2, // Center vertically
      );
    } else {
      // Bottom-center for portrait
      return Offset(
        screenSize.width / 2, // Center horizontally
        screenSize.height - 120 - safeArea.bottom, // 120px from bottom
      );
    }
  }

  /// Get main axis alignment for controls based on orientation
  static MainAxisAlignment getControlsAlignment(Orientation orientation) {
    return isLandscape(orientation) ? MainAxisAlignment.spaceAround : MainAxisAlignment.spaceEvenly;
  }

  /// Calculate mode selector position
  static Offset getModeSelectorPosition({
    required Size screenSize,
    required Orientation orientation,
    required EdgeInsets safeArea,
  }) {
    if (isLandscape(orientation)) {
      // Bottom-center in landscape
      return Offset(
        screenSize.width / 2,
        screenSize.height - 60 - safeArea.bottom,
      );
    } else {
      // Above capture button in portrait
      return Offset(
        screenSize.width / 2,
        screenSize.height - 180 - safeArea.bottom,
      );
    }
  }

  /// Get gallery button position
  static Offset getGalleryButtonPosition({
    required Size screenSize,
    required Orientation orientation,
    required EdgeInsets safeArea,
  }) {
    if (isLandscape(orientation)) {
      // Left-center in landscape
      return Offset(
        16 + safeArea.left,
        screenSize.height / 2 - 60, // Offset above center for visual balance
      );
    } else {
      // Bottom-left in portrait (part of bottom controls)
      return Offset(
        screenSize.width * 0.2, // 20% from left
        screenSize.height - 120 - safeArea.bottom,
      );
    }
  }

  /// Get mode info position
  static Offset getModeInfoPosition({
    required Size screenSize,
    required Orientation orientation,
    required EdgeInsets safeArea,
  }) {
    if (isLandscape(orientation)) {
      // Left-center in landscape (below gallery)
      return Offset(
        16 + safeArea.left,
        screenSize.height / 2 + 20, // Offset below center
      );
    } else {
      // Bottom-right in portrait (part of bottom controls)
      return Offset(
        screenSize.width * 0.8, // 80% from left
        screenSize.height - 120 - safeArea.bottom,
      );
    }
  }

  /// Calculate top controls positioning
  static EdgeInsets getTopControlsInsets({
    required Orientation orientation,
    required EdgeInsets safeArea,
  }) {
    return EdgeInsets.only(
      top: 16 + safeArea.top,
      left: 16 + safeArea.left,
      right: 16 + safeArea.right,
    );
  }

  /// Get safe areas for UI zones that don't conflict with preview
  static Map<String, Rect> getUIZones({
    required Size screenSize,
    required Orientation orientation,
    required EdgeInsets safeArea,
  }) {
    final zones = <String, Rect>{};

    if (isLandscape(orientation)) {
      // Top zone for controls
      zones['top'] = Rect.fromLTRB(
        safeArea.left,
        safeArea.top,
        screenSize.width - safeArea.right,
        80 + safeArea.top,
      );

      // Left zone for gallery and mode info
      zones['left'] = Rect.fromLTRB(
        safeArea.left,
        80 + safeArea.top,
        100 + safeArea.left,
        screenSize.height - 80 - safeArea.bottom,
      );

      // Right zone for capture button
      zones['right'] = Rect.fromLTRB(
        screenSize.width - 120 - safeArea.right,
        80 + safeArea.top,
        screenSize.width - safeArea.right,
        screenSize.height - 80 - safeArea.bottom,
      );

      // Bottom zone for mode selector
      zones['bottom'] = Rect.fromLTRB(
        100 + safeArea.left,
        screenSize.height - 80 - safeArea.bottom,
        screenSize.width - 120 - safeArea.right,
        screenSize.height - safeArea.bottom,
      );
    } else {
      // Portrait zones
      zones['top'] = Rect.fromLTRB(
        safeArea.left,
        safeArea.top,
        screenSize.width - safeArea.right,
        80 + safeArea.top,
      );

      zones['bottom'] = Rect.fromLTRB(
        safeArea.left,
        screenSize.height - 200 - safeArea.bottom,
        screenSize.width - safeArea.right,
        screenSize.height - safeArea.bottom,
      );
    }

    return zones;
  }

  /// Calculate transition animation parameters
  static Duration getOrientationTransitionDuration() {
    return const Duration(milliseconds: 300);
  }

  static Curve getOrientationTransitionCurve() {
    return Curves.easeInOut;
  }

  /// Check if UI should be compact based on screen size
  static bool shouldUseCompactUI(Size screenSize) {
    return screenSize.width < 400 || screenSize.height < 600;
  }

  /// Get minimum touch target size for accessibility
  static double getMinTouchTargetSize() {
    return 48.0; // Material Design minimum
  }

  /// Calculate button size based on orientation and screen size
  static double getCaptureButtonSize({
    required Orientation orientation,
    required Size screenSize,
  }) {
    final compact = shouldUseCompactUI(screenSize);

    if (isLandscape(orientation)) {
      return compact ? 60.0 : 80.0;
    } else {
      return compact ? 70.0 : 80.0;
    }
  }

  /// Get control button size (flash, camera switch, etc.)
  static double getControlButtonSize({
    required Orientation orientation,
    required Size screenSize,
  }) {
    final compact = shouldUseCompactUI(screenSize);
    return compact ? 40.0 : 48.0;
  }
}
