import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chanchi_app/config/theme.dart';

class TransactionFiltersWidget extends StatelessWidget {
  final bool showFilterOptions;
  final VoidCallback onToggleFilterOptions;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onShowDateRangePicker; 
  final DateTime selectedMonth;

  const TransactionFiltersWidget({
    Key? key,
    required this.showFilterOptions,
    required this.onToggleFilterOptions,
    required this.startDate,
    required this.endDate,
    required this.onShowDateRangePicker,
    required this.selectedMonth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(
        bottom: AppTheme.spacingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Filtros",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (startDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Activos",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: Icon(
                  showFilterOptions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppTheme.textSecondaryColor,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onToggleFilterOptions,
              ),
            ],
          ),
          if (showFilterOptions) ...[
            const SizedBox(height: AppTheme.spacingS),
            _buildDateFilterChip(context),
          ],
        ],
      ),
    );
  }

  Widget _buildDateFilterChip(BuildContext context) {
    final hasDateFilter = startDate != null || endDate != null;

    String chipLabel = "Fecha";
    if (hasDateFilter) {
      final DateFormat formatter = DateFormat('dd/MM');
      if (startDate != null && endDate != null) {
        chipLabel = "${formatter.format(startDate!)} - ${formatter.format(endDate!)}";
      } else if (startDate != null) {
        chipLabel = "Desde ${formatter.format(startDate!)}";
      } else if (endDate != null) {
        chipLabel = "Hasta ${formatter.format(endDate!)}";
      }
    }

    return FilterChip(
      label: Text(chipLabel),
      labelStyle: TextStyle(
        color: hasDateFilter ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      avatar: Icon(
        Icons.date_range,
        size: 16,
        color: hasDateFilter ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
      ),
      backgroundColor: Colors.white,
      selectedColor: hasDateFilter ? AppTheme.primaryColor.withOpacity(0.1) : null,
      selected: hasDateFilter,
      showCheckmark: false,
      elevation: 1,
      shadowColor: Colors.black12,
      side: BorderSide(
        color: hasDateFilter ? AppTheme.primaryColor : Colors.grey.shade300,
        width: 1,
      ),
      onSelected: (_) => onShowDateRangePicker(), 
    );
  }
}