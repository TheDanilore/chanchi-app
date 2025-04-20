// lib/features/home/data/data_sources/transaction_remote_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chanchi_app/features/home/domain/models/transaction.dart';

class TransactionRemoteDataSource {
  final FirebaseFirestore _firestore;
  
  TransactionRemoteDataSource({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  // Obtener transacciones de Firebase
  Future<List<FinancialTransaction>> getTransactions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
  }) async {
    Query query = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('isInTrash', isEqualTo: false);
    
    if (startDate != null) {
      query = query.where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    
    if (endDate != null) {
      query = query.where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    
    if (accountId != null) {
      query = query.where('accountId', isEqualTo: accountId);
    }
    
    final querySnapshot = await query.orderBy('dateTime', descending: true).get();
    
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return FinancialTransaction.fromMap(data, doc.id);
    }).toList();
  }
  
  // Añadir una transacción a Firebase
  Future<void> addTransaction(FinancialTransaction transaction) async {
    final batch = _firestore.batch();
    
    // Crear referencia para la nueva transacción
    final transactionRef = _firestore.collection('transactions').doc();
    
    // Actualizar balance de la cuenta
    final accountRef = _firestore
        .collection('users')
        .doc(transaction.userId)
        .collection('accounts')
        .doc(transaction.accountId);
    
    // Obtener documento de la cuenta
    final accountDoc = await accountRef.get();
    
    if (!accountDoc.exists) {
      throw Exception('La cuenta no existe');
    }
    
    final accountData = accountDoc.data()!;
    final currentBalance = (accountData['balance'] ?? 0.0).toDouble();
    double newBalance = currentBalance;
    
    // Actualizar balance según tipo de transacción
    if (transaction.type == 'income') {
      newBalance = currentBalance + transaction.amount;
    } else if (transaction.type == 'expense') {
      newBalance = currentBalance - transaction.amount;
    }
    
    // Añadir transacción al batch
    batch.set(
      transactionRef,
      {
        ...transaction.toMap(),
        'id': transactionRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    
    // Actualizar cuenta en el batch
    batch.update(accountRef, {'balance': newBalance});
    
    // Ejecutar batch
    await batch.commit();
  }
  
  // Actualizar una transacción
  Future<void> updateTransaction(
    FinancialTransaction transaction, {
    String? originalAccountId,
    double? originalAmount,
    String? originalType,
  }) async {
    final batch = _firestore.batch();
    
    // Referencia a la transacción
    final transactionRef = _firestore.collection('transactions').doc(transaction.id);
    
    // Si cambia la cuenta o el monto, actualizar balances
    if (originalAccountId != null && 
        (originalAccountId != transaction.accountId || 
        originalAmount != transaction.amount || 
        originalType != transaction.type)) {
      
      // Si cambió de cuenta, actualizar ambas cuentas
      if (originalAccountId != transaction.accountId) {
        // Obtener la cuenta original
        final originalAccountRef = _firestore
            .collection('users')
            .doc(transaction.userId)
            .collection('accounts')
            .doc(originalAccountId);
        
        final originalAccountDoc = await originalAccountRef.get();
        
        if (!originalAccountDoc.exists) {
          throw Exception('La cuenta original no existe');
        }
        
        final originalAccountData = originalAccountDoc.data()!;
        double originalBalance = (originalAccountData['balance'] ?? 0.0).toDouble();
        
        // Revertir la transacción original
        if (originalType == 'income') {
          originalBalance -= originalAmount!;
        } else if (originalType == 'expense') {
          originalBalance += originalAmount!;
        }
        
        // Actualizar la cuenta original
        batch.update(originalAccountRef, {'balance': originalBalance});
        
        // Obtener la nueva cuenta
        final newAccountRef = _firestore
            .collection('users')
            .doc(transaction.userId)
            .collection('accounts')
            .doc(transaction.accountId);
        
        final newAccountDoc = await newAccountRef.get();
        
        if (!newAccountDoc.exists) {
          throw Exception('La nueva cuenta no existe');
        }
        
        final newAccountData = newAccountDoc.data()!;
        double newBalance = (newAccountData['balance'] ?? 0.0).toDouble();
        
        // Aplicar la nueva transacción
        if (transaction.type == 'income') {
          newBalance += transaction.amount;
        } else if (transaction.type == 'expense') {
          newBalance -= transaction.amount;
        }
        
        // Actualizar la nueva cuenta
        batch.update(newAccountRef, {'balance': newBalance});
      } else {
        // Solo cambió el monto o el tipo, actualizar la cuenta
        final accountRef = _firestore
            .collection('users')
            .doc(transaction.userId)
            .collection('accounts')
            .doc(transaction.accountId);
        
        final accountDoc = await accountRef.get();
        
        if (!accountDoc.exists) {
          throw Exception('La cuenta no existe');
        }
        
        final accountData = accountDoc.data()!;
        double balance = (accountData['balance'] ?? 0.0).toDouble();
        
        // Revertir transacción original
        if (originalType == 'income') {
          balance -= originalAmount!;
        } else if (originalType == 'expense') {
          balance += originalAmount!;
        }
        
        // Aplicar nueva transacción
        if (transaction.type == 'income') {
          balance += transaction.amount;
        } else if (transaction.type == 'expense') {
          balance -= transaction.amount;
        }
        
        // Actualizar la cuenta
        batch.update(accountRef, {'balance': balance});
      }
    }
    
    // Actualizar la transacción
    batch.update(
      transactionRef,
      {
        ...transaction.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    
    // Ejecutar batch
    await batch.commit();
  }
  
  // Mover a papelera
  Future<void> moveToTrash(String userId, String transactionId) async {
    final transactionRef = _firestore.collection('transactions').doc(transactionId);
    final transactionDoc = await transactionRef.get();
    
    if (!transactionDoc.exists) {
      throw Exception('La transacción no existe');
    }
    
    final transactionData = transactionDoc.data()!;
    
    // Verificar que la transacción pertenezca al usuario
    if (transactionData['userId'] != userId) {
      throw Exception('La transacción no pertenece a este usuario');
    }
    
    final accountId = transactionData['accountId'];
    final amount = (transactionData['amount'] ?? 0.0).toDouble();
    final type = transactionData['type'];
    
    // Actualizar la cuenta
    final accountRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(accountId);
    
    final accountDoc = await accountRef.get();
    
    if (!accountDoc.exists) {
      throw Exception('La cuenta no existe');
    }
    
    final accountData = accountDoc.data()!;
    double balance = (accountData['balance'] ?? 0.0).toDouble();
    
    // Revertir el efecto de la transacción
    if (type == 'income') {
      balance -= amount;
    } else if (type == 'expense') {
      balance += amount;
    }
    
    // Realizar cambios en una transacción
    final batch = _firestore.batch();
    
    // Actualizar transacción y cuenta
    batch.update(transactionRef, {
      'isInTrash': true,
      'trashedAt': FieldValue.serverTimestamp(),
    });
    
    batch.update(accountRef, {'balance': balance});
    
    // Ejecutar batch
    await batch.commit();
  }
  
  // Eliminar permanentemente
  Future<void> deletePermanently(String userId, String transactionId) async {
    await _firestore.collection('transactions').doc(transactionId).delete();
  }
}
