import 'package:chanchi_app/core/utils/currency_util.dart';
import 'package:chanchi_app/features/accounts/presentation/widgets/animated_balance_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chanchi_app/core/config/theme.dart';

class FinancialSummaryDashboard extends StatefulWidget {
  final String userId;
  final DateTime selectedMonth;
  final Function(int)? onNavigateToTab;

  const FinancialSummaryDashboard({
    Key? key,
    required this.userId,
    required this.selectedMonth,
    this.onNavigateToTab,
  }) : super(key: key);

  @override
  State<FinancialSummaryDashboard> createState() =>
      FinancialSummaryDashboardState();
}

class FinancialSummaryDashboardState extends State<FinancialSummaryDashboard> {
  final _firestore = FirebaseFirestore.instance;
  bool _isBalanceHidden = false;

  // Método de actualización
  Future<void> refresh() async {
    if (mounted) {
      setState(() {}); // Forzar actualización del widget
    }
  }

  Query _getMonthlyTransactionsQuery() {
    final firstDayOfMonth = DateTime(
      widget.selectedMonth.year,
      widget.selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      widget.selectedMonth.year,
      widget.selectedMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: widget.userId)
        .where('isInTrash', isNotEqualTo: true)
        .where('dateTime', isGreaterThanOrEqualTo: firstDayOfMonth)
        .where('dateTime', isLessThanOrEqualTo: lastDayOfMonth);
  }

