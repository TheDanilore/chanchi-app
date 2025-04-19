import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chanchi_app/features/transactions/domain/services/transaction_service.dart';
import 'package:chanchi_app/services/connectivity_service.dart';
import 'package:chanchi_app/services/offline_sync_service.dart';

class HomeService {
  final FirebaseFirestore _firestore;
  final TransactionService _transactionService;
  final ConnectivityService _connectivityService;
  final OfflineSyncService _offlineService;

  HomeService(this._firestore, this._transactionService, this._connectivityService, this._offlineService);

  Stream<QuerySnapshot> getMonthlyTransactions(String userId, DateTime selectedMonth) {
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('isInTrash', isNotEqualTo: true)
        .where('dateTime', isGreaterThanOrEqualTo: firstDayOfMonth)
        .where('dateTime', isLessThanOrEqualTo: lastDayOfMonth)
        .snapshots();
  }

  Stream<QuerySnapshot> getAccounts(String userId) {
    return _firestore.collection('users').doc(userId).collection('accounts').snapshots();
  }

  Stream<QuerySnapshot> getTrashTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('isInTrash', isEqualTo: true)
        .snapshots();
  }

  Future<int> getPendingOperationsCount(String userId) async {
    return _transactionService.getPendingOperationsCount(userId);
  }

  Future<void> syncPendingOperations(String userId) async {
    return _transactionService.syncPendingOperations(userId);
  }

  Future<bool> attemptSync() async {
    return _offlineService.attemptSync();
  }

  Future<bool> checkConnectivity() async {
    return _connectivityService.checkConnectivity();
  }
}
