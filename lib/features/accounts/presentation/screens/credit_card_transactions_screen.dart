import 'package:chanchi_app/features/home/presentation/widgets/transaction_list_widgets.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/core/utils/currency_util.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:intl/intl.dart';

class CreditCardTransactionsScreen extends StatefulWidget {
  final String userId;
  final Account card;

  const CreditCardTransactionsScreen({
    super.key,
    required this.userId,
    required this.card,
  });

  @override
  State<CreditCardTransactionsScreen> createState() => _CreditCardTransactionsScreenState();
}

class _CreditCardTransactionsScreenState extends State<CreditCardTransactionsScreen> {
  DateTime _selectedMonth = DateTime.now();
  final GlobalKey<TransactionListState> _transactionListKey = GlobalKey<TransactionListState>();

  @override
  Widget build(BuildContext context) {
    final cardColor = _getCardColor(widget.card.color);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de ${widget.card.name}'),
        backgroundColor: cardColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCardHeader(cardColor),
          _buildMonthSelector(),
          Expanded(
            child: TransactionList(
              key: _transactionListKey,
              userId: widget.userId,
              onEditTransaction: _onEditTransaction,
              selectedAccountId: widget.card.id,
              selectedMonth: _selectedMonth,
              onError: (message) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
              onRefresh: () {
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(Color cardColor) {
    final creditLimit = widget.card.creditLimit ?? 0.0;
    final available = creditLimit - widget.card.balance;
    final usagePercentage = widget.card.creditUsagePercentage ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
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
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    CurrencyUtil.format(
                      amount: widget.card.balance,
                      currencyCode: widget.card.currencyCode ?? 'PEN',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
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
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    CurrencyUtil.format(
                      amount: available,
                      currencyCode: widget.card.currencyCode ?? 'PEN',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (creditLimit > 0) ...[
            LinearProgressIndicator(
              value: widget.card.balance / creditLimit,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                usagePercentage > 80
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
                  "Límite: ${CurrencyUtil.format(amount: creditLimit, currencyCode: widget.card.currencyCode ?? 'PEN')}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final formatter = DateFormat('MMMM yyyy', 'es');
    final formattedMonth = formatter.format(_selectedMonth);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final now = DateTime.now();
              final nextMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month + 1,
                1,
              );
              
              // No permitir seleccionar meses futuros
              if (nextMonth.year < now.year || 
                  (nextMonth.year == now.year && nextMonth.month <= now.month)) {
                setState(() {
                  _selectedMonth = nextMonth;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getCardColor(String? colorHex) {
    if (colorHex != null && colorHex.startsWith('#')) {
      return Color(int.parse(colorHex.substring(1, 7), radix: 16) + 0xFF000000);
    }
    return AppTheme.primaryColor;
  }

  void _onEditTransaction(Map<String, dynamic> transaction, String transactionId) {
    // Implementar la lógica para editar una transacción
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          userId: widget.userId,
          transaction: transaction,
          docId: transactionId,
          isEditing: true,
        ),
      ),
    ).then((_) {
      // Refresh transactions list after returning from the edit screen
      if (_transactionListKey.currentState != null) {
        _transactionListKey.currentState!.loadData();
      }
    });
  }
}