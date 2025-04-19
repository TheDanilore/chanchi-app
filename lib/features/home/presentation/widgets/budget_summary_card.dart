import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/services/category_service.dart';
import 'package:chanchi_app/data/models/category.dart';

class BudgetSummaryCard extends StatefulWidget {
  final Map<String, Map<String, double>> budgetProgress;

  const BudgetSummaryCard({Key? key, required this.budgetProgress})
    : super(key: key);

  @override
  State<BudgetSummaryCard> createState() => _BudgetSummaryCardState();
}

class _BudgetSummaryCardState extends State<BudgetSummaryCard> {
  final CategoryService _categoryService = CategoryService();
  Map<String, Category> _categories = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
  
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final categories = await _categoryService.getCategories();
      
      if (mounted) {
        setState(() {
          _categories = {for (var cat in categories) cat.id: cat};
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar categorías en BudgetSummaryCard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      decimalDigits: 0,
      symbol: 'S/',
      locale: 'es_PE',
    );

    // Esperar a que se carguen las categorías
    if (_isLoading) {
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
                "Resumen Presupuestario",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final monthName = DateFormat('MMMM', 'es').format(now);
    final capitalizedMonth =
        monthName.substring(0, 1).toUpperCase() + monthName.substring(1);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Resumen Presupuestario",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    "$capitalizedMonth ${now.year}",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),

            if (widget.budgetProgress.isEmpty)
              _buildEmptyState(context)
            else
              ...widget.budgetProgress.entries.map((entry) {
                final categoryId = entry.key;
                final data = entry.value;
                final budget = data['budget'] ?? 0.0;
                final spent = data['spent'] ?? 0.0;
                final progress = data['progress'] ?? 0.0;

                final isExceeded = progress > 1.0;
                
                // Obtener nombre y color de la categoría desde la lista cargada
                String categoryName;
                Color categoryColor;
                
                if (_categories.containsKey(categoryId)) {
                  final category = _categories[categoryId]!;
                  categoryName = category.name;
                  categoryColor = Color(
                    int.parse(category.color.substring(1, 7), radix: 16) + 0xFF000000,
                  );
                } else {
                  // Valores por defecto si no se encuentra la categoría
                  categoryName = _getDefaultCategoryName(categoryId);
                  categoryColor = _getDefaultCategoryColor(categoryId);
                }

                final label =
                    "${currencyFormat.format(spent)} de ${currencyFormat.format(budget)}";

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                  child: _buildBudgetProgressBar(
                    context,
                    categoryName,
                    progress > 1.0 ? 1.0 : progress,
                    label,
                    categoryColor,
                    isExceeded: isExceeded,
                    excessPercentage:
                        isExceeded
                            ? (((spent / budget) - 1.0) * 100).toStringAsFixed(
                              0,
                            )
                            : null,
                  ),
                );
              }).toList(),
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
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              "No hay presupuestos configurados",
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetProgressBar(
    BuildContext context,
    String category,
    double progress,
    String label,
    Color color, {
    bool isExceeded = false,
    String? excessPercentage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: isExceeded ? Colors.red.shade300 : color,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            if (isExceeded && excessPercentage != null)
              Positioned(
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+$excessPercentage%',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  // Método para obtener nombre por defecto de categoría
  String _getDefaultCategoryName(String categoryId) {
    switch (categoryId) {
      case 'general': return 'General';
      case 'food': return 'Alimentación';
      case 'transport': return 'Transporte';
      case 'entertainment': return 'Entretenimiento';
      case 'services': return 'Servicios';
      case 'home': return 'Hogar';
      case 'health': return 'Salud';
      case 'other': return 'Otros';
      default: return 'Categoría';
    }
  }

  // Método para obtener color por defecto de categoría
  Color _getDefaultCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'general': return Colors.lightBlueAccent;
      case 'food': return Colors.orange;
      case 'transport': return Colors.blue;
      case 'entertainment': return Colors.purple;
      case 'services': return Colors.teal;
      case 'home': return Colors.redAccent;
      case 'health': return Colors.deepPurpleAccent;
      case 'other': return Colors.deepPurpleAccent;
      default: return Colors.grey;
    }
  }
}