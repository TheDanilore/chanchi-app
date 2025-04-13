import 'package:chanchi_app/services/transaction_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/models/category.dart';
import 'package:chanchi_app/models/account.dart';
import 'package:intl/intl.dart';

class TransactionListService {
  final FirebaseFirestore _firestore;
  final TransactionService _transactionService;
  final String userId;

  TransactionListService({
    required this.userId,
    FirebaseFirestore? firestore,
    TransactionService? transactionService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _transactionService = transactionService ?? TransactionService();

  // Obtener categorías para caché
  Future<Map<String, Category>> loadCategories() async {
    try {
      final categories = await _firestore.collection('categories').get();

      final Map<String, Category> cache = {};
      for (var doc in categories.docs) {
        final data = doc.data();
        cache[doc.id] = Category(
          id: doc.id,
          name: data['name'] ?? 'Sin nombre',
          iconName: data['iconName'] ?? 'category',
          color: data['color'] ?? '#4A6FFF',
          type: data['type'] ?? 'expense',
        );
      }

      return cache;
    } catch (e) {
      print('Error al cargar categorías: $e');
      return {};
    }
  }

  // Obtener cuentas para caché
  Future<Map<String, Account>> loadAccounts() async {
    try {
      final accounts =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('accounts')
              .get();

      final Map<String, Account> cache = {};
      for (var doc in accounts.docs) {
        final data = doc.data();
        cache[doc.id] = Account(
          id: doc.id,
          name: data['name'] ?? 'Sin nombre',
          type: data['type'] ?? '',
          institution: data['institution'] ?? '',
          balance: (data['balance'] ?? 0.0).toDouble(),
          iconName: data['iconName'],
          color: data['color'],
        );
      }

      return cache;
    } catch (e) {
      print('Error al cargar cuentas: $e');
      return {};
    }
  }

  // Consulta de transacciones
  Query getTransactionsQuery({
    String? selectedAccountId,
    String? selectedCategoryId,
  }) {
    Query query = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('isInTrash', isNotEqualTo: true);

    if (selectedAccountId != null) {
      query = query.where('accountId', isEqualTo: selectedAccountId);
    }

    if (selectedCategoryId != null) {
      query = query.where('categoryId', isEqualTo: selectedCategoryId);
    }

    return query.orderBy('dateTime', descending: true).limit(100);
  }

  // Filtrar transacciones por fecha
  List<QueryDocumentSnapshot> filterTransactionsByDate(
    List<QueryDocumentSnapshot> docs,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null && endDate == null) {
      return docs;
    }

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final dateTime = (data['dateTime'] as Timestamp).toDate();

      if (startDate != null && dateTime.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && dateTime.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();
  }

  // Agrupar transacciones por día
  Map<String, List<QueryDocumentSnapshot>> groupTransactionsByDay(
    List<QueryDocumentSnapshot> docs,
  ) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateTime = (data['dateTime'] as Timestamp).toDate();

      // Formatear fecha para agrupar
      final dateKey = DateFormat('dd MMM yyyy').format(dateTime);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }

      grouped[dateKey]!.add(doc);
    }

    return grouped;
  }

  // Operaciones con transacciones
  Future<void> moveToTrash(String docId, BuildContext context) async {
    try {
      await _transactionService.moveToTrash(userId, docId);

      // Verificar si el context aún es válido
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Transacción movida a papelera"),
          action: SnackBarAction(
            label: "Deshacer",
            onPressed: () async {
              await _transactionService.restoreFromTrash(userId, docId);
            },
          ),
        ),
      );
    } catch (e) {
      // Verificar si el context aún es válido
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  Future<String?> duplicateTransaction(
    Map<String, dynamic> transaction,
    BuildContext context,
  ) async {
    try {
      final String newTransactionId = await _transactionService
          .duplicateTransaction(userId, transaction);

      // Verificar si el context aún es válido
      if (!context.mounted) return null;

      return newTransactionId;
    } catch (e) {
      // Verificar si el context aún es válido
      if (!context.mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al duplicar: ${e.toString()}")),
      );
      return null;
    }
  }

  // Métodos para papelera
Future<void> restoreFromTrash(String docId, BuildContext context) async {
  try {
    await _transactionService.restoreFromTrash(userId, docId);

    // Verificar si el context aún es válido
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Transacción restaurada con éxito")),
    );
  } catch (e) {
    // Verificar si el context aún es válido
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error al restaurar: ${e.toString()}")),
    );
  }
}
  Future<void> deleteTransactionPermanently(
    String docId,
    BuildContext context,
  ) async {
    try {
      await _transactionService.deletePermanently(userId, docId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transacción eliminada permanentemente")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar: ${e.toString()}")),
      );
    }
  }

  Future<void> emptyTrash(BuildContext context) async {
    try {
      await _transactionService.emptyTrash(userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Papelera vaciada con éxito")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al vaciar la papelera: ${e.toString()}")),
      );
    }
  }
}
