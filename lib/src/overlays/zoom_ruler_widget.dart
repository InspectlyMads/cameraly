import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A customizable zoom ruler widget that displays a scale with a fixed central indicator.
///
/// This widget shows a horizontal ruler with tick marks for different zoom levels,
/// with a fixed indicator in the center showing the current angle of view.
/// The ruler animates in when zoom changes and automatically hides after a delay.
class ZoomRulerWidget extends StatefulWidget {
  /// Creates a new ZoomRulerWidget.
  const ZoomRulerWidget({
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    this.onZoomChanged,
    this.availableZoomLevels = const [0.5, 1.0, 2.0, 3.0],
    this.hideDelay = const Duration(seconds: 3),
    this.thumbIndicatorSize = 30.0,
    this.rulerHeight = 50.0,
    this.rulerWidth = 300.0,
    this.fadeAnimationDuration = const Duration(milliseconds: 150),
    this.showAngle = true,
    this.angleValue = 5,
    this.trackColor = Colors.white,
    this.trackWidth = 2.0,
    super.key,
  });

  /// The current zoom level of the camera.
  final double currentZoom;

  /// The minimum zoom level allowed.
  final double minZoom;

  /// The maximum zoom level allowed.
  final double maxZoom;

  /// Callback when zoom level is changed via the ruler.
  final Function(double)? onZoomChanged;

  /// Available preset zoom levels to mark on the ruler.
  final List<double> availableZoomLevels;

  /// The delay after which the ruler auto-hides.
  final Duration hideDelay;

  /// The size of the center indicator.
  final double thumbIndicatorSize;

  /// The height of the ruler.
  final double rulerHeight;

  /// The width of the ruler.
  final double rulerWidth;

  /// The duration of the fade animation.
  final Duration fadeAnimationDuration;

  /// Whether to show the angle indicator.
  final bool showAngle;

  /// The angle value to display.
  final int angleValue;

  /// The color of the ruler track.
  final Color trackColor;

  /// The width of the ruler track.
  final double trackWidth;

  @override
  State<ZoomRulerWidget> createState() => _ZoomRulerWidgetState();
}

