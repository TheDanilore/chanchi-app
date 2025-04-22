import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chanchi_app/core/utils/currency_util.dart';
import 'package:chanchi_app/data/models/account.dart';

class CreditCardPaymentDialog extends StatefulWidget {
  final String userId;
  final Account card;

  const CreditCardPaymentDialog({
    super.key,
    required this.userId,
    required this.card,
  });

  @override
  State<CreditCardPaymentDialog> createState() => _CreditCardPaymentDialogState();
}

class _CreditCardPaymentDialogState extends State<CreditCardPaymentDialog> {
  final TextEditingController amountController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? selectedAccountId;
  bool isLoading = false;
  List<Account> accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accountSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('accounts')
        .where('isCreditCard', isEqualTo: false)
        .get();

    setState(() {
      accounts = accountSnapshot.docs
          .map((doc) => Account.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return AlertDialog(
        title: Text("Registrar pago a ${widget.card.name}"),
        content: const Text(
          'No hay cuentas disponibles para realizar el pago',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cerrar"),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text("Registrar pago a ${widget.card.name}"),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Saldo actual: ${CurrencyUtil.format(amount: widget.card.balance, currencyCode: widget.card.currencyCode ?? 'PEN')}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Monto a pagar',
                prefixText:
                    CurrencyUtil
                        .currencies[widget.card.currencyCode ?? 'PEN']!
                        .symbol,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa un monto';
                }
                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Monto inválido';
                }
                if (amount <= 0) {
                  return 'El monto debe ser mayor a 0';
                }
                if (amount > widget.card.balance) {
                  return 'El monto no puede ser mayor al saldo consumido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Cuenta de pago',
                prefixIcon: const Icon(
                  Icons.account_balance_wallet,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              value: selectedAccountId,
              items:
                  accounts.map((account) {
                    return DropdownMenuItem<String>(
                      value: account.id,
                      child: Text(
                        '${account.name} - ${CurrencyUtil.format(amount: account.balance, currencyCode: account.currencyCode ?? 'PEN')}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
              validator:
                  (value) =>
                      value == null
                          ? 'Selecciona una cuenta'
                          : null,
              onChanged: (value) => setState(() => selectedAccountId = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _processPayment,
          child: isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text("Registrar Pago"),
        ),
      ],
    );
  }

  void _processPayment() {
    if (formKey.currentState!.validate() && selectedAccountId != null) {
      final amount = double.parse(amountController.text);
      final paymentAccount = accounts.firstWhere(
        (account) => account.id == selectedAccountId,
      );

      setState(() {
        isLoading = true;
      });

      _confirmAndProcessPayment(paymentAccount, amount);
    } else if (selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor selecciona una cuenta de pago',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmAndProcessPayment(
    Account paymentAccount,
    double amount,
  ) {
    // Función asíncrona para procesar la transacción
    Future<void> processTransaction() async {
      try {
        await FirebaseFirestore.instance
            .runTransaction((transaction) async {
              // PRIMER PASO: TODAS LAS LECTURAS

              // Referencias a las cuentas
              final creditCardRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('accounts')
                  .doc(widget.card.id);

              final paymentAccountRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('accounts')
                  .doc(paymentAccount.id);

              // Obtener datos actuales de las cuentas
              final creditCardDoc = await transaction.get(creditCardRef);
              final paymentAccountDoc = await transaction.get(
                paymentAccountRef,
              );

              if (!creditCardDoc.exists || !paymentAccountDoc.exists) {
                throw Exception("Una de las cuentas no existe");
              }

              // SEGUNDO PASO: CALCULAR NUEVOS BALANCES

              // Obtener balances actuales (asegurando que no sean nulos)
              final creditCardData = creditCardDoc.data()!;
              final paymentAccountData = paymentAccountDoc.data()!;

              double creditCardBalance =
                  (creditCardData['balance'] ?? 0.0).toDouble();
              double paymentAccountBalance =
                  (paymentAccountData['balance'] ?? 0.0).toDouble();

              // Validaciones adicionales
              if (creditCardBalance < amount) {
                throw Exception(
                  "El monto excede el saldo de la tarjeta de crédito",
                );
              }

              if (paymentAccountBalance < amount) {
                throw Exception("Saldo insuficiente en la cuenta de pago");
              }

              // Actualizar balances - usando asignación directa, no += o -=
              creditCardBalance = creditCardBalance - amount;
              paymentAccountBalance = paymentAccountBalance - amount;

              // Verificar que los balances no sean negativos
              if (creditCardBalance < 0) {
                throw Exception(
                  "El pago resultaría en un saldo negativo para la tarjeta",
                );
              }

              if (paymentAccountBalance < 0) {
                throw Exception("Saldo insuficiente en la cuenta de pago");
              }

              // Datos para la transacción de pago
              final transactionData = {
                'userId': widget.userId,
                'accountId': widget.card.id,
                'fromAccountId': paymentAccount.id,
                'categoryId': 'credit_card_payment',
                'description': 'Pago de tarjeta de crédito',
                'amount': amount,
                'dateTime': Timestamp.fromDate(DateTime.now()),
                'type': 'income',
                'notes':
                    'Pago de ${CurrencyUtil.format(amount: amount, currencyCode: widget.card.currencyCode ?? 'PEN')} desde ${paymentAccount.name}',
                'currencyCode': widget.card.currencyCode ?? 'PEN',
                'isInTrash': false,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              };

              // TERCER PASO: TODAS LAS ESCRITURAS

              // Actualizar cuentas
              transaction.update(creditCardRef, {'balance': creditCardBalance});
              transaction.update(paymentAccountRef, {
                'balance': paymentAccountBalance,
              });

              // Crear la transacción
              final newTransactionRef =
                  FirebaseFirestore.instance.collection('transactions').doc();
              transaction.set(newTransactionRef, transactionData);
            })
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('La operación tardó demasiado');
              },
            );
      } catch (error) {
        // Cerrar el diálogo de carga si aún está abierto
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Mostrar mensaje de error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al registrar el pago: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // Imprimir el error para debugging
        print('Error al registrar pago: $error');

        // Relanzar el error para que pueda ser manejado por el llamador
        rethrow;
      }
    }

    // Ejecutar la transacción
    processTransaction()
        .then((_) {
          // Cerrar el diálogo de carga
          if (context.mounted) {
            Navigator.of(context).pop();
          }

          // Mostrar mensaje de éxito
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Pago de ${CurrencyUtil.format(amount: amount, currencyCode: widget.card.currencyCode ?? 'PEN')} registrado con éxito desde ${paymentAccount.name}',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        })
        .catchError((error) {
          // Manejar cualquier error no capturado anteriormente
          if (context.mounted) {
            setState(() {
              isLoading = false;
            });
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error inesperado: ${error.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }
}