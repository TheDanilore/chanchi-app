import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:intl/intl.dart';
import 'package:chanchi_app/features/home/presentation/widgets/budget_summary_card.dart';
import 'package:chanchi_app/core/widgets/expenses_by_category_card.dart';
import 'package:chanchi_app/core/widgets/income_expense_chart.dart';
import 'package:chanchi_app/features/home/presentation/widgets/recommendations_card.dart';
import 'package:chanchi_app/services/budget_service.dart';
import 'package:chanchi_app/services/category_service.dart';
import 'package:chanchi_app/data/models/category.dart';

class AnalyticsDashboard extends StatefulWidget {
  final String userId;

  const AnalyticsDashboard({Key? key, required this.userId}) : super(key: key);

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BudgetService _budgetService = BudgetService();
  final CategoryService _categoryService = CategoryService();

  // Estado para almacenar datos procesados
  List<Map<String, dynamic>> _categorizedExpenses = [];
  double _totalExpenses = 0;
  Map<String, double> _monthlyIncome = {};
  Map<String, double> _monthlyExpenses = {};
  Map<String, Map<String, double>> _budgetProgress = {};
  Map<String, Category> _categories = {};

  // Estado de carga
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Método para obtener y procesar todos los datos necesarios
  Future<void> _fetchData() async {
    // Verificar si el widget sigue montado antes de actualizar el estado
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Cargar categorías
      await _loadCategories();
      
      // Verificar si el widget sigue montado
      if (!mounted) return;

      // Obtener fecha inicio y fin para el mes actual
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final nextMonth =
          now.month < 12
              ? DateTime(now.year, now.month + 1, 1)
              : DateTime(now.year + 1, 1, 1);
      final endOfMonth = nextMonth.subtract(const Duration(days: 1));

      // Consulta de transacciones del mes actual - CORREGIDA: usar isEqualTo en lugar de isNotEqualTo
      final currentMonthTransactions =
          await _firestore
              .collection('transactions')
              .where('userId', isEqualTo: widget.userId)
              .where('isInTrash', isEqualTo: false)
              .where('dateTime', isGreaterThanOrEqualTo: startOfMonth)
              .where('dateTime', isLessThanOrEqualTo: endOfMonth)
              .get();

      // Verificar si el widget sigue montado
      if (!mounted) return;

      // Consulta de transacciones de los últimos 4 meses para el gráfico de línea
      await _loadHistoricalTransactions(startOfMonth, endOfMonth);

      // Verificar si el widget sigue montado
      if (!mounted) return;

      // Procesar datos para gráfico de categorías de gastos
      await _processCategoryExpenses(currentMonthTransactions.docs);

      // Verificar si el widget sigue montado
      if (!mounted) return;

      // Procesar datos para presupuestos usando BudgetService
      await _processBudgetDataWithService();

      // Verificación final antes de actualizar el estado
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Verificar si el widget sigue montado antes de actualizar el estado en caso de error
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = "Error al cargar datos: $e";
      });
      print('Error en AnalyticsDashboard: $e');
    }
  }

  // Nuevo método para cargar categorías
  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = {for (var cat in categories) cat.id: cat};
        });
      }
    } catch (e) {
      print('Error al cargar categorías: $e');
    }
  }

  // Método para cargar transacciones históricas
  Future<void> _loadHistoricalTransactions(DateTime startOfMonth, DateTime endOfMonth) async {
    try {
      final fourMonthsAgo = DateTime(startOfMonth.year, startOfMonth.month - 3, 1);
      
      // CORREGIDO: Usar isEqualTo en lugar de isNotEqualTo para evitar problemas de consulta en Firestore
      final historicalTransactions =
          await _firestore
              .collection('transactions')
              .where('userId', isEqualTo: widget.userId)
              .where('isInTrash', isEqualTo: false)
              .where('dateTime', isGreaterThanOrEqualTo: fourMonthsAgo)
              .where('dateTime', isLessThanOrEqualTo: endOfMonth)
              .get();

      // Procesar datos para gráfico de ingresos/gastos
      await _processMonthlyData(historicalTransactions.docs);
    } catch (e) {
      print('Error al cargar transacciones históricas: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingL),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Mostrar el dashboard con datos reales
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpensesByCategoryCard(
            categorizedExpenses: _categorizedExpenses,
            totalExpenses: _totalExpenses,
          ),
          const SizedBox(height: AppTheme.spacingL),
          IncomeExpenseChart(
            monthlyIncome: _monthlyIncome,
            monthlyExpenses: _monthlyExpenses,
          ),
          const SizedBox(height: AppTheme.spacingL),
          BudgetSummaryCard(budgetProgress: _budgetProgress),
          const SizedBox(height: AppTheme.spacingL),
          RecommendationsCard(
            budgetProgress: _budgetProgress,
            monthlyIncome: _monthlyIncome,
            monthlyExpenses: _monthlyExpenses,
            categorizedExpenses: _categorizedExpenses,
          ),
        ],
      ),
    );
  }

  Future<void> _processCategoryExpenses(
    List<DocumentSnapshot> transactions,
  ) async {
    if (!mounted) return;

    Map<String, double> categoryTotals = {};
    double total = 0;

    // Calcular totales por categoría
    for (var doc in transactions) {
      final data = doc.data() as Map<String, dynamic>;

      // Solo contar gastos, no ingresos
      if (data['type'] == 'expense') {
        final categoryId = data['categoryId'] as String? ?? 'general';
        final amount = (data['amount'] as num).toDouble();

        categoryTotals[categoryId] = (categoryTotals[categoryId] ?? 0) + amount;
        total += amount;
      }
    }

    // Convertir a lista para el gráfico
    List<Map<String, dynamic>> result = [];

    // Ordenar categorías por monto (de mayor a menor)
    final sortedCategories =
        categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Tomar las 4 categorías principales y agrupar el resto como "Otros"
    double otherTotal = 0;

    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      if (i < 10) {
        // Obtener nombre y color de la categoría
        String categoryName;
        Color categoryColor;
        
        if (_categories.containsKey(entry.key)) {
          final category = _categories[entry.key]!;
          categoryName = category.name;
          categoryColor = Color(
            int.parse(category.color.substring(1, 7), radix: 16) + 0xFF000000,
          );
        } else {
          // Valores por defecto si no se encuentra la categoría
          categoryName = _getDefaultCategoryName(entry.key);
          categoryColor = _getDefaultCategoryColor(entry.key);
        }

        result.add({
          'category': categoryName,
          'categoryId': entry.key,
          'value': entry.value,
          'percentage': total > 0 ? entry.value / total : 0,
          'color': categoryColor,
        });
      } else {
        otherTotal += entry.value;
      }
    }

    // Agregar categoría "Otros" si hay más de 4 categorías
    if (otherTotal > 0) {
      result.add({
        'category': 'Otros',
        'categoryId': 'other',
        'value': otherTotal,
        'percentage': total > 0 ? otherTotal / total : 0,
        'color': Colors.grey,
      });
    }

    if (mounted) {
      setState(() {
        _categorizedExpenses = result;
        _totalExpenses = total;
      });
    }
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
      case 'other': return 'Otro';
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

  // Procesar datos mensuales para gráfico de línea
  Future<void> _processMonthlyData(List<DocumentSnapshot> transactions) async {
    if (!mounted) return;

    Map<String, double> incomeByMonth = {};
    Map<String, double> expensesByMonth = {};

    // Crear entradas para los últimos 4 meses
    final now = DateTime.now();
    for (int i = 3; i >= 0; i--) {
      final month = now.month - i;
      final year = now.year + (month <= 0 ? -1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;

      final monthName =
          DateFormat(
            'MMM',
            'es',
          ).format(DateTime(year, adjustedMonth)).substring(0, 3).toUpperCase();

      incomeByMonth[monthName] = 0;
      expensesByMonth[monthName] = 0;
    }

    // Calcular totales por mes
    for (var doc in transactions) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['dateTime'] as Timestamp;
      final date = timestamp.toDate();
      final monthKey =
          DateFormat('MMM', 'es').format(date).substring(0, 3).toUpperCase();

      final amount = (data['amount'] as num).toDouble();

      if (data['type'] == 'income') {
        incomeByMonth[monthKey] = (incomeByMonth[monthKey] ?? 0) + amount;
      } else if (data['type'] == 'expense') {
        expensesByMonth[monthKey] = (expensesByMonth[monthKey] ?? 0) + amount;
      }
    }

    if (mounted) {
      setState(() {
        _monthlyIncome = incomeByMonth;
        _monthlyExpenses = expensesByMonth;
      });
    }
  }

  // NUEVO: Procesar datos de presupuesto usando BudgetService
  Future<void> _processBudgetDataWithService() async {
    if (!mounted) return;

    try {
      // Obtener el mes actual en formato "YYYY-MM"
      
      // Crear un Stream para escuchar presupuestos actuales
      _budgetService
          .getCurrentMonthBudgets(widget.userId)
          .first
          .then((budgets) {
            if (!mounted) return;
            
            // Transformar los presupuestos al formato esperado por BudgetSummaryCard
            final Map<String, Map<String, double>> result = {};
            
            for (final budget in budgets) {
              final categoryId = budget.categoryId ?? 'general';
              result[categoryId] = {
                'budget': budget.amount,
                'spent': budget.currentSpent ?? 0,
                'progress': (budget.percentageUsed).toDouble(),
              };
            }
            
            setState(() {
              _budgetProgress = result;
            });
          })
          .catchError((e) {
            print('Error al procesar presupuestos: $e');
            // No actualizamos el estado para mantener valores por defecto
          });
    } catch (e) {
      print('Error al procesar presupuestos: $e');
    }
  }
}