  double _getTotalBalanceInCurrency(
    List<QueryDocumentSnapshot> accounts,
    String targetCurrency,
  ) {
    double totalBalance = 0;

    for (var doc in accounts) {
      final data = doc.data() as Map<String, dynamic>;
      final balance = (data['balance'] ?? 0).toDouble();
      final accountCurrency = data['currencyCode'] ?? 'PEN';
      final isCreditCard = data['isCreditCard'] ?? false;
      final includeInTotalBalance = data['includeInTotalBalance'] ?? true;

      if (includeInTotalBalance) {
        final convertedBalance = CurrencyUtil.convert(
          amount: balance,
          fromCurrency: accountCurrency,
          toCurrency: targetCurrency,
        );

        if (isCreditCard) {
          totalBalance -= convertedBalance;
        } else {
          totalBalance += convertedBalance;
        }
      }
    }

    return totalBalance;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with visibility toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Resumen Financiero",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isBalanceHidden = !_isBalanceHidden;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      _isBalanceHidden
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Total balance
            _buildTotalBalance(),

            const SizedBox(height: 16),

            // Monthly income and expenses
            _buildMonthlyStats(),

            const SizedBox(height: 12),

            // Main accounts section
            _buildMainAccounts(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalance() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('users')
              .doc(widget.userId)
              .collection('accounts')
              .snapshots(),
      builder: (context, accountsSnapshot) {
        if (accountsSnapshot.connectionState == ConnectionState.waiting) {
          return _buildBalanceSkeleton();
        }

        final accounts = accountsSnapshot.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream:
              _firestore
                  .collection('transactions')
                  .where('userId', isEqualTo: widget.userId)
                  .where('isInTrash', isEqualTo: true)
                  .snapshots(),
          builder: (context, trashTransactionsSnapshot) {
            if (trashTransactionsSnapshot.connectionState ==
                ConnectionState.waiting) {
              return _buildBalanceSkeleton();
            }

            final trashTransactions =
                trashTransactionsSnapshot.data?.docs ?? [];
            Map<String, double> adjustmentsByAccount = {};

            for (var doc in trashTransactions) {
              final data = doc.data() as Map<String, dynamic>;
              final accountId = data['accountId'] as String?;
              final amount = (data['amount'] ?? 0).toDouble();
              final type = data['type'] as String?;

              if (accountId != null) {
                if (!adjustmentsByAccount.containsKey(accountId)) {
                  adjustmentsByAccount[accountId] = 0;
                }

                if (type == 'income') {
                  adjustmentsByAccount[accountId] =
                      (adjustmentsByAccount[accountId] ?? 0) - amount;
                } else {
                  adjustmentsByAccount[accountId] =
                      (adjustmentsByAccount[accountId] ?? 0) + amount;
                }
              }
            }

            List<QueryDocumentSnapshot> adjustedAccounts = [];
            for (var account in accounts) {
              final accountData = account.data() as Map<String, dynamic>;
              final accountId = account.id;

              if (adjustmentsByAccount.containsKey(accountId)) {
                final adjustment = adjustmentsByAccount[accountId]!;
                accountData['balance'] =
                    (accountData['balance'] ?? 0).toDouble() + adjustment;
              }

              adjustedAccounts.add(account);
            }

            final totalBalance = _getTotalBalanceInCurrency(
              adjustedAccounts,
              'PEN',
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBalanceWidget(
                  balance: totalBalance,
                  currencySymbol: 'S/',
                  isHidden: _isBalanceHidden,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        totalBalance >= 0
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                  ),
                ),
                Text(
                  "Balance Total",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMonthlyStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getMonthlyTransactionsQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildMonthlyStatsSkeleton();
        }

        final transactions = snapshot.data?.docs ?? [];
        double totalIncome = 0;
        double totalExpense = 0;

        for (var doc in transactions) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0).toDouble();

          if (data['type'] == 'income') {
            totalIncome += amount;
          } else {
            totalExpense += amount;
          }
        }

        final savings = totalIncome - totalExpense;
        final savingsColor =
            savings >= 0 ? AppTheme.successColor : AppTheme.errorColor;

        return Column(
          children: [
            // Income and expense cards in row
            Row(
              children: [
                Expanded(
                  child: _buildMonthlyStatCard(
                    context,
                    "Ingresos",
                    totalIncome,
                    Icons.arrow_downward,
                    AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMonthlyStatCard(
                    context,
                    "Gastos",
                    totalExpense,
                    Icons.arrow_upward,
                    AppTheme.errorColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Progress bar for expenses vs income
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: totalIncome > 0 ? totalExpense / totalIncome : 0,
                backgroundColor: Colors.grey.shade200,
                color:
                    totalExpense < totalIncome
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                minHeight: 4,
              ),
            ),

            const SizedBox(height: 8),

            // Savings summary card
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    savings >= 0
                        ? AppTheme.successColor.withOpacity(0.08)
                        : AppTheme.errorColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      savings >= 0
                          ? AppTheme.successColor.withOpacity(0.2)
                          : AppTheme.errorColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(
                      savings >= 0 ? Icons.trending_up : Icons.trending_down,
                      color:
                          savings >= 0
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ahorro este mes",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondaryColor),
                        ),
                        Text(
                          CurrencyUtil.format(
                            amount: savings,
                            currencyCode: 'PEN',
                          ),
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                savings >= 0
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBalanceSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 70,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyStatsSkeleton() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsListSkeleton() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 80,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Container(
              width: 50,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            children: List.generate(
              2,
              (_) => Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyStatCard(
    BuildContext context,
    String title,
    double amount,
    IconData iconData,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isBalanceHidden
                ? "S/•••.••"
                : CurrencyUtil.format(amount: amount, currencyCode: 'PEN'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            "Este mes",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAccountIcon(dynamic iconName) {
    if (iconName is String) {
      switch (iconName) {
        case 'credit_card':
          return Icons.credit_card;
        case 'savings':
          return Icons.savings;
        case 'account_balance':
          return Icons.account_balance;
        case 'wallet':
          return Icons.account_balance_wallet;
      }
    }
    return Icons.account_balance_wallet;
  }

  Color _getAccountColor(Map<String, dynamic> data) {
    final color = data['color'];
    if (color != null && color is String && color.startsWith('#')) {
      return Color(int.parse(color.substring(1, 7), radix: 16) + 0xFF000000);
    }
    return AppTheme.primaryColor;
  }

  Widget _buildMainAccounts() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('users')
              .doc(widget.userId)
              .collection('accounts')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildAccountsListSkeleton();
        }

        final accounts = snapshot.data?.docs ?? [];

        if (accounts.isEmpty) {
          return TextButton.icon(
            onPressed: () {
              if (widget.onNavigateToTab != null) {
                widget.onNavigateToTab!(2);
              }
            },
            icon: Icon(Icons.add, color: AppTheme.primaryColor, size: 16),
            label: Text(
              "Añadir cuenta",
              style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }

        final accountsToShow = accounts.take(2).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Cuentas Principales",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (widget.onNavigateToTab != null) {
                      widget.onNavigateToTab!(2);
                    }
                  },
                  child: Text(
                    "Ver todas",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  ...accountsToShow.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final balance = (data['balance'] ?? 0.0).toDouble();
                    final isPositive = balance >= 0;
                    final isCreditCard = data['isCreditCard'] ?? false;
                    final creditLimit = (data['creditLimit'] ?? 0.0).toDouble();

                    return Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _getAccountColor(data).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getAccountIcon(data['iconName']),
                                color: _getAccountColor(data),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'Sin nombre',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall?.copyWith(
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  Text(
                                    "${data['type'] ?? ''} - ${data['institution'] ?? ''}",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _isBalanceHidden
                                      ? "S/•••.••"
                                      : CurrencyUtil.format(
                                        amount: balance,
                                        currencyCode:
                                            data['currencyCode'] ?? 'PEN',
                                      ),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.copyWith(
                                    color:
                                        isPositive
                                            ? AppTheme.successColor
                                            : AppTheme.errorColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (isCreditCard && creditLimit > 0)
                                  Text(
                                    _isBalanceHidden
                                        ? ""
                                        : "${CurrencyUtil.format(amount: balance, currencyCode: 'PEN')} de ${CurrencyUtil.format(amount: creditLimit, currencyCode: 'PEN')}",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        if (doc != accountsToShow.last)
                          Divider(
                            color: Colors.grey.shade200,
                            height: 16,
                            thickness: 1,
                          ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
