import 'package:chanchi_app/models/currency_util.dart';
import 'package:chanchi_app/presentation/widgets/add_account_form.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/models/account.dart';

class AccountsScreen extends StatefulWidget {
  final String userId;

  const AccountsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingM, // Reducir espacio vertical
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Mis Cuentas",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('users')
                        .doc(widget.userId)
                        .collection('accounts')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error al cargar las cuentas: ${snapshot.error}",
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    );
                  }

                  final accounts = snapshot.data?.docs ?? [];

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
                            onPressed: () => _showAddAccountDialog(context),
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
                    itemCount:
                        accounts.length + 1, // +1 para el botón de añadir
                    itemBuilder: (context, index) {
                      if (index == accounts.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingM,
                          ),
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddAccountDialog(context),
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

                      final doc = accounts[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final account = Account.fromMap(data, doc.id);

                      return _buildAccountCard(account);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    final Color accountColor =
        account.color != null
            ? Color(
              int.parse(account.color!.substring(1, 7), radix: 16) + 0xFF000000,
            )
            : AppTheme.primaryColor;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: InkWell(
        onTap: () => _editAccount(account),
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
                      color:
                          account.balance >= 0
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

  void _showAddAccountDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      builder:
          (context) => AddAccountForm(
            userId: widget.userId,
            // Importante: Añade estos parámetros si es necesario
            account: null, // Si es una nueva cuenta
            isEditing: false,
          ),
    );
  }

  void _editAccount(Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      builder:
          (context) => AddAccountForm(
            userId: widget.userId,
            account: account,
            isEditing: true,
          ),
    );
  }
}
