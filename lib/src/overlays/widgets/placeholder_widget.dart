import 'package:flutter/material.dart';

enum PlaceholderType {
  bottomOverlay,
  topLeft,
  centerLeft,
}

class PlaceholderWidget extends StatelessWidget {
  const PlaceholderWidget({
    super.key,
    required this.type,
  });

  final PlaceholderType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: type == PlaceholderType.bottomOverlay ? 200 : 100,
      height: type == PlaceholderType.bottomOverlay ? 60 : 80,
      decoration: BoxDecoration(
        color: _getColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _getText(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getColor() {
    switch (type) {
      case PlaceholderType.bottomOverlay:
        return const Color.fromRGBO(156, 39, 176, 0.7);
      case PlaceholderType.topLeft:
      case PlaceholderType.centerLeft:
        return const Color.fromRGBO(255, 255, 255, 0.7);
    }
  }

  String _getText() {
    switch (type) {
      case PlaceholderType.bottomOverlay:
        return 'Bottom Overlay';
      case PlaceholderType.topLeft:
        return 'Top Left';
      case PlaceholderType.centerLeft:
        return 'Center Left';
    }
  }
}
