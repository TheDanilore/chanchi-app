import 'package:chanchi_app/presentation/widgets/donut_chart_painter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chanchi_app/config/theme.dart';

class ExpensesByCategoryCard extends StatelessWidget {
  final List<Map<String, dynamic>> categorizedExpenses;
  final double totalExpenses;

  const ExpensesByCategoryCard({
    Key? key,
    required this.categorizedExpenses,
    required this.totalExpenses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Formatear el monto total con 2 decimales
    final currencyFormat = NumberFormat.currency(
      decimalDigits: 2,
      symbol: 'S/',
      locale: 'es_PE',
    );
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gastos por Categoría",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            if (categorizedExpenses.isEmpty)
              _buildEmptyState(context)
            else
              _buildCategoryExpensesContent(context, currencyFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              "No hay datos de gastos para este mes",
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryExpensesContent(BuildContext context, NumberFormat currencyFormat) {
    return Column(
      children: [
        // Gráfico de pastel
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.transparent),
                ),
                child: CustomPaint(
                  size: const Size(240, 240),
                  painter: DonutChartPainter(data: categorizedExpenses),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currencyFormat.format(totalExpenses),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    "Gasto Total",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        // Leyenda del gráfico
        ...categorizedExpenses.map((item) {
          final percentage = (item['percentage'] * 100).toStringAsFixed(0);
          final value = currencyFormat.format(item['value']);
          return _buildLegendItem(
            item['category'], 
            item['color'], 
            "$percentage%", 
            value
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String percentage, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            percentage,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            amount,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}