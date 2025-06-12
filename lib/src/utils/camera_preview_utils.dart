import 'package:flutter/material.dart';

class CameraPreviewUtils {
  /// Calculate optimal preview size that maintains camera aspect ratio
  /// while fitting within the available screen space
  static Size calculatePreviewSize({
    required Size screenSize,
    required double cameraAspectRatio,
    required Orientation orientation,
    EdgeInsets safeArea = EdgeInsets.zero,
  }) {
    // Available space for preview (screen minus safe areas)
    final availableWidth = screenSize.width - safeArea.left - safeArea.right;
    final availableHeight = screenSize.height - safeArea.top - safeArea.bottom;

    double previewWidth;
    double previewHeight;

    if (orientation == Orientation.portrait) {
      // In portrait, camera aspect ratio is typically wider than tall
      // Try to fit width first, then check if height fits
      previewWidth = availableWidth;
      previewHeight = previewWidth / cameraAspectRatio;

      // If height is too large, scale down by height
      if (previewHeight > availableHeight) {
        previewHeight = availableHeight;
        previewWidth = previewHeight * cameraAspectRatio;
      }
    } else {
      // In landscape, try to fit height first
      previewHeight = availableHeight;
      previewWidth = previewHeight * cameraAspectRatio;

      // If width is too large, scale down by width
      if (previewWidth > availableWidth) {
        previewWidth = availableWidth;
        previewHeight = previewWidth / cameraAspectRatio;
      }
    }

    return Size(previewWidth, previewHeight);
  }

  /// Calculate padding/bezels around the preview to center it
  static EdgeInsets calculatePreviewPadding({
    required Size screenSize,
    required Size previewSize,
    EdgeInsets safeArea = EdgeInsets.zero,
  }) {
    final availableWidth = screenSize.width - safeArea.left - safeArea.right;
    final availableHeight = screenSize.height - safeArea.top - safeArea.bottom;

    final horizontalPadding = (availableWidth - previewSize.width) / 2;
    final verticalPadding = (availableHeight - previewSize.height) / 2;

    return EdgeInsets.only(
      left: safeArea.left + horizontalPadding.clamp(0, double.infinity),
      right: safeArea.right + horizontalPadding.clamp(0, double.infinity),
      top: safeArea.top + verticalPadding.clamp(0, double.infinity),
      bottom: safeArea.bottom + verticalPadding.clamp(0, double.infinity),
    );
  }

  /// Get the ideal aspect ratio for camera preview based on common camera ratios
  static double getStandardCameraAspectRatio(double rawAspectRatio) {
    // Common camera aspect ratios
    const standardRatios = [
      4.0 / 3.0, // 4:3 (1.333...)
      16.0 / 9.0, // 16:9 (1.777...)
      3.0 / 2.0, // 3:2 (1.5)
      1.0, // 1:1 (square)
    ];

    // Find the closest standard ratio
    double closestRatio = standardRatios[0];
    double smallestDifference = (rawAspectRatio - standardRatios[0]).abs();

    for (final ratio in standardRatios) {
      final difference = (rawAspectRatio - ratio).abs();
      if (difference < smallestDifference) {
        smallestDifference = difference;
        closestRatio = ratio;
      }
    }

    return closestRatio;
  }

  /// Calculate if preview should use rounded corners
  static BorderRadius getPreviewBorderRadius({
    required Size previewSize,
    required Size screenSize,
  }) {
    // Use rounded corners if preview doesn't fill the entire screen
    final isFullScreen = previewSize.width >= screenSize.width * 0.95 && previewSize.height >= screenSize.height * 0.95;

    return isFullScreen ? BorderRadius.zero : BorderRadius.circular(12);
  }

  /// Calculate optimal UI control positions outside the preview area
  static Rect getPreviewRect({
    required Size screenSize,
    required Size previewSize,
    required EdgeInsets padding,
  }) {
    return Rect.fromLTWH(
      padding.left,
      padding.top,
      previewSize.width,
      previewSize.height,
    );
  }

  /// Check if a point is within the preview area (for touch handling)
  static bool isPointInPreview({
    required Offset point,
    required Rect previewRect,
  }) {
    return previewRect.contains(point);
  }

  /// Calculate safe zones for UI controls that don't overlap with preview
  static Map<String, Rect> calculateControlZones({
    required Size screenSize,
    required Rect previewRect,
    required EdgeInsets safeArea,
  }) {
    final zones = <String, Rect>{};

    // Top zone (above preview)
    if (previewRect.top > safeArea.top + 60) {
      zones['top'] = Rect.fromLTRB(
        safeArea.left,
        safeArea.top,
        screenSize.width - safeArea.right,
        previewRect.top - 8,
      );
    }

    // Bottom zone (below preview)
    if (previewRect.bottom < screenSize.height - safeArea.bottom - 60) {
      zones['bottom'] = Rect.fromLTRB(
        safeArea.left,
        previewRect.bottom + 8,
        screenSize.width - safeArea.right,
        screenSize.height - safeArea.bottom,
      );
    }

    // Left zone (left of preview)
    if (previewRect.left > safeArea.left + 60) {
      zones['left'] = Rect.fromLTRB(
        safeArea.left,
        previewRect.top,
        previewRect.left - 8,
        previewRect.bottom,
      );
    }

    // Right zone (right of preview)
    if (previewRect.right < screenSize.width - safeArea.right - 60) {
      zones['right'] = Rect.fromLTRB(
        previewRect.right + 8,
        previewRect.top,
        screenSize.width - safeArea.right,
        previewRect.bottom,
      );
    }

    return zones;
  }
}
