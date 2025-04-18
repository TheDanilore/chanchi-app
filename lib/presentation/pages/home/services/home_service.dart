import 'package:cloud_firestore/cloud_firestore.dart';

class HomeService {
  final FirebaseFirestore _firestore;

  HomeService(this._firestore);

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
}
