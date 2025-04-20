
// lib/features/home/data/data_sources/transaction_local_data_source.dart
import 'package:chanchi_app/features/home/domain/models/transaction.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class TransactionLocalDataSource {
  static const String _transactionsBoxName = 'transactions';
  static const String _pendingOperationsBoxName = 'pending_operations';
  
  // Inicializar Hive
  Future<void> _initHive() async {
    if (!Hive.isAdapterRegistered(0)) {
      final appDir = await getApplicationDocumentsDirectory();
      Hive.init(appDir.path);
      Hive.registerAdapter(TransactionAdapter());
    }
  }
  
  // Obtener caja de transacciones
  Future<Box<FinancialTransaction>> _getTransactionsBox() async {
    await _initHive();
    return await Hive.openBox<FinancialTransaction>(_transactionsBoxName);
  }
  
  // Obtener caja de operaciones pendientes
  Future<Box<String>> _getPendingOperationsBox() async {
    await _initHive();
    return await Hive.openBox<String>(_pendingOperationsBoxName);
  }
  
  // Guardar transacciones en caché
  Future<void> cacheTransactions(String userId, List<FinancialTransaction> transactions) async {
    final box = await _getTransactionsBox();
    
    // Eliminar transacciones existentes del usuario
    final keysToDelete = box.keys.where((key) {
      final transaction = box.get(key);
      return transaction?.userId == userId;
    }).toList();
    
    await box.deleteAll(keysToDelete);
    
    // Guardar nuevas transacciones
    for (var transaction in transactions) {
      await box.put(transaction.id, transaction);
    }
  }
  
  // Obtener transacciones de la caché
  Future<List<FinancialTransaction>> getTransactions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
  }) async {
    final box = await _getTransactionsBox();
    
    // Filtrar transacciones
    final transactions = box.values.where((transaction) {
      if (transaction.userId != userId || transaction.isInTrash) {
        return false;
      }
      
      if (startDate != null && transaction.dateTime.isBefore(startDate)) {
        return false;
      }
      
      if (endDate != null && transaction.dateTime.isAfter(endDate)) {
        return false;
      }
      
      if (categoryId != null && transaction.categoryId != categoryId) {
        return false;
      }
      
      if (accountId != null && transaction.accountId != accountId) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Ordenar por fecha (más reciente primero)
    transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    return transactions;
  }
  
  // Añadir una transacción localmente
  Future<void> addTransaction(FinancialTransaction transaction) async {
    final box = await _getTransactionsBox();
    await box.put(transaction.id, transaction);
  }
  
  // Actualizar una transacción localmente
  Future<void> updateTransaction(FinancialTransaction transaction) async {
    final box = await _getTransactionsBox();
    await box.put(transaction.id, transaction);
  }
  
  // Mover a papelera localmente
  Future<void> moveToTrash(String userId, String transactionId) async {
    final box = await _getTransactionsBox();
    final transaction = box.get(transactionId);
    
    if (transaction != null && transaction.userId == userId) {
      final updatedTransaction = FinancialTransaction(
        id: transaction.id,
        userId: transaction.userId,
        accountId: transaction.accountId,
        categoryId: transaction.categoryId,
        description: transaction.description,
        amount: transaction.amount,
        dateTime: transaction.dateTime,
        type: transaction.type,
        notes: transaction.notes,
        currencyCode: transaction.currencyCode,
        isInTrash: true,
      );
      
      await box.put(transactionId, updatedTransaction);
    }
  }
  
  // Eliminar permanentemente localmente
  Future<void> deletePermanently(String userId, String transactionId) async {
    final box = await _getTransactionsBox();
    await box.delete(transactionId);
  }
  
  // Añadir operación pendiente
  Future<void> addPendingOperation(String operationType, Map<String, dynamic> data) async {
    final box = await _getPendingOperationsBox();
    
    final operation = {
      'type': operationType,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    await box.add(jsonEncode(operation));
  }
  
  // Obtener operaciones pendientes
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final box = await _getPendingOperationsBox();
    
    return box.values.map((operationJson) {
      return jsonDecode(operationJson) as Map<String, dynamic>;
    }).toList();
  }
  
  // Eliminar operación pendiente
  Future<void> deletePendingOperation(int index) async {
    final box = await _getPendingOperationsBox();
    await box.deleteAt(index);
  }
  
  // Obtener cantidad de operaciones pendientes
  Future<int> getPendingOperationsCount() async {
    final box = await _getPendingOperationsBox();
    return box.length;
  }
}