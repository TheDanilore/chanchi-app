import 'package:chanchi_app/data/models/account.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/features/transactions/domain/services/transaction_service.dart';
import 'package:chanchi_app/services/connectivity_service.dart';

class AccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionService _transactionService = TransactionService();
  final ConnectivityService _connectivityService = ConnectivityService();

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

      // Validación básica
      if (userId.isEmpty || accountId.isEmpty) {
        throw Exception('IDs de usuario y cuenta no pueden estar vacíos');
      }

      // Verificar conectividad
      final isConnected = await _connectivityService.checkConnectivity();
      if (!isConnected) {
        throw Exception('No hay conexión a internet. Intenta más tarde.');
      }

      // Referencia a la cuenta
      final accountRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(accountId);

      // 1. Verificar que la cuenta existe
      final accountDoc = await accountRef.get();
      if (!accountDoc.exists) {
        throw Exception('La cuenta no existe');
      }

      // 2. Obtener datos de la cuenta
      final accountData = accountDoc.data() as Map<String, dynamic>;
      final bool isCreditCard = accountData['isCreditCard'] ?? false;
      final double balance = (accountData['balance'] ?? 0.0).toDouble();

      // 3. Obtener y procesar transacciones en un proceso de varios pasos:

      // Paso 1: Mover todas las transacciones activas a la papelera
      // Esto actualizará los balances automáticamente a través de _adjustBalanceForTrash
      await _transactionService.moveAccountTransactionsToTrash(
        userId,
        accountId,
      );

      // Paso 2: Eliminar permanentemente las transacciones que ya estaban en la papelera
      await _transactionService.deleteAccountTrashTransactions(
        userId,
        accountId,
      );

      // Paso 3: Eliminar la cuenta con seguridad
      await accountRef.delete();

      print('Cuenta eliminada correctamente');

      // Sincronizar las operaciones pendientes si existen
      try {
        await _transactionService.syncPendingOperations(userId);
      } catch (syncError) {
        print('Error al sincronizar operaciones pendientes: $syncError');
        // No interrumpir el flujo por errores de sincronización
      }
    } catch (e) {
      print('Error detallado al eliminar cuenta: $e');

      if (e is FirebaseException) {
        print('Código de error: ${e.code}');
        print('Mensaje de error: ${e.message}');
      }

      rethrow;
    }
  }

  // Método para verificar si hay transacciones asociadas a una cuenta
  Future<int> getAssociatedTransactionsCount(
    String userId,
    String accountId,
  ) async {
    try {
      // Contar transacciones donde esta cuenta es la principal
      final transactionsQuery =
          await _firestore
              .collection('transactions')
              .where('userId', isEqualTo: userId)
              .where('accountId', isEqualTo: accountId)
              .count()
              .get();

      // Contar transacciones donde esta cuenta es la cuenta origen
      final fromAccountTransactions =
          await _firestore
              .collection('transactions')
              .where('userId', isEqualTo: userId)
              .where('fromAccountId', isEqualTo: accountId)
              .count()
              .get();

      // Usar el operador ?? para proporcionar un valor predeterminado de 0 si count es nulo
      final mainCount = transactionsQuery.count ?? 0;
      final fromCount = fromAccountTransactions.count ?? 0;

      return mainCount + fromCount;
    } catch (e) {
      print('Error al contar transacciones asociadas: $e');
      return 0; // En caso de error, devolver 0
    }
  }
}
