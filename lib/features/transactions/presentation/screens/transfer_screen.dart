import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/core/utils/currency_util.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/features/home/domain/models/transaction.dart';
import 'package:chanchi_app/features/transactions/domain/services/transaction_service.dart' show TransactionService;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class TransferScreen extends StatefulWidget {
  final String userId;
  final List<Account> accounts;

  const TransferScreen({
    Key? key, 
    required this.userId, 
    required this.accounts,
  }) : super(key: key);

  @override
  _TransferScreenState createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  Account? _fromAccount;
  Account? _toAccount;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _performTransfer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final amount = double.parse(_amountController.text);
        final uuid = const Uuid();
        final now = DateTime.now();
        
        // Crear transacciones para la transferencia
        final transferTransactions = [
          Transaction(
            id: uuid.v4(), // Generar un ID único
            userId: widget.userId,
            accountId: _fromAccount!.id,
            categoryId: 'transfer_out',
            description: 'Transferencia a ${_toAccount!.name}',
            amount: amount,
            dateTime: now,
            type: 'expense',
            notes: _notesController.text,
            currencyCode: _fromAccount!.currencyCode ?? 'PEN',
            isInTrash: false,
            fromAccountId: _toAccount!.id,
          ),
          Transaction(
            id: uuid.v4(), // Generar un ID único
            userId: widget.userId,
            accountId: _toAccount!.id,
            categoryId: 'transfer_in',
            description: 'Transferencia desde ${_fromAccount!.name}',
            amount: amount,
            dateTime: now,
            type: 'income',
            notes: _notesController.text,
            currencyCode: _toAccount!.currencyCode ?? 'PEN',
            isInTrash: false,
            fromAccountId: _fromAccount!.id,
          )
        ];

        // Usar el servicio de transacciones para agregar ambas transacciones
        final transactionService = TransactionService();
        for (var transaction in transferTransactions) {
          await transactionService.addTransaction(transaction);
        }

        // Navegar de vuelta con éxito
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transferencia realizada con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Mostrar error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al realizar transferencia: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar cuentas para transferencia (excluyendo tarjetas de crédito)
    final transferAccounts = widget.accounts
        .where((account) => !(account.isCreditCard ?? false))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferir entre Cuentas'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Cuenta de origen
              DropdownButtonFormField<Account>(
                decoration: const InputDecoration(
                  labelText: 'Cuenta de Origen',
                ),
                value: _fromAccount,
                items: transferAccounts.map((account) {
                  return DropdownMenuItem<Account>(
                    value: account,
                    child: Text(
                      '${account.name} - ${CurrencyUtil.format(
                        amount: account.balance ?? 0, 
                        currencyCode: account.currencyCode ?? 'PEN'
                      )}',
                    ),
                  );
                }).toList(),
                onChanged: (account) {
                  setState(() {
                    _fromAccount = account;
                    // Evitar seleccionar la misma cuenta
                    if (_toAccount == account) {
                      _toAccount = null;
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecciona una cuenta de origen';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Cuenta de destino
              DropdownButtonFormField<Account>(
                decoration: const InputDecoration(
                  labelText: 'Cuenta de Destino',
                ),
                value: _toAccount,
                items: transferAccounts
                    .where((account) => account.id != _fromAccount?.id)
                    .map((account) {
                  return DropdownMenuItem<Account>(
                    value: account,
                    child: Text(
                      '${account.name} - ${CurrencyUtil.format(
                        amount: account.balance ?? 0, 
                        currencyCode: account.currencyCode ?? 'PEN'
                      )}',
                    ),
                  );
                }).toList(),
                onChanged: (account) {
                  setState(() {
                    _toAccount = account;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecciona una cuenta de destino';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Monto de transferencia
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Monto a Transferir',
                  prefixText: CurrencyUtil.currencies[_fromAccount?.currencyCode ?? 'PEN']!.symbol,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un monto';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Ingresa un monto válido';
                  }
                  if (_fromAccount != null && 
                      amount > (_fromAccount!.balance ?? 0)) {
                    return 'Saldo insuficiente';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Notas (opcional)
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Botón de transferencia
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _performTransfer,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.swap_horiz),
                label: Text(_isLoading ? 'Transfiriendo...' : 'Realizar Transferencia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}