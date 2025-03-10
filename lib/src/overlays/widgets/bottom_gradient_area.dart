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
      width: isLandscape ? 140 : double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLandscape ? Alignment.centerRight : Alignment.bottomCenter,
          end: isLandscape ? Alignment.centerLeft : Alignment.topCenter,
          colors: const [
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
