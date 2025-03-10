import 'package:flutter/material.dart';

class FocusCircle extends StatelessWidget {
  const FocusCircle({
    super.key,
    required this.position,
  });

  final Offset position;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 20,
      top: position.dy - 20,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) => Transform.scale(
          scale: 2 - value,
          child: Opacity(
            opacity: value,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                shape: BoxShape.circle,
                color: Colors.white.withAlpha((0.3 * 255).round()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
