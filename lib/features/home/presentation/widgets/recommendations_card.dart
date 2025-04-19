import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/services/category_service.dart';
import 'package:chanchi_app/data/models/category.dart';

class RecommendationsCard extends StatefulWidget {
  final Map<String, Map<String, double>> budgetProgress;
  final Map<String, double> monthlyIncome;
  final Map<String, double> monthlyExpenses;
  final List<Map<String, dynamic>> categorizedExpenses;

  const RecommendationsCard({
    Key? key,
    required this.budgetProgress,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.categorizedExpenses,
  }) : super(key: key);

  @override
  State<RecommendationsCard> createState() => _RecommendationsCardState();
}

class _RecommendationsCardState extends State<RecommendationsCard> {
  final CategoryService _categoryService = CategoryService();
  Map<String, Category> _categories = {};
  bool _isLoading = true;
  List<Map<String, dynamic>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndGenerateRecommendations();
  }

  Future<void> _loadCategoriesAndGenerateRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar categorías
      final categories = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = {for (var cat in categories) cat.id: cat};
          // Generar recomendaciones con las categorías cargadas
          _recommendations = _generateRecommendations();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar categorías para recomendaciones: $e');
      if (mounted) {
        setState(() {
          // Generar recomendaciones con categorías predeterminadas si hay error
          _recommendations = _generateRecommendations();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Row(
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Recomendaciones",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  "Recomendaciones",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            ..._recommendations.map((rec) => _buildRecommendationItem(
              rec['text'], 
              rec['icon'], 
              rec['color']
            )).toList(),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateRecommendations() {
    // Generar recomendaciones basadas en datos reales
    List<Map<String, dynamic>> recommendations = [];
    
    // Verificar si existen gastos o presupuestos
    final hasExpenses = widget.categorizedExpenses.isNotEmpty;
    final hasBudgets = widget.budgetProgress.isNotEmpty;
    
    // Verificar excesos de presupuesto
    for (var entry in widget.budgetProgress.entries) {
      final categoryId = entry.key;
      final data = entry.value;
      final progress = data['progress'] ?? 0.0;
      
      if (progress > 0.8) {
        // Obtener nombre de la categoría desde las categorías cargadas
        String categoryName;
        if (_categories.containsKey(categoryId)) {
          categoryName = _categories[categoryId]!.name;
        } else {
          categoryName = _getDefaultCategoryName(categoryId);
        }
        
        if (progress >= 1.0) {
          recommendations.add({
            'text': "Has excedido tu presupuesto de $categoryName",
            'icon': Icons.warning_amber_rounded,
            'color': Colors.red,
          });
        } else {
          recommendations.add({
            'text': "Estás cerca de exceder tu presupuesto de $categoryName",
            'icon': Icons.warning_amber_rounded,
            'color': Colors.amber,
          });
        }
      }
    }
    
    // Verificar balances
    if (widget.monthlyIncome.isNotEmpty && widget.monthlyExpenses.isNotEmpty) {
      final lastMonthKey = widget.monthlyIncome.keys.last;
      final lastMonthIncome = widget.monthlyIncome[lastMonthKey] ?? 0;
      final lastMonthExpenses = widget.monthlyExpenses[lastMonthKey] ?? 0;
      
      if (lastMonthIncome > lastMonthExpenses) {
        final savings = lastMonthIncome - lastMonthExpenses;
        final currencyFormat = NumberFormat.currency(
          decimalDigits: 0,
          symbol: 'S/',
          locale: 'es_PE',
        );
        
        if (savings > 0) {
          recommendations.add({
            'text': "Ahorraste ${currencyFormat.format(savings)} este mes, ¡buen trabajo!",
            'icon': Icons.thumb_up,
            'color': Colors.green,
          });
        }
      } else if (lastMonthExpenses > lastMonthIncome) {
        final deficit = lastMonthExpenses - lastMonthIncome;
        final currencyFormat = NumberFormat.currency(
          decimalDigits: 0,
          symbol: 'S/',
          locale: 'es_PE',
        );
        
        recommendations.add({
          'text': "Este mes tus gastos superaron a tus ingresos por ${currencyFormat.format(deficit)}",
          'icon': Icons.warning,
          'color': Colors.orange,
        });
      }
    }
    
    // Agregar recomendación sobre categorías
    if (hasExpenses && widget.categorizedExpenses.length < 3) {
      recommendations.add({
        'text': "Considera categorizar mejor tus gastos para un mejor análisis",
        'icon': Icons.lightbulb,
        'color': AppTheme.primaryColor,
      });
    }
    
    // Recomendar crear presupuestos si no hay
    if (!hasBudgets) {
      recommendations.add({
        'text': "Establece presupuestos para tus categorías principales para un mejor control de gastos",
        'icon': Icons.money,
        'color': AppTheme.primaryColor,
      });
    }
    
    // Recomendar registrar transacciones si no hay datos
    if (!hasExpenses && !hasBudgets) {
      recommendations.add({
        'text': "Registra tus transacciones diarias para obtener análisis financieros personalizados",
        'icon': Icons.add_circle_outline,
        'color': AppTheme.primaryColor,
      });
    }
    
    // Si no hay recomendaciones, agregar sugerencias generales
    if (recommendations.isEmpty) {
      recommendations.add({
        'text': "Establece metas de ahorro mensuales para mejorar tu salud financiera",
        'icon': Icons.lightbulb,
        'color': AppTheme.primaryColor,
      });
      
      recommendations.add({
        'text': "Recuerda revisar periódicamente tu progreso presupuestario",
        'icon': Icons.event_note,
        'color': AppTheme.primaryColor,
      });
    }
    
    return recommendations;
  }

  // Método para construir un ítem de recomendación
  Widget _buildRecommendationItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
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
      default: return 'Otra categoría';
    }
  }
}