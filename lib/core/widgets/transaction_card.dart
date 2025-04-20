import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:intl/intl.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/data/models/category.dart';
import 'package:chanchi_app/data/models/account.dart';

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final String docId;
  final Function(Map<String, dynamic>, String) onEdit;
  final Category? category;
  final Account? account;
  final VoidCallback? onDuplicate;
  final VoidCallback? onMoveToTrash;

  const TransactionCard({
    Key? key,
    required this.transaction,
    required this.docId,
    required this.onEdit,
    this.category,
    this.account,
    this.onDuplicate,
    this.onMoveToTrash,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction['type'] == 'expense';
    final dateTime = (transaction['dateTime'] as Timestamp).toDate();
    final amount = (transaction['amount'] as num).toDouble();
    final isTemp = docId.startsWith('temp_');

    // Determinar colores basados en tipo y categoría
    final Color amountColor =
        isExpense ? AppTheme.errorColor : AppTheme.successColor;

    final Color categoryColor =
        category?.color != null && category!.color.isNotEmpty
            ? Color(
              int.parse(category!.color.substring(1, 7), radix: 16) +
                  0xFF000000,
            )
            : isExpense
            ? AppTheme.errorColor
            : AppTheme.successColor;

    final String amountText = NumberFormat.currency(
      symbol: '',
      decimalDigits: 2,
    ).format(amount);

    final String currencySymbol =
        transaction['currencyCode'] != null
            ? _getCurrencySymbol(transaction['currencyCode'])
            : '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border:
            isTemp
                ? Border.all(color: Colors.amber.shade300, width: 1.5)
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          onTap: () => onEdit(transaction, docId),
          onLongPress: () => _showOptions(context),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                // Icono con fondo de color
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(),
                    color: categoryColor,
                    size: 24,
                  ),
                ),

                const SizedBox(width: AppTheme.spacingM),

                // Descripción, fecha y cuenta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['description'] ?? 'Sin descripción',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy • HH:mm').format(dateTime),
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (account != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              account!.name,
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Monto
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: amountColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Text(
                    '${isExpense ? '-' : '+'} $currencySymbol$amountText',
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  ListTile(
                    leading: Icon(Icons.edit, color: AppTheme.primaryColor),
                    title: const Text('Editar transacción'),
                    onTap: () {
                      Navigator.pop(context);
                      onEdit(transaction, docId);
                    },
                  ),
                if (onDuplicate != null)
                  ListTile(
                    leading: const Icon(Icons.copy, color: Colors.blue),
                    title: const Text('Duplicar transacción'),
                    onTap: () {
                      Navigator.pop(context);
                      onDuplicate!();
                    },
                  ),
                if (onMoveToTrash != null)
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: AppTheme.errorColor,
                    ),
                    title: const Text('Mover a papelera'),
                    onTap: () {
                      Navigator.pop(context);
                      onMoveToTrash!();
                    },
                  ),
              ],
            ),
          ),
    );
  }

  IconData _getCategoryIcon() {
    const iconMap = {
      'shopping_cart': Icons.shopping_cart,
      'restaurant': Icons.restaurant,
      'home': Icons.home,
      'directions_car': Icons.directions_car,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'sports_esports': Icons.sports_esports,
      'work': Icons.work,
      'credit_card': Icons.credit_card,
      'savings': Icons.savings,
      'attach_money': Icons.attach_money,
      'category': Icons.category,
      'shop_sharp': Icons.shop_sharp,
    };

    if (category?.iconName != null && iconMap.containsKey(category!.iconName)) {
      return iconMap[category!.iconName]!;
    }

    return transaction['type'] == 'expense'
        ? Icons.arrow_upward
        : Icons.arrow_downward;
  }

  String _getCurrencySymbol(String currencyCode) {
    final Map<String, String> symbols = {
      'PEN': 'S/ ',
      'USD': '\$ ',
      'EUR': '€ ',
      // Puedes agregar más monedas según sea necesario
    };

    return symbols[currencyCode] ?? '';
  }
}
