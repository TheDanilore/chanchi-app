import 'package:flutter/material.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/data/models/category.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/features/home/presentation/widgets/transaction_card.dart';

class TransactionDateGroup extends StatelessWidget {
  final String dateTitle;
  final List<Map<String, dynamic>> transactions;
  final Function(Map<String, dynamic>, String) onEditTransaction;
  final Map<String, Category> categoriesCache;
  final Map<String, Account> accountsCache;
  final Function(Map<String, dynamic>) onDuplicate;
  final Function(String) onMoveToTrash;

  const TransactionDateGroup({
    Key? key,
    required this.dateTitle,
    required this.transactions,
    required this.onEditTransaction,
    required this.categoriesCache,
    required this.accountsCache,
    required this.onDuplicate,
    required this.onMoveToTrash,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
          child: Text(
            dateTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...transactions.map((transaction) {
          final docId = transaction['id'];
          final isTemp = docId.startsWith('temp_');

          return Stack(
            children: [
              TransactionCard(
                transaction: transaction,
                docId: docId,
                onEdit: onEditTransaction,
                category: categoriesCache[transaction['categoryId']],
                account: accountsCache[transaction['accountId']],
                onDuplicate: () => onDuplicate(transaction),
                onMoveToTrash: () => onMoveToTrash(docId),
              ),
              if (isTemp)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Tooltip(
                    message: 'Pendiente de sincronización',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.sync,
                        size: 12,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
        const Divider(),
      ],
    );
  }
}