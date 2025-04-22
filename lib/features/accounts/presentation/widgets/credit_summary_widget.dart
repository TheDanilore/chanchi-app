import 'package:flutter/material.dart';
import 'package:chanchi_app/core/utils/currency_util.dart';
import 'package:chanchi_app/data/models/account.dart';

class CreditSummaryWidget extends StatelessWidget {
  final List<Account> cards;

  const CreditSummaryWidget({
    super.key,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    double totalUsed = 0;
    double totalAvailable = 0;
    double totalLimit = 0;

    for (var card in cards) {
      if (card.isCreditCard && card.creditLimit != null) {
        totalUsed += card.balance;
        totalLimit += card.creditLimit!;
        totalAvailable += (card.creditLimit! - card.balance);
      }
    }

    final usagePercentage = totalLimit > 0 ? (totalUsed / totalLimit) * 100 : 0;

    // Determinar color según porcentaje de uso
    Color usageColor = Colors.green;
    if (usagePercentage > 90) {
      usageColor = Colors.red;
    } else if (usagePercentage > 70) {
      usageColor = Colors.orange;
    } else if (usagePercentage > 50) {
      usageColor = Colors.amber;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Resumen de Crédito",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: usageColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: usageColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    "${usagePercentage.toStringAsFixed(1)}% utilizado",
                    style: TextStyle(
                      color: usageColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: totalLimit > 0 ? totalUsed / totalLimit : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(usageColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCreditStatItem(
                    context,
                    "Deuda Total",
                    totalUsed,
                    Colors.red[700]!,
                  ),
                ),
                Expanded(
                  child: _buildCreditStatItem(
                    context,
                    "Disponible",
                    totalAvailable,
                    Colors.green[700]!,
                  ),
                ),
                Expanded(
                  child: _buildCreditStatItem(
                    context,
                    "Límite Total",
                    totalLimit,
                    Colors.blue[700]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditStatItem(
    BuildContext context,
    String title,
    double amount,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyUtil.format(amount: amount, currencyCode: 'PEN'),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}