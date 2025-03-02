import 'package:flutter/material.dart';

class GridBackground extends StatelessWidget {
  final double gridSize;
  final Color gridColor;
  final double gridThickness;

  const GridBackground({
    Key? key,
    this.gridSize = 20.0,
    this.gridColor = Colors.grey,
    this.gridThickness = 0.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _GridPainter(
          gridSize: gridSize,
          gridColor: gridColor,
          gridThickness: gridThickness,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double gridSize;
  final Color gridColor;
  final double gridThickness;

  _GridPainter({
    required this.gridSize,
    required this.gridColor,
    required this.gridThickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = gridThickness
      ..style = PaintingStyle.stroke;

    // Draw vertical grid lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal grid lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return gridSize != oldDelegate.gridSize ||
        gridColor != oldDelegate.gridColor ||
        gridThickness != oldDelegate.gridThickness;
  }
}
