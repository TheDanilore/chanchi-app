import 'package:chanchi_app/core/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/features/accounts/domain/services/account_service.dart';
import 'package:chanchi_app/features/accounts/presentation/widgets/account_card.dart';

class AccountList extends StatelessWidget {
  final List<Account> accounts;
  final Function(Account) onEditAccount;
  final VoidCallback onAddAccount;
  final AccountService _accountService = AccountService();

  AccountList({
    Key? key,
    required this.accounts,
    required this.onEditAccount,
    required this.onAddAccount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildAccountList(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            "No tienes cuentas aún",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            "Añade tu primera cuenta para comenzar a rastrear tus finanzas",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXL),
          ElevatedButton.icon(
            onPressed: onAddAccount,
            icon: const Icon(Icons.add),
            label: const Text("Añadir Cuenta"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXL,
                vertical: AppTheme.spacingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList(BuildContext context) {
    return ListView.builder(
      itemCount: accounts.length + 1, // +1 para el botón de añadir
      itemBuilder: (context, index) {
        if (index == accounts.length) {
          return _buildAddAccountButton(context);
        }
        return _buildAccountItem(context, accounts[index]);
      },
    );
  }

  Widget _buildAddAccountButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spacingM,
        horizontal: AppTheme.spacingS,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          side: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: onAddAccount,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  "Añadir Nueva Cuenta",
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountItem(BuildContext context, Account account) {
    return Dismissible(
      key: Key(account.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _confirmDelete(context, account),
      onDismissed: (direction) {
        _deleteAccount(context, account);
      },
      child: InkWell(
        onTap: () => onEditAccount(account),
        onLongPress: () => _showAccountOptions(context, account),
        child: AccountCard(account: account, onTap: onEditAccount),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Account account) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          title: Text("Eliminar ${account.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("¿Estás seguro que deseas eliminar esta cuenta?"),
              const SizedBox(height: AppTheme.spacingM),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Text(
                        "Esta acción no se puede deshacer y eliminará todas las transacciones asociadas a esta cuenta.",
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Eliminar"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount(BuildContext context, Account account) async {
    try {
      // Depuración para ver la estructura del ID
      print('ID completo de la cuenta: ${account.id}');

      // Verificar si el ID incluye el userId
      final parts = account.id.split('/');

      String userId;
      String accountId;

      if (parts.length > 1) {
        // Si el ID tiene más de una parte, asumir que la primera es el userId
        userId = parts[0];
        accountId = parts[1];
      } else {
        // Si solo hay una parte, usar el userId pasado desde el padre
        // Esto requiere modificar cómo se pasa el userId al AccountList
        throw Exception('Estructura de ID de cuenta no válida');
      }

      print('User ID extraído: $userId');
      print('Account ID extraído: $accountId');

      await _accountService.deleteAccount(userId, accountId);

      // Resto del código de éxito...
    } catch (e) {
      print('Error en _deleteAccount: $e');

      // Mostrar error con un diseño más informativo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Error al eliminar la cuenta: ${e.toString()}",
                  style: TextStyle(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 150,
            left: 16,
            right: 16,
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showAccountOptions(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      account.color != null
                          ? Color(
                            int.parse(
                                  account.color!.substring(1, 7),
                                  radix: 16,
                                ) +
                                0xFF000000,
                          ).withOpacity(0.2)
                          : AppTheme.primaryColor.withOpacity(0.2),
                  child: Icon(
                    _getIconData(account.iconName),
                    color:
                        account.color != null
                            ? Color(
                              int.parse(
                                    account.color!.substring(1, 7),
                                    radix: 16,
                                  ) +
                                  0xFF000000,
                            )
                            : AppTheme.primaryColor,
                  ),
                ),
                title: Text(
                  account.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("${account.type} · ${account.institution}"),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.edit, color: AppTheme.primaryColor),
                title: const Text("Editar cuenta"),
                onTap: () {
                  Navigator.pop(context);
                  onEditAccount(account);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text("Ver historial de transacciones"),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar navegación al historial
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text("Eliminar cuenta"),
                onTap: () async {
                  Navigator.pop(context);
                  if (await _confirmDelete(context, account)) {
                    _deleteAccount(context, account);
                  }
                },
              ),
            ],
          ),
        );
      },
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
      case 'money':
        return Icons.attach_money;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
