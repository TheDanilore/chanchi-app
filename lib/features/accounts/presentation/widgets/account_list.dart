import 'package:chanchi_app/core/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/features/accounts/presentation/widgets/account_card.dart';

class AccountList extends StatelessWidget {
  final List<Account> accounts;
  final Function(Account) onEditAccount;
  final VoidCallback onAddAccount;

  const AccountList({
    Key? key,
    required this.accounts,
    required this.onEditAccount,
    required this.onAddAccount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              "No tienes cuentas aún",
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            ElevatedButton.icon(
              onPressed: onAddAccount,
              icon: const Icon(Icons.add),
              label: const Text("Añadir Cuenta"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingM,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: accounts.length + 1, // +1 para el botón de añadir
      itemBuilder: (context, index) {
        if (index == accounts.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spacingM,
            ),
            child: OutlinedButton.icon(
              onPressed: onAddAccount,
              icon: const Icon(Icons.add),
              label: const Text("Añadir Nueva Cuenta"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingM,
                ),
              ),
            ),
          );
        }

        return AccountCard(
          account: accounts[index],
          onTap: onEditAccount,
        );
      },
    );
  }
}