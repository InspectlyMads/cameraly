import 'package:flutter/material.dart';

/// Types of placeholders available in the camera overlay
enum PlaceholderType {
  /// Placeholder for the center-left area
  centerLeft,

  /// Placeholder for the bottom overlay
  bottomOverlay,
}

/// A widget that displays a placeholder for customizable areas in the camera overlay
class PlaceholderWidget extends StatelessWidget {
  /// Creates a placeholder widget
  const PlaceholderWidget({
    super.key,
    required this.type,
  });

  /// The type of placeholder to display
  final PlaceholderType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: type == PlaceholderType.centerLeft ? 100 : double.infinity,
      height: type == PlaceholderType.centerLeft ? 80 : 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          type == PlaceholderType.centerLeft ? 'Center Left' : 'Bottom Overlay',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
