import 'package:chanchi_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/data/models/budget.dart';
import 'package:chanchi_app/data/models/category.dart';
import 'package:chanchi_app/services/budget_service.dart';
import 'package:chanchi_app/services/category_service.dart';
import 'package:intl/intl.dart';

class BudgetDashboardWidget extends StatefulWidget {
  final String userId;

  const BudgetDashboardWidget({Key? key, required this.userId})
    : super(key: key);

  @override
  State<BudgetDashboardWidget> createState() => BudgetDashboardWidgetState();
}

class BudgetDashboardWidgetState extends State<BudgetDashboardWidget> {
  final BudgetService _budgetService = BudgetService();
  final CategoryService _categoryService = CategoryService();
  List<Budget> _budgets = [];
  Map<String, Category> _categoriesMap = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Cargar categorías
      final categories = await _categoryService.getCategories();

      if (mounted) {
        setState(() {
          _categoriesMap = {for (var cat in categories) cat.id: cat};
        });
      }

      // Iniciar la escucha de presupuestos
      _budgetService
          .getCurrentMonthBudgets(widget.userId)
          .listen(
            (budgets) {
              if (mounted) {
                setState(() {
                  _budgets = budgets;
                  _isLoading = false;
                });

                // Verificar notificaciones
                if (budgets.isNotEmpty) {
                  _budgetService.checkBudgetNotifications(budgets, context);
                }
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = "Error al cargar presupuestos: $error";
                });
                print('Error al cargar presupuestos: $error');
              }
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = "Error al cargar datos: $e";
        });
        print('Error al cargar datos de presupuesto: $e');
      }
    }
  }