class _ZoomRulerWidgetState extends State<ZoomRulerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _hideTimer;

  // Track pan gesture for manual zoom adjustment
  double _dragStartZoom = 1.0;
  double _lastZoom = 1.0;
  double _rulerOffset = 0.0;

  // Track if we're currently in a snap zone to prevent repeated haptic feedback
  bool _isInSnapZone = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for fade in/out
    _animationController = AnimationController(
      vsync: this,
      duration: widget.fadeAnimationDuration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Show the ruler immediately on creation
    _animationController.forward();
    _startHideTimer();

    _lastZoom = widget.currentZoom;
    _updateRulerOffset();
  }

  @override
  void didUpdateWidget(ZoomRulerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If zoom level changed, show the ruler again
    if (oldWidget.currentZoom != widget.currentZoom) {
      _showRuler();
      _lastZoom = widget.currentZoom;
      _updateRulerOffset();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// Shows the ruler and starts the hide timer.
  void _showRuler() {
    _hideTimer?.cancel();
    _animationController.forward();
    _startHideTimer();
  }

  /// Starts the timer to auto-hide the ruler.
  void _startHideTimer() {
    _hideTimer = Timer(widget.hideDelay, () {
      if (mounted) {
        _animationController.reverse();
      }
    });
  }

  /// Updates the ruler offset based on current zoom.
  void _updateRulerOffset() {
    // Get the zoom range and available width
    final double zoomRange = widget.maxZoom - widget.minZoom;
    final double totalWidth = widget.rulerWidth * 2.0;

    // Calculate normalized position of current zoom within the range
    final double normalizedZoom = (widget.currentZoom - widget.minZoom) / zoomRange;

    // Calculate offset so that current zoom position is centered
    // The totalWidth * normalizedZoom gives us the absolute position
    // Then we subtract half the width to center it
    _rulerOffset = -(normalizedZoom * totalWidth - (widget.rulerWidth / 2));
  }

  /// Formats the zoom value for display.
  String _formatZoomValue(double value) {
    if (value >= 1.0) {
      return '${value.toStringAsFixed(1)}×';
    } else {
      // Remove leading zero for values less than 1
      return '.${(value * 10).toStringAsFixed(0)}×';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always update the ruler offset when building to ensure it's correct
    _updateRulerOffset();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stack for ruler and fixed center indicator
          Stack(
            alignment: Alignment.center,
            children: [
              // Ruler track with tick marks - Add a larger hit area
              Container(
                width: widget.rulerWidth,
                // Make touch area taller than visual ruler for easier interaction
                height: widget.rulerHeight + 30,
                color: Colors.transparent,
                child: GestureDetector(
                  // Use a behavior that doesn't require hitting exactly on the ruler
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (details) {
                    _dragStartZoom = widget.currentZoom;
                    _hideTimer?.cancel();

                    // Provide haptic feedback when drag starts
                    HapticFeedback.selectionClick();
                  },
                  onHorizontalDragUpdate: (details) {
                    if (widget.onZoomChanged != null) {
                      // Calculate zoom change based on drag distance
                      final double dragDistance = details.delta.dx;

                      // Significantly reduce sensitivity by using a much lower multiplier
                      // Negate the dragDistance to mirror the gesture (left increases zoom, right decreases)
                      final double zoomDelta = -dragDistance * 0.5 * (widget.maxZoom - widget.minZoom) / widget.rulerWidth;

                      // Calculate new zoom level - now dragging left increases zoom, right decreases
                      double newZoom = _dragStartZoom + zoomDelta;

                      // Check if we need to snap to an integer value
                      final double originalZoom = newZoom;
                      const double snapThreshold = 0.03; // 3% threshold
                      final double fractionalPart = newZoom - newZoom.floor();
                      final double distanceToNextInteger = 1.0 - fractionalPart;

                      bool wasSnapped = false;

                      // Check if we're close to an integer value - either the floor or ceiling
                      if (fractionalPart < snapThreshold) {
                        // Close to lower integer (e.g., 1.97 → 1.0)
                        newZoom = newZoom.floor().toDouble();
                        wasSnapped = true;

                        // Only provide haptic feedback when entering the snap zone from outside
                        if (!_isInSnapZone) {
                          HapticFeedback.selectionClick();
                          _isInSnapZone = true;
                        }
                      } else if (distanceToNextInteger < snapThreshold) {
                        // Close to upper integer (e.g., 2.03 → 2.0)
                        newZoom = newZoom.ceil().toDouble();
                        wasSnapped = true;

                        // Only provide haptic feedback when entering the snap zone from outside
                        if (!_isInSnapZone) {
                          HapticFeedback.selectionClick();
                          _isInSnapZone = true;
                        }
                      } else {
                        // We're not in a snap zone anymore
                        _isInSnapZone = false;
                      }

                      // Clamp to min/max zoom
                      newZoom = newZoom.clamp(widget.minZoom, widget.maxZoom);

                      // Add haptic feedback when crossing major zoom levels
                      for (final zoomLevel in widget.availableZoomLevels) {
                        if ((_lastZoom < zoomLevel && newZoom >= zoomLevel) || (_lastZoom > zoomLevel && newZoom <= zoomLevel)) {
                          HapticFeedback.lightImpact();
                          break;
                        }
                      }

                      // CRITICAL FIX: Update the ruler position FIRST before calling widget.onZoomChanged
                      // This ensures the ruler position updates in real-time during dragging
                      setState(() {
                        // Save last zoom for comparison in next update
                        _lastZoom = newZoom;

                        // Calculate new ruler offset - use the same logic as _updateRulerOffset
                        final zoomRange = widget.maxZoom - widget.minZoom;
                        final totalWidth = widget.rulerWidth * 2.0;
                        final normalizedZoom = (newZoom - widget.minZoom) / zoomRange;
                        _rulerOffset = -(normalizedZoom * totalWidth - (widget.rulerWidth / 2));
                      });

                      // THEN update the camera zoom after ruler position has been updated
                      widget.onZoomChanged!(newZoom);

                      // Update drag start zoom incrementally to make continuous dragging smoother
                      _dragStartZoom = newZoom;
                    }
                  },
                  onHorizontalDragEnd: (_) {
                    // Provide haptic feedback when drag ends
                    HapticFeedback.selectionClick();

                    // Reset snap zone tracking for next drag
                    _isInSnapZone = false;

                    _startHideTimer();
                  },
                  onTap: () {
                    _showRuler();
                  },
                  // Add long press gesture for accessibility
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    // Reset to 1.0x zoom on long press
                    if (widget.onZoomChanged != null) {
                      widget.onZoomChanged!(1.0);
                    }
                  },
                  child: CustomPaint(
                    size: Size(widget.rulerWidth, widget.rulerHeight),
                    painter: RulerPainter(
                      currentZoom: widget.currentZoom,
                      minZoom: widget.minZoom,
                      maxZoom: widget.maxZoom,
                      availableZoomLevels: widget.availableZoomLevels,
                      offset: _rulerOffset,
                      trackColor: widget.trackColor,
                      trackWidth: widget.trackWidth,
                    ),
                  ),
                ),
              ),

              // Fixed center indicator
              if (widget.showAngle)
                Container(
                  width: widget.thumbIndicatorSize,
                  height: widget.thumbIndicatorSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.angleValue}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Vertical center line
              Container(
                height: widget.rulerHeight,
                width: 1,
                color: Colors.white,
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Current zoom value text
          Text(
            _formatZoomValue(widget.currentZoom),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for drawing the ruler scale with tick marks.
class RulerPainter extends CustomPainter {
  RulerPainter({
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.availableZoomLevels,
    required this.offset,
    required this.trackColor,
    required this.trackWidth,
  });

  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final List<double> availableZoomLevels;
  final double offset;
  final Color trackColor;
  final double trackWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = trackColor
      ..strokeWidth = trackWidth
      ..style = PaintingStyle.stroke;

    // Define a fill paint for highlighting current zoom
    final fillPaint = Paint()
      ..color = trackColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      color: trackColor,
      fontSize: 13,
      fontWeight: FontWeight.normal,
    );

    // Draw the horizontal track line
    final centerY = size.height / 2;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint,
    );

    // Calculate the total scale width and range
    final totalWidth = size.width * 2.0;
    final zoomRange = maxZoom - minZoom;

    // Draw tick marks for available zoom levels
    for (final zoomLevel in availableZoomLevels) {
      // Skip if outside our min/max range
      if (zoomLevel < minZoom || zoomLevel > maxZoom) continue;

      // Calculate position for this zoom level using same offset logic
      final normalizedPosition = (zoomLevel - minZoom) / zoomRange;
      final xPos = normalizedPosition * totalWidth + offset;

      // Only draw if in visible area
      if (xPos >= 0 && xPos <= size.width) {
        // Check if this tick mark is close to current zoom
        final isCurrentZoom = (zoomLevel - currentZoom).abs() < 0.1;

        // Draw the tick mark (taller for current zoom)
        final tickHeight = isCurrentZoom ? 15.0 : 10.0;

        // Use a thicker line for major ticks
        paint.strokeWidth = isCurrentZoom ? trackWidth * 2.0 : trackWidth;

        canvas.drawLine(
          Offset(xPos, centerY - tickHeight),
          Offset(xPos, centerY + tickHeight),
          paint,
        );

        // Draw highlight circle for current zoom
        if (isCurrentZoom) {
          canvas.drawCircle(
            Offset(xPos, centerY),
            4.0,
            fillPaint,
          );
        }

        // Draw the zoom level text with bolder font if current zoom
        final textSpan = TextSpan(
          text: zoomLevel % 1 == 0 ? '${zoomLevel.toInt()}' : '.${(zoomLevel * 10).toInt()}',
          style: textStyle.copyWith(
            fontWeight: isCurrentZoom ? FontWeight.bold : FontWeight.normal,
            fontSize: isCurrentZoom ? 14.0 : 13.0,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(xPos - textPainter.width / 2, centerY + 18),
        );
      }
    }

    // Draw minor tick marks (avoid using startZoom-endZoom ranges for better precision)
    const tickCount = 5; // Define number of minor ticks between major divisions
    final totalTicks = ((maxZoom - minZoom) * tickCount).floor();
    final tickInterval = zoomRange / totalTicks;

    // Draw all small ticks at regular intervals
    for (int i = 0; i <= totalTicks; i++) {
      final tickZoom = minZoom + (i * tickInterval);

      // Skip if on a major tick or out of range
      if (availableZoomLevels.any((z) => (z - tickZoom).abs() < 0.01) || tickZoom < minZoom || tickZoom > maxZoom) {
        continue;
      }

      // Calculate position
      final normalizedPosition = (tickZoom - minZoom) / zoomRange;
      final xPos = normalizedPosition * totalWidth + offset;

      // Only draw if in visible area
      if (xPos >= 0 && xPos <= size.width) {
        // Check if this minor tick is close to current zoom
        final isCurrentZoom = (tickZoom - currentZoom).abs() < 0.05;

        // Draw smaller tick mark
        paint.strokeWidth = isCurrentZoom ? trackWidth * 0.75 : trackWidth / 2;
        final minorTickHeight = isCurrentZoom ? 8.0 : 5.0;

        canvas.drawLine(
          Offset(xPos, centerY - minorTickHeight),
          Offset(xPos, centerY + minorTickHeight),
          paint,
        );

        // Draw tiny highlight for current zoom on minor ticks
        if (isCurrentZoom) {
          canvas.drawCircle(
            Offset(xPos, centerY),
            2.0,
            fillPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(RulerPainter oldDelegate) {
    return oldDelegate.currentZoom != currentZoom || oldDelegate.offset != offset;
  }
}
