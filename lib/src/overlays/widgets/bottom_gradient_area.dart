import 'package:flutter/material.dart';

class BottomGradientArea extends StatelessWidget {
  const BottomGradientArea({
    super.key,
    required this.isLandscape,
    required this.child,
  });

  final bool isLandscape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isLandscape ? 120 : double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.fromRGBO(0, 0, 0, 0.95),
            Color.fromRGBO(0, 0, 0, 0.8),
            Color.fromRGBO(0, 0, 0, 0.5),
            Colors.transparent,
          ],
        ),
        color: Colors.black.withAlpha(77),
      ),
      child: child,
    );
  }
}
