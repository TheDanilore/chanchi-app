import 'dart:math' show pi;
import 'package:flutter/material.dart';

class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  DonutChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Calcular ángulos de inicio
    double startAngle = -pi / 2;
    
    for (var item in data) {
      final sweepAngle = item['percentage'] * 2 * pi;
      final paint = Paint()
        ..color = item['color']
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) => false;
}