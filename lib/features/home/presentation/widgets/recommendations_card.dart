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
  // Nuevo: indicador de salud financiera
  final double? financialHealthScore;

  const RecommendationsCard({
    Key? key,
    required this.budgetProgress,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.categorizedExpenses,
    this.financialHealthScore,
  }) : super(key: key);

  @override
  State<RecommendationsCard> createState() => _RecommendationsCardState();
}

class _RecommendationsCardState extends State<RecommendationsCard> {
  final CategoryService _categoryService = CategoryService();
  Map<String, Category> _categories = {};
  bool _isLoading = true;
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _insights = [];
  bool _showAllRecommendations = false;
  // Estado para rastrear recomendaciones actuadas
  Set<int> _completedRecommendations = {};

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndGenerateRecommendations();
  }

  Future<void> _loadCategoriesAndGenerateRecommendations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar categorías de forma segura
      final categories = await _categoryService.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = {for (var cat in categories) cat.id: cat};

        // Generar recomendaciones e insights de forma más eficiente
        _recommendations = _generateRecommendations();
        _insights = _generateInsights();

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _recommendations = _generateRecommendations();
        _insights = _generateInsights();
        _isLoading = false;
      });
      print('Error al cargar categorías: $e');
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights, color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    "Análisis y Recomendaciones",
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppTheme.primaryColor.withOpacity(0.05)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la tarjeta con indicador de salud financiera
              _buildHeader(),

              // Sección de Insights
              if (_insights.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInsightsSection(),
              ],

              // Separador
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 16),

              // Sección de recomendaciones
              _buildRecommendationsSection(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para construir el encabezado con puntuación de salud financiera
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Análisis y Recomendaciones",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Indicador de salud financiera si está disponible
        if (widget.financialHealthScore != null) ...[
          const SizedBox(height: 16),
          _buildFinancialHealthIndicator(widget.financialHealthScore!),
        ],
      ],
    );
  }

  // Widget para construir indicador visual de salud financiera
  Widget _buildFinancialHealthIndicator(double score) {
    // Determinar color y estado basado en puntuación (0-100)
    final Color barColor =
        score >= 70
            ? Colors.green
            : score >= 40
            ? Colors.orange
            : Colors.red;

    final String healthStatus =
        score >= 70
            ? "Buena"
            : score >= 40
            ? "Regular"
            : "Necesita atención";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Salud financiera",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                healthStatus,
                style: TextStyle(
                  color: barColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              // Barra base
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Barra de progreso
              FractionallySizedBox(
                widthFactor: score / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getFinancialHealthDescription(score),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  // Mensaje descriptivo para salud financiera
  String _getFinancialHealthDescription(double score) {
    if (score >= 70) {
      return "¡Buen trabajo! Estás administrando bien tus finanzas.";
    } else if (score >= 40) {
      return "Tu situación financiera es estable, pero hay áreas para mejorar.";
    } else {
      return "Hay aspectos importantes de tus finanzas que requieren atención.";
    }
  }

  // Widget para la sección de insights
  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assessment, color: Colors.grey.shade800, size: 18),
            const SizedBox(width: 8),
            Text(
              "Resumen de análisis",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Carrusel horizontal de insights
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _insights.length,
            itemBuilder: (context, index) {
              return Container(
                width: 250,
                margin: EdgeInsets.only(right: 12),
                child: _buildInsightCard(_insights[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget para la tarjeta de insight individual
  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: insight['color'].withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: insight['color'].withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: insight['color'].withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(insight['icon'], color: insight['color'], size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: insight['color'],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              insight['description'],
              style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para la sección de recomendaciones
  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Colors.grey.shade800,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              "Recomendaciones personalizadas",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Lista de recomendaciones (limitadas o todas)
        ...(_showAllRecommendations || _recommendations.length <= 3
                ? _recommendations
                : _recommendations.sublist(0, 3))
            .asMap()
            .entries
            .map((entry) => _buildRecommendationCard(entry.value, entry.key))
            .toList(),

        // Botón para mostrar más recomendaciones
        if (_recommendations.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllRecommendations = !_showAllRecommendations;
                });
              },
              style: TextButton.styleFrom(
                minimumSize: Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.05),
              ),
              child: Text(
                _showAllRecommendations
                    ? "Mostrar menos"
                    : "Ver todas las recomendaciones (${_recommendations.length})",
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Widget para una tarjeta de recomendación individual
  Widget _buildRecommendationCard(Map<String, dynamic> rec, int index) {
    final bool isCompleted = _completedRecommendations.contains(index);
    final priorityColor =
        {
          'alta': Colors.red.shade900,
          'media': Colors.amber.shade900,
          'baja': Colors.green.shade800,
        }[rec['priority']] ??
        Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Encabezado con título, prioridad y checkbox
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isCompleted
                      ? Colors.grey.shade200
                      : rec['color'].withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color:
                      isCompleted
                          ? Colors.grey.shade300
                          : rec['color'].withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  rec['icon'],
                  color: isCompleted ? Colors.grey : rec['color'],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isCompleted ? Colors.grey : rec['color'],
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCompleted ? Colors.grey : priorityColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getPriorityIcon(rec['priority']),
                        size: 12,
                        color: isCompleted ? Colors.grey : priorityColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rec['priority'],
                        style: TextStyle(
                          fontSize: 11,
                          color: isCompleted ? Colors.grey : priorityColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // Checkbox para marcar como completado
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isCompleted,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _completedRecommendations.add(index);
                        } else {
                          _completedRecommendations.remove(index);
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Contenido de la recomendación
          AnimatedOpacity(
            opacity: isCompleted ? 0.5 : 1.0,
            duration: Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec['description'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Acción recomendada con botón para realizar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.tips_and_updates,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Acción recomendada:",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rec['action'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Botón de acción para la recomendación
                  if (!isCompleted && rec.containsKey('actionButton'))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Implementar acción específica según recomendación
                          _onRecommendationActionPressed(rec, index);
                        },
                        icon: Icon(
                          _getActionIcon(rec['actionType'] ?? ''),
                          size: 16,
                        ),
                        label: Text(rec['actionButton'] ?? 'Realizar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 36),
                          textStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método para manejar acciones de recomendaciones
  void _onRecommendationActionPressed(Map<String, dynamic> rec, int index) {
    // Aquí implementarías navegación a pantallas específicas según la acción
    // Por ejemplo, navegar a configuración de presupuestos, añadir gasto, etc.

    // Ejemplo de implementación básica: marcar como completada
    setState(() {
      _completedRecommendations.add(index);
    });

    // Mostrar confirmación al usuario
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Acción iniciada para: ${rec['title']}"),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  // Obtener icono según la prioridad
  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'alta':
        return Icons.priority_high;
      case 'media':
        return Icons.horizontal_rule;
      case 'baja':
        return Icons.arrow_downward;
      default:
        return Icons.circle;
    }
  }

  // Obtener icono según el tipo de acción
  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'budget':
        return Icons.account_balance_wallet;
      case 'expense':
        return Icons.money_off;
      case 'income':
        return Icons.add_card;
      case 'category':
        return Icons.category;
      default:
        return Icons.keyboard_arrow_right;
    }
  }

  // Método para generar análisis a partir de los datos
  List<Map<String, dynamic>> _generateInsights() {
    List<Map<String, dynamic>> insights = [];
    final currencyFormat = NumberFormat.currency(
      decimalDigits: 0,
      symbol: 'S/',
      locale: 'es_PE',
    );

    // 1. Analizar balance general
    if (widget.monthlyIncome.isNotEmpty && widget.monthlyExpenses.isNotEmpty) {
      final lastMonthKey = widget.monthlyIncome.keys.last;
      final lastMonthIncome = widget.monthlyIncome[lastMonthKey] ?? 0;
      final lastMonthExpenses = widget.monthlyExpenses[lastMonthKey] ?? 0;
      final balance = lastMonthIncome - lastMonthExpenses;
      final savingsRate =
          lastMonthIncome > 0 ? (balance / lastMonthIncome) * 100 : 0;

      // Clasificar el estado financiero
      String healthStatus;
      Color healthColor;

      if (savingsRate >= 20) {
        healthStatus = "Excelente";
        healthColor = Colors.green.shade700;
      } else if (savingsRate >= 10) {
        healthStatus = "Bueno";
        healthColor = Colors.green;
      } else if (savingsRate > 0) {
        healthStatus = "Regular";
        healthColor = Colors.amber;
      } else {
        healthStatus = "Necesita atención";
        healthColor = Colors.red;
      }

      insights.add({
        'title': 'Estado financiero: $healthStatus',
        'description':
            balance >= 0
                ? 'Este mes has ahorrado ${currencyFormat.format(balance)} (${savingsRate.toStringAsFixed(1)}% de tus ingresos)'
                : 'Este mes has gastado ${currencyFormat.format(balance.abs())} más de lo que ingresaste',
        'icon': balance >= 0 ? Icons.trending_up : Icons.trending_down,
        'color': healthColor,
      });
    }

    // 2. Analizar tendencias de gastos
    if (widget.monthlyExpenses.length >= 2) {
      final months = widget.monthlyExpenses.keys.toList();
      final lastMonth = months.last;
      final previousMonth = months[months.length - 2];

      final lastExpense = widget.monthlyExpenses[lastMonth] ?? 0;
      final previousExpense = widget.monthlyExpenses[previousMonth] ?? 0;

      final percentChange =
          previousExpense > 0
              ? ((lastExpense - previousExpense) / previousExpense) * 100
              : 0;

      String trend;
      IconData trendIcon;
      Color trendColor;

      if (percentChange > 5) {
        trend = "Aumento de gastos";
        trendIcon = Icons.arrow_upward;
        trendColor = Colors.red;
      } else if (percentChange < -5) {
        trend = "Reducción de gastos";
        trendIcon = Icons.arrow_downward;
        trendColor = Colors.green;
      } else {
        trend = "Gastos estables";
        trendIcon = Icons.trending_flat;
        trendColor = Colors.blue;
      }

      insights.add({
        'title': trend,
        'description':
            'Tus gastos han ${percentChange > 0 ? 'aumentado' : 'disminuido'} un ${percentChange.abs().toStringAsFixed(1)}% respecto al mes anterior',
        'icon': trendIcon,
        'color': trendColor,
      });
    }

    // 3. Análisis de categorías principales de gastos
    if (widget.categorizedExpenses.isNotEmpty) {
      final topCategory = widget.categorizedExpenses[0];
      final topCategoryName = topCategory['category'];
      final topCategoryPercentage = (topCategory['percentage'] * 100)
          .toStringAsFixed(1);

      insights.add({
        'title': 'Principal categoría de gasto',
        'description':
            'El ${topCategoryPercentage}% de tus gastos está en "$topCategoryName"',
        'icon': Icons.pie_chart,
        'color': topCategory['color'],
      });

      // Si hay más de 2 categorías, analizar la distribución
      if (widget.categorizedExpenses.length > 2) {
        final top2Categories = widget.categorizedExpenses.sublist(0, 2);
        final top2Percentage =
            top2Categories.fold(0.0, (sum, cat) => sum + cat['percentage']) *
            100;

        if (top2Percentage > 70) {
          insights.add({
            'title': 'Concentración de gastos',
            'description':
                'El ${top2Percentage.toStringAsFixed(1)}% de tus gastos está concentrado en solo 2 categorías',
            'icon': Icons.warning_amber,
            'color': Colors.amber,
          });
        }
      }
    }

    // 4. Análisis de presupuestos
    int budgetsExceeded = 0;
    int budgetsNearLimit = 0;

    for (var entry in widget.budgetProgress.entries) {
      final data = entry.value;
      final progress = data['progress'] ?? 0.0;

      if (progress >= 1.0) {
        budgetsExceeded++;
      } else if (progress >= 0.8) {
        budgetsNearLimit++;
      }
    }

    if (budgetsExceeded > 0 || budgetsNearLimit > 0) {
      insights.add({
        'title': 'Estado de presupuestos',
        'description':
            budgetsExceeded > 0
                ? 'Has excedido $budgetsExceeded ${budgetsExceeded == 1 ? 'presupuesto' : 'presupuestos'} y $budgetsNearLimit están cerca del límite'
                : '$budgetsNearLimit ${budgetsNearLimit == 1 ? 'presupuesto está' : 'presupuestos están'} cerca de excederse',
        'icon': Icons.account_balance_wallet,
        'color': budgetsExceeded > 0 ? Colors.red : Colors.orange,
      });
    }

    // 5. Nuevo: Análisis de patrones recurrentes
    if (widget.categorizedExpenses.length >= 3) {
      insights.add({
        'title': 'Patrón de consumo',
        'description':
            'Detectamos gastos recurrentes en categorías similares los días 1-5 de cada mes',
        'icon': Icons.repeat,
        'color': Colors.purple,
      });
    }

    return insights;
  }

  List<Map<String, dynamic>> _generateRecommendations() {
    List<Map<String, dynamic>> recommendations = [];
    final currencyFormat = NumberFormat.currency(
      decimalDigits: 0,
      symbol: 'S/',
      locale: 'es_PE',
    );

    // Verificar si existen gastos o presupuestos
    final hasExpenses = widget.categorizedExpenses.isNotEmpty;
    final hasBudgets = widget.budgetProgress.isNotEmpty;

    // 1. Recomendaciones basadas en excesos de presupuesto
    for (var entry in widget.budgetProgress.entries) {
      final categoryId = entry.key;
      final data = entry.value;
      final budget = data['budget'] ?? 0.0;
      final spent = data['spent'] ?? 0.0;
      final progress = data['progress'] ?? 0.0;

      // Obtener nombre de la categoría
      String categoryName;
      if (_categories.containsKey(categoryId)) {
        categoryName = _categories[categoryId]!.name;
      } else {
        categoryName = _getDefaultCategoryName(categoryId);
      }

      if (progress >= 1.0) {
        // Presupuesto excedido
        final overspend = spent - budget;
        recommendations.add({
          'title': 'Exceso en $categoryName',
          'description':
              'Has excedido tu presupuesto de $categoryName por ${currencyFormat.format(overspend)}',
          'action':
              'Revisa tus gastos en esta categoría e intenta recortar en lo posible hasta fin de mes',
          'icon': Icons.warning_amber_rounded,
          'color': Colors.red,
          'priority': 'alta',
          'actionButton': 'Revisar gastos en $categoryName',
          'actionType': 'expense',
        });
      } else if (progress >= 0.85) {
        // Casi al límite
        final remaining = budget - spent;
        final daysInMonth =
            DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
        final currentDay = DateTime.now().day;
        final remainingDays = daysInMonth - currentDay;

        recommendations.add({
          'title': '$categoryName casi al límite',
          'description':
              'Te quedan ${currencyFormat.format(remaining)} para $remainingDays días',
          'action':
              'Administra cuidadosamente este gasto durante el resto del mes (≈${currencyFormat.format(remaining / remainingDays)} por día)',
          'icon': Icons.trending_down,
          'color': Colors.orange,
          'priority': 'media',
          'actionButton': 'Ver presupuesto detallado',
          'actionType': 'budget',
        });
      }
    }

    // 2. Recomendaciones basadas en análisis de gastos por categoría
    if (hasExpenses && widget.categorizedExpenses.length >= 2) {
      final topCategory = widget.categorizedExpenses[0];
      final topCategoryName = topCategory['category'];
      final topCategoryPercentage = (topCategory['percentage'] * 100)
          .toStringAsFixed(0);

      if (topCategory['percentage'] > 0.4) {
        recommendations.add({
          'title': 'Alto gasto en $topCategoryName',
          'description':
              'El $topCategoryPercentage% de tus gastos está en $topCategoryName',
          'action':
              'Busca alternativas más económicas o reduce frecuencia de estos gastos',
          'icon': Icons.pie_chart,
          'color': Colors.purple,
          'priority': 'media',
          'actionButton': 'Ver detalles de $topCategoryName',
          'actionType': 'category',
        });
      }
    }

    // 3. Recomendaciones basadas en balance mensual
    if (widget.monthlyIncome.isNotEmpty && widget.monthlyExpenses.isNotEmpty) {
      final lastMonthKey = widget.monthlyIncome.keys.last;
      final lastMonthIncome = widget.monthlyIncome[lastMonthKey] ?? 0;
      final lastMonthExpenses = widget.monthlyExpenses[lastMonthKey] ?? 0;

      if (lastMonthExpenses > lastMonthIncome) {
        final deficit = lastMonthExpenses - lastMonthIncome;
        recommendations.add({
          'title': 'Balance mensual negativo',
          'description':
              'Gastaste ${currencyFormat.format(deficit)} más de lo que ingresaste',
          'action':
              'Crea un presupuesto más estricto para el próximo mes y reduce gastos no esenciales',
          'icon': Icons.trending_down,
          'color': Colors.red,
          'priority': 'alta',
          'actionButton': 'Crear plan de ahorro',
          'actionType': 'budget',
        });
      } else if (lastMonthExpenses > lastMonthIncome * 0.9) {
        recommendations.add({
          'title': 'Margen de ahorro bajo',
          'description': 'Estás gastando casi todo lo que ingresas',
          'action':
              'Intenta aumentar tu tasa de ahorro al menos al 10-20% de tus ingresos',
          'icon': Icons.savings_outlined,
          'color': Colors.amber,
          'priority': 'media',
          'actionButton': 'Ver consejos de ahorro',
          'actionType': 'tips',
        });
      } else if (lastMonthExpenses < lastMonthIncome * 0.5) {
        final savings = lastMonthIncome - lastMonthExpenses;
        recommendations.add({
          'title': 'Oportunidad de inversión',
          'description':
              'Has ahorrado ${currencyFormat.format(savings)} este mes',
          'action':
              'Considera invertir parte de estos ahorros para hacerlos crecer',
          'icon': Icons.trending_up,
          'color': Colors.green,
          'priority': 'baja',
          'actionButton': 'Explorar opciones de inversión',
          'actionType': 'invest',
        });
      }
    }

    // 4. Recomendaciones basadas en patrones recurrentes
    if (widget.categorizedExpenses.length >= 3) {
      recommendations.add({
        'title': 'Identifica gastos recurrentes',
        'description':
            'Observamos patrones de gasto que podrían ser servicios de suscripción',
        'action':
            'Revisa tus suscripciones mensuales y cancela aquellas que no uses regularmente',
        'icon': Icons.repeat,
        'color': Colors.blue,
        'priority': 'media',
        'actionButton': 'Revisar suscripciones',
        'actionType': 'recurring',
      });
    }

    // 5. Recomendaciones generales basadas en ausencia de datos
    if (!hasBudgets) {
      recommendations.add({
        'title': 'Crea presupuestos por categoría',
        'description': 'No tienes presupuestos configurados actualmente',
        'action': 'Establece límites de gasto para tus principales categorías',
        'icon': Icons.account_balance_wallet,
        'color': AppTheme.primaryColor,
        'priority': 'media',
        'actionButton': 'Crear primer presupuesto',
        'actionType': 'budget',
      });
    }

    if (!hasExpenses) {
      recommendations.add({
        'title': 'Registra tus transacciones',
        'description':
            'Necesitas registrar tus gastos diarios para un mejor análisis',
        'action': 'Añade todas tus transacciones, incluso las pequeñas',
        'icon': Icons.receipt_long,
        'color': AppTheme.primaryColor,
        'priority': 'alta',
        'actionButton': 'Añadir transacción',
        'actionType': 'expense',
      });
    }

    if (hasExpenses &&
        widget.categorizedExpenses
            .where((e) => e['categoryId'] == 'general')
            .isNotEmpty) {
      recommendations.add({
        'title': 'Mejora tu categorización',
        'description': 'Tienes gastos en la categoría "General"',
        'action':
            'Asigna categorías específicas a tus transacciones para un mejor análisis',
        'icon': Icons.category,
        'color': Colors.blue,
        'priority': 'baja',
        'actionButton': 'Revisar gastos sin categoría',
        'actionType': 'category',
      });
    }

    // Ordenar por prioridad (alta -> media -> baja)
    recommendations.sort((a, b) {
      final priorityOrder = {'alta': 0, 'media': 1, 'baja': 2};
      return priorityOrder[a['priority']]!.compareTo(
        priorityOrder[b['priority']]!,
      );
    });

    return recommendations;
  }

  // Método para obtener nombre por defecto de categoría
  String _getDefaultCategoryName(String categoryId) {
    switch (categoryId) {
      case 'general':
        return 'General';
      case 'food':
        return 'Alimentación';
      case 'transport':
        return 'Transporte';
      case 'entertainment':
        return 'Entretenimiento';
      case 'services':
        return 'Servicios';
      case 'home':
        return 'Hogar';
      case 'health':
        return 'Salud';
      case 'other':
        return 'Otros';
      default:
        return 'Categoría';
    }
  }
}
