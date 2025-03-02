import 'package:flutter/material.dart';

class AlignmentGuides extends StatelessWidget {
  final List<double> horizontalGuideLines;
  final List<double> verticalGuideLines;
  final Color guideColor;
  final double guideThickness;

  const AlignmentGuides({
    Key? key,
    required this.horizontalGuideLines,
    required this.verticalGuideLines,
    this.guideColor = Colors.blue,
    this.guideThickness = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _AlignmentGuidesPainter(
          horizontalGuideLines: horizontalGuideLines,
          verticalGuideLines: verticalGuideLines,
          guideColor: guideColor,
          guideThickness: guideThickness,
        ),
      ),
    );
  }
}

class _AlignmentGuidesPainter extends CustomPainter {
  final List<double> horizontalGuideLines;
  final List<double> verticalGuideLines;
  final Color guideColor;
  final double guideThickness;

  _AlignmentGuidesPainter({
    required this.horizontalGuideLines,
    required this.verticalGuideLines,
    required this.guideColor,
    required this.guideThickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = guideColor
      ..strokeWidth = guideThickness
      ..style = PaintingStyle.stroke;

    // Draw horizontal guide lines
    for (final y in horizontalGuideLines) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw vertical guide lines
    for (final x in verticalGuideLines) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_AlignmentGuidesPainter oldDelegate) {
    return horizontalGuideLines != oldDelegate.horizontalGuideLines ||
        verticalGuideLines != oldDelegate.verticalGuideLines ||
        guideColor != oldDelegate.guideColor ||
        guideThickness != oldDelegate.guideThickness;
  }
}
