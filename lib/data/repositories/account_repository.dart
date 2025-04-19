// lib/data/repositories/account_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chanchi_app/data/models/account.dart';

class AccountRepository {
  final FirebaseFirestore _firestore;

  AccountRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<Account>> getAccounts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Account.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Otros métodos para manipular cuentas
  Future<void> addAccount(String userId, Map<String, dynamic> accountData) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .add(accountData);
  }

  Future<void> updateAccount(String userId, String accountId, Map<String, dynamic> accountData) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(accountId)
        .update(accountData);
  }
}