// lib/features/home/data/repositories/sync_repository.dart
import 'package:chanchi_app/core/utils/connectivity_helper.dart';
import 'package:chanchi_app/features/home/data/data_sources/transaction_local_data_source.dart';
import 'package:chanchi_app/features/home/data/data_sources/transaction_remote_data_source.dart';
import 'package:chanchi_app/features/home/domain/models/transaction.dart';

class SyncRepository {
  final TransactionLocalDataSource _localDataSource;
  final TransactionRemoteDataSource _remoteDataSource;
  final ConnectivityHelper _connectivityHelper;
  
  SyncRepository({
    TransactionLocalDataSource? localDataSource,
    TransactionRemoteDataSource? remoteDataSource,
    ConnectivityHelper? connectivityHelper,
  }) : 
    _localDataSource = localDataSource ?? TransactionLocalDataSource(),
    _remoteDataSource = remoteDataSource ?? TransactionRemoteDataSource(),
    _connectivityHelper = connectivityHelper ?? ConnectivityHelper();
  
  // Obtener cantidad de operaciones pendientes
  Future<int> getPendingOperationsCount(String userId) async {
    return await _localDataSource.getPendingOperationsCount();
  }
  
  // Sincronizar operaciones pendientes
  Future<void> syncPendingOperations([String? userId]) async {
    final isConnected = await _connectivityHelper.isConnected();
    
    if (!isConnected) {
      throw Exception('No hay conexión a internet para sincronizar');
    }
    
    final pendingOperations = await _localDataSource.getPendingOperations();
    
    for (int i = 0; i < pendingOperations.length; i++) {
      final operation = pendingOperations[i];
      final operationType = operation['type'];
      final data = operation['data'];
      
      try {
        switch (operationType) {
          case 'add_transaction':
            final transaction = FinancialTransaction.fromMap(data, data['id'] ?? '');
            await _remoteDataSource.addTransaction(transaction);
            break;
          
          case 'update_transaction':
            final transaction = FinancialTransaction.fromMap(data['transaction'], data['transaction']['id'] ?? '');
            await _remoteDataSource.updateTransaction(
              transaction,
              originalAccountId: data['originalAccountId'],
              originalAmount: data['originalAmount'],
              originalType: data['originalType'],
            );
            break;
          
          case 'move_to_trash':
            await _remoteDataSource.moveToTrash(
              data['userId'],
              data['transactionId'],
            );
            break;
          
          case 'delete_permanently':
            await _remoteDataSource.deletePermanently(
              data['userId'],
              data['transactionId'],
            );
            break;
        }
        
        // Si la operación se realizó correctamente, eliminarla
        await _localDataSource.deletePendingOperation(i);
      } catch (e) {
        // Seguir con la siguiente operación
        print('Error al sincronizar operación ${i}: ${e.toString()}');
      }
    }
  }
}