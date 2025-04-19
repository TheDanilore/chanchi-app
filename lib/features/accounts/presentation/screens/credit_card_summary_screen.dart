// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/core/utils/currency_util.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/features/accounts/presentation/widgets/add_account_form.dart';

class CreditCardSummaryScreen extends StatelessWidget {
  final String userId;

  const CreditCardSummaryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Tarjetas de Crédito"),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('accounts')
                .where('isCreditCard', isEqualTo: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error al cargar las tarjetas: ${snapshot.error}"),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_off,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No tienes tarjetas de crédito",
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddCreditCardDialog(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Agregar tarjeta"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Crear una lista de objetos Account
          final cards =
              docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Account.fromMap(data, doc.id);
              }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTotalCreditStats(context, cards),
              const SizedBox(height: 24),
              ...cards.map((card) => _buildCreditCardSummary(context, card)),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCreditCardDialog(context);
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCreditCardDialog(BuildContext context) {
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
            userId: userId,
            account: null,
            isEditing: false,
            initialAccountType: 'credit_card',
          ),
    );
  }

  Widget _buildTotalCreditStats(BuildContext context, List<Account> cards) {
    double totalUsed = 0;
    double totalAvailable = 0;
    double totalLimit = 0;

    for (var card in cards) {
      if (card.isCreditCard && card.creditLimit != null) {
        totalUsed += card.balance;
        totalLimit += card.creditLimit!;
        totalAvailable += (card.creditLimit! - card.balance);
      }
    }

    final usagePercentage = totalLimit > 0 ? (totalUsed / totalLimit) * 100 : 0;

    // Determinar color según porcentaje de uso
    Color usageColor = Colors.green;
    if (usagePercentage > 90) {
      usageColor = Colors.red;
    } else if (usagePercentage > 70) {
      usageColor = Colors.orange;
    } else if (usagePercentage > 50) {
      usageColor = Colors.amber;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Resumen de Crédito",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: usageColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: usageColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    "${usagePercentage.toStringAsFixed(1)}% utilizado",
                    style: TextStyle(
                      color: usageColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: totalLimit > 0 ? totalUsed / totalLimit : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(usageColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCreditStatItem(
                    context,
                    "Deuda Total",
                    totalUsed,
                    Colors.red[700]!,
                  ),
                ),
                Expanded(
                  child: _buildCreditStatItem(
                    context,
                    "Disponible",
                    totalAvailable,
                    Colors.green[700]!,
                  ),
                ),
                Expanded(
                  child: _buildCreditStatItem(
                    context,
                    "Límite Total",
                    totalLimit,
                    Colors.blue[700]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditStatItem(
    BuildContext context,
    String title,
    double amount,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyUtil.format(amount: amount, currencyCode: 'PEN'),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCreditCardSummary(BuildContext context, Account card) {
    // Calcular porcentaje de uso y días para fecha de pago
    final double? usagePercentage = card.creditUsagePercentage;
    final creditLimit = card.creditLimit ?? 0.0;
    final available = creditLimit - card.balance;

    // Calcular días hasta la fecha de cierre
    String dueDateText = "No establecida";
    int daysLeft = 0;
    if (card.billingCycleEndDate != null) {
      final now = DateTime.now();
      final dueDay = card.billingCycleEndDate!.day;

      // Crear fecha de cierre para el mes actual o el siguiente
      final dueDate =
          (now.day > dueDay)
              ? DateTime(now.year, now.month + 1, dueDay) // Próximo mes
              : DateTime(now.year, now.month, dueDay); // Este mes

      daysLeft = dueDate.difference(now).inDays;
      dueDateText =
          daysLeft == 0
              ? "¡Hoy es tu fecha de cierre!"
              : "$daysLeft días para el cierre";
    }

    // Determinar color según días restantes
    Color dateColor = Colors.blue;
    if (daysLeft <= 3) {
      dateColor = Colors.red;
    } else if (daysLeft <= 7) {
      dateColor = Colors.orange;
    }

    // Obtener color de la tarjeta
    Color cardColor =
        card.color != null
            ? Color(
              int.parse(card.color!.substring(1, 7), radix: 16) + 0xFF000000,
            )
            : Colors.deepPurple[800]!;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cardColor, cardColor.withOpacity(0.8)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    card.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.credit_card, color: Colors.white, size: 32),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                card.institution,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Saldo utilizado",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        CurrencyUtil.format(
                          amount: card.balance,
                          currencyCode: card.currencyCode ?? 'PEN',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Disponible",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        CurrencyUtil.format(
                          amount: available,
                          currencyCode: card.currencyCode ?? 'PEN',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (card.creditLimit != null) ...[
                LinearProgressIndicator(
                  value:
                      card.creditLimit! > 0
                          ? card.balance / card.creditLimit!
                          : 0,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    usagePercentage! > 80
                        ? Colors.red[300]!
                        : usagePercentage > 60
                        ? Colors.orange[300]!
                        : Colors.green[300]!,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${usagePercentage.toStringAsFixed(1)}% utilizado",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "Límite: ${CurrencyUtil.format(amount: creditLimit, currencyCode: card.currencyCode ?? 'PEN')}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: dateColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dueDateText,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    card.includeInTotalBalance
                        ? "Incluida en balance total"
                        : "No incluida en balance total",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Switch(
                    value: card.includeInTotalBalance,
                    onChanged: (value) {
                      _updateCardIncludeInBalance(card.id, value);
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Colors.green.withOpacity(0.5),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  _buildTransactionsHistoryScreen(card),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text("Ver historial"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showRegisterPaymentDialog(context, card);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: cardColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    icon: const Icon(Icons.payments, size: 16),
                    label: const Text("Registrar pago"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método para actualizar el campo includeInTotalBalance de la tarjeta
  void _updateCardIncludeInBalance(String cardId, bool includeInBalance) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(cardId)
        .update({'includeInTotalBalance': includeInBalance});
  }

  // Placeholder para la pantalla de historial de transacciones
  Widget _buildTransactionsHistoryScreen(Account card) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Historial de ${card.name}"),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('transactions')
                .where('userId', isEqualTo: userId)
                .where('accountId', isEqualTo: card.id)
                .where(
                  'isInTrash',
                  isEqualTo: false,
                ) // Solo transacciones activas
                .orderBy('dateTime', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error al cargar transacciones: ${snapshot.error}"),
            );
          }

          final transactions = snapshot.data?.docs ?? [];

          if (transactions.isEmpty) {
            return Center(
              child: Text(
                "No hay transacciones para esta tarjeta",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transactionData =
                  transactions[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(
                  transactionData['description'] ?? 'Sin descripción',
                ),
                subtitle: Text(
                  DateTime.fromMillisecondsSinceEpoch(
                    (transactionData['dateTime'] as Timestamp)
                        .millisecondsSinceEpoch,
                  ).toString(),
                ),
                trailing: Text(
                  CurrencyUtil.format(
                    amount: transactionData['amount'],
                    currencyCode: transactionData['currencyCode'] ?? 'PEN',
                  ),
                  style: TextStyle(
                    color:
                        transactionData['type'] == 'income'
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRegisterPaymentDialog(BuildContext context, Account card) {
    final TextEditingController amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedAccountId;

    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<List<Account>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('accounts')
              .where('isCreditCard', isEqualTo: false)
              .snapshots()
              .map(
                (snapshot) =>
                    snapshot.docs
                        .map((doc) => Account.fromMap(doc.data(), doc.id))
                        .toList(),
              ),
          builder: (context, accountSnapshot) {
            if (accountSnapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: Center(child: CircularProgressIndicator()),
              );
            }

            final accounts = accountSnapshot.data ?? [];

            if (accounts.isEmpty) {
              return AlertDialog(
                title: Text("Registrar pago a ${card.name}"),
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
              title: Text("Registrar pago a ${card.name}"),
              content: StatefulBuilder(
                builder: (context, setState) {
                  return Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Saldo actual: ${CurrencyUtil.format(amount: card.balance, currencyCode: card.currencyCode ?? 'PEN')}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: amountController,
                          decoration: InputDecoration(
                            labelText: 'Monto a pagar',
                            prefixText:
                                CurrencyUtil
                                    .currencies[card.currencyCode ?? 'PEN']!
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
                            if (amount > card.balance) {
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
                          onChanged:
                              (value) =>
                                  setState(() => selectedAccountId = value),
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate() &&
                        selectedAccountId != null) {
                      final amount = double.parse(amountController.text);
                      final paymentAccount = accounts.firstWhere(
                        (account) => account.id == selectedAccountId,
                      );

                      Navigator.of(context).pop();
                      _confirmAndProcessPayment(
                        context,
                        card,
                        paymentAccount,
                        amount,
                      );
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
                  },
                  child: const Text("Registrar Pago"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmAndProcessPayment(
    BuildContext context,
    Account creditCard,
    Account paymentAccount,
    double amount,
  ) {
    // Mostrar un diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Función asíncrona para procesar la transacción
    Future<void> processTransaction() async {
      try {
        await FirebaseFirestore.instance
            .runTransaction((transaction) async {
              // Referencias a las cuentas
              final creditCardRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('accounts')
                  .doc(creditCard.id);

              final paymentAccountRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
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

              // Obtener balances actuales
              double creditCardBalance =
                  (creditCardDoc.data()!['balance'] ?? 0.0).toDouble();
              double paymentAccountBalance =
                  (paymentAccountDoc.data()!['balance'] ?? 0.0).toDouble();

              // Validaciones adicionales
              if (creditCardBalance < amount) {
                throw Exception(
                  "El monto excede el saldo de la tarjeta de crédito",
                );
              }

              if (paymentAccountBalance < amount) {
                throw Exception("Saldo insuficiente en la cuenta de pago");
              }

              // Actualizar balances
              creditCardBalance -= amount;
              paymentAccountBalance -= amount;

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
                'userId': userId,
                'accountId': creditCard.id,
                'fromAccountId': paymentAccount.id,
                'categoryId': 'credit_card_payment',
                'description': 'Pago de tarjeta de crédito',
                'amount': amount,
                'dateTime': Timestamp.fromDate(DateTime.now()),
                'type': 'income',
                'notes':
                    'Pago de ${CurrencyUtil.format(amount: amount, currencyCode: creditCard.currencyCode ?? 'PEN')} desde ${paymentAccount.name}',
                'currencyCode': creditCard.currencyCode ?? 'PEN',
                'isInTrash': false,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              };

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
                  'Pago de ${CurrencyUtil.format(amount: amount, currencyCode: creditCard.currencyCode ?? 'PEN')} registrado con éxito desde ${paymentAccount.name}',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        })
        .catchError((error) {
          // Manejar cualquier error no capturado anteriormente
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.of(
              context,
            ).pop(); // Cerrar el diálogo de carga si sigue abierto
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
