// lib/features/transactions/presentation/widgets/transaction_type_selector.dart
import 'package:flutter/material.dart';
import 'package:chanchi_app/core/config/theme.dart';

class TransactionTypeSelector extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeChanged;

  const TransactionTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onTypeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTypeButton(
            type: 'expense',
            icon: Icons.arrow_upward,
            label: 'Gasto',
            color: AppTheme.errorColor,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildTypeButton(
            type: 'income',
            icon: Icons.arrow_downward,
            label: 'Ingreso',
            color: AppTheme.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton({
    required String type,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = selectedType == type;

    return OutlinedButton.icon(
      onPressed: () => onTypeChanged(type),
      icon: Icon(icon, color: isSelected ? Colors.white : color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : color,
        backgroundColor: isSelected ? color : Colors.transparent,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
      ),
    );
  }
}