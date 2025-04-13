import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/models/account.dart';
import 'package:chanchi_app/models/category.dart';

class TransactionFilterChips extends StatelessWidget {
  final String userId;
  final String? selectedCategoryId;
  final String? selectedAccountId;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(String?) onCategoryChanged;
  final Function(String?) onAccountChanged;
  final Function(DateTime?, DateTime?) onDateRangeChanged;

  const TransactionFilterChips({
    Key? key,
    required this.userId,
    this.selectedCategoryId,
    this.selectedAccountId,
    this.startDate,
    this.endDate,
    required this.onCategoryChanged,
    required this.onAccountChanged,
    required this.onDateRangeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chips de filtro con diseño mejorado
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: AppTheme.spacingS,
            children: [
              // Filtro de categorías
              _buildCategoryFilterChip(context),
              
              // Filtro de cuentas
              _buildAccountFilterChip(context),
              
              // Filtro de fecha
              _buildDateFilterChip(context),
              
              // Si hay filtros activos, mostrar botón para limpiar todos
              if (selectedCategoryId != null || selectedAccountId != null || startDate != null)
                ActionChip(
                  label: const Text("Limpiar filtros"),
                  labelStyle: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  avatar: Icon(
                    Icons.close,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
                  elevation: 0,
                  onPressed: () {
                    onCategoryChanged(null);
                    onAccountChanged(null);
                    onDateRangeChanged(null, null);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterChip(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final categories = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Category(
            id: doc.id,
            name: data['name'] ?? 'Sin nombre',
            iconName: data['iconName'] ?? 'category',
            color: data['color'] ?? '#4A6FFF',
            type: data['type'] ?? 'expense',
          );
        }).toList();

        return PopupMenuButton<String?>(
          initialValue: selectedCategoryId,
          onSelected: onCategoryChanged,
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem<String?>(
              value: null,
              child: Text("Todas las categorías"),
            ),
            const PopupMenuDivider(),
            ...categories.map((category) {
              final color = Color(int.parse(category.color.substring(1, 7), radix: 16) + 0xFF000000);
              return PopupMenuItem<String>(
                value: category.id,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Icon(
                        _getCategoryIcon(category.iconName),
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            category.type == 'income' ? 'Ingreso' : 'Gasto',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedCategoryId == category.id)
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                  ],
                ),
              );
            }),
          ],
          child: FilterChip(
            label: Text(
              selectedCategoryId == null
                  ? "Categorías"
                  : _getCategoryName(categories, selectedCategoryId!),
            ),
            labelStyle: TextStyle(
              color: selectedCategoryId == null
                  ? AppTheme.textPrimaryColor
                  : _getCategoryColor(categories, selectedCategoryId!),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            avatar: Icon(
              selectedCategoryId == null
                  ? Icons.category
                  : _getCategoryIcon(_getCategoryIconName(categories, selectedCategoryId!)),
              size: 16,
              color: selectedCategoryId == null
                  ? AppTheme.textSecondaryColor
                  : _getCategoryColor(categories, selectedCategoryId!),
            ),
            backgroundColor: Colors.white,
            selectedColor: selectedCategoryId == null
                ? null
                : _getCategoryColor(categories, selectedCategoryId!).withOpacity(0.1),
            selected: selectedCategoryId != null,
            showCheckmark: false,
            elevation: 0,
            side: BorderSide(
              color: selectedCategoryId == null
                  ? Colors.grey.shade300
                  : _getCategoryColor(categories, selectedCategoryId!),
              width: 1,
            ),
            onSelected: (_) {},
          ),
        );
      },
    );
  }