// Método de actualización
  Future<void> refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return InkWell(
        onTap: _loadData, // Reintentar al hacer clic
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error al cargar presupuestos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_budgets.isEmpty) {
      return GestureDetector(
        onTap: () => _showAddBudgetDialog(context),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configura un presupuesto',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Establece límites de gastos mensuales',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Presupuestos del Mes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                // Agregar botón de recálculo
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Recalcular gastos',
                  onPressed: _recalculateAllBudgets,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showAddBudgetDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spacingM),
        // Lista de presupuestos
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _budgets.length,
          itemBuilder: (context, index) {
            final budget = _budgets[index];
            return _buildBudgetCard(budget, context);
          },
        ),
      ],
    );
  }

  Widget _buildBudgetCard(Budget budget, BuildContext context) {
    // Obtener categoría si existe
    final category =
        budget.categoryId != null ? _categoriesMap[budget.categoryId] : null;

    // Formatear cantidades
    final formattedAmount = NumberFormat.currency(
      symbol: 'S/ ',
      decimalDigits: 2,
    ).format(budget.amount);
    final formattedSpent = NumberFormat.currency(
      symbol: 'S/ ',
      decimalDigits: 2,
    ).format(budget.currentSpent ?? 0);
    final formattedRemaining = NumberFormat.currency(
      symbol: 'S/ ',
      decimalDigits: 2,
    ).format(budget.remainingAmount);

    // Determinar color según el estado
    Color progressColor;
    if (budget.percentageUsed >= 1.0) {
      progressColor = AppTheme.errorColor;
    } else if (budget.percentageUsed >= budget.notificationThreshold) {
      progressColor = Colors.orange;
    } else {
      progressColor = AppTheme.primaryColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y tipo de presupuesto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    category?.name ?? 'Presupuesto General',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formattedAmount,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingM),

            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              child: LinearProgressIndicator(
                value:
                    budget.percentageUsed > 1.0 ? 1.0 : budget.percentageUsed,
                backgroundColor: Colors.grey.shade200,
                color: progressColor,
                minHeight: 8,
              ),
            ),

            const SizedBox(height: AppTheme.spacingS),

            // Datos de gasto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gastado: $formattedSpent',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Restante: $formattedRemaining',
                  style: TextStyle(
                    color:
                        budget.remainingAmount < 0
                            ? AppTheme.errorColor
                            : AppTheme.textSecondaryColor,
                    fontSize: 14,
                    fontWeight:
                        budget.remainingAmount < 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingS),

            // Acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showEditBudgetDialog(context, budget),
                  child: const Text('Editar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _confirmDeleteBudget(context, budget),
                  child: const Text('Eliminar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo para añadir un nuevo presupuesto
  Future<void> _showAddBudgetDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    double amount = 0.0;
    String? selectedCategoryId;
    // Usamos variables locales en lugar de estado del widget
    double thresholdValue = 0.8; // 80% por defecto
    bool notifyCloseValue = true;
    bool notifyReachedValue = true;
    bool notifyExceededValue = true;

    final notificationService = NotificationService();
    // Verificar permisos de notificación
    bool hasPermission =
        await notificationService.requestNotificationPermissions();

    if (!hasPermission) {
      // Mostrar diálogo explicativo si no hay permisos
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Permisos de Notificación'),
              content: const Text(
                'Para recibir alertas de presupuesto, necesitamos tu permiso para enviar notificaciones. ¿Deseas habilitar las notificaciones?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await notificationService.requestNotificationPermissions();
                  },
                  child: const Text('Habilitar'),
                ),
              ],
            ),
      );
    }

    // Cargar categorías si es necesario
    if (_categoriesMap.isEmpty) {
      try {
        final categories = await _categoryService.getCategories();
        setState(() {
          _categoriesMap = {for (var cat in categories) cat.id: cat};
        });
      } catch (e) {
        print('Error al cargar categorías: $e');
        // Mostrar error pero continuar con el diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar categorías: $e')),
        );
      }
    }

    // Lista de categorías para el desplegable
    final categoryItems = [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('General (todos los gastos)'),
      ),
      ..._categoriesMap.values
          .where((c) => c.type == 'expense')
          .map(
            (c) => DropdownMenuItem<String>(value: c.id, child: Text(c.name)),
          )
          .toList(),
    ];

    await showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Nuevo Presupuesto'),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Categoría
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                            ),
                            value: selectedCategoryId,
                            items: categoryItems,
                            onChanged: (value) {
                              selectedCategoryId = value;
                            },
                          ),

                          const SizedBox(height: AppTheme.spacingM),

                          // Monto
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Límite de presupuesto',
                              prefixText: 'S/ ',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa un monto';
                              }
                              if (double.tryParse(value) == null ||
                                  double.parse(value) <= 0) {
                                return 'Ingresa un monto válido';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              amount = double.parse(value!);
                            },
                          ),

                          const SizedBox(height: AppTheme.spacingM),

                          // Umbral de notificación
                          Text(
                            'Notificar cuando alcance:',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                          Slider(
                            value: thresholdValue,
                            min: 0.5,
                            max: 0.95,
                            divisions: 9,
                            label: '${(thresholdValue * 100).round()}%',
                            onChanged: (value) {
                              setDialogState(() {
                                thresholdValue = value;
                              });
                            },
                          ),

                          const SizedBox(height: AppTheme.spacingM),

                          // Opciones de notificación
                          CheckboxListTile(
                            title: const Text(
                              'Notificar cuando esté cerca del límite',
                            ),
                            value: notifyCloseValue,
                            onChanged: (value) {
                              setDialogState(() {
                                notifyCloseValue = value ?? true;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),

                          CheckboxListTile(
                            title: const Text(
                              'Notificar cuando alcance el límite',
                            ),
                            value: notifyReachedValue,
                            onChanged: (value) {
                              setDialogState(() {
                                notifyReachedValue = value ?? true;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),

                          CheckboxListTile(
                            title: const Text(
                              'Notificar cuando exceda el límite',
                            ),
                            value: notifyExceededValue,
                            onChanged: (value) {
                              setDialogState(() {
                                notifyExceededValue = value ?? true;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();

                          try {
                            // Crear presupuesto
                            final currentMonth = DateFormat(
                              'yyyy-MM',
                            ).format(DateTime.now());
                            final budget = Budget(
                              id: '', // Será generado por Firestore
                              userId: widget.userId,
                              amount: amount,
                              categoryId: selectedCategoryId,
                              month: currentMonth,
                              currentSpent: 0.0,
                              notifyWhenClose: notifyCloseValue,
                              notifyWhenReached: notifyReachedValue,
                              notifyWhenExceeded: notifyExceededValue,
                              notificationThreshold: thresholdValue,
                            );

                            await _budgetService.createBudget(budget);
                            Navigator.pop(dialogContext);

                            // Mostrar mensaje de éxito
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Presupuesto creado con éxito'),
                                ),
                              );
                            }
                          } catch (e) {
                            // Mostrar error
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al crear presupuesto: $e',
                                  ),
                                ),
                              );
                            }
                            print('Error al crear presupuesto: $e');
                          }
                        }
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
          ),
    );
  }

  // Corrección para el diálogo de presupuesto en BudgetDashboardWidget
  // Modificar el método _showEditBudgetDialog para ajustar el ancho del diálogo y evitar overflows

  Future<void> _showEditBudgetDialog(
    BuildContext context,
    Budget budget,
  ) async {
    final formKey = GlobalKey<FormState>();
    double amount = budget.amount;
    String? selectedCategoryId = budget.categoryId;
    double thresholdValue = budget.notificationThreshold;
    bool notifyCloseValue = budget.notifyWhenClose;
    bool notifyReachedValue = budget.notifyWhenReached;
    bool notifyExceededValue = budget.notifyWhenExceeded;

    // Lista de categorías para el desplegable con manejo de overflow
    final categoryItems = [
      const DropdownMenuItem<String>(
        value: null,
        child: Text(
          'General (todos los gastos)',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      ..._categoriesMap.values
          .where((c) => c.type == 'expense')
          .map(
            (c) => DropdownMenuItem<String>(
              value: c.id,
              child: Text(c.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
    ];

    await showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  // Aumentar el ancho usando IntrinsicWidth
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Editar Presupuesto',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Form(
                                key: formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Categoría (no editable si ya tiene gastos registrados)
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Categoría',
                                        isCollapsed: false,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 10,
                                        ),
                                      ),
                                      value: selectedCategoryId,
                                      items: categoryItems,
                                      isExpanded:
                                          true, // Importante para evitar overflow
                                      onChanged:
                                          (budget.currentSpent ?? 0) > 0
                                              ? null
                                              : (value) {
                                                selectedCategoryId = value;
                                              },
                                      hint:
                                          (budget.currentSpent ?? 0) > 0
                                              ? const Text(
                                                'No se puede cambiar (ya tiene gastos)',
                                                overflow: TextOverflow.ellipsis,
                                              )
                                              : null,
                                    ),

                                    const SizedBox(height: AppTheme.spacingM),

                                    // Monto
                                    TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Límite de presupuesto',
                                        prefixText: 'S/ ',
                                      ),
                                      initialValue: amount.toString(),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Ingresa un monto';
                                        }
                                        if (double.tryParse(value) == null ||
                                            double.parse(value) <= 0) {
                                          return 'Ingresa un monto válido';
                                        }
                                        return null;
                                      },
                                      onSaved: (value) {
                                        amount = double.parse(value!);
                                      },
                                    ),

                                    const SizedBox(height: AppTheme.spacingM),

                                    // Umbral de notificación
                                    Text(
                                      'Notificar cuando alcance:',
                                      style: TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Slider(
                                      value: thresholdValue,
                                      min: 0.5,
                                      max: 0.95,
                                      divisions: 9,
                                      label:
                                          '${(thresholdValue * 100).round()}%',
                                      onChanged: (value) {
                                        setDialogState(() {
                                          thresholdValue = value;
                                        });
                                      },
                                    ),

                                    const SizedBox(height: AppTheme.spacingM),

                                    // Opciones de notificación
                                    CheckboxListTile(
                                      title: const Text(
                                        'Notificar cuando esté cerca del límite',
                                      ),
                                      value: notifyCloseValue,
                                      onChanged: (value) {
                                        setDialogState(() {
                                          notifyCloseValue = value ?? true;
                                        });
                                      },
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    ),

                                    CheckboxListTile(
                                      title: const Text(
                                        'Notificar cuando alcance el límite',
                                      ),
                                      value: notifyReachedValue,
                                      onChanged: (value) {
                                        setDialogState(() {
                                          notifyReachedValue = value ?? true;
                                        });
                                      },
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    ),

                                    CheckboxListTile(
                                      title: const Text(
                                        'Notificar cuando exceda el límite',
                                      ),
                                      value: notifyExceededValue,
                                      onChanged: (value) {
                                        setDialogState(() {
                                          notifyExceededValue = value ?? true;
                                        });
                                      },
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Cancelar'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    formKey.currentState!.save();

                                    try {
                                      // Actualizar presupuesto
                                      final updatedBudget = budget.copyWith(
                                        amount: amount,
                                        categoryId: selectedCategoryId,
                                        notifyWhenClose: notifyCloseValue,
                                        notifyWhenReached: notifyReachedValue,
                                        notifyWhenExceeded: notifyExceededValue,
                                        notificationThreshold: thresholdValue,
                                      );

                                      await _budgetService.updateBudget(
                                        updatedBudget,
                                      );
                                      Navigator.pop(dialogContext);

                                      // Mostrar mensaje de éxito
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Presupuesto actualizado con éxito',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      // Mostrar error
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error al actualizar presupuesto: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                child: const Text('Guardar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  // Confirmar eliminación de presupuesto
  Future<void> _confirmDeleteBudget(BuildContext context, Budget budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Eliminar Presupuesto'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar este presupuesto?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _budgetService.disableBudget(budget.id);

        // Mostrar mensaje de éxito
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Presupuesto eliminado con éxito')),
          );
        }
      } catch (e) {
        // Mostrar error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar presupuesto: $e')),
          );
        }
        print('Error al eliminar presupuesto: $e');
      }
    }
  }

  /// Recalcula el gasto real de todos los presupuestos mostrados
  Future<void> _recalculateAllBudgets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Recalcular cada presupuesto
      for (final budget in _budgets) {
        await _budgetService.recalculateBudgetSpent(budget);
      }

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presupuestos actualizados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error al recalcular presupuestos: $e');
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar presupuestos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Refrescar la vista (los cambios se verán gracias al Stream)
      setState(() {
        _isLoading = false;
      });
    }
  }
}
