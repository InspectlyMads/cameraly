import 'package:flutter/material.dart';

enum GridType {
  none,
  ruleOfThirds,
  grid3x3,
  grid4x4,
}

class CameraGridOverlay extends StatelessWidget {
  final GridType gridType;
  final double opacity;

  const CameraGridOverlay({
    super.key,
    this.gridType = GridType.ruleOfThirds,
    this.opacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    if (gridType == GridType.none) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: GridPainter(
          gridType: gridType,
          opacity: opacity,
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final GridType gridType;
  final double opacity;

  GridPainter({
    required this.gridType,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    switch (gridType) {
      case GridType.ruleOfThirds:
        _drawRuleOfThirds(canvas, size, paint);
        break;
      case GridType.grid3x3:
        _drawGrid(canvas, size, paint, 3);
        break;
      case GridType.grid4x4:
        _drawGrid(canvas, size, paint, 4);
        break;
      case GridType.none:
        break;
    }
  }

  void _drawRuleOfThirds(Canvas canvas, Size size, Paint paint) {
    // Draw two vertical lines
    final thirdWidth = size.width / 3;
    canvas.drawLine(
      Offset(thirdWidth, 0),
      Offset(thirdWidth, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(thirdWidth * 2, 0),
      Offset(thirdWidth * 2, size.height),
      paint,
    );

    // Draw two horizontal lines
    final thirdHeight = size.height / 3;
    canvas.drawLine(
      Offset(0, thirdHeight),
      Offset(size.width, thirdHeight),
      paint,
    );
    canvas.drawLine(
      Offset(0, thirdHeight * 2),
      Offset(size.width, thirdHeight * 2),
      paint,
    );

    // Optional: Draw power points (intersections) with slightly thicker circles
    final powerPointPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const radius = 4.0;
    final points = [
      Offset(thirdWidth, thirdHeight),
      Offset(thirdWidth * 2, thirdHeight),
      Offset(thirdWidth, thirdHeight * 2),
      Offset(thirdWidth * 2, thirdHeight * 2),
    ];

    for (final point in points) {
      canvas.drawCircle(point, radius, powerPointPaint);
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint, int divisions) {
    final cellWidth = size.width / divisions;
    final cellHeight = size.height / divisions;

    // Draw vertical lines
    for (int i = 1; i < divisions; i++) {
      final x = cellWidth * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (int i = 1; i < divisions; i++) {
      final y = cellHeight * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.gridType != gridType || oldDelegate.opacity != opacity;
  }
}

// Grid type selector widget for settings
class GridTypeSelector extends StatelessWidget {
  final GridType selectedType;
  final ValueChanged<GridType> onChanged;

  const GridTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _GridTypeButton(
          type: GridType.none,
          isSelected: selectedType == GridType.none,
          onTap: () => onChanged(GridType.none),
        ),
        _GridTypeButton(
          type: GridType.ruleOfThirds,
          isSelected: selectedType == GridType.ruleOfThirds,
          onTap: () => onChanged(GridType.ruleOfThirds),
        ),
        _GridTypeButton(
          type: GridType.grid3x3,
          isSelected: selectedType == GridType.grid3x3,
          onTap: () => onChanged(GridType.grid3x3),
        ),
        _GridTypeButton(
          type: GridType.grid4x4,
          isSelected: selectedType == GridType.grid4x4,
          onTap: () => onChanged(GridType.grid4x4),
        ),
      ],
    );
  }
}

class _GridTypeButton extends StatelessWidget {
  final GridType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _GridTypeButton({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: CustomPaint(
          painter: _MiniGridPainter(
            type: type,
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _MiniGridPainter extends CustomPainter {
  final GridType type;
  final Color color;

  _MiniGridPainter({
    required this.type,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final padding = 12.0;
    final drawSize = Size(
      size.width - padding * 2,
      size.height - padding * 2,
    );
    final offset = Offset(padding, padding);

    canvas.translate(offset.dx, offset.dy);

    switch (type) {
      case GridType.none:
        // Draw an X
        canvas.drawLine(
          Offset.zero,
          Offset(drawSize.width, drawSize.height),
          paint,
        );
        canvas.drawLine(
          Offset(drawSize.width, 0),
          Offset(0, drawSize.height),
          paint,
        );
        break;
      case GridType.ruleOfThirds:
        _drawMiniGrid(canvas, drawSize, paint, 3, true);
        break;
      case GridType.grid3x3:
        _drawMiniGrid(canvas, drawSize, paint, 3, false);
        break;
      case GridType.grid4x4:
        _drawMiniGrid(canvas, drawSize, paint, 4, false);
        break;
    }
  }

  void _drawMiniGrid(Canvas canvas, Size size, Paint paint, int divisions, bool withDots) {
    final cellWidth = size.width / divisions;
    final cellHeight = size.height / divisions;

    // Draw vertical lines
    for (int i = 1; i < divisions; i++) {
      final x = cellWidth * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (int i = 1; i < divisions; i++) {
      final y = cellHeight * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw dots for rule of thirds
    if (withDots && divisions == 3) {
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      const radius = 2.0;
      for (int i = 1; i < divisions; i++) {
        for (int j = 1; j < divisions; j++) {
          canvas.drawCircle(
            Offset(cellWidth * i, cellHeight * j),
            radius,
            dotPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MiniGridPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}