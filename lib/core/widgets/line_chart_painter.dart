import 'package:flutter/material.dart';

class LineChartPainter extends CustomPainter {
  final Map<String, double> incomeData;
  final Map<String, double> expenseData;

  LineChartPainter({
    required this.incomeData,
    required this.expenseData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final List<String> months = incomeData.keys.toList();
    final List<double> incomeValues = incomeData.values.toList();
    final List<double> expenseValues = expenseData.values.toList();

    // Encontrar el valor máximo para escalar
    final maxValue = [
      ...incomeValues,
      ...expenseValues,
    ].reduce((a, b) => a > b ? a : b);

    // Configurar pinturas
    final incomePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final expensePaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Calcular puntos
    final points = _calculatePoints(size, months, incomeValues, expenseValues, maxValue);

    // Dibujar líneas
    _drawLine(canvas, points['income']!, incomePaint);
    _drawLine(canvas, points['expense']!, expensePaint);
  }

  Map<String, List<Offset>> _calculatePoints(
    Size size, 
    List<String> months, 
    List<double> incomeValues, 
    List<double> expenseValues, 
    double maxValue
  ) {
    final width = size.width;
    final height = size.height;
    final padding = 20.0;

    final incomePoints = <Offset>[];
    final expensePoints = <Offset>[];

    for (int i = 0; i < months.length; i++) {
      final x = padding + (i * (width - 2 * padding) / (months.length - 1));
      final incomeY = height - (padding + (incomeValues[i] / maxValue * (height - 2 * padding)));
      final expenseY = height - (padding + (expenseValues[i] / maxValue * (height - 2 * padding)));

      incomePoints.add(Offset(x, incomeY));
      expensePoints.add(Offset(x, expenseY));
    }

    return {
      'income': incomePoints,
      'expense': expensePoints,
    };
  }

  void _drawLine(Canvas canvas, List<Offset> points, Paint paint) {
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) => false;
}