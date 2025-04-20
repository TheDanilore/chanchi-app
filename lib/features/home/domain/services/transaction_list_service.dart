import 'dart:convert';
import 'package:chanchi_app/services/connectivity_service.dart';
import 'package:chanchi_app/features/transactions/domain/services/transaction_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/data/models/category.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionListService {
  final FirebaseFirestore _firestore;
  final TransactionService _transactionService;
  final ConnectivityService _connectivityService;
  final String userId;

  TransactionListService({
    required this.userId,
    FirebaseFirestore? firestore,
    TransactionService? transactionService,
    ConnectivityService? connectivityService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _transactionService = transactionService ?? TransactionService(),
       _connectivityService = connectivityService ?? ConnectivityService();

  Future<void> _enableOfflineCapabilities() async {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

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

  Future<List<Map<String, dynamic>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    required DateTime selectedMonth,
  }) async {
    final List<Map<String, dynamic>> result = [];

    // Obtener el primer y último día del mes seleccionado
    final firstDayOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
      23,
      59,
      59,
      999,
    );

    try {
      // Consulta base para transacciones de Firestore
      Query query = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('isInTrash', isNotEqualTo: true);

      // Filtro de fechas del mes seleccionado
      query = query
          .where('dateTime', isGreaterThanOrEqualTo: firstDayOfMonth)
          .where('dateTime', isLessThanOrEqualTo: lastDayOfMonth);

      // Obtener transacciones de Firestore
      final QuerySnapshot snapshot =
          await query.orderBy('dateTime', descending: true).limit(100).get();

      // Convertir transacciones de Firestore
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        result.add({'id': doc.id, ...data});
      }

      // Obtener transacciones locales
      final localTransactions = await getLocalTransactions(userId);

      // Filtrar transacciones locales
      for (var transaction in localTransactions) {
        final transactionDate = (transaction['dateTime'] as Timestamp).toDate();

        // Filtro riguroso de mes
        if (transactionDate.isBefore(firstDayOfMonth) ||
            transactionDate.isAfter(lastDayOfMonth)) {
          continue; // Saltar transacciones fuera del mes seleccionado
        }

        bool matchesFilters = (transaction['isInTrash'] != true);

        if (matchesFilters) {
          bool exists = result.any((r) => r['id'] == transaction['id']);
          if (!exists) {
            result.add(transaction);
          }
        }
      }

      // Ordenar por fecha (más reciente primero)
      result.sort((a, b) {
        final dateA = (a['dateTime'] as Timestamp).toDate();
        final dateB = (b['dateTime'] as Timestamp).toDate();
        return dateB.compareTo(dateA);
      });

      print('Transacciones encontradas en el mes: ${result.length}');
      print('Mes seleccionado: $selectedMonth');
    } catch (e) {
      print('Error al obtener transacciones: $e');
    }

    return result;
  }

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

  Map<String, List<QueryDocumentSnapshot>> groupTransactionsByDay(
    List<QueryDocumentSnapshot> docs,
  ) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateTime = (data['dateTime'] as Timestamp).toDate();

      final dateKey = DateFormat('dd MMM yyyy').format(dateTime);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }

      grouped[dateKey]!.add(doc);
    }

    return grouped;
  }

  Future<void> _updateLocalTransactionTrashStatus(
    String docId,
    bool isInTrash,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_transactions_$userId';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> rawList = jsonDecode(cachedJson) as List;
        List<Map<String, dynamic>> transactions = [];

        for (var item in rawList) {
          Map<String, dynamic> transaction = Map<String, dynamic>.from(item);
          if (transaction['id'] == docId) {
            transaction['isInTrash'] = isInTrash;
          }
          transactions.add(transaction);
        }

        await prefs.setString(cacheKey, jsonEncode(transactions));
        print(
          'Estado de papelera de transacción $docId actualizado localmente: $isInTrash',
        );
      }
    } catch (e) {
      print('Error al actualizar estado de papelera localmente: $e');
      throw e;
    }
  }

  Future<void> moveToTrash(
    String docId,
    BuildContext context, {
    bool refreshUI = true,
  }) async {
    try {
      // Verificar si es un ID temporal
      if (docId.startsWith('temp_')) {
        // Si es un ID temporal, manejarlo localmente
        await _handleTemporaryIdDeletion(docId);
      } else {
        // Para IDs regulares, usar el servicio y manejar posibles errores
        try {
          await _transactionService.moveToTrash(userId, docId);
        } catch (e) {
          print('Error al mover a papelera mediante servicio: $e');
          // Fallback: actualizar al menos la caché local en caso de error
          await _updateLocalTransactionTrashStatus(docId, true);

          // No mostrar SnackBar en este punto para evitar mensajes de error confusos
        }
      }

      // Actualización de UI delegada al componente que llama a este método
    } catch (e) {
      print('Error general en moveToTrash: $e');
      if (context.mounted) {
        // Solo mostrar el error si es algo inesperado que no sea de permisos
        if (!e.toString().contains('permission-denied')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al procesar la transacción: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleTemporaryIdDeletion(String tempId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_transactions_$userId';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> transactions = jsonDecode(cachedJson) as List;
        final newTransactions =
            transactions.where((t) => (t as Map)['id'] != tempId).toList();
        await prefs.setString(cacheKey, jsonEncode(newTransactions));
        print('ID temporal $tempId eliminado localmente');

        // También verificar si hay operaciones pendientes para este ID y eliminarlas
        final pendingOpsKey = 'pending_transactions_$userId';
        final pendingJson = prefs.getString(pendingOpsKey);

        if (pendingJson != null && pendingJson.isNotEmpty) {
          final List<dynamic> pendingOps = jsonDecode(pendingJson) as List;
          final newPendingOps =
              pendingOps.where((op) => (op as Map)['docId'] != tempId).toList();

          if (pendingOps.length != newPendingOps.length) {
            await prefs.setString(pendingOpsKey, jsonEncode(newPendingOps));
            print('Operaciones pendientes para ID $tempId eliminadas');
          }
        }
      }
    } catch (e) {
      print('Error al eliminar ID temporal: $e');
      throw e;
    }
  }

  Future<String> duplicateTransaction(
    String userId,
    Map<String, dynamic> transaction,
  ) async {
    try {
      // El método delega la operación al TransactionService
      final String newTransactionId = await _transactionService
          .duplicateTransaction(userId, transaction);

      return newTransactionId;
    } catch (e) {
      print('Error en TransactionListService.duplicateTransaction: $e');
      throw e; // Re-lanzar el error para que el llamador pueda manejarlo
    }
  }

  Future<List<Map<String, dynamic>>> getLocalTransactions(String userId) async {
    try {
      return await _transactionService.getLocalTransactions(userId);
    } catch (e) {
      print('Error al obtener transacciones locales: $e');
      return []; // Devolver lista vacía en caso de error
    }
  }

  Future<void> restoreFromTrash(String docId, BuildContext context) async {
    try {
      await _transactionService.restoreFromTrash(userId, docId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transacción restaurada con éxito")),
      );
    } catch (e) {
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