  Widget _buildAccountFilterChip(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final accounts = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Account(
            id: doc.id,
            name: data['name'] ?? 'Sin nombre',
            type: data['type'] ?? '',
            institution: data['institution'] ?? '',
            balance: (data['balance'] ?? 0.0).toDouble(),
            iconName: data['iconName'],
            color: data['color'],
          );
        }).toList();

        return PopupMenuButton<String?>(
          initialValue: selectedAccountId,
          onSelected: onAccountChanged,
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem<String?>(
              value: null,
              child: Text("Todas las cuentas"),
            ),
            const PopupMenuDivider(),
            ...accounts.map((account) {
              final color = account.color != null
                  ? Color(int.parse(account.color!.substring(1, 7), radix: 16) + 0xFF000000)
                  : AppTheme.primaryColor;
              return PopupMenuItem<String>(
                value: account.id,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Icon(
                        _getAccountIcon(account.iconName),
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            "${account.type} - ${account.institution}",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedAccountId == account.id)
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                  ],
                ),
              );
            }),
          ],
          child: FilterChip(
            label: Text(
              selectedAccountId == null
                  ? "Cuentas"
                  : _getAccountName(accounts, selectedAccountId!),
            ),
            labelStyle: TextStyle(
              color: selectedAccountId == null
                  ? AppTheme.textPrimaryColor
                  : _getAccountColor(accounts, selectedAccountId!),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            avatar: Icon(
              selectedAccountId == null
                  ? Icons.account_balance_wallet
                  : _getAccountIcon(_getAccountIconName(accounts, selectedAccountId!)),
              size: 16,
              color: selectedAccountId == null
                  ? AppTheme.textSecondaryColor
                  : _getAccountColor(accounts, selectedAccountId!),
            ),
            backgroundColor: Colors.white,
            selectedColor: selectedAccountId == null
                ? null
                : _getAccountColor(accounts, selectedAccountId!).withOpacity(0.1),
            selected: selectedAccountId != null,
            showCheckmark: false,
            elevation: 0,
            side: BorderSide(
              color: selectedAccountId == null
                  ? Colors.grey.shade300
                  : _getAccountColor(accounts, selectedAccountId!),
              width: 1,
            ),
            onSelected: (_) {},
          ),
        );
      },
    );
  }

  Widget _buildDateFilterChip(BuildContext context) {
    final hasDateFilter = startDate != null || endDate != null;
    
    String chipLabel = "Fecha";
    if (hasDateFilter) {
      final DateFormat formatter = DateFormat('dd/MM');
      if (startDate != null && endDate != null) {
        chipLabel = "${formatter.format(startDate!)} - ${formatter.format(endDate!)}";
      } else if (startDate != null) {
        chipLabel = "Desde ${formatter.format(startDate!)}";
      } else if (endDate != null) {
        chipLabel = "Hasta ${formatter.format(endDate!)}";
      }
    }
    
    return FilterChip(
      label: Text(chipLabel),
      labelStyle: TextStyle(
        color: hasDateFilter ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      avatar: Icon(
        Icons.date_range,
        size: 16,
        color: hasDateFilter ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
      ),
      backgroundColor: Colors.white,
      selectedColor: hasDateFilter ? AppTheme.primaryColor.withOpacity(0.1) : null,
      selected: hasDateFilter,
      showCheckmark: false,
      elevation: 0,
      side: BorderSide(
        color: hasDateFilter ? AppTheme.primaryColor : Colors.grey.shade300,
        width: 1,
      ),
      onSelected: (_) => _showDateRangePicker(context),
    );
  }

  void _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
            dialogBackgroundColor: Colors.white,
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
              elevation: 8,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateRangeChanged(picked.start, picked.end);
    }
  }

  // Funciones de utilidad para categorías
  String _getCategoryName(List<Category> categories, String categoryId) {
    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(
        id: '',
        name: 'Desconocida',
        iconName: 'category',
        color: '#4A6FFF',
        type: 'expense',
      ),
    );
    return category.name;
  }

  String _getCategoryIconName(List<Category> categories, String categoryId) {
    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(
        id: '',
        name: 'Desconocida',
        iconName: 'category',
        color: '#4A6FFF',
        type: 'expense',
      ),
    );
    return category.iconName;
  }

  Color _getCategoryColor(List<Category> categories, String categoryId) {
    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(
        id: '',
        name: 'Desconocida',
        iconName: 'category',
        color: '#4A6FFF',
        type: 'expense',
      ),
    );
    return Color(int.parse(category.color.substring(1, 7), radix: 16) + 0xFF000000);
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'home':
        return Icons.home;
      case 'directions_car':
        return Icons.directions_car;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'work':
        return Icons.work;
      case 'credit_card':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.category;
    }
  }

  // Funciones de utilidad para cuentas
  String _getAccountName(List<Account> accounts, String accountId) {
    final account = accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => Account(
        id: '',
        name: 'Desconocida',
        type: '',
        institution: '',
        balance: 0,
        iconName: 'account_balance_wallet',
      ),
    );
    return account.name;
  }

  String? _getAccountIconName(List<Account> accounts, String accountId) {
    final account = accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => Account(
        id: '',
        name: 'Desconocida',
        type: '',
        institution: '',
        balance: 0,
        iconName: 'account_balance_wallet',
      ),
    );
    return account.iconName;
  }

  Color _getAccountColor(List<Account> accounts, String accountId) {
    final account = accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => Account(
        id: '',
        name: 'Desconocida',
        type: '',
        institution: '',
        balance: 0,
        color: '#4A6FFF',
      ),
    );
    return account.color != null
        ? Color(int.parse(account.color!.substring(1, 7), radix: 16) + 0xFF000000)
        : AppTheme.primaryColor;
  }

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
      default:
        return Icons.account_balance_wallet;
    }
  }
}