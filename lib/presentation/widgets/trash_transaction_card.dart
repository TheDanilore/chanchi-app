import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/models/currency_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrashTransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final String docId;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  const TrashTransactionCard({
    Key? key,
    required this.transaction,
    required this.docId,
    required this.onRestore,
    required this.onDelete,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final type = transaction['type'] as String? ?? 'expense';
    final amount = transaction['amount'] as num? ?? 0.0;
    final description = transaction['description'] as String? ?? 'Sin descripción';
    final dateTime = (transaction['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
    final currencyCode = transaction['currencyCode'] as String? ?? 'PEN';
    final trashedAt = (transaction['trashedAt'] as Timestamp?)?.toDate();
    
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    final formattedTrashedDate = trashedAt != null 
        ? DateFormat('dd MMM yyyy').format(trashedAt) 
        : 'Fecha desconocida';
    
    final currency = CurrencyUtil.currencies[currencyCode]!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: type == 'expense' 
              ? AppTheme.errorColor.withOpacity(0.2) 
              : AppTheme.successColor.withOpacity(0.2),
          child: Icon(
            type == 'expense' ? Icons.arrow_upward : Icons.arrow_downward,
            color: type == 'expense' ? AppTheme.errorColor : AppTheme.successColor,
          ),
        ),
        title: Text(
          description,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formattedDate),
            Text(
              "En papelera desde: $formattedTrashedDate",
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        trailing: Text(
          "${type == 'expense' ? '-' : '+'} ${currency.symbol}${amount.toStringAsFixed(2)}",
          style: TextStyle(
            color: type == 'expense' ? AppTheme.errorColor : AppTheme.successColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => _showOptions(context),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.green),
            title: const Text("Restaurar transacción"),
            onTap: () {
              Navigator.pop(context);
              onRestore();
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Ver detalles antes de restaurar"),
            onTap: () {
              Navigator.pop(context);
              onViewDetails();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Eliminar permanentemente", 
              style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}