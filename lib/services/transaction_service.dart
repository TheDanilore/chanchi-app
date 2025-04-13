import 'package:chanchi_app/models/budget.dart';
import 'package:chanchi_app/models/transaction.dart';
import 'package:chanchi_app/services/budget_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionService {
  final FirebaseFirestore _firestore;
  final BudgetService _budgetService;

  TransactionService({
    FirebaseFirestore? firestore,
    BudgetService? budgetService
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _budgetService = budgetService ?? BudgetService();

  // Mover una transacción a la papelera
  Future<void> moveToTrash(String userId, String transactionId) async {
    final transactionRef = _firestore
        .collection('transactions')
        .doc(transactionId);

    await _firestore.runTransaction((transaction) async {
      final transactionDoc = await transaction.get(transactionRef);

      if (!transactionDoc.exists) {
        throw Exception("La transacción no existe");
      }

      final transactionData = transactionDoc.data() as Map<String, dynamic>;

      // Solo proceder si no está ya en la papelera
      if (transactionData['isInTrash'] == true) {
        return;
      }

      final accountId = transactionData['accountId'];
      final accountRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(accountId);

      final accountDoc = await transaction.get(accountRef);

      if (!accountDoc.exists) {
        throw Exception("La cuenta no existe");
      }

      final accountData = accountDoc.data() as Map<String, dynamic>;
      double currentBalance = (accountData['balance'] ?? 0.0).toDouble();
      double amount = (transactionData['amount'] ?? 0.0).toDouble();

      // Ajustar balance según tipo de transacción
      if (transactionData['type'] == 'expense') {
        currentBalance += amount; // Revertir un gasto
      } else {
        currentBalance -= amount; // Revertir un ingreso
      }

      // Marcar como en papelera y actualizar el balance
      transaction.update(transactionRef, {
        'isInTrash': true,
        'trashedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(accountRef, {'balance': currentBalance});
    });
    
    // Actualizar presupuestos después de mover a papelera (si es gasto)
    final transactionDoc = await transactionRef.get();
    final transactionData = transactionDoc.data() as Map<String, dynamic>;
    
    if (transactionData['type'] == 'expense') {
      final amount = (transactionData['amount'] ?? 0.0).toDouble();
      final categoryId = transactionData['categoryId'];
      final dateTime = (transactionData['dateTime'] as Timestamp).toDate();
      
      // Quitar el gasto del presupuesto (isAddition = false)
      await _budgetService.updateBudgetsForTransaction(
        userId, 
        amount, 
        categoryId, 
        dateTime, 
        false
      );
    }
  }

  // Restaurar una transacción desde la papelera
  Future<void> restoreFromTrash(String userId, String transactionId) async {
    final transactionRef = _firestore
        .collection('transactions')
        .doc(transactionId);

    await _firestore.runTransaction((transaction) async {
      final transactionDoc = await transaction.get(transactionRef);

      if (!transactionDoc.exists) {
        throw Exception("La transacción no existe");
      }

      final transactionData = transactionDoc.data() as Map<String, dynamic>;

      // Solo proceder si está en la papelera
      if (transactionData['isInTrash'] != true) {
        return;
      }

      final accountId = transactionData['accountId'];
      final accountRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(accountId);

      final accountDoc = await transaction.get(accountRef);

      if (!accountDoc.exists) {
        throw Exception("La cuenta no existe");
      }

      final accountData = accountDoc.data() as Map<String, dynamic>;
      double currentBalance = (accountData['balance'] ?? 0.0).toDouble();
      double amount = (transactionData['amount'] ?? 0.0).toDouble();

      // Ajustar balance según tipo de transacción
      if (transactionData['type'] == 'expense') {
        currentBalance -= amount; // Aplicar un gasto
      } else {
        currentBalance += amount; // Aplicar un ingreso
      }

      // Quitar marca de papelera y actualizar el balance
      transaction.update(transactionRef, {
        'isInTrash': false,
        'trashedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(accountRef, {'balance': currentBalance});
    });
    
    // Actualizar presupuestos después de restaurar (si es gasto)
    final transactionDoc = await transactionRef.get();
    final transactionData = transactionDoc.data() as Map<String, dynamic>;
    
    if (transactionData['type'] == 'expense') {
      final amount = (transactionData['amount'] ?? 0.0).toDouble();
      final categoryId = transactionData['categoryId'];
      final dateTime = (transactionData['dateTime'] as Timestamp).toDate();
      
      // Añadir el gasto al presupuesto (isAddition = true)
      await _budgetService.updateBudgetsForTransaction(
        userId, 
        amount, 
        categoryId, 
        dateTime, 
        true
      );
    }
  }

  // Eliminar permanentemente una transacción
  Future<void> deletePermanently(String userId, String transactionId) async {
    final transactionRef = _firestore
        .collection('transactions')
        .doc(transactionId);
    
    // Obtener datos de la transacción antes de eliminarla para actualizar presupuestos
    final transactionDoc = await transactionRef.get();
    final transactionData = transactionDoc.data() as Map<String, dynamic>;
    final isInTrash = transactionData['isInTrash'] == true;
    final isExpense = transactionData['type'] == 'expense';
    final amount = (transactionData['amount'] ?? 0.0).toDouble();
    final categoryId = transactionData['categoryId'];
    final dateTime = (transactionData['dateTime'] as Timestamp).toDate();

    await _firestore.runTransaction((transaction) async {
      final transactionDoc = await transaction.get(transactionRef);

      if (!transactionDoc.exists) {
        throw Exception("La transacción no existe");
      }

      final transactionData = transactionDoc.data() as Map<String, dynamic>;

      // Si no está en papelera, debemos ajustar el balance
      if (transactionData['isInTrash'] != true) {
        final accountId = transactionData['accountId'];
        final accountRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('accounts')
            .doc(accountId);

        final accountDoc = await transaction.get(accountRef);

        if (!accountDoc.exists) {
          throw Exception("La cuenta no existe");
        }

        final accountData = accountDoc.data() as Map<String, dynamic>;
        double currentBalance = (accountData['balance'] ?? 0.0).toDouble();
        double amount = (transactionData['amount'] ?? 0.0).toDouble();

        // Ajustar balance según tipo de transacción
        if (transactionData['type'] == 'expense') {
          currentBalance += amount; // Revertir un gasto
        } else {
          currentBalance -= amount; // Revertir un ingreso
        }

        // Actualizar el balance
        transaction.update(accountRef, {'balance': currentBalance});
      }

      // Eliminar la transacción
      transaction.delete(transactionRef);
    });
    
    // Actualizar presupuestos si es necesario
    // Solo si es un gasto y no está en papelera (si está en papelera, ya se actualizaron los presupuestos)
    if (isExpense && !isInTrash) {
      await _budgetService.updateBudgetsForTransaction(
        userId, 
        amount, 
        categoryId, 
        dateTime, 
        false // quitar
      );
    }
  }

  // Duplicar una transacción
  Future<String> duplicateTransaction(
    String userId,
    Map<String, dynamic> originalTransaction,
  ) async {
    try {
      // Crear una copia de la transacción con un nuevo ID
      final newTransactionRef = _firestore.collection('transactions').doc();

      // Datos para la nueva transacción - conservar todos los datos importantes
      final Map<String, dynamic> newTransactionData = {
        ...originalTransaction, // Mantener todos los datos originales
        'dateTime': Timestamp.fromDate(
          DateTime.now(),
        ), // Solo actualizar la fecha
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isInTrash': false,
      };

      // Eliminar campos que no deben copiarse o que serán actualizados
      newTransactionData.remove('trashedAt');

      // Crear la transacción duplicada sin modificar el balance aún
      await newTransactionRef.set(newTransactionData);

      return newTransactionRef.id;
    } catch (e) {
      throw Exception("Error al duplicar la transacción: $e");
    }
  }
  
  // Método para actualizar presupuestos cuando se crea una nueva transacción
  Future<void> updateBudgetsForNewTransaction(
    BuildContext context,
    String userId,
    Map<String, dynamic> transactionData
  ) async {
    try {
      // Solo actualizar presupuestos para gastos
      if (transactionData['type'] == 'expense') {
        final amount = (transactionData['amount'] as num).toDouble();
        final categoryId = transactionData['categoryId'];
        final dateTime = (transactionData['dateTime'] as Timestamp).toDate();
        
        // Actualizar presupuestos
        await _budgetService.updateBudgetsForTransaction(
          userId, 
          amount, 
          categoryId,
          dateTime, 
          true // Añadir
        );
        
        // Obtener presupuestos actuales para mostrar notificaciones
        final String currentMonth = DateFormat('yyyy-MM').format(dateTime);
        final budgets = await _firestore
            .collection('budgets')
            .where('userId', isEqualTo: userId)
            .where('month', isEqualTo: currentMonth)
            .where('isEnabled', isEqualTo: true)
            .get();
            
        final budgetList = budgets.docs
            .map((doc) => Budget.fromMap(doc.data(), doc.id))
            .toList();
            
        if (budgetList.isNotEmpty && context.mounted) {
          _budgetService.checkBudgetNotifications(budgetList, context);
        }
      }
    } catch (e) {
      print('Error al actualizar presupuestos para nueva transacción: $e');
    }
  }
  
  // Método para actualizar presupuestos cuando se edita o elimina una transacción
  Future<void> updateBudgetsForTransaction(
    String userId,
    double amount,
    String? categoryId,
    DateTime transactionDate,
    bool isAddition // true: añadir, false: quitar
  ) async {
    try {
      await _budgetService.updateBudgetsForTransaction(
        userId, 
        amount, 
        categoryId, 
        transactionDate, 
        isAddition
      );
    } catch (e) {
      print('Error al actualizar presupuestos para transacción: $e');
    }
  }

  // Limpiar transacciones antiguas de la papelera (más de 30 días)
  Future<void> cleanupOldTrashedTransactions() async {
    // Calcular la fecha límite (30 días atrás)
    final DateTime cutoffDate = DateTime.now().subtract(
      const Duration(days: 30),
    );
    final Timestamp cutoffTimestamp = Timestamp.fromDate(cutoffDate);

    try {
      // Obtener todas las transacciones en papelera con fecha anterior al límite
      final trashedTransactionsQuery =
          await _firestore
              .collection('transactions')
              .where('isInTrash', isEqualTo: true)
              .where('trashedAt', isLessThan: cutoffTimestamp)
              .get();

      // Eliminar cada transacción en un batch
      final batch = _firestore.batch();
      for (final doc in trashedTransactionsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Ejecutar el batch si hay documentos para eliminar
      if (trashedTransactionsQuery.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      throw Exception("Error al limpiar transacciones antiguas: $e");
    }
  }

  // Vaciar completamente la papelera de un usuario
  Future<void> emptyTrash(String userId) async {
    try {
      // Obtener todas las transacciones en papelera del usuario
      final trashedTransactionsQuery =
          await _firestore
              .collection('transactions')
              .where('userId', isEqualTo: userId)
              .where('isInTrash', isEqualTo: true)
              .get();

      // Eliminar cada transacción en un batch
      final batch = _firestore.batch();
      for (final doc in trashedTransactionsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Ejecutar el batch si hay documentos para eliminar
      if (trashedTransactionsQuery.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      throw Exception("Error al vaciar la papelera: $e");
    }
  }

  // Corregir lógica al cambiar de cuenta en una transacción
  Future<void> updateTransactionWithAccountChange(
    String userId,
    String transactionId,
    Map<String, dynamic> newData,
    String originalAccountId,
    String newAccountId,
    double originalAmount,
    String originalType,
  ) async {
    final transactionRef = _firestore
        .collection('transactions')
        .doc(transactionId);

    await _firestore.runTransaction((transaction) async {
      // Referencias a las cuentas
      final originalAccountRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(originalAccountId);

      final newAccountRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(newAccountId);

      // Obtener documentos
      final originalAccountDoc = await transaction.get(originalAccountRef);
      final newAccountDoc = await transaction.get(newAccountRef);
      final transactionDoc = await transaction.get(transactionRef);

      if (!originalAccountDoc.exists ||
          !newAccountDoc.exists ||
          !transactionDoc.exists) {
        throw Exception("Documento no encontrado");
      }

      // Datos actuales
      final originalAccountData =
          originalAccountDoc.data() as Map<String, dynamic>;
      final newAccountData = newAccountDoc.data() as Map<String, dynamic>;

      // Balances actuales
      double originalBalance =
          (originalAccountData['balance'] ?? 0.0).toDouble();
      double newBalance = (newAccountData['balance'] ?? 0.0).toDouble();

      // 1. Revertir la transacción original en la cuenta original
      if (originalType == 'expense') {
        originalBalance += originalAmount; // Revertir un gasto
      } else {
        originalBalance -= originalAmount; // Revertir un ingreso
      }

      // 2. Aplicar la nueva transacción en la nueva cuenta
      final newAmount = double.parse(newData['amount'].toString());
      final newType = newData['type'];

      if (newType == 'expense') {
        newBalance -= newAmount; // Aplicar un gasto
      } else {
        newBalance += newAmount; // Aplicar un ingreso
      }

      // 3. Actualizar ambas cuentas y la transacción
      transaction.update(originalAccountRef, {'balance': originalBalance});
      transaction.update(newAccountRef, {'balance': newBalance});
      transaction.update(transactionRef, {
        ...newData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    
    // Actualizar presupuestos si es necesario
    final transactionDoc = await transactionRef.get();
    final transactionData = transactionDoc.data() as Map<String, dynamic>;
    
    // Si la transacción original era un gasto, quitar del presupuesto
    if (originalType == 'expense') {
      final dateTime = (transactionData['dateTime'] as Timestamp).toDate();
      await _budgetService.updateBudgetsForTransaction(
        userId, 
        originalAmount, 
        transactionData['categoryId'], 
        dateTime, 
        false // quitar
      );
    }
    
    // Si la nueva transacción es un gasto, añadir al presupuesto
    if (transactionData['type'] == 'expense') {
      final amount = (transactionData['amount'] as num).toDouble();
      final categoryId = transactionData['categoryId'];
      final dateTime = (transactionData['dateTime'] as Timestamp).toDate();
      
      await _budgetService.updateBudgetsForTransaction(
        userId, 
        amount, 
        categoryId, 
        dateTime, 
        true // añadir
      );
    }
  }

  // Crear una nueva transacción
  Future<void> addTransaction(FinancialTransaction transaction) {
    return _firestore.collection('transactions').add(transaction.toMap());
  }

  // Actualizar una transacción existente
  Future<void> updateTransaction(FinancialTransaction transaction) {
    return _firestore
        .collection('transactions')
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  // Eliminar una transacción
  Future<void> deleteTransaction(String transactionId) {
    return _firestore.collection('transactions').doc(transactionId).delete();
  }

  // Obtener transacciones con filtros
  Stream<List<FinancialTransaction>> getTransactions({
    required String userId,
    String? accountId,
    String? categoryId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) {
    try {
      // Crear la consulta base
      Query query = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId);

      // Aplicar filtros adicionales
      if (accountId != null) {
        query = query.where('accountId', isEqualTo: accountId);
      }

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }

      // Aplicar ordenamiento después de los filtros
      query = query.orderBy('dateTime', descending: true).limit(limit);

      return query.snapshots().map((snapshot) {
        List<FinancialTransaction> transactions = [];
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final transaction = FinancialTransaction.fromMap(data, doc.id);
            transactions.add(transaction);
          } catch (e) {
            print('Error al convertir documento ${doc.id}: $e');
            // Continuar con el siguiente documento
          }
        }

        // Filtrado adicional por fecha si es necesario
        if (startDate != null || endDate != null) {
          transactions =
              transactions.where((transaction) {
                if (startDate != null &&
                    transaction.dateTime.isBefore(startDate)) {
                  return false;
                }
                if (endDate != null && transaction.dateTime.isAfter(endDate)) {
                  return false;
                }
                return true;
              }).toList();
        }

        return transactions;
      });
    } catch (e) {
      print('Error en getTransactions: $e');
      return Stream.value([]);
    }
  }
}
