import 'package:chanchi_app/data/models/account.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Verificar si es necesaria la migración
  Future<bool> needsMigration(String userId) async {
    try {
      final accounts =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('accounts')
              .get();

      Map<String, String> oldTypes = {
        'Efectivo': 'cash',
        'Cuenta Corriente': 'checking',
        'Cuenta de Ahorros': 'savings',
        'Tarjeta de Crédito': 'credit_card',
        'Inversión': 'investment',
      };

      // Verificar si alguna cuenta tiene un tipo antiguo
      for (var doc in accounts.docs) {
        final data = doc.data();
        final currentType = data['type'] as String?;

        if (currentType != null && oldTypes.containsKey(currentType)) {
          return true; // Necesita migración
        }
      }

      return false; // No necesita migración
    } catch (e) {
      print('Error al verificar migración: $e');

      // Si hay un error de permisos, devolver false para evitar bloquear la aplicación
      if (e is FirebaseException && e.code == 'permission-denied') {
        print('Permiso denegado al verificar migración');
        return false;
      }

      // Relanzar cualquier otro tipo de error
      rethrow;
    }
  }

  Future<void> migrateAccountTypes(String userId) async {
    Map<String, String> typeMapping = {
      'Efectivo': 'cash',
      'Cuenta Corriente': 'checking',
      'Cuenta de Ahorros': 'savings',
      'Tarjeta de Crédito': 'credit_card',
      'Inversión': 'investment',
    };

    final accounts =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('accounts')
            .get();

    WriteBatch batch = _firestore.batch();

    for (var doc in accounts.docs) {
      final data = doc.data();
      final currentType = data['type'] as String?;

      if (currentType != null && typeMapping.containsKey(currentType)) {
        batch.update(doc.reference, {
          'type': typeMapping[currentType],
          // Si es tarjeta de crédito, asegúrate de que tenga esta propiedad
          if (typeMapping[currentType] == 'credit_card') 'isCreditCard': true,
        });
      }
    }

    if (accounts.docs.isNotEmpty) {
      await batch.commit();
    }
  }

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
  Future<void> deleteAccount(String userId, String accountId) async {
    try {
      print('Iniciando eliminación de cuenta');
      print('User ID: $userId');
      print('Account ID: $accountId');

      // Eliminar validación que compara userId y accountId
      if (userId.isEmpty || accountId.isEmpty) {
        throw Exception('IDs de usuario y cuenta no pueden estar vacíos');
      }

      // Resto del método permanece igual...
    } catch (e) {
      print('Error detallado al eliminar cuenta: $e');

      if (e is FirebaseException) {
        print('Código de error: ${e.code}');
        print('Mensaje de error: ${e.message}');
      }

      rethrow;
    }
  }
}
