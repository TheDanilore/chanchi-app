import 'package:flutter/material.dart';

class LineChartPainter extends CustomPainter {
  final Map<String, double> incomeData;
  final Map<String, double> expenseData;
  final bool useGradient;
  final bool showDots;
  final bool showGrid;
  final double dotRadius;
  
  LineChartPainter({
    required this.incomeData,
    required this.expenseData,
    this.useGradient = true,
    this.showDots = true,
    this.showGrid = true,
    this.dotRadius = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (incomeData.isEmpty || expenseData.isEmpty) return;
    
    final List<String> months = _getSortedMonths();
    final List<double> incomeValues = months.map((m) => incomeData[m] ?? 0).toList();
    final List<double> expenseValues = months.map((m) => expenseData[m] ?? 0).toList();

    // Find maximum value for scaling with some padding
    final maxValue = [
      ...incomeValues,
      ...expenseValues,
    ].reduce((a, b) => a > b ? a : b) * 1.1;

    // Chart area dimensions
    final width = size.width;
    final height = size.height;
    final chartPadding = _getChartPadding();
    
    // Draw grid lines and labels
    if (showGrid) {
      _drawGridAndLabels(canvas, size, maxValue, months, chartPadding);
    }
    
    // Calculate points for both lines
    final incomePoints = _calculatePoints(
      size, 
      months, 
      incomeValues, 
      maxValue,
      chartPadding
    );
    
    final expensePoints = _calculatePoints(
      size, 
      months, 
      expenseValues, 
      maxValue,
      chartPadding
    );
    
    // Configure paint objects
    final incomePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final expensePaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    // Draw income line and area
    if (useGradient && incomePoints.isNotEmpty) {
      _drawAreaWithGradient(
        canvas, 
        size, 
        incomePoints, 
        Colors.green.withOpacity(0.7), 
        Colors.green.withOpacity(0.05), 
        chartPadding
      );
    }
    
    // Draw expense line and area
    if (useGradient && expensePoints.isNotEmpty) {
      _drawAreaWithGradient(
        canvas, 
        size, 
        expensePoints, 
        Colors.redAccent.withOpacity(0.7), 
        Colors.redAccent.withOpacity(0.05), 
        chartPadding
      );
    }
    
    // Draw lines
    _drawLine(canvas, incomePoints, incomePaint);
    _drawLine(canvas, expensePoints, expensePaint);
    
    // Draw dots at data points
    if (showDots) {
      _drawDots(canvas, incomePoints, Colors.green);
      _drawDots(canvas, expensePoints, Colors.redAccent);
    }
  }
  
  // Get months in chronological order
  List<String> _getSortedMonths() {
    final Set<String> allMonths = {...incomeData.keys, ...expenseData.keys};
    final List<String> sortedMonths = allMonths.toList();
    
    // Define month order for sorting (assuming all months are 3-letter codes: ENE, FEB, MAR, etc.)
    final monthOrder = {
      'ENE': 1, 'FEB': 2, 'MAR': 3, 'ABR': 4, 'MAY': 5, 'JUN': 6,
      'JUL': 7, 'AGO': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DIC': 12
    };
    
    sortedMonths.sort((a, b) {
      return (monthOrder[a] ?? 0).compareTo(monthOrder[b] ?? 0);
    });
    
    return sortedMonths;
  }
  
  // Calculate padding for the chart
  EdgeInsets _getChartPadding() {
    return const EdgeInsets.fromLTRB(40, 20, 20, 40);
  }

  // Draw grid lines and month/value labels
  void _drawGridAndLabels(
    Canvas canvas, 
    Size size, 
    double maxValue, 
    List<String> months,
    EdgeInsets padding
  ) {
    final width = size.width;
    final height = size.height;
    final availableHeight = height - padding.top - padding.bottom;
    final availableWidth = width - padding.left - padding.right;
    
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    final textStyle = TextStyle(
      color: Colors.grey.shade600,
      fontSize: 10,
    );
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Draw horizontal grid lines and value labels
    final horizontalLines = 5;
    for (int i = 0; i <= horizontalLines; i++) {
      final y = padding.top + (i * availableHeight / horizontalLines);
      
      // Draw grid line
      canvas.drawLine(
        Offset(padding.left, y),
        Offset(width - padding.right, y),
        gridPaint,
      );
      
      // Draw value label
      final value = maxValue - (i * maxValue / horizontalLines);
      final valueText = value >= 1000 
          ? '${(value / 1000).toStringAsFixed(1)}k' 
          : value.toStringAsFixed(0);
      
      textPainter.text = TextSpan(
        text: valueText,
        style: textStyle,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas, 
        Offset(padding.left - textPainter.width - 8, y - textPainter.height / 2)
      );
    }
    
    // Draw vertical grid lines and month labels
    for (int i = 0; i < months.length; i++) {
      final x = padding.left + (i * availableWidth / (months.length - 1));
      
      // Draw grid line
      if (i > 0) {
        canvas.drawLine(
          Offset(x, padding.top),
          Offset(x, height - padding.bottom),
          gridPaint,
        );
      }
      
      // Draw month label
      final month = months[i];
      textPainter.text = TextSpan(
        text: month,
        style: textStyle,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas, 
        Offset(
          x - textPainter.width / 2, 
          height - padding.bottom + 8
        )
      );
    }
  }

  // Calculate points for drawing a line
  List<Offset> _calculatePoints(
    Size size, 
    List<String> months, 
    List<double> values, 
    double maxValue,
    EdgeInsets padding
  ) {
    final width = size.width;
    final height = size.height;
    final availableWidth = width - padding.left - padding.right;
    final availableHeight = height - padding.top - padding.bottom;
    
    final points = <Offset>[];
    
    for (int i = 0; i < months.length; i++) {
      final x = padding.left + (i * availableWidth / (months.length - 1));
      final normalizedValue = values[i] / maxValue;
      final y = height - padding.bottom - (normalizedValue * availableHeight);
      
      points.add(Offset(x, y));
    }
    
    return points;
  }

  // Draw a single line
  void _drawLine(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    
    for (int i = 1; i < points.length; i++) {
      // Use a bezier curve for smoother lines
      if (i < points.length - 1) {
        final controlPoint1 = Offset(
          points[i].dx - ((points[i].dx - points[i-1].dx) / 2),
          points[i].dy
        );
        
        final controlPoint2 = Offset(
          points[i].dx + ((points[i+1].dx - points[i].dx) / 2),
          points[i].dy
        );
        
        path.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          points[i+1].dx, points[i+1].dy
        );
        i++;
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    
    canvas.drawPath(path, paint);
  }
  
  // Draw an area under the line with gradient
  void _drawAreaWithGradient(
    Canvas canvas, 
    Size size, 
    List<Offset> points, 
    Color topColor,
    Color bottomColor,
    EdgeInsets padding
  ) {
    if (points.isEmpty) return;
    
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    
    // Draw line part
    for (int i = 1; i < points.length; i++) {
      // Use a bezier curve for smoother lines (simplified version)
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    // Complete the path back to start point
    path.lineTo(points.last.dx, size.height - padding.bottom);
    path.lineTo(points.first.dx, size.height - padding.bottom);
    path.close();
    
    // Fill with gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, bottomColor],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, padding.top, size.width, size.height - padding.bottom - padding.top)
      )
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, paint);
  }
  
  // Draw dots at data points
  void _drawDots(Canvas canvas, List<Offset> points, Color color) {
    final dotFillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (final point in points) {
      // White border
      canvas.drawCircle(point, dotRadius, dotBorderPaint);
      // Color fill
      canvas.drawCircle(point, dotRadius - 2, dotFillPaint);
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) => 
    oldDelegate.incomeData != incomeData ||
    oldDelegate.expenseData != expenseData ||
    oldDelegate.useGradient != useGradient ||
    oldDelegate.showDots != showDots ||
    oldDelegate.showGrid != showGrid ||
    oldDelegate.dotRadius != dotRadius;
}