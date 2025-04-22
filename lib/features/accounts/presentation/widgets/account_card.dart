import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/core/utils/currency_util.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/data/models/account.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final Function(Account) onTap;

  const AccountCard({
    super.key,
    required this.account,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accountColor = account.color != null
        ? Color(int.parse(account.color!.substring(1, 7), radix: 16) + 0xFF000000)
        : AppTheme.primaryColor;

    // Mostrar distinto si es tarjeta de crédito
    if (account.isCreditCard) {
      return _buildCreditCardItem(context, accountColor);
    } else {
      return _buildRegularAccountItem(context, accountColor);
    }
  }

  Widget _buildRegularAccountItem(BuildContext context, Color accountColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: InkWell(
        onTap: () => onTap(account),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accountColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                ),
                child: Icon(
                  _getIconData(account.iconName),
                  color: accountColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      "${account.type} - ${account.institution}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyUtil.format(
                      amount: account.balance,
                      currencyCode: account.currencyCode ?? 'PEN',
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: account.balance >= 0
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
                  ),
                  Text(
                    "Balance actual",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditCardItem(BuildContext context, Color accountColor) {
    // Calcular porcentaje de uso
    final double? usagePercentage = account.creditUsagePercentage;
    final double availableCredit = account.availableBalance;
    
    // Determinar el color según el porcentaje de uso
    Color usageColor = Colors.green;
    if (usagePercentage != null) {
      if (usagePercentage > 90) {
        usageColor = Colors.red;
      } else if (usagePercentage > 70) {
        usageColor = Colors.orange;
      } else if (usagePercentage > 50) {
        usageColor = Colors.amber;
      }
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: InkWell(
        onTap: () => onTap(account),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accountColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    ),
                    child: Icon(
                      Icons.credit_card,
                      color: accountColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          "${account.institution}",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (account.billingCycleEndDate != null)
                          Text(
                            "Cierre: día ${account.billingCycleEndDate!.day}",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (account.includeInTotalBalance)
                        Chip(
                          label: Text("En balance", style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.green[100],
                          labelStyle: TextStyle(color: Colors.green[800]),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyUtil.format(
                          amount: account.balance,
                          currencyCode: account.currencyCode ?? 'PEN',
                        ),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Utilizado",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Barra de progreso del crédito usado
            if (account.creditLimit != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: account.balance / account.creditLimit!,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(usageColor),
                      minHeight: 5,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Disponible: ${CurrencyUtil.format(
                              amount: availableCredit,
                              currencyCode: account.currencyCode ?? 'PEN',
                            )}",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Límite: ${CurrencyUtil.format(
                              amount: account.creditLimit!,
                              currencyCode: account.currencyCode ?? 'PEN',
                            )}",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
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

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'credit_card':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      case 'account_balance':
        return Icons.account_balance;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
