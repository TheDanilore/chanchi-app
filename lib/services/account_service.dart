import 'package:chanchi_app/models/account.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todas las cuentas de un usuario
  Stream<List<Account>> getAccounts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Account.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Crear una nueva cuenta
  Future<void> addAccount(String userId, Account account) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .add(account.toMap());
  }

  // Actualizar una cuenta existente
  Future<void> updateAccount(String userId, Account account) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(account.id)
        .update(account.toMap());
  }

  // Eliminar una cuenta
  Future<void> deleteAccount(String userId, String accountId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(accountId)
        .delete();
  }
}

