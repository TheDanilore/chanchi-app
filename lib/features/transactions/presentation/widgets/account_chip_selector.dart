// lib/features/transactions/presentation/widgets/account_chip_selector.dart
import 'package:flutter/material.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/data/models/account.dart';

class AccountChipSelector extends StatelessWidget {
  final List<Account> accounts;
  final String? selectedAccountId;
  final Function(String) onAccountSelected;

  const AccountChipSelector({
    Key? key,
    required this.accounts,
    this.selectedAccountId,
    required this.onAccountSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return ListTile(
        title: const Text("No tienes cuentas configuradas"),
        subtitle: const Text("Debes crear al menos una cuenta"),
        trailing: const Icon(Icons.warning, color: AppTheme.warningColor),
        tileColor: AppTheme.warningColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cuenta', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppTheme.spacingS),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: accounts.map((account) {
              final isSelected = account.id == selectedAccountId;
              final color = account.color != null
                  ? Color(int.parse(account.color!.substring(1, 7), radix: 16) + 0xFF000000)
                  : AppTheme.primaryColor;

              return Padding(
                padding: const EdgeInsets.only(right: AppTheme.spacingS),
                child: ChoiceChip(
                  label: Text(account.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onAccountSelected(account.id);
                    }
                  },
                  avatar: Icon(
                    _getAccountIcon(account.iconName),
                    size: 18,
                    color: isSelected ? Colors.white : color,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.transparent,
                  selectedColor: color,
                  side: BorderSide(color: color),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getAccountIcon(String? iconName) {
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