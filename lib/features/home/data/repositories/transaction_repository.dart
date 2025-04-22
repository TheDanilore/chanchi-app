import 'package:chanchi_app/features/home/domain/models/transaction.dart';
import 'package:chanchi_app/core/utils/connectivity_helper.dart';
import 'package:chanchi_app/features/home/data/data_sources/transaction_local_data_source.dart';
import 'package:chanchi_app/features/home/data/data_sources/transaction_remote_data_source.dart';

class TransactionRepository {
  final TransactionRemoteDataSource _remoteDataSource;
  final TransactionLocalDataSource _localDataSource;
  final ConnectivityHelper _connectivityHelper;
  
  TransactionRepository({
    TransactionRemoteDataSource? remoteDataSource,
    TransactionLocalDataSource? localDataSource,
    ConnectivityHelper? connectivityHelper,
  }) : 
    _remoteDataSource = remoteDataSource ?? TransactionRemoteDataSource(),
    _localDataSource = localDataSource ?? TransactionLocalDataSource(),
    _connectivityHelper = connectivityHelper ?? ConnectivityHelper();
  
  // Obtener transacciones (con manejo de modo offline)
  Future<List<FinancialTransaction>> getTransactions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
  }) async {
    final isConnected = await _connectivityHelper.isConnected();
    
    if (isConnected) {
      try {
        final transactions = await _remoteDataSource.getTransactions(
          userId,
          startDate: startDate,
          endDate: endDate,
          categoryId: categoryId,
          accountId: accountId,
        );
        
        // Guardar en cache local
        await _localDataSource.cacheTransactions(userId, transactions);
        
        return transactions;
      } catch (e) {
        // Si hay error, intentar obtener de la caché
        return _localDataSource.getTransactions(
          userId,
          startDate: startDate,
          endDate: endDate,
          categoryId: categoryId,
          accountId: accountId,
        );
      }
    } else {
      // Modo offline: obtener de la caché
      return _localDataSource.getTransactions(
        userId,
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
        accountId: accountId,
      );
    }
  }
  
  // Añadir una transacción (con manejo de modo offline)
  Future<void> addTransaction(FinancialTransaction transaction) async {
    final isConnected = await _connectivityHelper.isConnected();
    
    if (isConnected) {
      try {
        await _remoteDataSource.addTransaction(transaction);
      } catch (e) {
        // Si falla, guardar como operación pendiente
        await _localDataSource.addTransaction(transaction);
        await _localDataSource.addPendingOperation(
          'add_transaction',
          transaction.toMap(),
        );
      }
    } else {
      // Modo offline: guardar localmente y como operación pendiente
      await _localDataSource.addTransaction(transaction);
      await _localDataSource.addPendingOperation(
        'add_transaction',
        transaction.toMap(),
      );
    }
  }
  
  // Actualizar una transacción
  Future<void> updateTransaction(
    FinancialTransaction transaction, {
    String? originalAccountId,
    double? originalAmount,
    String? originalType,
  }) async {
    final isConnected = await _connectivityHelper.isConnected();
    
    if (isConnected) {
      try {
        await _remoteDataSource.updateTransaction(
          transaction,
          originalAccountId: originalAccountId,
          originalAmount: originalAmount,
          originalType: originalType,
        );
      } catch (e) {
        // Si falla, guardar como operación pendiente
        await _localDataSource.updateTransaction(transaction);
        await _localDataSource.addPendingOperation(
          'update_transaction',
          {
            'transaction': transaction.toMap(),
            'originalAccountId': originalAccountId,
            'originalAmount': originalAmount,
            'originalType': originalType,
          },
        );
      }
    } else {
      // Modo offline: actualizar localmente y como operación pendiente
      await _localDataSource.updateTransaction(transaction);
      await _localDataSource.addPendingOperation(
        'update_transaction',
        {
          'transaction': transaction.toMap(),
          'originalAccountId': originalAccountId,
          'originalAmount': originalAmount,
          'originalType': originalType,
        },
      );
    }
  }
  
  // Mover a papelera
  Future<void> moveToTrash(String userId, String transactionId) async {
    final isConnected = await _connectivityHelper.isConnected();
    
    if (isConnected) {
      try {
        await _remoteDataSource.moveToTrash(userId, transactionId);
      } catch (e) {
        // Si falla, guardar como operación pendiente
        await _localDataSource.moveToTrash(userId, transactionId);
        await _localDataSource.addPendingOperation(
          'move_to_trash',
          {
            'userId': userId,
            'transactionId': transactionId,
          },
        );
      }
    } else {
      // Modo offline: actualizar localmente y como operación pendiente
      await _localDataSource.moveToTrash(userId, transactionId);
      await _localDataSource.addPendingOperation(
        'move_to_trash',
        {
          'userId': userId,
          'transactionId': transactionId,
        },
      );
    }
  }
  
  // Eliminar permanentemente
  Future<void> deletePermanently(String userId, String transactionId) async {
    final isConnected = await _connectivityHelper.isConnected();
    
    if (isConnected) {
      try {
        await _remoteDataSource.deletePermanently(userId, transactionId);
      } catch (e) {
        // Si falla, guardar como operación pendiente
        await _localDataSource.deletePermanently(userId, transactionId);
        await _localDataSource.addPendingOperation(
          'delete_permanently',
          {
            'userId': userId,
            'transactionId': transactionId,
          },
        );
      }
    } else {
      // Modo offline: actualizar localmente y como operación pendiente
      await _localDataSource.deletePermanently(userId, transactionId);
      await _localDataSource.addPendingOperation(
        'delete_permanently',
        {
          'userId': userId,
          'transactionId': transactionId,
        },
      );
    }
  }
}