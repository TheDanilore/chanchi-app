import 'package:flutter/material.dart';
import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/models/currency_util.dart';

class MonthlyStats extends StatelessWidget {
  final int totalIncome;
  final int totalExpense;
  final int savings;

  const MonthlyStats({
    Key? key,
    required this.totalIncome,
    required this.totalExpense,
    required this.savings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(context, "Ingresos", totalIncome, Icons.arrow_downward, AppTheme.successColor),
            const SizedBox(width: AppTheme.spacingL),
            _buildStatCard(context, "Gastos", totalExpense, Icons.arrow_upward, AppTheme.errorColor),
          ],
        ),
        const SizedBox(height: AppTheme.spacingS),
        Container(
          margin: const EdgeInsets.only(top: AppTheme.spacingXS),
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: totalIncome > 0 ? totalExpense / totalIncome : 0,
              backgroundColor: Colors.grey.shade200,
              color: totalExpense < totalIncome ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: savings >= 0 ? AppTheme.successColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: savings >= 0 ? AppTheme.successColor.withOpacity(0.3) : AppTheme.errorColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(
                  savings >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: savings >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ahorro este mes",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryColor),
                  ),
                  Text(
                    CurrencyUtil.format(amount: savings, currencyCode: 'PEN'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: savings >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, int amount, IconData iconData, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: color, size: 16),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              CurrencyUtil.format(amount: amount, currencyCode: 'PEN'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              "Este mes",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
