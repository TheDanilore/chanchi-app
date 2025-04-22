import 'dart:async';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/features/accounts/presentation/screens/add_account_screen.dart'; 
import 'package:chanchi_app/features/accounts/presentation/screens/credit_card_summary_screen.dart';
import 'package:chanchi_app/features/accounts/presentation/widgets/account_list.dart';
import 'package:chanchi_app/features/transactions/domain/services/transaction_service.dart';
import 'package:chanchi_app/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:chanchi_app/features/transactions/presentation/screens/transfer_screen.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/features/accounts/domain/services/account_service.dart';

class AccountsScreen extends StatefulWidget {
  final String userId;

  const AccountsScreen({super.key, required this.userId});
  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountService _accountService = AccountService();
  bool _isMigrating = false;
  bool _needsMigration = false;
  bool _isRefreshing = false;

  // Clave para el RefreshIndicator
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // StreamController para forzar la actualización de los datos
  final StreamController<List<Account>> _accountsController =
      StreamController<List<Account>>.broadcast();
  Stream<List<Account>>? _accountsStream;

  @override
  void initState() {
    super.initState();
    _checkMigrationNeeded();
    _setupAccountStream();
  }

  @override
  void dispose() {
    _accountsController.close();
    super.dispose();
  }

  void _setupAccountStream() {
    // Establecer el stream inicial
    _accountsStream = _accountService.getAccounts(widget.userId);
  }

  Future<void> _checkMigrationNeeded() async {
    final needsMigration = await _accountService.needsMigration(widget.userId);
    if (mounted) {
      setState(() {
        _needsMigration = needsMigration;
      });
    }
  }

  // Método para refrescar los datos
  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Refrescar los datos de migración
      await _checkMigrationNeeded();

      // Forzar una actualización del stream de cuentas
      _setupAccountStream();

      // Notificar a la UI que se ha completado el refresco
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error al refrescar datos: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Método para manejar la edición de transacciones
  void _onEditTransaction(Map<String, dynamic> transaction, String transactionId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          userId: widget.userId,
          transaction: transaction,
          docId: transactionId,
          isEditing: true,
        ),
      ),
    ).then((_) => _refreshData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshData,
        child: Padding(
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
                              (context) => CreditCardSummaryScreen(
                                userId: widget.userId,
                              ),
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
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded),
                    onPressed: () async {
                      final transactionService = TransactionService();
                      final accounts = await transactionService.loadAccounts(
                        widget.userId,
                      );

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => TransferScreen(
                                userId: widget.userId,
                                accounts: accounts,
                              ),
                        ),
                      );
                    },
                    tooltip: 'Transferir entre cuentas',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              // Botón de migración
              Visibility(
                visible:
                    _needsMigration, // Solo mostrar cuando se necesite migración
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
                            onPressed:
                                _isMigrating
                                    ? null
                                    : () => _migrateAccounts(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child:
                                _isMigrating
                                    ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
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
                  stream: _accountsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !_isRefreshing) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppTheme.errorColor,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Error al cargar las cuentas",
                              style: TextStyle(
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: TextStyle(color: AppTheme.errorColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshData,
                              child: const Text("Intentar de nuevo"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final accounts = snapshot.data ?? [];

                    return AccountList(
                      accounts: accounts,
                      onEditAccount: _editAccount,
                      onAddAccount: _addAccount, // Usamos _addAccount directamente
                      userId: widget.userId,
                      onEditTransaction: _onEditTransaction, // Pasamos el callback
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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

        // Refrescar los datos después de la migración
        _refreshData();
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

  // Método actualizado para usar AddAccountScreen en lugar de AddAccountForm
  void _addAccount() {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (context) => AddAccountScreen(
            userId: widget.userId,
          ),
        ))
        .then((_) => _refreshData());
  }

  // Método actualizado para usar AddAccountScreen en lugar de AddAccountForm
  void _editAccount(Account account) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (context) => AddAccountScreen(
            userId: widget.userId,
            account: account,
          ),
        ))
        .then((_) => _refreshData());
  }
}