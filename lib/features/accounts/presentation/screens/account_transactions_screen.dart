import 'package:flutter/material.dart';
import 'package:chanchi_app/core/utils/icon_utils.dart'; // Import IconUtils
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/core/utils/currency_util.dart';
import 'package:chanchi_app/features/home/presentation/widgets/transaction_list_widgets.dart';
import 'package:intl/intl.dart';
import 'package:chanchi_app/features/transactions/presentation/screens/add_transaction_screen.dart';

class AccountTransactionsScreen extends StatefulWidget {
  final String userId;
  final Account account;
  final Function(Map<String, dynamic>, String) onEditTransaction;

  const AccountTransactionsScreen({
    Key? key,
    required this.userId,
    required this.account,
    required this.onEditTransaction,
  }) : super(key: key);

  @override
  State<AccountTransactionsScreen> createState() =>
      _AccountTransactionsScreenState();
}

class _AccountTransactionsScreenState extends State<AccountTransactionsScreen> {
  DateTime _selectedMonth = DateTime.now();
  final GlobalKey<TransactionListState> _transactionListKey =
      GlobalKey<TransactionListState>();

  // Method to get account color
  Color _getAccountColor(String? colorHex) {
    if (colorHex != null && colorHex.startsWith('#')) {
      return Color(int.parse(colorHex.substring(1, 7), radix: 16) + 0xFF000000);
    }
    return AppTheme.primaryColor;
  }

  // Method to handle transaction editing
  void _handleEditTransaction(Map<String, dynamic> transaction, String docId) {
    // Navegamos a la pantalla de edición y refrescamos los datos al volver
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddTransactionScreen(
              userId: widget.userId,
              transaction: transaction,
              docId: docId,
              isEditing: true,
              account: widget.account,
            ),
          ),
        )
        .then((_) {
          if (_transactionListKey.currentState != null && mounted) {
            _transactionListKey.currentState!.loadData();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final accountColor = _getAccountColor(widget.account.color);
    final formatter = DateFormat('MMMM yyyy', 'es');
    final formattedMonth = formatter.format(_selectedMonth);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: accountColor,
        foregroundColor: Colors.white,
        title: Text('Historial'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Sección del saldo con color de cuenta e icono
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: accountColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icono de la cuenta
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    // Use IconUtils to get the icon
                    IconUtils.getIconByName(
                      widget.account.iconName, 
                      fallbackType: widget.account.type // Use account type as fallback
                    ),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Información de la cuenta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.account.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.account.institution,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Saldo actual:',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            CurrencyUtil.format(
                              amount: widget.account.balance,
                              currencyCode:
                                  widget.account.currencyCode ?? 'PEN',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Resto del código permanece igual...
          // Selector de mes, lista de transacciones, etc.
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: accountColor),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month - 1,
                        1,
                      );
                    });
                  },
                ),
                Text(
                  formattedMonth[0].toUpperCase() + formattedMonth.substring(1),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accountColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: accountColor),
                  onPressed: () {
                    final now = DateTime.now();
                    final nextMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                      1,
                    );

                    if (nextMonth.year < now.year ||
                        (nextMonth.year == now.year &&
                            nextMonth.month <= now.month)) {
                      setState(() {
                        _selectedMonth = nextMonth;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Divisor
          Divider(height: 1, thickness: 1, color: Colors.grey[200]),

          // Lista de transacciones
          Expanded(
            child: Builder(
              builder: (context) {
                try {
                  return TransactionList(
                    key: _transactionListKey,
                    userId: widget.userId,
                    onEditTransaction: _handleEditTransaction,
                    selectedAccountId: widget.account.id,
                    selectedMonth: _selectedMonth,
                    onError: (message) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    },
                    onRefresh: () {
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  );
                } catch (e) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 36, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error al cargar las transacciones',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accountColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),

      // Botón simple para añadir transacción
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder:
                      (context) => AddTransactionScreen(
                        userId: widget.userId,
                        account: widget.account,
                      ),
                ),
              )
              .then((_) {
                if (_transactionListKey.currentState != null && mounted) {
                  _transactionListKey.currentState!.loadData();
                }
              });
        },
        backgroundColor: accountColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}