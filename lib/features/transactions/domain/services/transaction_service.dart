import 'dart:convert';
import 'package:chanchi_app/core/utils/currency_util.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/data/models/budget.dart';
import 'package:chanchi_app/data/models/category.dart';
import 'package:chanchi_app/features/home/domain/models/transaction.dart';
import 'package:chanchi_app/services/budget_service.dart';
import 'package:chanchi_app/services/category_service.dart';
import 'package:chanchi_app/services/connectivity_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionService {
  late final FirebaseFirestore _firestore;
  late final BudgetService _budgetService;
  late final ConnectivityService _connectivityService;
  late final CategoryService _categoryService;

  TransactionService({
    FirebaseFirestore? firestore,
    BudgetService? budgetService,
    ConnectivityService? connectivityService,
    CategoryService?
    categoryService, // Asegúrate de que este parámetro esté presente
  }) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _connectivityService = connectivityService ?? ConnectivityService();
    _budgetService = budgetService ?? BudgetService();
    _categoryService =
        categoryService ?? CategoryService(); // Asegúrate de inicializar esto

    _enableOfflineCapabilities();
  }

  // Habilitar funcionalidades offline de Firestore
  Future<void> _enableOfflineCapabilities() async {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Método para cargar cuentas
  Future<List<Account>> loadAccounts(String userId) async {
    try {
      final accountsSnapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('accounts')
              .get();

      return accountsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Account(
          id: doc.id,
          name: data['name'] ?? '',
          type: data['type'] ?? '',
          institution: data['institution'] ?? '',
          balance: (data['balance'] ?? 0.0).toDouble(),
          iconName: data['iconName'],
          color: data['color'],
        );
      }).toList();
    } catch (e) {
      print('Error al cargar cuentas: $e');
      return [];
    }
  }

  // Método para cargar categorías por tipo
  Future<List<Category>> getCategoriesByType(String transactionType) async {
    try {
      // Usar el servicio existente que ya definiste en el constructor
      return await _categoryService.getCategoriesByType(transactionType);
    } catch (e) {
      print('Error al cargar categorías: $e');
      return [];
    }
  }

  // Guardar una operación pendiente para sincronizar después
  Future<void> _savePendingOperation(
    String operation,
    String userId,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOpsKey = 'pending_transactions_$userId';

      // Convertir Timestamp a formato serializable
      Map<String, dynamic> serializableData = _makeSerializable(data);

      // Obtener operaciones pendientes existentes
      List<Map<String, dynamic>> pendingOps = [];
      final pendingString = prefs.getString(pendingOpsKey);

      if (pendingString != null && pendingString.isNotEmpty) {
        pendingOps = List<Map<String, dynamic>>.from(
          jsonDecode(pendingString) as List,
        );
      }

      // Agregar la nueva operación
      pendingOps.add({
        'operation': operation,
        'docId': docId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': serializableData,
      });

      // Guardar la lista actualizada
      await prefs.setString(pendingOpsKey, jsonEncode(pendingOps));
      print('Operación "$operation" guardada para sincronización posterior');
    } catch (e) {
      print('Error al guardar operación pendiente: $e');
    }
  }

  // Añadir función para convertir a formato serializable
  Map<String, dynamic> _makeSerializable(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    // Convertir Timestamp a mapa con segundos y nanosegundos
    result.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = {
          '_isTimestamp': true,
          'seconds': value.seconds,
          'nanoseconds': value.nanoseconds,
        };
      }
    });

    return result;
  }

  // Añadir función para restaurar desde formato serializable
  Map<String, dynamic> _restoreFromSerializable(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    // Restaurar Timestamp desde mapa
    result.forEach((key, value) {
      if (value is Map && value.containsKey('_isTimestamp')) {
        final seconds = value['seconds'] as int;
        final nanoseconds = value['nanoseconds'] as int;
        result[key] = Timestamp(seconds, nanoseconds);
      }
    });

    return result;
  }

  // Intentar sincronizar operaciones pendientes
  Future<void> syncPendingOperations(String userId) async {
    try {
      // Verificar conexión
      final isConnected = await _connectivityService.checkConnectivity();
      if (!isConnected) {
        print(
          'Sin conexión a internet. No se pueden sincronizar las operaciones.',
        );
        return;
      }

      // Obtener operaciones pendientes
      final prefs = await SharedPreferences.getInstance();
      final pendingOpsKey = 'pending_transactions_$userId';
      final pendingString = prefs.getString(pendingOpsKey);

      if (pendingString == null || pendingString.isEmpty) {
        print('No hay operaciones pendientes para sincronizar.');
        return;
      }

      // Decodificar las operaciones pendientes
      final pendingOps = List<Map<String, dynamic>>.from(
        jsonDecode(pendingString) as List,
      );

      // Ordenar por timestamp
      pendingOps.sort(
        (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int),
      );

      // Para rastrear los IDs temporales y sus equivalentes en Firestore
      Map<String, String> tempToFirestoreIdMap = {};

      // Operaciones procesadas correctamente
      final processedOps = <Map<String, dynamic>>[];

      // Procesar cada operación
      for (final op in pendingOps) {
        try {
          final operation = op['operation'] as String;
          String docId = op['docId'] as String;

          // Restaurar datos serializados a su forma original
          Map<String, dynamic> data = _restoreFromSerializable(
            Map<String, dynamic>.from(op['data'] as Map),
          );

          // Si el docId es temporal pero ya tiene un equivalente en Firestore, usarlo
          if (docId.startsWith('temp_') &&
              tempToFirestoreIdMap.containsKey(docId)) {
            docId = tempToFirestoreIdMap[docId]!;
          }

          // Si es una transacción con accountId temporal, actualizarla
          if (data.containsKey('accountId') &&
              data['accountId'].toString().startsWith('temp_') &&
              tempToFirestoreIdMap.containsKey(data['accountId'])) {
            data['accountId'] = tempToFirestoreIdMap[data['accountId']]!;
          }

          switch (operation) {
            case 'trash':
              await moveToTrash(userId, docId, sync: false);
              processedOps.add(op);
              break;
            case 'restore':
              await restoreFromTrash(userId, docId, sync: false);
              processedOps.add(op);
              break;
            case 'delete':
              await deletePermanently(userId, docId, sync: false);
              processedOps.add(op);
              break;
            case 'add':
              // Si es una transacción nueva con ID temporal
              if (docId.startsWith('temp_')) {
                // Crear un nuevo documento en Firestore
                final newRef = await _firestore.collection('transactions').add({
                  ...data,
                  'userId': userId,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                  'isInTrash': false,
                });

                // Actualizar el balance de la cuenta
                await _firestore.runTransaction((transaction) async {
                  final accountRef = _firestore
                      .collection('users')
                      .doc(userId)
                      .collection('accounts')
                      .doc(data['accountId']);
                  final accountDoc = await transaction.get(accountRef);

                  if (!accountDoc.exists) {
                    throw Exception("La cuenta no existe");
                  }

                  final accountData = accountDoc.data() as Map<String, dynamic>;
                  double currentBalance =
                      (accountData['balance'] ?? 0.0).toDouble();
                  double amount = (data['amount'] ?? 0.0).toDouble();

                  // Ajustar balance según tipo
                  if (data['type'] == 'expense') {
                    currentBalance -= amount;
                  } else {
                    currentBalance += amount;
                  }

                  transaction.update(accountRef, {'balance': currentBalance});
                });

                // Guardar la relación entre ID temporal y ID real
                tempToFirestoreIdMap[docId] = newRef.id;
                print(
                  'Transacción temporal sincronizada: $docId -> ${newRef.id}',
                );
                processedOps.add(op);
              } else {
                // ID normal de Firestore - ya debería estar sincronizado
                processedOps.add(op);
              }
              break;
            case 'update':
              // Si es un ID temporal, rechazar la actualización (debería haberse manejado en 'add')
              if (docId.startsWith('temp_')) {
                processedOps.add(op);
                continue;
              }

              await _firestore.collection('transactions').doc(docId).update({
                ...data,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              processedOps.add(op);
              break;
            case 'emptyTrash':
              await emptyTrash(userId, sync: false);
              processedOps.add(op);
              break;
          }
        } catch (e) {
          print('Error al sincronizar operación: $e');
          // No agregar a processedOps para reintentar después
        }
      }

      // Eliminar operaciones procesadas
      pendingOps.removeWhere((op) => processedOps.contains(op));

      // Actualizar preferencias
      if (pendingOps.isEmpty) {
        await prefs.remove(pendingOpsKey);
        print('Todas las operaciones sincronizadas correctamente.');
      } else {
        await prefs.setString(pendingOpsKey, jsonEncode(pendingOps));
        print('Quedan ${pendingOps.length} operaciones por sincronizar.');
      }

      // Actualizar la caché local con los IDs actualizados
      await _updateLocalCacheWithRealIds(userId, tempToFirestoreIdMap);
    } catch (e) {
      print('Error durante la sincronización: $e');
    }
  }

  // Método para obtener transacciones de la caché local
  Future<List<Map<String, dynamic>>> getLocalTransactions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_transactions_$userId';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson == null || cachedJson.isEmpty) {
        return [];
      }

      // Decodificar transacciones
      final List<dynamic> rawTransactions = jsonDecode(cachedJson) as List;

      // Convertir a Lista de Mapas y restaurar los Timestamps
      return rawTransactions.map((item) {
        final transaction = Map<String, dynamic>.from(item as Map);
        return _restoreFromSerializable(transaction);
      }).toList();
    } catch (e) {
      print('Error al obtener transacciones locales: $e');
      return [];
    }
  }

  // Método para actualizar la caché local con los IDs reales después de sincronizar
  Future<void> _updateLocalCacheWithRealIds(
    String userId,
    Map<String, String> tempToRealIdMap,
  ) async {
    if (tempToRealIdMap.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_transactions_$userId';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<Map<String, dynamic>> transactions =
            List<Map<String, dynamic>>.from(jsonDecode(cachedJson) as List);

        bool hasChanges = false;

        // Actualizar IDs temporales por reales
        for (int i = 0; i < transactions.length; i++) {
          final String id = transactions[i]['id'];

          if (tempToRealIdMap.containsKey(id)) {
            transactions[i]['id'] = tempToRealIdMap[id]!;
            hasChanges = true;
          }

          // También actualizar accountId si es necesario
          if (transactions[i].containsKey('accountId') &&
              tempToRealIdMap.containsKey(transactions[i]['accountId'])) {
            transactions[i]['accountId'] =
                tempToRealIdMap[transactions[i]['accountId']]!;
            hasChanges = true;
          }
        }

        // Guardar cambios si hubo actualizaciones
        if (hasChanges) {
          await prefs.setString(cacheKey, jsonEncode(transactions));
        }
      }
    } catch (e) {
      print('Error al actualizar caché con IDs reales: $e');
    }
  }

  // Método para agregar una transacción a la caché local
  Future<void> _addToLocalTransactionsCache(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = data['userId'];
      final cacheKey = 'cached_transactions_$userId';

      // Convertir datos a formato serializable
      final serializableData = _makeSerializable(data);

      // Obtener transacciones en caché
      List<Map<String, dynamic>> transactions = [];
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        transactions = List<Map<String, dynamic>>.from(
          jsonDecode(cachedJson) as List,
        );
      }

      // Agregar la nueva transacción con su ID
      transactions.add({
        'id': id,
        ...serializableData,
        'localTimestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Guardar cambios
      await prefs.setString(cacheKey, jsonEncode(transactions));
    } catch (e) {
      print('Error al agregar transacción a caché local: $e');
    }
  }

  // Método para actualizar una transacción en la caché local
  Future<void> _updateLocalTransactionCache(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Asumimos que userId está en data, pero también podríamos pasarlo como parámetro
      final userId = data['userId'];
      final cacheKey = 'cached_transactions_$userId';

      // Convertir datos a formato serializable
      final serializableData = _makeSerializable(data);

      // Obtener transacciones en caché
      List<Map<String, dynamic>> transactions = [];
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        transactions = List<Map<String, dynamic>>.from(
          jsonDecode(cachedJson) as List,
        );
      }

      // Buscar y actualizar la transacción
      bool found = false;
      for (int i = 0; i < transactions.length; i++) {
        if (transactions[i]['id'] == id) {
          transactions[i] = {
            'id': id,
            ...transactions[i], // Mantener datos originales
            ...serializableData, // Sobrescribir con nuevos datos
            'localTimestamp': DateTime.now().millisecondsSinceEpoch,
          };
          found = true;
          break;
        }
      }

      // Si no se encontró, agregarla como nueva
      if (!found && id.startsWith('temp_')) {
        transactions.add({
          'id': id,
          ...serializableData,
          'localTimestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Guardar cambios
      await prefs.setString(cacheKey, jsonEncode(transactions));
    } catch (e) {
      print('Error al actualizar transacción en caché local: $e');
    }
  }

  // Dentro de TransactionService, modificamos addTransaction y updateTransaction
  Future<String> addTransaction(FinancialTransaction transaction) async {
    final isConnected = await _connectivityService.checkConnectivity();

    try {
      // Primero, obtener la cuenta para determinar si es tarjeta de crédito
      final accountRef = _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('accounts')
          .doc(transaction.accountId);

      final accountDoc = await accountRef.get();
      if (!accountDoc.exists) {
        throw Exception("La cuenta no existe");
      }

      final accountData = accountDoc.data() as Map<String, dynamic>;
      final bool isCreditCard = accountData['isCreditCard'] ?? false;
      final bool includeInTotalBalance =
          accountData['includeInTotalBalance'] ?? true;

      // Verificar límite disponible para tarjetas de crédito
      if (isCreditCard && transaction.type == 'expense') {
        final double creditLimit =
            (accountData['creditLimit'] ?? 0.0).toDouble();
        final double currentBalance =
            (accountData['balance'] ?? 0.0).toDouble();
        final double availableCredit = creditLimit - currentBalance;

        if (transaction.amount > availableCredit) {
          throw Exception(
            "El monto excede el límite disponible de la tarjeta (${CurrencyUtil.format(amount: availableCredit, currencyCode: transaction.currencyCode)})",
          );
        }
      }

      if (isConnected) {
        // Modo online: Crear nueva transacción en Firestore directamente
        final docRef = _firestore.collection('transactions').doc();
        String newTransactionId = docRef.id;

        // Datos para guardar en Firestore
        final transactionData = {
          'userId': transaction.userId,
          'accountId': transaction.accountId,
          'categoryId': transaction.categoryId,
          'description': transaction.description,
          'amount': transaction.amount,
          'dateTime': Timestamp.fromDate(transaction.dateTime),
          'type': transaction.type,
          'notes': transaction.notes,
          'currencyCode': transaction.currencyCode,
          'isInTrash': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Actualizar el balance de la cuenta
        await _firestore.runTransaction((firestoreTransaction) async {
          // Obtener la cuenta
          final accountDoc = await firestoreTransaction.get(accountRef);

          if (!accountDoc.exists) {
            throw Exception("La cuenta no existe");
          }

          final accountData = accountDoc.data() as Map<String, dynamic>;
          double currentBalance = (accountData['balance'] ?? 0.0).toDouble();

          // Comportamiento especial para tarjetas de crédito
          if (isCreditCard) {
            // Para tarjetas, aumentamos el balance gastado independientemente del tipo
            // Pero, si es un ingreso, es un pago a la tarjeta (reduce el saldo)
            if (transaction.type == 'expense') {
              currentBalance +=
                  transaction.amount; // Sumar al balance de la tarjeta
            } else {
              currentBalance -=
                  transaction.amount; // Restar del balance (pagos)
            }
          } else {
            // Comportamiento normal para cuentas regulares
            if (transaction.type == 'expense') {
              currentBalance -= transaction.amount; // Restar un gasto
            } else {
              currentBalance += transaction.amount; // Sumar un ingreso
            }
          }

          // Guardar transacción y actualizar cuenta
          firestoreTransaction.set(docRef, transactionData);
          firestoreTransaction.update(accountRef, {'balance': currentBalance});
        });

        return newTransactionId;
      } else {
        // Modo offline: guardar para sincronizar después
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

        // Guardar los datos de la transacción para sincronización posterior
        final transactionData = {
          'userId': transaction.userId,
          'accountId': transaction.accountId,
          'categoryId': transaction.categoryId,
          'description': transaction.description,
          'amount': transaction.amount,
          'dateTime': Timestamp.fromDate(transaction.dateTime),
          'type': transaction.type,
          'notes': transaction.notes,
          'currencyCode': transaction.currencyCode,
          'isInTrash': false,
          'isCreditCard':
              isCreditCard, // Guardar esta info para procesamiento offline
          'includeInTotalBalance': includeInTotalBalance,
        };

        // Actualizar el balance local de la cuenta, considerando si es tarjeta de crédito
        await _updateLocalAccountBalance(
          transaction.userId,
          transaction.accountId,
          transaction.amount,
          transaction.type,
          isCreditCard: isCreditCard,
        );

        // Guardar en el almacenamiento local para sincronizar después
        await _savePendingOperation(
          'add',
          transaction.userId,
          tempId,
          transactionData,
        );

        // También agregar a la caché local para que aparezca en la UI inmediatamente
        await _addToLocalTransactionsCache(tempId, transactionData);

        return tempId;
      }
    } catch (e) {
      print('Error al agregar transacción: $e');

      // En caso de error no relacionado con validación, intentamos guardar para sincronización posterior
      if (!e.toString().contains("excede el límite")) {
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final transactionData = {
          'userId': transaction.userId,
          'accountId': transaction.accountId,
          'categoryId': transaction.categoryId,
          'description': transaction.description,
          'amount': transaction.amount,
          'dateTime': Timestamp.fromDate(transaction.dateTime),
          'type': transaction.type,
          'notes': transaction.notes,
          'currencyCode': transaction.currencyCode,
          'isInTrash': false,
        };

        try {
          // Intentar guardar localmente a pesar del error
          await _savePendingOperation(
            'add',
            transaction.userId,
            tempId,
            transactionData,
          );
          await _addToLocalTransactionsCache(tempId, transactionData);
        } catch (innerError) {
          print('Error al guardar transacción localmente: $innerError');
        }

        return tempId;
      }

      // Relanzar el error para ser manejado por el llamador
      rethrow;
    }
  }

  // También modificamos el método de actualizar el balance local de la cuenta
  Future<void> _updateLocalAccountBalance(
    String userId,
    String accountId,
    double amount,
    String transactionType, {
    bool isCreditCard = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsKey = 'cached_accounts_$userId';

      // Obtener cuentas almacenadas
      String? accountsJson = prefs.getString(accountsKey);
      List<Map<String, dynamic>> accounts = [];

      if (accountsJson != null && accountsJson.isNotEmpty) {
        accounts = List<Map<String, dynamic>>.from(
          jsonDecode(accountsJson) as List,
        );
      } else {
        // Si no hay cuentas en caché, intentar obtener desde Firestore
        try {
          final accountsSnapshot =
              await _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('accounts')
                  .get();

          accounts =
              accountsSnapshot.docs.map((doc) {
                final data = doc.data();
                return {'id': doc.id, ...data};
              }).toList();
        } catch (e) {
          print('Error al cargar cuentas desde Firestore: $e');
        }
      }

      // Encontrar y actualizar la cuenta
      bool found = false;
      for (int i = 0; i < accounts.length; i++) {
        if (accounts[i]['id'] == accountId) {
          double currentBalance = (accounts[i]['balance'] ?? 0.0).toDouble();
          bool accountIsCreditCard = accounts[i]['isCreditCard'] ?? false;

          // Verificar si la cuenta es una tarjeta de crédito (podría estar guardada en caché)
          isCreditCard = isCreditCard || accountIsCreditCard;

          if (isCreditCard) {
            // Para tarjetas de crédito
            if (transactionType == 'expense') {
              currentBalance += amount; // Sumar al saldo utilizado
            } else {
              currentBalance -= amount; // Restar del saldo (pagos)
            }
          } else {
            // Para cuentas normales
            if (transactionType == 'expense') {
              currentBalance -= amount; // Restar un gasto
            } else {
              currentBalance += amount; // Sumar un ingreso
            }
          }

          accounts[i]['balance'] = currentBalance;
          found = true;
          break;
        }
      }

      // Si encontramos y actualizamos la cuenta, guardar cambios
      if (found) {
        await prefs.setString(accountsKey, jsonEncode(accounts));
      }
    } catch (e) {
      print('Error al actualizar balance local: $e');
    }
  }

  // Agregar una nueva transacción (con soporte offline)

  // Actualizar una transacción existente (con soporte offline)
  Future<void> updateTransaction(
    FinancialTransaction transaction, {
    String? originalAccountId,
    double? originalAmount,
    String? originalType,
  }) async {
    // Si no hay datos originales, usar los que están en la transacción
    originalAccountId = originalAccountId ?? transaction.accountId;
    originalAmount = originalAmount ?? transaction.amount;
    originalType = originalType ?? transaction.type;

    // Luego continuar con la lógica existente en tu updateTransaction actual
    final isConnected = await _connectivityService.checkConnectivity();

    try {
      if (isConnected) {
        // Datos para actualizar
        final transactionData = {
          'accountId': transaction.accountId,
          'categoryId': transaction.categoryId,
          'description': transaction.description,
          'amount': transaction.amount,
          'dateTime': Timestamp.fromDate(transaction.dateTime),
          'type': transaction.type,
          'notes': transaction.notes,
          'currencyCode': transaction.currencyCode,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final transactionRef = _firestore
            .collection('transactions')
            .doc(transaction.id);

        // Si es un ID temporal, tratar como una nueva transacción
        if (transaction.id.startsWith('temp_')) {
          await addTransaction(transaction);
          return;
        }

        // Obtener la transacción original
        final transactionDoc = await transactionRef.get();

        if (!transactionDoc.exists) {
          throw Exception("La transacción no existe");
        }

        final oldData = transactionDoc.data() as Map<String, dynamic>;
        final originalAccountId = oldData['accountId'];
        final originalAmount = (oldData['amount'] ?? 0.0).toDouble();
        final originalType = oldData['type'];

        // Si cambió la cuenta o el tipo/monto, necesitamos ajustar los balances
        if (originalAccountId != transaction.accountId ||
            originalAmount != transaction.amount ||
            originalType != transaction.type) {
          await _firestore.runTransaction((firestoreTransaction) async {
            // Referencia a la cuenta original
            final originalAccountRef = _firestore
                .collection('users')
                .doc(transaction.userId)
                .collection('accounts')
                .doc(originalAccountId);

            // Referencia a la nueva cuenta (puede ser la misma)
            final newAccountRef = _firestore
                .collection('users')
                .doc(transaction.userId)
                .collection('accounts')
                .doc(transaction.accountId);

            // Obtener datos de las cuentas
            final originalAccountDoc = await firestoreTransaction.get(
              originalAccountRef,
            );

            if (!originalAccountDoc.exists) {
              throw Exception("La cuenta original no existe");
            }

            // Si es la misma cuenta, solo obtenemos una vez
            final newAccountDoc =
                originalAccountId == transaction.accountId
                    ? originalAccountDoc
                    : await firestoreTransaction.get(newAccountRef);

            if (!newAccountDoc.exists) {
              throw Exception("La nueva cuenta no existe");
            }

            // Obtener balances actuales
            final originalAccountData =
                originalAccountDoc.data() as Map<String, dynamic>;
            double originalBalance =
                (originalAccountData['balance'] ?? 0.0).toDouble();

            // Si es la misma cuenta, originalBalance = newBalance
            double newBalance =
                originalAccountId == transaction.accountId
                    ? originalBalance
                    : ((newAccountDoc.data()
                                as Map<String, dynamic>)['balance'] ??
                            0.0)
                        .toDouble();

            // 1. Revertir la transacción original en la cuenta original
            if (originalType == 'expense') {
              originalBalance += originalAmount; // Revertir un gasto
            } else {
              originalBalance -= originalAmount; // Revertir un ingreso
            }

            // 2. Aplicar la nueva transacción a la cuenta correspondiente
            if (originalAccountId == transaction.accountId) {
              // Misma cuenta, usar el balance ya modificado
              if (transaction.type == 'expense') {
                originalBalance -= transaction.amount; // Aplicar nuevo gasto
              } else {
                originalBalance += transaction.amount; // Aplicar nuevo ingreso
              }

              // Actualizar la cuenta
              firestoreTransaction.update(originalAccountRef, {
                'balance': originalBalance,
              });
            } else {
              // Cuentas diferentes
              // Actualizar cuenta original
              firestoreTransaction.update(originalAccountRef, {
                'balance': originalBalance,
              });

              // Aplicar a la nueva cuenta
              if (transaction.type == 'expense') {
                newBalance -= transaction.amount; // Aplicar nuevo gasto
              } else {
                newBalance += transaction.amount; // Aplicar nuevo ingreso
              }

              // Actualizar nueva cuenta
              firestoreTransaction.update(newAccountRef, {
                'balance': newBalance,
              });
            }

            // Actualizar la transacción
            firestoreTransaction.update(transactionRef, transactionData);
          });
        } else {
          // Si no hay cambios que afecten balances, simplemente actualizamos
          await transactionRef.update(transactionData);
        }
      } else {
        // Modo offline: guardar para sincronizar después
        final transactionData = {
          'accountId': transaction.accountId,
          'categoryId': transaction.categoryId,
          'description': transaction.description,
          'amount': transaction.amount,
          'dateTime': Timestamp.fromDate(transaction.dateTime),
          'type': transaction.type,
          'notes': transaction.notes,
          'currencyCode': transaction.currencyCode,
        };

        // Si es un ID temporal, solo actualizamos la caché local
        if (transaction.id.startsWith('temp_')) {
          await _updateLocalTransactionCache(transaction.id, transactionData);
        } else {
          // Para transacciones reales, guardamos para sincronizar
          await _savePendingOperation(
            'update',
            transaction.userId,
            transaction.id,
            transactionData,
          );
          await _updateLocalTransactionCache(transaction.id, transactionData);
        }
      }
    } catch (e) {
      print('Error al actualizar transacción: $e');
      // Si ocurre un error, guardar para sincronizar después
      final transactionData = {
        'accountId': transaction.accountId,
        'categoryId': transaction.categoryId,
        'description': transaction.description,
        'amount': transaction.amount,
        'dateTime': Timestamp.fromDate(transaction.dateTime),
        'type': transaction.type,
        'notes': transaction.notes,
        'currencyCode': transaction.currencyCode,
      };

      await _savePendingOperation(
        'update',
        transaction.userId,
        transaction.id,
        transactionData,
      );
      await _updateLocalTransactionCache(transaction.id, transactionData);
    }
  }

  // Método para actualizar el estado de papelera de una transacción localmente
  Future<void> _updateLocalTransactionTrashStatus(
    String userId,
    String transactionId,
    bool isInTrash,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_transactions_$userId';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> rawList = jsonDecode(cachedJson) as List;
        List<Map<String, dynamic>> transactions = [];
        bool found = false;

        for (var item in rawList) {
          Map<String, dynamic> transaction = Map<String, dynamic>.from(item);
          if (transaction['id'] == transactionId) {
            transaction['isInTrash'] = isInTrash;
            found = true;
          }
          transactions.add(transaction);
        }

        if (found) {
          // Guardar las transacciones actualizadas
          await prefs.setString(cacheKey, jsonEncode(transactions));
          print(
            'Estado de papelera de transacción $transactionId actualizado localmente: $isInTrash',
          );
        }
      }
    } catch (e) {
      print('Error al actualizar estado de papelera localmente: $e');
    }
  }

  // Corrección para el método moveToTrash
  Future<void> moveToTrash(
    String userId,
    String transactionId, {
    bool sync = true,
  }) async {
    final isConnected = await _connectivityService.checkConnectivity();

    try {
      if (isConnected) {
        final transactionRef = _firestore
            .collection('transactions')
            .doc(transactionId);

        await _firestore.runTransaction((transaction) async {
          // PRIMER PASO: TODAS LAS LECTURAS

          // 1. Leer la transacción
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
          final categoryId = transactionData['categoryId'] ?? '';
          final isCreditCardPayment = categoryId == 'credit_card_payment';
          final fromAccountId = transactionData['fromAccountId'];
          final amount = (transactionData['amount'] ?? 0.0).toDouble();
          final transactionType = transactionData['type'] ?? 'expense';

          // 2. Leer la cuenta principal
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
          final isCreditCard = accountData['isCreditCard'] ?? false;
          double currentBalance = (accountData['balance'] ?? 0.0).toDouble();

          // 3. Si es un pago de tarjeta, leer también la cuenta de origen
          Map<String, dynamic>? fromAccountData;
          DocumentSnapshot? fromAccountDoc;
          double? fromAccountBalance;

          if (isCreditCardPayment && fromAccountId != null) {
            final fromAccountRef = _firestore
                .collection('users')
                .doc(userId)
                .collection('accounts')
                .doc(fromAccountId);

            fromAccountDoc = await transaction.get(fromAccountRef);

            if (!fromAccountDoc.exists) {
              throw Exception("La cuenta de origen no existe");
            }

            fromAccountData = fromAccountDoc.data() as Map<String, dynamic>;
            // Inicializar fromAccountBalance como no-nulo
            fromAccountBalance = (fromAccountData['balance'] ?? 0.0).toDouble();
          }

          // SEGUNDO PASO: PROCESAR LA LÓGICA

          // Calcular nuevo balance para la cuenta principal
          if (isCreditCard) {
            if (transactionType == 'expense') {
              currentBalance = currentBalance - amount; // Revertir un gasto
            } else {
              currentBalance = currentBalance + amount; // Revertir un pago
            }
          } else {
            if (transactionType == 'expense') {
              currentBalance = currentBalance + amount; // Revertir un gasto
            } else {
              currentBalance = currentBalance - amount; // Revertir un ingreso
            }
          }

          // Calcular nuevo balance para la cuenta de origen si aplica
          if (fromAccountBalance != null) {
            // Usar operador null-safe
            fromAccountBalance =
                fromAccountBalance +
                amount; // Devolver el monto a la cuenta de origen
          }

          // TERCER PASO: TODAS LAS ESCRITURAS

          // 1. Actualizar la transacción
          transaction.update(transactionRef, {
            'isInTrash': true,
            'trashedAt': FieldValue.serverTimestamp(),
          });

          // 2. Actualizar la cuenta principal
          transaction.update(accountRef, {'balance': currentBalance});

          // 3. Actualizar la cuenta de origen si aplica
          if (fromAccountDoc != null && fromAccountBalance != null) {
            transaction.update(fromAccountDoc.reference, {
              'balance': fromAccountBalance,
            });
          }
        });

        // Actualizar presupuestos después de mover a papelera (si es gasto)
        final transactionDoc = await transactionRef.get();
        if (transactionDoc.exists) {
          final transactionData = transactionDoc.data() as Map<String, dynamic>;
          final categoryId = transactionData['categoryId'] ?? '';

          // No actualizar presupuestos si es un pago de tarjeta de crédito
          if (categoryId != 'credit_card_payment' &&
              transactionData['type'] == 'expense') {
            final amount = (transactionData['amount'] ?? 0.0).toDouble();
            final dateTime =
                (transactionData['dateTime'] as Timestamp).toDate();

            // Quitar el gasto del presupuesto (isAddition = false)
            await _budgetService.updateBudgetsForTransaction(
              userId,
              amount,
              categoryId,
              dateTime,
              false,
            );
          }
        }
      } else {
        print(
          'Modo offline: Guardando operación para sincronización posterior',
        );
        // Actualizar la caché local para reflejar el cambio inmediatamente
        await _updateLocalTransactionTrashStatus(userId, transactionId, true);

        // Guardar para sincronización posterior
        if (sync) {
          await _savePendingOperation('trash', userId, transactionId, {});
          print('Operación "trash" guardada para sincronización posterior');
        }
      }
    } catch (e) {
      print('Error al mover a papelera: $e');
      // Si ocurre un error, actualizar la caché local para reflejar el cambio inmediatamente
      await _updateLocalTransactionTrashStatus(userId, transactionId, true);

      // Y guardar para sincronización posterior
      if (sync) {
        await _savePendingOperation('trash', userId, transactionId, {});
        print('Operación "trash" guardada para sincronización posterior');
      }
      rethrow;
    }
  }

  // Corrección para el método deletePermanently
  Future<void> deletePermanently(
    String userId,
    String transactionId, {
    bool sync = true,
  }) async {
    final isConnected = _connectivityService.isConnected;

    try {
      final transactionRef = _firestore
          .collection('transactions')
          .doc(transactionId);

      if (isConnected) {
        // Obtener datos de la transacción antes de eliminarla para actualizar presupuestos
        final transactionDoc = await transactionRef.get();
        if (!transactionDoc.exists) {
          throw Exception("La transacción no existe");
        }

        final transactionData = transactionDoc.data() as Map<String, dynamic>;
        final isInTrash = transactionData['isInTrash'] == true;
        final isExpense = transactionData['type'] == 'expense';
        final amount = (transactionData['amount'] ?? 0.0).toDouble();
        final categoryId = transactionData['categoryId'] ?? '';
        final dateTime = (transactionData['dateTime'] as Timestamp).toDate();
        final isCreditCardPayment = categoryId == 'credit_card_payment';
        final fromAccountId = transactionData['fromAccountId'];

        await _firestore.runTransaction((transaction) async {
          // PRIMER PASO: TODAS LAS LECTURAS

          // 1. Leer la transacción (ya la tenemos de antes, pero por claridad la volvemos a leer)
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

            // 2. Leer la cuenta principal
            final accountDoc = await transaction.get(accountRef);

            if (!accountDoc.exists) {
              throw Exception("La cuenta no existe");
            }

            final accountData = accountDoc.data() as Map<String, dynamic>;
            double currentBalance = (accountData['balance'] ?? 0.0).toDouble();
            double amount = (transactionData['amount'] ?? 0.0).toDouble();
            String transactionType = transactionData['type'] ?? 'expense';

            // CALCULAR NUEVO BALANCE

            // Ajustar balance según tipo de transacción
            if (transactionType == 'expense') {
              currentBalance = currentBalance + amount; // Revertir un gasto
            } else {
              currentBalance = currentBalance - amount; // Revertir un ingreso
            }

            // 3. Leer la cuenta de origen si es un pago de tarjeta
            DocumentSnapshot? fromAccountDoc;
            double? fromAccountBalance;

            if (isCreditCardPayment && fromAccountId != null) {
              final fromAccountRef = _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('accounts')
                  .doc(fromAccountId);

              fromAccountDoc = await transaction.get(fromAccountRef);

              if (fromAccountDoc.exists) {
                final fromAccountData =
                    fromAccountDoc.data() as Map<String, dynamic>;
                // Usar una variable no-nula para el cálculo
                final double currentFromBalance =
                    (fromAccountData['balance'] ?? 0.0).toDouble();

                // Asignar directamente a una variable potencialmente nula
                fromAccountBalance = currentFromBalance + amount;
              }
            }

            // SEGUNDO PASO: TODAS LAS ESCRITURAS

            // 1. Actualizar el balance de la cuenta principal
            transaction.update(accountRef, {'balance': currentBalance});

            // 2. Actualizar la cuenta de origen si aplica
            if (fromAccountDoc != null && fromAccountBalance != null) {
              transaction.update(fromAccountDoc.reference, {
                'balance': fromAccountBalance,
              });
            }
          }

          // 3. Eliminar la transacción
          transaction.delete(transactionRef);
        });

        // Actualizar presupuestos si es necesario
        // Solo si es un gasto y no está en papelera (si está en papelera, ya se actualizaron los presupuestos)
        if (isExpense && !isInTrash && !isCreditCardPayment) {
          await _budgetService.updateBudgetsForTransaction(
            userId,
            amount,
            categoryId,
            dateTime,
            false, // quitar
          );
        }
      } else {
        // Sin conexión, guardar para sincronizar después
        if (sync) {
          await _savePendingOperation('delete', userId, transactionId, {});
        }
      }
    } catch (e) {
      print('Error al eliminar permanentemente: $e');
      // Si ocurre un error, guardar para sincronizar después
      if (sync) {
        await _savePendingOperation('delete', userId, transactionId, {});
      }
      rethrow;
    }
  }

  Future<void> restoreFromTrash(
    String userId,
    String transactionId, {
    bool sync = true,
  }) async {
    final isConnected = _connectivityService.isConnected;

    try {
      final transactionRef = _firestore
          .collection('transactions')
          .doc(transactionId);

      if (isConnected) {
        await _firestore.runTransaction((transaction) async {
          // PRIMER PASO: TODAS LAS LECTURAS

          // 1. Leer la transacción
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
          final transactionType = transactionData['type'] ?? 'expense';
          final amount = (transactionData['amount'] ?? 0.0).toDouble();
          final categoryId = transactionData['categoryId'] ?? '';
          final isCreditCardPayment = categoryId == 'credit_card_payment';
          final fromAccountId = transactionData['fromAccountId'];

          // 2. Leer la cuenta principal
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
          final isCreditCard = accountData['isCreditCard'] ?? false;

          // 3. Leer la cuenta de origen si es un pago de tarjeta
          DocumentSnapshot? fromAccountDoc;
          double? fromAccountBalance;

          if (isCreditCardPayment && fromAccountId != null) {
            final fromAccountRef = _firestore
                .collection('users')
                .doc(userId)
                .collection('accounts')
                .doc(fromAccountId);

            fromAccountDoc = await transaction.get(fromAccountRef);

            if (fromAccountDoc.exists) {
              final fromAccountData =
                  fromAccountDoc.data() as Map<String, dynamic>;
              // Asegurar que no sea nulo usando un valor predeterminado
              final double currentFromBalance =
                  (fromAccountData['balance'] ?? 0.0).toDouble();
              // Asignar a variable potencialmente nula
              fromAccountBalance = currentFromBalance;
            }
          }

          // SEGUNDO PASO: CALCULAR NUEVOS BALANCES

          // Ajustar balance según tipo de cuenta y transacción
          if (isCreditCard) {
            if (transactionType == 'expense') {
              currentBalance = currentBalance + amount; // Restaurar el gasto
            } else {
              currentBalance = currentBalance - amount; // Restaurar el pago
            }
          } else {
            // Comportamiento normal para cuentas regulares
            if (transactionType == 'expense') {
              currentBalance = currentBalance - amount; // Aplicar un gasto
            } else {
              currentBalance = currentBalance + amount; // Aplicar un ingreso
            }
          }

          // Si es un pago de tarjeta, reducir balance de la cuenta de origen
          if (fromAccountBalance != null) {
            // Usar operador seguro para valores null
            fromAccountBalance = fromAccountBalance - amount;
          }

          // TERCER PASO: TODAS LAS ESCRITURAS

          // 1. Actualizar la transacción
          transaction.update(transactionRef, {
            'isInTrash': false,
            'trashedAt': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // 2. Actualizar balance de la cuenta principal
          transaction.update(accountRef, {'balance': currentBalance});

          // 3. Actualizar balance de la cuenta de origen si aplica
          if (fromAccountDoc != null && fromAccountBalance != null) {
            transaction.update(fromAccountDoc.reference, {
              'balance': fromAccountBalance,
            });
          }
        });

        // Actualizar presupuestos después de restaurar (si es gasto)
        final transactionDoc = await transactionRef.get();
        if (transactionDoc.exists) {
          final transactionData = transactionDoc.data() as Map<String, dynamic>;
          final categoryId = transactionData['categoryId'] ?? '';

          if (transactionData['type'] == 'expense' &&
              categoryId != 'credit_card_payment') {
            final amount = (transactionData['amount'] ?? 0.0).toDouble();
            final dateTime =
                (transactionData['dateTime'] as Timestamp).toDate();

            // Añadir el gasto al presupuesto (isAddition = true)
            await _budgetService.updateBudgetsForTransaction(
              userId,
              amount,
              categoryId,
              dateTime,
              true,
            );
          }
        }
      } else {
        // Sin conexión, guardar para sincronizar después
        if (sync) {
          await _savePendingOperation('restore', userId, transactionId, {});
        }
      }
    } catch (e) {
      print('Error al restaurar de papelera: $e');
      // Si ocurre un error, guardar para sincronizar después
      if (sync) {
        await _savePendingOperation('restore', userId, transactionId, {});
      }
      rethrow;
    }
  }

  // Duplicar una transacción
  Future<String> duplicateTransaction(
    String userId,
    Map<String, dynamic> originalTransaction,
  ) async {
    final isConnected = _connectivityService.isConnected;

    try {
      // Datos para la nueva transacción
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

      String newTransactionId;

      if (isConnected) {
        // Crear la transacción duplicada en Firestore
        final newTransactionRef = _firestore.collection('transactions').doc();
        await newTransactionRef.set(newTransactionData);
        newTransactionId = newTransactionRef.id;
      } else {
        // Generar un ID temporal para la transacción
        newTransactionId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        // Guardar para sincronizar después
        await _savePendingOperation(
          'add',
          userId,
          newTransactionId,
          newTransactionData,
        );
      }

      return newTransactionId;
    } catch (e) {
      print('Error al duplicar la transacción: $e');
      throw Exception("Error al duplicar la transacción: $e");
    }
  }

  // Método para actualizar presupuestos cuando se crea una nueva transacción
  Future<void> updateBudgetsForNewTransaction(
    BuildContext context,
    String userId,
    Map<String, dynamic> transactionData,
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
          true, // Añadir
        );

        // Obtener presupuestos actuales para mostrar notificaciones
        final isConnected = _connectivityService.isConnected;
        if (isConnected) {
          final String currentMonth = DateFormat('yyyy-MM').format(dateTime);
          final budgets =
              await _firestore
                  .collection('budgets')
                  .where('userId', isEqualTo: userId)
                  .where('month', isEqualTo: currentMonth)
                  .where('isEnabled', isEqualTo: true)
                  .get();

          final budgetList =
              budgets.docs
                  .map((doc) => Budget.fromMap(doc.data(), doc.id))
                  .toList();

          if (budgetList.isNotEmpty && context.mounted) {
            _budgetService.checkBudgetNotifications(budgetList, context);
          }
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
    bool isAddition, // true: añadir, false: quitar
  ) async {
    try {
      await _budgetService.updateBudgetsForTransaction(
        userId,
        amount,
        categoryId,
        transactionDate,
        isAddition,
      );
    } catch (e) {
      print('Error al actualizar presupuestos para transacción: $e');
    }
  }

  // Vaciar completamente la papelera de un usuario
  Future<void> emptyTrash(String userId, {bool sync = true}) async {
    final isConnected = _connectivityService.isConnected;

    try {
      if (isConnected) {
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
      } else {
        // Sin conexión, guardar para sincronizar después
        if (sync) {
          await _savePendingOperation('emptyTrash', userId, '', {});
        }
      }
    } catch (e) {
      print('Error al vaciar la papelera: $e');
      // Si ocurre un error, guardar para sincronizar después
      if (sync) {
        await _savePendingOperation('emptyTrash', userId, '', {});
      }
      throw Exception("Error al vaciar la papelera: $e");
    }
  }

  // Verificar si hay transacciones pendientes
  Future<bool> hasPendingOperations(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOpsKey = 'pending_transactions_$userId';
      final pendingString = prefs.getString(pendingOpsKey);

      return pendingString != null && pendingString.isNotEmpty;
    } catch (e) {
      print('Error al verificar operaciones pendientes: $e');
      return false;
    }
  }

  // Obtener el número de operaciones pendientes
  Future<int> getPendingOperationsCount(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOpsKey = 'pending_transactions_$userId';
      final pendingString = prefs.getString(pendingOpsKey);

      if (pendingString == null || pendingString.isEmpty) {
        return 0;
      }

      final pendingOps = List<Map<String, dynamic>>.from(
        jsonDecode(pendingString) as List,
      );

      return pendingOps.length;
    } catch (e) {
      print('Error al contar operaciones pendientes: $e');
      return 0;
    }
  }
}
