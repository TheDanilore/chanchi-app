import 'package:chanchi_app/models/budget.dart';
import 'package:chanchi_app/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  
  factory BudgetService() => _instance;
  
  BudgetService._internal();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  
  // Registro de presupuestos verificados para evitar notificaciones repetidas
  final Map<String, double> _lastProcessedBudgets = {};

  /// Obtiene todos los presupuestos de un usuario
  Stream<List<Budget>> getBudgets(String userId) {
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('isEnabled', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Budget.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Obtiene los presupuestos del mes actual
  Stream<List<Budget>> getCurrentMonthBudgets(String userId) {
    final String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('month', isEqualTo: currentMonth)
        .where('isEnabled', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final budgets = snapshot.docs.map((doc) {
            return Budget.fromMap(doc.data(), doc.id);
          }).toList();
          
          // Procesar notificaciones de presupuestos de manera controlada
          _processCurrentBudgets(budgets);
          
          return budgets;
        });
  }

  /// Obtiene un presupuesto específico por ID
  Future<Budget?> getBudgetById(String budgetId) async {
    try {
      final doc = await _firestore.collection('budgets').doc(budgetId).get();

      if (doc.exists) {
        return Budget.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error al obtener presupuesto: $e');
      return null;
    }
  }

  /// Crea un nuevo presupuesto y calcula el gasto acumulado hasta la fecha
  Future<String?> createBudget(Budget budget) async {
    try {
      // Calcular gastos acumulados para este mes y categoría
      final initialSpent = await _calculateInitialSpent(
        budget.userId,
        budget.month,
        budget.categoryId,
      );

      print('Gasto inicial para nuevo presupuesto: $initialSpent');

      // Crear presupuesto con el gasto inicial calculado
      final budgetData = {
        ...budget.toMap(),
        'currentSpent': initialSpent,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('budgets').add(budgetData);
      return docRef.id;
    } catch (e) {
      print('Error al crear presupuesto: $e');
      return null;
    }
  }

  /// Calcula el gasto acumulado hasta la fecha para un mes y categoría específicos
  Future<double> _calculateInitialSpent(
    String userId,
    String month,
    String? categoryId,
  ) async {
    try {
      // Convertir el formato de mes (YYYY-MM) a fechas de inicio y fin
      final parts = month.split('-');
      final year = int.parse(parts[0]);
      final monthNum = int.parse(parts[1]);

      final startOfMonth = DateTime(year, monthNum, 1);
      final endOfMonth =
          (monthNum < 12)
              ? DateTime(
                year,
                monthNum + 1,
                1,
              ).subtract(const Duration(days: 1))
              : DateTime(year + 1, 1, 1).subtract(const Duration(days: 1));

      // Construir consulta básica para transacciones del mes
      Query query = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'expense') // Solo gastos
          .where(
            'isInTrash',
            isEqualTo: false,
          ) // Solo transacciones activas
          .where('dateTime', isGreaterThanOrEqualTo: startOfMonth)
          .where('dateTime', isLessThanOrEqualTo: endOfMonth);

      // Filtrar por categoría si corresponde
      QuerySnapshot snapshot;

      if (categoryId != null) {
        // Para consultas específicas de categoría
        snapshot = await query.where('categoryId', isEqualTo: categoryId).get();
      } else {
        // Para presupuestos generales, necesitamos obtener todas las transacciones sin filtro adicional
        snapshot = await query.get();
      }

      // Sumar todos los gastos
      double totalSpent = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalSpent += (data['amount'] as num).toDouble();
      }

      print(
        'Total calculado para ${categoryId ?? "todas las categorías"}: $totalSpent',
      );
      return totalSpent;
    } catch (e) {
      print('Error al calcular gasto inicial: $e');
      // Registrar más detalles sobre el error
      if (e is FirebaseException) {
        print('Código: ${e.code}, Mensaje: ${e.message}');
      }
      return 0.0;
    }
  }

  /// Actualiza un presupuesto existente
  Future<bool> updateBudget(Budget budget) async {
    try {
      await _firestore
          .collection('budgets')
          .doc(budget.id)
          .update(budget.toMap());
      return true;
    } catch (e) {
      print('Error al actualizar presupuesto: $e');
      return false;
    }
  }

  /// Elimina un presupuesto (desactivación lógica)
  Future<bool> disableBudget(String budgetId) async {
    try {
      await _firestore.collection('budgets').doc(budgetId).update({
        'isEnabled': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error al desactivar presupuesto: $e');
      return false;
    }
  }

  /// Actualiza el gasto actual de un presupuesto
  Future<bool> updateBudgetSpent(String budgetId, double newSpentAmount) async {
    try {
      await _firestore.collection('budgets').doc(budgetId).update({
        'currentSpent': newSpentAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error al actualizar gasto del presupuesto: $e');
      return false;
    }
  }

  /// Actualiza el gasto actual de todos los presupuestos afectados por una transacción
  /// Esto debe llamarse cuando se agrega/edita/elimina una transacción
  Future<void> updateBudgetsForTransaction(
    String userId,
    double amount,
    String? categoryId,
    DateTime transactionDate,
    bool isAddition, // true si se agrega, false si se quita
  ) async {
    try {
      final month = DateFormat('yyyy-MM').format(transactionDate);

      // Consultar presupuestos afectados (generales o de la categoría específica)
      final budgetsQuery =
          await _firestore
              .collection('budgets')
              .where('userId', isEqualTo: userId)
              .where('month', isEqualTo: month)
              .where('isEnabled', isEqualTo: true)
              .get();

      // Procesar cada presupuesto afectado
      final batch = _firestore.batch();
      final List<Budget> updatedBudgets = [];

      for (final doc in budgetsQuery.docs) {
        final budget = Budget.fromMap(doc.data(), doc.id);

        // Verificar si afecta a este presupuesto (si es general o coincide la categoría)
        final bool affectsBudget =
            budget.categoryId == null || // Presupuesto general
            budget.categoryId ==
                categoryId; // Presupuesto específico de categoría

        if (affectsBudget) {
          // Calcular nuevo gasto
          double newSpent = (budget.currentSpent ?? 0);

          if (isAddition) {
            newSpent += amount;
          } else {
            newSpent -= amount;
            // Evitar valores negativos
            if (newSpent < 0) newSpent = 0;
          }

          // Actualizar presupuesto
          batch.update(doc.reference, {
            'currentSpent': newSpent,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          // Guardar para notificaciones
          updatedBudgets.add(budget.copyWith(currentSpent: newSpent));
        }
      }

      // Confirmar todas las actualizaciones
      await batch.commit();
      
      // Evaluar notificaciones para los presupuestos actualizados
      for (final budget in updatedBudgets) {
        _evaluateBudgetForNotification(budget);
      }
    } catch (e) {
      print('Error al actualizar presupuestos para transacción: $e');
    }
  }

  /// Método para actualizar todos los presupuestos cuando se crea una nueva transacción
  Future<void> updateBudgetsForNewTransaction(
    BuildContext context,
    String userId,
    Map<String, dynamic> transactionData,
  ) async {
    try {
      // Verificar si es un gasto
      if (transactionData['type'] != 'expense') return;

      // Extraer datos relevantes
      final amount = (transactionData['amount'] as num).toDouble();
      final categoryId = transactionData['categoryId'] as String?;
      final dateTime = (transactionData['dateTime'] as Timestamp).toDate();

      // Actualizar presupuestos afectados
      await updateBudgetsForTransaction(
        userId,
        amount,
        categoryId,
        dateTime,
        true, // Es una adición
      );
    } catch (e) {
      print('Error al actualizar presupuestos para nueva transacción: $e');
    }
  }

  /// Recalcula y actualiza el gasto actual para un presupuesto específico
  /// Útil para actualizar manualmente un presupuesto existente
  Future<bool> recalculateBudgetSpent(Budget budget) async {
    try {
      // Calcular el gasto acumulado hasta la fecha
      final updatedSpent = await _calculateInitialSpent(
        budget.userId,
        budget.month,
        budget.categoryId,
      );

      // Actualizar el presupuesto con el nuevo gasto calculado
      final updatedBudget = budget.copyWith(currentSpent: updatedSpent);
      return await updateBudget(updatedBudget);
    } catch (e) {
      print('Error al recalcular gasto del presupuesto: $e');
      return false;
    }
  }

  // Método para procesar y verificar notificaciones de presupuestos actuales
  void _processCurrentBudgets(List<Budget> budgets) {
    for (final budget in budgets) {
      // Solo verificar si está habilitado
      if (!budget.isEnabled) continue;
      
      // Verificar si ya procesamos este presupuesto con el mismo valor
      final lastAmount = _lastProcessedBudgets[budget.id];
      final currentAmount = budget.currentSpent ?? 0.0;
      
      // Si ya lo procesamos con el mismo gasto, omitir
      if (lastAmount != null && (lastAmount - currentAmount).abs() < 0.01) {
        continue;
      }
      
      // Actualizar registro
      _lastProcessedBudgets[budget.id] = currentAmount;
      
      // Evaluar si corresponde enviar notificación
      _evaluateBudgetForNotification(budget);
    }
  }
  
  // Evalúa un presupuesto para determinar si debe enviar notificación
  void _evaluateBudgetForNotification(Budget budget) {
    if (!budget.isEnabled) return;
    
    String? title;
    String? body;
    
    // Verificar condiciones en orden de prioridad
    if (budget.isLimitExceeded && budget.notifyWhenExceeded) {
      title = 'Presupuesto Excedido';
      body =
          'Has superado tu presupuesto ${budget.categoryId != null ? 'para esta categoría' : 'mensual'} (${(budget.percentageUsed * 100).toStringAsFixed(0)}%)';
    } else if (budget.isLimitReached && budget.notifyWhenReached) {
      title = 'Límite de Presupuesto Alcanzado';
      body =
          'Has alcanzado tu presupuesto ${budget.categoryId != null ? 'para esta categoría' : 'mensual'}';
    } else if (budget.isCloseToLimit && budget.notifyWhenClose) {
      title = 'Alerta de Presupuesto';
      body =
          'Estás cerca de alcanzar tu presupuesto ${budget.categoryId != null ? 'para esta categoría' : 'mensual'} (${(budget.percentageUsed * 100).toStringAsFixed(0)}%)';
    }
    
    // Enviar notificación si hay mensaje
    if (title != null && body != null) {
      _notificationService.sendBudgetNotification(budget.id, title, body);
    }
  }

  /// Resetea los gastos de todos los presupuestos al cambiar de mes
  Future<void> resetMonthlyBudgets(String userId) async {
    try {
      final previousMonth = DateFormat(
        'yyyy-MM',
      ).format(DateTime.now().subtract(const Duration(days: 31)));

      // Obtener presupuestos del mes anterior
      final lastMonthBudgets =
          await _firestore
              .collection('budgets')
              .where('userId', isEqualTo: userId)
              .where('month', isEqualTo: previousMonth)
              .where('isEnabled', isEqualTo: true)
              .get();

      // Crear nuevos presupuestos para el mes actual
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      final batch = _firestore.batch();

      for (final doc in lastMonthBudgets.docs) {
        final oldBudget = Budget.fromMap(doc.data(), doc.id);

        // Crear un nuevo documento para el mes actual
        final newDocRef = _firestore.collection('budgets').doc();

        batch.set(newDocRef, {
          'userId': oldBudget.userId,
          'amount': oldBudget.amount,
          'categoryId': oldBudget.categoryId,
          'month': currentMonth,
          'currentSpent': 0.0, // Resetear gasto actual
          'isEnabled': true,
          'notifyWhenClose': oldBudget.notifyWhenClose,
          'notifyWhenReached': oldBudget.notifyWhenReached,
          'notifyWhenExceeded': oldBudget.notifyWhenExceeded,
          'notificationThreshold': oldBudget.notificationThreshold,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error al resetear presupuestos mensuales: $e');
    }
  }
  
  // Limpiar el registro de presupuestos procesados
  void clearProcessedBudgets() {
    _lastProcessedBudgets.clear();
  }

  /// Verifica y muestra notificaciones según el estado de los presupuestos
void checkBudgetNotifications(List<Budget> budgets, BuildContext context) {
  for (final budget in budgets) {
    // Solo verificar si está habilitado
    if (!budget.isEnabled) continue;

    // Evaluar si corresponde enviar notificación
    _evaluateBudgetForNotification(budget);
  }
}
}