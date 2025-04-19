import 'package:flutter/material.dart';
import 'package:chanchi_app/core/config/theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback? onClearFilters;

  const EmptyStateWidget({
    Key? key,
    this.isFiltered = false,
    this.onClearFilters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            isFiltered
                ? "No hay transacciones con los filtros seleccionados"
                : "No hay transacciones",
            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 16),
          ),
          if (isFiltered && onClearFilters != null) ...[
            const SizedBox(height: AppTheme.spacingM),
            TextButton.icon(
              onPressed: onClearFilters,
              icon: Icon(Icons.filter_list_off, color: AppTheme.primaryColor),
              label: Text(
                "Quitar filtros",
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}