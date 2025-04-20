// lib/features/home/domain/services/home_service.dart
import 'package:chanchi_app/core/utils/connectivity_helper.dart';
import 'package:chanchi_app/features/home/data/repositories/transaction_repository.dart';
import 'package:chanchi_app/features/home/data/repositories/sync_repository.dart';
import 'package:chanchi_app/features/home/domain/models/transaction.dart';

class HomeService {
  final TransactionRepository _transactionRepository;
  final SyncRepository _syncRepository;
  final ConnectivityHelper _connectivityHelper;
  
  HomeService({
    TransactionRepository? transactionRepository,
    SyncRepository? syncRepository,
    ConnectivityHelper? connectivityHelper,
  }) : 
    _transactionRepository = transactionRepository ?? TransactionRepository(),
    _syncRepository = syncRepository ?? SyncRepository(),
    _connectivityHelper = connectivityHelper ?? ConnectivityHelper();
  
  // Verificar conectividad
  Future<bool> checkConnectivity() async {
    return await _connectivityHelper.isConnected();
  }
  
  // Obtener cantidad de operaciones pendientes
  Future<int> getPendingOperationsCount(String userId) async {
    return await _syncRepository.getPendingOperationsCount(userId);
  }
  
  // Intentar sincronizar datos
  Future<bool> attemptSync() async {
    final isConnected = await checkConnectivity();
    if (!isConnected) return false;
    
    await _syncRepository.syncPendingOperations();
    return true;
  }
  
  // Sincronizar operaciones pendientes para un usuario específico
  Future<void> syncPendingOperations(String userId) async {
    await _syncRepository.syncPendingOperations(userId);
  }
  
  // Obtener transacciones para un usuario
  Future<List<Transaction>> getTransactions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
  }) async {
    return await _transactionRepository.getTransactions(
      userId,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      accountId: accountId,
    );
  }
  
  // Obtener resumen financiero
  Future<Map<String, dynamic>> getFinancialSummary(
    String userId,
    DateTime month,
  ) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    
    final transactions = await _transactionRepository.getTransactions(
      userId,
      startDate: startDate,
      endDate: endDate,
    );
    
    double totalIncome = 0;
    double totalExpense = 0;
    
    for (var transaction in transactions) {
      if (transaction.type == 'income') {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }
    
    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': totalIncome - totalExpense,
      'transactionCount': transactions.length,
    };
  }
}