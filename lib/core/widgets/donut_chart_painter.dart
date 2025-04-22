import 'dart:math';
import 'package:flutter/material.dart';

class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double innerRadius;
  final double thickness;
  final bool drawShadow;

  DonutChartPainter({
    required this.data, 
    this.innerRadius = 0.6, 
    this.thickness = 0.2,
    this.drawShadow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2 : size.height / 2;
    
    // Outer and inner radius
    final outerRadius = radius;
    final innerRadiusValue = radius * innerRadius;
    
    // Shadow for 3D effect
    if (drawShadow) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawCircle(
        Offset(center.dx, center.dy + 2), 
        outerRadius - 2,
        shadowPaint
      );
    }
    
    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, outerRadius, bgPaint);
    
    // Inner circle (creates donut hole)
    final centerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Calcular ángulos de inicio
    double startAngle = -pi / 2; // Start from top
    
    for (var item in data) {
      final percentage = item['percentage'] as double;
      
      if (percentage <= 0) continue;
      
      final sweepAngle = percentage * 2 * pi;
      final color = item['color'] as Color;
      
      // Outer arc
      final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..strokeWidth = 0;
      
      // Draw segment
      _drawSegment(
        canvas,
        center,
        startAngle, 
        sweepAngle,
        innerRadiusValue,
        outerRadius,
        color
      );
      
      startAngle += sweepAngle;
    }
    
    // Draw inner white circle on top
    canvas.drawCircle(center, innerRadiusValue, centerCirclePaint);
  }
  
  // Helper method to draw a donut segment
  void _drawSegment(
    Canvas canvas, 
    Offset center,
    double startAngle, 
    double sweepAngle,
    double innerRadius,
    double outerRadius,
    Color color
  ) {
    final path = Path();
    
    // Move to inner arc start
    path.moveTo(
      center.dx + innerRadius * cos(startAngle),
      center.dy + innerRadius * sin(startAngle)
    );
    
    // Line to outer arc start
    path.lineTo(
      center.dx + outerRadius * cos(startAngle),
      center.dy + outerRadius * sin(startAngle)
    );
    
    // Draw outer arc
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      sweepAngle,
      false
    );
    
    // Line to inner arc end
    path.lineTo(
      center.dx + innerRadius * cos(startAngle + sweepAngle),
      center.dy + innerRadius * sin(startAngle + sweepAngle)
    );
    
    // Draw inner arc
    path.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle + sweepAngle,
      -sweepAngle,
      false
    );
    
    // Close the path
    path.close();
    
    // Fill the segment
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, paint);
    
    // Add subtle highlight for 3D effect
    final highlightPath = Path();
    final highlightStart = startAngle + sweepAngle * 0.03;
    final highlightSweep = sweepAngle * 0.15;
    
    if (sweepAngle > 0.2) {  // Only add highlight for larger segments
      highlightPath.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius - 2),
        highlightStart,
        highlightSweep,
        true
      );
      
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawPath(highlightPath, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) => 
    oldDelegate.data != data || 
    oldDelegate.innerRadius != innerRadius ||
    oldDelegate.thickness != thickness ||
    oldDelegate.drawShadow != drawShadow;
}