import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/features/accounts/presentation/screens/credit_card_summary_screen.dart';
import 'package:chanchi_app/features/accounts/presentation/widgets/account_list.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/features/accounts/domain/services/account_service.dart';
import 'package:chanchi_app/features/accounts/presentation/widgets/add_account_form.dart';

class AccountsScreen extends StatefulWidget {
  final String userId;

  const AccountsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountService _accountService = AccountService();
  bool _isMigrating = false;
  bool _needsMigration = false;
  
  @override
  void initState() {
    super.initState();
    _checkMigrationNeeded();
  }
  
  Future<void> _checkMigrationNeeded() async {
    final needsMigration = await _accountService.needsMigration(widget.userId);
    if (mounted) {
      setState(() {
        _needsMigration = needsMigration;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Mis Cuentas",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                CreditCardSummaryScreen(userId: widget.userId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.credit_card, size: 18),
                  label: const Text("Tarjetas de Crédito"),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            // Botón de migración
            Visibility(
              visible: _needsMigration, // Solo mostrar cuando se necesite migración
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Actualización de cuentas",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Actualiza tus cuentas al nuevo formato para aprovechar todas las características.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isMigrating 
                              ? null 
                              : () => _migrateAccounts(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: _isMigrating
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text("Migrando..."),
                                  ],
                                )
                              : const Text("Actualizar cuentas"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Expanded(
              child: StreamBuilder<List<Account>>(
                stream: _accountService.getAccounts(widget.userId),
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

                  final accounts = snapshot.data ?? [];

                  return AccountList(
                    accounts: accounts,
                    onEditAccount: _editAccount,
                    onAddAccount: () => _showAddAccountDialog(context),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Método para migrar las cuentas
  Future<void> _migrateAccounts(BuildContext context) async {
    setState(() {
      _isMigrating = true;
    });
    
    try {
      await _accountService.migrateAccountTypes(widget.userId);
      
      if (mounted) {
        // Actualizar el estado para ocultar el botón
        setState(() {
          _needsMigration = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Cuentas actualizadas con éxito!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al actualizar cuentas: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMigrating = false;
        });
      }
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
            account: null,
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