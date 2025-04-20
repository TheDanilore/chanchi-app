import 'package:flutter/material.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/core/utils/currency_util.dart';

class AccountsList extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;
  final bool isBalanceHidden;

  const AccountsList({
    Key? key,
    required this.accounts,
    required this.isBalanceHidden,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Cuentas Principales",
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            children:
                accounts.map((account) {
                  final balance = (account['balance'] ?? 0.0).toDouble();
                  final isPositive = balance >= 0;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getAccountColor(account).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusM,
                              ),
                            ),
                            child: Icon(
                              _getAccountIcon(account['iconName']),
                              color: _getAccountColor(account),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account['name'] ?? 'Sin nombre',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.copyWith(
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                Text(
                                  "${account['type'] ?? ''} - ${account['institution'] ?? ''}",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            isBalanceHidden
                                ? "S/•••.••"
                                : CurrencyUtil.format(
                                  amount: balance,
                                  currencyCode:
                                      account['currencyCode'] ?? 'PEN',
                                ),
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(
                              color:
                                  isPositive
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (account != accounts.last)
                        Divider(color: Colors.grey.shade300, height: 24),
                    ],
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getAccountIcon(dynamic iconName) {
    if (iconName is String) {
      switch (iconName) {
        case 'credit_card':
          return Icons.credit_card;
        case 'savings':
          return Icons.savings;
        case 'account_balance':
          return Icons.account_balance;
        case 'wallet':
          return Icons.account_balance_wallet;
      }
    }
    return Icons.account_balance_wallet;
  }

  Color _getAccountColor(Map<String, dynamic> data) {
    final color = data['color'];
    if (color != null && color is String && color.startsWith('#')) {
      return Color(int.parse(color.substring(1, 7), radix: 16) + 0xFF000000);
    }
    return AppTheme.primaryColor;
  }
}
