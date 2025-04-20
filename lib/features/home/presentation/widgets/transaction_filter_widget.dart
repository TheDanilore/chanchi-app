import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/data/models/category.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:intl/intl.dart';

class TransactionFilterWidget extends StatefulWidget {
  final String userId;
  final Function(String?) onCategorySelected;
  final Function(String?) onAccountSelected;
  final Function(DateTime?, DateTime?) onDateRangeSelected;
  final Function() onClearFilters;
  final String? selectedCategoryId;
  final String? selectedAccountId;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime selectedMonth;
  final Map<String, Category> categoriesCache;
  final Map<String, Account> accountsCache;

  const TransactionFilterWidget({
    Key? key,
    required this.userId,
    required this.onCategorySelected,
    required this.onAccountSelected,
    required this.onDateRangeSelected,
    required this.onClearFilters,
    this.selectedCategoryId,
    this.selectedAccountId,
    this.startDate,
    this.endDate,
    required this.selectedMonth,
    required this.categoriesCache,
    required this.accountsCache,
  }) : super(key: key);

  @override
  _TransactionFilterWidgetState createState() =>
      _TransactionFilterWidgetState();
}

class _TransactionFilterWidgetState extends State<TransactionFilterWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilters =
        widget.selectedCategoryId != null ||
        widget.selectedAccountId != null ||
        widget.startDate != null ||
        widget.endDate != null;

    return Column(
      children: [
        // Cabecera del filtro
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Filtros",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    if (hasActiveFilters) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Activos",
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (hasActiveFilters)
                      TextButton(
                        onPressed: widget.onClearFilters,
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Limpiar",
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppTheme.textSecondaryColor,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Contenido expandible del filtro
        AnimatedCrossFade(
          firstChild: _buildExpandedFilterContent(),
          secondChild: const SizedBox(height: 0),
          crossFadeState:
              _isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),

        // Chip de filtros activos
        if (hasActiveFilters && !_isExpanded) _buildActiveFiltersChips(),
      ],
    );
  }

  Widget _buildExpandedFilterContent() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtro de categoría
          Row(
            children: [
              Icon(
                Icons.category,
                size: 14,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                "Categoría",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCategoryFilter(),
          const SizedBox(height: 16),

          // Filtro de cuenta
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 14,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                "Cuenta",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildAccountFilter(),
          const SizedBox(height: 16),

          // Filtro de fecha (dentro del mes seleccionado)
          Row(
            children: [
              Icon(
                Icons.date_range,
                size: 14,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                "Rango de fechas",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDateRangeFilter(),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (widget.selectedCategoryId != null)
            _buildFilterChip(
              widget.categoriesCache[widget.selectedCategoryId]?.name ??
                  "Categoría",
              Icons.category,
              () {
                widget.onCategorySelected(null);
              },
            ),
          if (widget.selectedAccountId != null)
            _buildFilterChip(
              widget.accountsCache[widget.selectedAccountId]?.name ?? "Cuenta",
              Icons.account_balance_wallet,
              () {
                widget.onAccountSelected(null);
              },
            ),
          if (widget.startDate != null && widget.endDate != null)
            _buildFilterChip(
              "${DateFormat('dd/MM').format(widget.startDate!)} - ${DateFormat('dd/MM').format(widget.endDate!)}",
              Icons.date_range,
              () {
                widget.onDateRangeSelected(null, null);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        deleteIcon: const Icon(
          Icons.close,
          size: 14,
          color: AppTheme.primaryColor,
        ),
        onDeleted: onRemove,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = widget.categoriesCache.values.toList();

    // Ordenar categorías por nombre
    categories.sort((a, b) => a.name.compareTo(b.name));

    return SizedBox(
      height: 84,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.9,
        ),
        itemCount: categories.length,
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = widget.selectedCategoryId == category.id;

          return GestureDetector(
            onTap: () {
              widget.onCategorySelected(isSelected ? null : category.id);
            },
            child: Container(
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? _getCategoryColor(category.color).withOpacity(0.9)
                        : _getCategoryColor(category.color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getCategoryColor(
                    category.color,
                  ).withOpacity(isSelected ? 0.9 : 0.3),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(category.iconName),
                    color:
                        isSelected
                            ? Colors.white
                            : _getCategoryColor(category.color),
                    size: 18,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          isSelected ? Colors.white : AppTheme.textPrimaryColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountFilter() {
    final accounts = widget.accountsCache.values.toList();

    if (accounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: Text(
          "No hay cuentas disponibles",
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final account = accounts[index];
          final isSelected = widget.selectedAccountId == account.id;

          return GestureDetector(
            onTap: () {
              widget.onAccountSelected(isSelected ? null : account.id);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                account.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    // Calcular el primer y último día del mes seleccionado
    final firstDayOfMonth = DateTime(
      widget.selectedMonth.year,
      widget.selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      widget.selectedMonth.year,
      widget.selectedMonth.month + 1,
      0,
    );

    // Dividir el mes en semanas para mostrar botones de filtrado rápido
    final weeks = _splitMonthIntoWeeks(firstDayOfMonth, lastDayOfMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botones para filtrar por semanas
        SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weeks.length,
            itemBuilder: (context, index) {
              final weekRange = weeks[index];
              final start = weekRange.item1;
              final end = weekRange.item2;

              // Verificar si esta semana está seleccionada
              final bool isSelected =
                  widget.startDate != null &&
                  widget.endDate != null &&
                  isSameDay(widget.startDate!, start) &&
                  isSameDay(widget.endDate!, end);

              return GestureDetector(
                onTap: () {
                  if (isSelected) {
                    widget.onDateRangeSelected(null, null);
                  } else {
                    widget.onDateRangeSelected(
                      DateTime(start.year, start.month, start.day, 0, 0, 0),
                      DateTime(end.year, end.month, end.day, 23, 59, 59),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Semana ${index + 1}",
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isSelected ? Colors.white : AppTheme.textPrimaryColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Botón para seleccionar rango personalizado
        OutlinedButton.icon(
          onPressed: () async {
            // Mostrar selector de rango de fechas
            final DateTimeRange? picked = await showDateRangePicker(
              context: context,
              firstDate: firstDayOfMonth,
              lastDate: lastDayOfMonth,
              initialDateRange:
                  widget.startDate != null && widget.endDate != null
                      ? DateTimeRange(
                        start: widget.startDate!,
                        end: widget.endDate!,
                      )
                      : DateTimeRange(
                        start: firstDayOfMonth,
                        end: lastDayOfMonth,
                      ),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppTheme.primaryColor,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: AppTheme.textPrimaryColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              // Ajustar para incluir todo el día de inicio y fin
              final startDate = DateTime(
                picked.start.year,
                picked.start.month,
                picked.start.day,
                0,
                0,
                0,
              );
              final endDate = DateTime(
                picked.end.year,
                picked.end.month,
                picked.end.day,
                23,
                59,
                59,
              );

              widget.onDateRangeSelected(startDate, endDate);
            }
          },
          icon: Icon(
            Icons.date_range,
            size: 14,
            color:
                widget.startDate != null
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryColor,
          ),
          label: Text(
            widget.startDate != null && widget.endDate != null
                ? "${DateFormat('dd MMM').format(widget.startDate!)} - ${DateFormat('dd MMM').format(widget.endDate!)}"
                : "Seleccionar rango personalizado",
            style: TextStyle(
              fontSize: 11,
              color:
                  widget.startDate != null
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color:
                  widget.startDate != null
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(double.infinity, 32),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          ),
        ),
      ],
    );
  }

  // Método para dividir el mes en semanas (para el filtro por semanas)
  List<Tuple2<DateTime, DateTime>> _splitMonthIntoWeeks(
    DateTime firstDay,
    DateTime lastDay,
  ) {
    List<Tuple2<DateTime, DateTime>> weeks = [];

    // Comenzar desde el primer día del mes
    DateTime weekStart = firstDay;

    while (weekStart.isBefore(lastDay) || isSameDay(weekStart, lastDay)) {
      // El fin de semana es 6 días después o el último día del mes, lo que ocurra primero
      DateTime weekEnd = weekStart.add(const Duration(days: 6));
      if (weekEnd.isAfter(lastDay)) {
        weekEnd = lastDay;
      }

      weeks.add(Tuple2(weekStart, weekEnd));

      // El siguiente inicio de semana
      weekStart = weekEnd.add(const Duration(days: 1));

      // Si ya pasamos el mes, terminar
      if (weekStart.month != firstDay.month) {
        break;
      }
    }

    return weeks;
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Color _getCategoryColor(String colorHex) {
    if (colorHex.startsWith('#')) {
      return Color(int.parse(colorHex.substring(1, 7), radix: 16) + 0xFF000000);
    }
    return AppTheme.primaryColor;
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'home':
        return Icons.home;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'school':
        return Icons.school;
      case 'credit_card':
        return Icons.credit_card;
      case 'monetization_on':
        return Icons.monetization_on;
      case 'attach_money':
        return Icons.attach_money;
      case 'payments':
        return Icons.payments;
      default:
        return Icons.category;
    }
  }
}

// Clase auxiliar para manejar tuplas
class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple2(this.item1, this.item2);
}
