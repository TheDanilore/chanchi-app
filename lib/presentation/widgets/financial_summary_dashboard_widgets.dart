import 'package:chanchi_app/models/currency_util.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/presentation/pages/accounts_screen.dart';
import 'package:intl/intl.dart';

class FinancialSummaryDashboard extends StatefulWidget {
  final String userId;
  final Function(int)? onNavigateToTab;

  const FinancialSummaryDashboard({
    Key? key,
    required this.userId,
    this.onNavigateToTab,
  }) : super(key: key);

  @override
  _FinancialSummaryDashboardState createState() =>
      _FinancialSummaryDashboardState();
}

class _FinancialSummaryDashboardState extends State<FinancialSummaryDashboard> {
  final _firestore = FirebaseFirestore.instance;
  bool _isBalanceHidden = false;

  // Método para obtener el balance total convertido a una moneda específica
  double _getTotalBalanceInCurrency(
    List<QueryDocumentSnapshot> accounts,
    String targetCurrency,
  ) {
    double totalBalance = 0;

    for (var doc in accounts) {
      final data = doc.data() as Map<String, dynamic>;
      final balance = (data['balance'] ?? 0).toDouble();
      final accountCurrency = data['currencyCode'] ?? 'PEN';

      // Convierte el balance a la moneda de destino
      final convertedBalance = CurrencyUtil.convert(
        amount: balance,
        fromCurrency: accountCurrency,
        toCurrency: targetCurrency,
      );

      totalBalance += convertedBalance;
    }

    return totalBalance;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                IconButton(
                  icon: Icon(
                    _isBalanceHidden ? Icons.visibility : Icons.visibility_off,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isBalanceHidden = !_isBalanceHidden;
                    });
                  },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Total balance en todas las cuentas
            StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('users')
                      .doc(widget.userId)
                      .collection('accounts')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildBalanceSkeleton();
                }

                final accounts = snapshot.data?.docs ?? [];

                // Usa la moneda predeterminada (PEN por defecto)
                final totalBalance = _getTotalBalanceInCurrency(
                  accounts,
                  'PEN',
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isBalanceHidden
                          ? "S/•••.••"
                          : CurrencyUtil.format(
                              amount: totalBalance,
                              currencyCode: 'PEN',
                            ),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: totalBalance >= 0 ? AppTheme.successColor : AppTheme.errorColor,
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
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Ingresos y gastos del mes actual
            StreamBuilder<QuerySnapshot>(
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
                final savingsColor = savings >= 0 ? AppTheme.successColor : AppTheme.errorColor;

                return Column(
                  children: [
                    Row(
                      children: [
                        // Ingresos del mes - Verde
                        Expanded(
                          child: _buildMonthlyStatCard(
                            context,
                            "Ingresos",
                            totalIncome,
                            Icons.arrow_downward,
                            AppTheme.successColor,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingL),
                        // Gastos del mes - Rojo
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
                    const SizedBox(height: AppTheme.spacingS),
                    
                    // Ahorro
                    Container(
                      margin: const EdgeInsets.only(top: AppTheme.spacingXS),
                      height: 6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: totalIncome > 0 ? totalExpense / totalIncome : 0,
                          backgroundColor: Colors.grey.shade200,
                          color: totalExpense < totalIncome ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spacingS),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Ahorro este mes",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          Text(
                            _isBalanceHidden
                                ? "S/•••.••"
                                : CurrencyUtil.format(
                                    amount: savings,
                                    currencyCode: 'PEN',
                                  ),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: savingsColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Cuentas principales
            StreamBuilder<QuerySnapshot>(
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
                        widget.onNavigateToTab!(
                          2,
                        ); // Navegar a la pestaña "Cuentas"
                      }
                    },
                    icon: Icon(Icons.add, color: AppTheme.primaryColor),
                    label: Text(
                      "Añadir cuenta",
                      style: TextStyle(color: AppTheme.primaryColor),
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
                              widget.onNavigateToTab!(
                                2,
                              ); // Navegar a la pestaña "Cuentas"
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
                    const SizedBox(height: AppTheme.spacingM),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      ),
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      child: Column(
                        children: [
                          ...accountsToShow.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final balance = (data['balance'] ?? 0.0).toDouble();
                            final isPositive = balance >= 0;

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _getAccountColor(data).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                      ),
                                      child: Icon(
                                        _getAccountIcon(data['iconName']),
                                        color: _getAccountColor(data),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spacingM),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['name'] ?? 'Sin nombre',
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              color: AppTheme.textPrimaryColor,
                                            ),
                                          ),
                                          Text(
                                            "${data['type'] ?? ''} - ${data['institution'] ?? ''}",
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppTheme.textSecondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _isBalanceHidden
                                          ? "S/•••.••"
                                          : CurrencyUtil.format(
                                              amount: balance,
                                              currencyCode: data['currencyCode'] ?? 'PEN',
                                            ),
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (doc != accountsToShow.last)
                                  Divider(
                                    color: Colors.grey.shade300,
                                    height: 24,
                                  ),
                              ],
                            );
                          }).toList(),
                          
                          if (accounts.length > 2)
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AccountsScreen(userId: widget.userId),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Ver todas mis cuentas",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 16),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Query _getMonthlyTransactionsQuery() {
    // Obtener primer y último día del mes actual
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: widget.userId)
        .where('dateTime', isGreaterThanOrEqualTo: firstDayOfMonth)
        .where('dateTime', isLessThanOrEqualTo: lastDayOfMonth);
  }

  Widget _buildBalanceSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Container(
          width: 80,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
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
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
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
              width: 100,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
            ),
            Container(
              width: 60,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            children: List.generate(
              2,
              (_) => Container(
                height: 50,
                margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
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
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, color: color, size: 16),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            _isBalanceHidden
                ? "S/•••.••"
                : CurrencyUtil.format(
                    amount: amount,
                    currencyCode: 'PEN',
                  ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            "Este mes",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
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
}