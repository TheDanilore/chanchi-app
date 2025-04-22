import 'package:flutter/material.dart';
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
  State<AccountTransactionsScreen> createState() => _AccountTransactionsScreenState();
}

class _AccountTransactionsScreenState extends State<AccountTransactionsScreen> {
  DateTime _selectedMonth = DateTime.now();
  final GlobalKey<TransactionListState> _transactionListKey = GlobalKey<TransactionListState>();

  // Method to get account color
  Color _getAccountColor(String? colorHex) {
    if (colorHex != null && colorHex.startsWith('#')) {
      return Color(int.parse(colorHex.substring(1, 7), radix: 16) + 0xFF000000);
    }
    return AppTheme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final accountColor = _getAccountColor(widget.account.color);
    final formatter = DateFormat('MMMM yyyy', 'es');
    formatter.format(_selectedMonth);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Elegant SliverAppBar with account details
          SliverAppBar(
            expandedHeight: 250,
            floating: false,
            pinned: true,
            backgroundColor: accountColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accountColor,
                      accountColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                _getAccountIcon(widget.account.iconName),
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            Text(
                              widget.account.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.account.institution,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          CurrencyUtil.format(
                            amount: widget.account.balance, 
                            currencyCode: 'PEN'
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black45,
                                offset: const Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Month Selector with improved design
          SliverPersistentHeader(
            pinned: true,
            delegate: _MonthSelectorDelegate(
              minHeight: 60,
              maxHeight: 60,
              selectedMonth: _selectedMonth,
              accountColor: accountColor,
              onPreviousMonth: () {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month - 1,
                    1,
                  );
                });
              },
              onNextMonth: () {
                final now = DateTime.now();
                final nextMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                  1,
                );
                
                if (nextMonth.year < now.year || 
                    (nextMonth.year == now.year && nextMonth.month <= now.month)) {
                  setState(() {
                    _selectedMonth = nextMonth;
                  });
                }
              },
            ),
          ),
          
          // Transaction List with improved padding and design
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: TransactionList(
                key: _transactionListKey,
                userId: widget.userId,
                onEditTransaction: widget.onEditTransaction,
                selectedAccountId: widget.account.id,
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
          ),
        ],
      ),
      
      // Floating Action Button with account color
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(
                userId: widget.userId,
                account: widget.account,
              ),
            ),
          );
        },
        backgroundColor: accountColor,
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Helper method to get account icon
  IconData _getAccountIcon(String? iconName) {
    switch (iconName) {
      case 'credit_card':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      case 'account_balance':
        return Icons.account_balance;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.account_balance_wallet;
    }
  }
}

// Custom persistent header delegate for month selector
class _MonthSelectorDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final DateTime selectedMonth;
  final Color accountColor;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  _MonthSelectorDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.selectedMonth,
    required this.accountColor,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(
    BuildContext context, 
    double shrinkOffset, 
    bool overlapsContent
  ) {
    final formatter = DateFormat('MMMM yyyy', 'es');
    final formattedMonth = formatter.format(selectedMonth);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left, 
              color: accountColor,
            ),
            onPressed: onPreviousMonth,
          ),
          Text(
            formattedMonth[0].toUpperCase() + formattedMonth.substring(1),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accountColor,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right, 
              color: accountColor,
            ),
            onPressed: onNextMonth,
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}