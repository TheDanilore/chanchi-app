import 'package:flutter/material.dart';
import 'package:chanchi_app/config/theme.dart';

class ProfileStats extends StatelessWidget {
  final int totalTransactions;
  final int incomeCount;
  final int expenseCount;
  final ThemeData theme;

  const ProfileStats({
    Key? key,
    required this.totalTransactions,
    required this.incomeCount,
    required this.expenseCount,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem("Transacciones", totalTransactions.toString(), theme),
        _buildStatItem("Ingresos", incomeCount.toString(), theme),
        _buildStatItem("Gastos", expenseCount.toString(), theme),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            label, 
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}