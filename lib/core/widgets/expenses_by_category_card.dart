import 'package:chanchi_app/core/widgets/donut_chart_painter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chanchi_app/core/config/theme.dart';

class ExpensesByCategoryCard extends StatefulWidget {
  final List<Map<String, dynamic>> categorizedExpenses;
  final double totalExpenses;

  const ExpensesByCategoryCard({
    Key? key,
    required this.categorizedExpenses,
    required this.totalExpenses,
  }) : super(key: key);

  @override
  State<ExpensesByCategoryCard> createState() => _ExpensesByCategoryCardState();
}

class _ExpensesByCategoryCardState extends State<ExpensesByCategoryCard> {
  bool _showAllCategories = false;
  String? _selectedCategoryId;

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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con título y total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Gastos por Categoría",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTheme.radiusXL,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      "Total: ${currencyFormat.format(widget.totalExpenses)}",
                      style: TextStyle(
                        fontSize: AppTheme.radiusL,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              // Subtítulo explicativo
              Text(
                "Analiza cómo se distribuyen tus gastos este mes",
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              
              if (widget.categorizedExpenses.isEmpty)
                _buildEmptyState(context)
              else
                _buildCategoryExpensesContent(context, currencyFormat),
            ],
          ),
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.add),
              label: Text("Añadir gasto"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryExpensesContent(BuildContext context, NumberFormat currencyFormat) {
    // Determinar qué categorías mostrar basado en el estado
    final categoriesToShow = _showAllCategories 
        ? widget.categorizedExpenses 
        : widget.categorizedExpenses.length > 5 
            ? widget.categorizedExpenses.sublist(0, 5) 
            : widget.categorizedExpenses;
    
    // Calcular análisis de gastos
    final hasOtherCategory = widget.categorizedExpenses.any((cat) => cat['categoryId'] == 'other');
    final topCategory = widget.categorizedExpenses.isNotEmpty ? widget.categorizedExpenses[0] : null;
    final topTwoPercentage = widget.categorizedExpenses.length >= 2 
        ? widget.categorizedExpenses.sublist(0, 2).fold(0.0, (sum, cat) => sum + cat['percentage']) * 100 
        : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gráfico y análisis en dos columnas
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gráfico circular
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _selectedCategoryId != null
                          ? _buildHighlightedDonut()
                          : CustomPaint(
                              size: const Size(180, 180),
                              painter: DonutChartPainter(data: widget.categorizedExpenses),
                            ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCategoryId != null
                              ? _getSelectedCategoryAmount(currencyFormat)
                              : currencyFormat.format(widget.totalExpenses),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _selectedCategoryId != null
                                ? _getSelectedCategoryColor()
                                : AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          _selectedCategoryId != null
                              ? _getSelectedCategoryName()
                              : "Gasto Total",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Resumen de análisis de gastos
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (topCategory != null) ...[
                      Text(
                        "Análisis de gastos",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAnalysisItem(
                        "Mayor categoría",
                        "${topCategory['category']} (${(topCategory['percentage'] * 100).toStringAsFixed(0)}%)",
                        topCategory['color'],
                      ),
                      if (topTwoPercentage > 0) ...[
                        const SizedBox(height: 8),
                        _buildAnalysisItem(
                          "Concentración",
                          "Las 2 principales categorías representan el ${topTwoPercentage.toStringAsFixed(0)}% del total",
                          topTwoPercentage > 70 ? Colors.orange : Colors.blue,
                        ),
                      ],
                      if (hasOtherCategory) ...[
                        const SizedBox(height: 8),
                        _buildAnalysisItem(
                          "Categoría Otros",
                          "Algunos gastos no están correctamente categorizados",
                          Colors.grey,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Leyenda del gráfico con todos los gastos por categoría
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Detalle por categorías",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ...categoriesToShow.map((item) {
              final percentage = (item['percentage'] * 100).toStringAsFixed(1);
              final value = currencyFormat.format(item['value']);
              return _buildLegendItem(
                item['category'], 
                item['color'], 
                percentage, 
                value,
                item['categoryId'],
              );
            }).toList(),
            
            // Botón de mostrar más/menos si hay más de 5 categorías
            if (widget.categorizedExpenses.length > 5)
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAllCategories = !_showAllCategories;
                  });
                },
                style: TextButton.styleFrom(
                  minimumSize: Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.05),
                ),
                child: Text(
                  _showAllCategories
                      ? "Mostrar menos categorías"
                      : "Ver todas las categorías (${widget.categorizedExpenses.length})",
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String percentage, String amount, String categoryId) {
    final isSelected = _selectedCategoryId == categoryId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = isSelected ? null : categoryId;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(color: color.withOpacity(0.5))
              : null,
        ),
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
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "$percentage%",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              amount,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Método para construir un donut chart destacando la categoría seleccionada
  Widget _buildHighlightedDonut() {
    // Crear una copia de los datos y ajustar opacidad
    final List<Map<String, dynamic>> highlightedData = [];
    for (var item in widget.categorizedExpenses) {
      final Map<String, dynamic> newItem = Map.from(item);
      if (item['categoryId'] == _selectedCategoryId) {
        // Mantener color original para categoría seleccionada
      } else {
        // Atenuar otras categorías
        newItem['color'] = (item['color'] as Color).withOpacity(0.3);
      }
      highlightedData.add(newItem);
    }
    
    return CustomPaint(
      size: const Size(180, 180),
      painter: DonutChartPainter(data: highlightedData),
    );
  }
  
  // Métodos para obtener información de la categoría seleccionada
  String _getSelectedCategoryName() {
    for (var item in widget.categorizedExpenses) {
      if (item['categoryId'] == _selectedCategoryId) {
        return item['category'] as String;
      }
    }
    return "";
  }
  
  String _getSelectedCategoryAmount(NumberFormat formatter) {
    for (var item in widget.categorizedExpenses) {
      if (item['categoryId'] == _selectedCategoryId) {
        return formatter.format(item['value']);
      }
    }
    return "";
  }
  
  Color _getSelectedCategoryColor() {
    for (var item in widget.categorizedExpenses) {
      if (item['categoryId'] == _selectedCategoryId) {
        return item['color'] as Color;
      }
    }
    return Colors.grey;
  }
}