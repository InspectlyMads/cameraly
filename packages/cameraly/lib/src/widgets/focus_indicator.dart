import 'package:flutter/material.dart';

class FocusIndicator extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const FocusIndicator({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<FocusIndicator> createState() => _FocusIndicatorState();
}

class _FocusIndicatorState extends State<FocusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _innerCircleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Outer circle scale animation
    _scaleAnimation = Tween<double>(
      begin: 1.4,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    // Inner circle pulse animation
    _innerCircleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
    ));

    // Fade out animation
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    // Start animation immediately
    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 35,
      top: widget.position.dy - 35,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: SizedBox(
                width: 70,
                height: 70,
                child: CustomPaint(
                  painter: PixelFocusPainter(
                    innerCircleProgress: _innerCircleAnimation.value,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PixelFocusPainter extends CustomPainter {
  final double innerCircleProgress;

  PixelFocusPainter({
    required this.innerCircleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Shadow for better visibility
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawCircle(center, radius, shadowPaint);
    
    // Outer circle
    final outerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, radius, outerPaint);
    
    // Inner filled circle (appears with animation)
    if (innerCircleProgress > 0) {
      final innerPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2 * innerCircleProgress)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        center, 
        (radius - 8) * innerCircleProgress, 
        innerPaint,
      );
    }
    
    // Center dot with shadow
    final centerShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    
    canvas.drawCircle(center, 3, centerShadowPaint);
    
    final centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 2, centerDotPaint);
  }

  @override
  bool shouldRepaint(PixelFocusPainter oldDelegate) {
    return oldDelegate.innerCircleProgress != innerCircleProgress;
  }
}