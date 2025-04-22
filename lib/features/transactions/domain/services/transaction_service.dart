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

  // Method to validate if a transaction can be performed based on available balance
  Future<bool> validateTransactionAmount(
    String userId,
    String accountId,
    double amount,
    String transactionType,
  ) async {
    try {
      // For income transactions, we always return true (no validation needed)
      if (transactionType == 'income') {
        return true;
      }

      // Get the account
      final accountDoc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('accounts')
              .doc(accountId)
              .get();

      if (!accountDoc.exists) {
        throw Exception("La cuenta no existe");
      }

      final accountData = accountDoc.data() as Map<String, dynamic>;
      final bool isCreditCard = accountData['isCreditCard'] ?? false;
      final double currentBalance = (accountData['balance'] ?? 0.0).toDouble();

      // Check if transaction is valid based on account type
      if (isCreditCard) {
        // For credit cards, check against the available credit limit
        final double creditLimit =
            (accountData['creditLimit'] ?? 0.0).toDouble();
        final double availableCredit = creditLimit - currentBalance;

        return amount <= availableCredit;
      } else {
        // For regular accounts, check against the current balance
        return amount <= currentBalance;
      }
    } catch (e) {
      print('Error validating transaction amount: $e');
      return false;
    }
  }

  // Method to get validation error message (returns null if valid)
  Future<String?> getTransactionValidationError(
    String userId,
    String accountId,
    double amount,
    String transactionType,
    String currencyCode,
  ) async {
    try {
      // Las transacciones de ingreso siempre son válidas
      if (transactionType == 'income') {
        return null;
      }

      // Si no hay un userId o accountId válido, no validamos (evitamos errores)
      if (userId.isEmpty || accountId.isEmpty) {
        return null;
      }

      // Verificar si la cuenta existe
      final accountDoc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('accounts')
              .doc(accountId)
              .get();

      if (!accountDoc.exists) {
        return "La cuenta seleccionada no existe";
      }

      final accountData = accountDoc.data() as Map<String, dynamic>;
      if (accountData == null) {
        return null; // Si no hay datos, no podemos validar pero tampoco bloqueamos
      }

      final bool isCreditCard = accountData['isCreditCard'] ?? false;
      final double currentBalance = (accountData['balance'] ?? 0.0).toDouble();
      final String accountName = accountData['name'] ?? 'Cuenta';

      // Validación para tarjetas de crédito
      if (isCreditCard) {
        // Solo validamos si hay límite definido
        if (accountData.containsKey('creditLimit')) {
          final double creditLimit =
              (accountData['creditLimit'] ?? 0.0).toDouble();
          final double availableCredit = creditLimit - currentBalance;

          if (amount > availableCredit) {
            return "El monto excede el límite disponible de la tarjeta (${CurrencyUtil.format(amount: availableCredit, currencyCode: currencyCode)})";
          }
        }
      }
      // Validación para cuentas normales
      else {
        if (amount > currentBalance) {
          return "El monto excede el saldo disponible en $accountName (${CurrencyUtil.format(amount: currentBalance, currencyCode: currencyCode)})";
        }
      }

      return null; // No hay error, la transacción es válida
    } catch (e) {
      print('Error en validación de transacción: $e');
      // En caso de error, permitimos que la operación continúe
      // pero registramos el error para depuración
      return null;
    }
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

  Future<String> addTransaction(FinancialTransaction transaction) async {
    final isConnected = await _connectivityService.checkConnectivity();

    try {
      // Validar el monto de la transacción solo para gastos
      if (transaction.type == 'expense') {
        try {
          final String? validationError = await getTransactionValidationError(
            transaction.userId,
            transaction.accountId,
            transaction.amount,
            transaction.type,
            transaction.currencyCode,
          );

          if (validationError != null) {
            throw Exception(validationError);
          }
        } catch (validationError) {
          print('Error en validación: $validationError');
          // Si la validación falla, continuamos pero registramos el error
        }
      }

      // Obtener referencia a la cuenta
      final accountRef = _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('accounts')
          .doc(transaction.accountId);

      // Obtener datos de la cuenta
      DocumentSnapshot? accountDoc;
      try {
        accountDoc = await accountRef.get();
      } catch (e) {
        print('Error al obtener cuenta: $e');
      }

      // Si la cuenta no existe, continuamos pero registramos el error
      if (accountDoc == null || !accountDoc.exists) {
        print('Cuenta no encontrada: ${transaction.accountId}');
      }

      // Datos predeterminados de la cuenta si no se puede acceder
      bool isCreditCard = false;
      bool includeInTotalBalance = true;

      // Si tenemos datos de la cuenta, los utilizamos
      if (accountDoc != null && accountDoc.exists) {
        final accountData = accountDoc.data() as Map<String, dynamic>?;
        if (accountData != null) {
          isCreditCard = accountData['isCreditCard'] ?? false;
          includeInTotalBalance = accountData['includeInTotalBalance'] ?? true;
        }
      }

      if (isConnected) {
        // Modo online: crear transacción directamente en Firestore
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

        try {
          // Actualizar el balance de la cuenta en una transacción
          await _firestore.runTransaction((firestoreTransaction) async {
            // Si la cuenta no existe, no actualizamos su balance
            if (accountDoc == null || !accountDoc.exists) {
              firestoreTransaction.set(docRef, transactionData);
              return;
            }

            final accountData = accountDoc.data() as Map<String, dynamic>;
            double currentBalance = (accountData['balance'] ?? 0.0).toDouble();

            // Comportamiento especial para tarjetas de crédito
            if (isCreditCard) {
              if (transaction.type == 'expense') {
                currentBalance +=
                    transaction.amount; // Sumar al saldo de la tarjeta
              } else {
                currentBalance -=
                    transaction.amount; // Restar del saldo (pagos)
              }
            } else {
              if (transaction.type == 'expense') {
                currentBalance -= transaction.amount; // Restar un gasto
              } else {
                currentBalance += transaction.amount; // Sumar un ingreso
              }
            }

            // Guardar transacción y actualizar cuenta
            firestoreTransaction.set(docRef, transactionData);
            firestoreTransaction.update(accountRef, {
              'balance': currentBalance,
            });
          });
        } catch (transactionError) {
          // Si falla la transacción, al menos intentamos guardar la transacción
          print('Error en transacción Firestore: $transactionError');
          await docRef.set(transactionData);
        }

        return newTransactionId;
      } else {
        // Modo offline: guardar para sincronizar después
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

        // Guardar datos de transacción para sincronización posterior
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
          'isCreditCard': isCreditCard,
          'includeInTotalBalance': includeInTotalBalance,
        };

        // Actualizar balance local de la cuenta
        try {
          await _updateLocalAccountBalance(
            transaction.userId,
            transaction.accountId,
            transaction.amount,
            transaction.type,
            isCreditCard: isCreditCard,
          );
        } catch (e) {
          print('Error al actualizar balance local: $e');
        }

        // Guardar para sincronización posterior
        try {
          await _savePendingOperation(
            'add',
            transaction.userId,
            tempId,
            transactionData,
          );
          await _addToLocalTransactionsCache(tempId, transactionData);
        } catch (e) {
          print('Error al guardar para sincronización: $e');
        }

        return tempId;
      }
    } catch (e) {
      print('Error al agregar transacción: $e');

      // Para errores no relacionados con validación, intentar guardar para sincronización posterior
      if (!e.toString().contains("excede")) {
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

      // Relanzar error para ser manejado por el llamador
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

  // Actualizar una transacción existente (con soporte offline)
  Future<void> updateTransaction(
    FinancialTransaction transaction, {
    String? originalAccountId,
    double? originalAmount,
    String? originalType,
  }) async {
    // If no original data provided, use current transaction data
    originalAccountId = originalAccountId ?? transaction.accountId;
    originalAmount = originalAmount ?? transaction.amount;
    originalType = originalType ?? transaction.type;

    final isConnected = await _connectivityService.checkConnectivity();

    try {
      // Validate transaction amount if:
      // 1. Transaction type changed from income to expense, or
      // 2. Expense amount increased, or
      // 3. Account changed for an expense
      if ((transaction.type == 'expense' && originalType == 'income') ||
          (transaction.type == 'expense' &&
              transaction.amount > (originalAmount ?? 0) &&
              transaction.accountId == originalAccountId) ||
          (transaction.type == 'expense' &&
              transaction.accountId != originalAccountId)) {
        final String? validationError = await getTransactionValidationError(
          transaction.userId,
          transaction.accountId,
          transaction.amount,
          transaction.type,
          transaction.currencyCode,
        );

        if (validationError != null) {
          throw Exception(validationError);
        }
      }

      if (isConnected) {
        // Data to update
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

        // If temporary ID, treat as new transaction
        if (transaction.id.startsWith('temp_')) {
          await addTransaction(transaction);
          return;
        }

        // Fetch original transaction
        final transactionDoc = await transactionRef.get();

        if (!transactionDoc.exists) {
          throw Exception("La transacción no existe");
        }

        final oldData = transactionDoc.data() as Map<String, dynamic>;
        final originalAccountId = oldData['accountId'];
        final originalAmount = (oldData['amount'] ?? 0.0).toDouble();
        final originalType = oldData['type'];

        // If account, amount or type changed, adjust balances
        if (originalAccountId != transaction.accountId ||
            originalAmount != transaction.amount ||
            originalType != transaction.type) {
          await _firestore.runTransaction((firestoreTransaction) async {
            // Reference to original account
            final originalAccountRef = _firestore
                .collection('users')
                .doc(transaction.userId)
                .collection('accounts')
                .doc(originalAccountId);

            // Reference to new account (might be the same)
            final newAccountRef = _firestore
                .collection('users')
                .doc(transaction.userId)
                .collection('accounts')
                .doc(transaction.accountId);

            // Get account data
            final originalAccountDoc = await firestoreTransaction.get(
              originalAccountRef,
            );

            if (!originalAccountDoc.exists) {
              throw Exception("La cuenta original no existe");
            }

            // If same account, only fetch once
            final newAccountDoc =
                originalAccountId == transaction.accountId
                    ? originalAccountDoc
                    : await firestoreTransaction.get(newAccountRef);

            if (!newAccountDoc.exists) {
              throw Exception("La nueva cuenta no existe");
            }

            // Get current balances
            final originalAccountData =
                originalAccountDoc.data() as Map<String, dynamic>;
            final bool originalIsCreditCard =
                originalAccountData['isCreditCard'] ?? false;
            double originalBalance =
                (originalAccountData['balance'] ?? 0.0).toDouble();

            // If same account, originalBalance = newBalance
            final newAccountData = newAccountDoc.data() as Map<String, dynamic>;
            final bool newIsCreditCard =
                newAccountData['isCreditCard'] ?? false;
            double newBalance =
                originalAccountId == transaction.accountId
                    ? originalBalance
                    : (newAccountData['balance'] ?? 0.0).toDouble();

            // 1. Revert original transaction from original account
            if (originalIsCreditCard) {
              if (originalType == 'expense') {
                originalBalance -=
                    originalAmount; // Reverse expense on credit card
              } else {
                originalBalance +=
                    originalAmount; // Reverse payment on credit card
              }
            } else {
              if (originalType == 'expense') {
                originalBalance += originalAmount; // Reverse expense
              } else {
                originalBalance -= originalAmount; // Reverse income
              }
            }

            // 2. Apply new transaction to appropriate account
            if (originalAccountId == transaction.accountId) {
              // Same account, use already modified balance
              if (newIsCreditCard) {
                if (transaction.type == 'expense') {
                  originalBalance +=
                      transaction.amount; // Apply expense to credit card
                } else {
                  originalBalance -=
                      transaction.amount; // Apply payment to credit card
                }
              } else {
                if (transaction.type == 'expense') {
                  originalBalance -= transaction.amount; // Apply expense
                } else {
                  originalBalance += transaction.amount; // Apply income
                }
              }

              // Update account
              firestoreTransaction.update(originalAccountRef, {
                'balance': originalBalance,
              });
            } else {
              // Different accounts
              // Update original account
              firestoreTransaction.update(originalAccountRef, {
                'balance': originalBalance,
              });

              // Apply to new account
              if (newIsCreditCard) {
                if (transaction.type == 'expense') {
                  newBalance +=
                      transaction.amount; // Apply expense to credit card
                } else {
                  newBalance -=
                      transaction.amount; // Apply payment to credit card
                }
              } else {
                if (transaction.type == 'expense') {
                  newBalance -= transaction.amount; // Apply expense
                } else {
                  newBalance += transaction.amount; // Apply income
                }
              }

              // Update new account
              firestoreTransaction.update(newAccountRef, {
                'balance': newBalance,
              });
            }

            // Update transaction
            firestoreTransaction.update(transactionRef, transactionData);
          });
        } else {
          // If no changes affecting balances, just update
          await transactionRef.update(transactionData);
        }
      } else {
        // Offline mode: store for later sync
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

        // If temporary ID, just update local cache
        if (transaction.id.startsWith('temp_')) {
          await _updateLocalTransactionCache(transaction.id, transactionData);
        } else {
          // For real transactions, save for sync
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
      // If error occurs, try to save for later sync
      if (!e.toString().contains("excede")) {
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

      // Re-throw to be handled by caller
      rethrow;
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

  Future<String> duplicateTransaction(
    String userId,
    Map<String, dynamic> originalTransaction,
  ) async {
    final isConnected = await _connectivityService.checkConnectivity();

    try {
      // Datos para la nueva transacción
      final Map<String, dynamic> newTransactionData = {
        ...Map<String, dynamic>.from(
          originalTransaction,
        ), // Mantener datos originales
        'dateTime': Timestamp.fromDate(DateTime.now()), // Actualizar fecha
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isInTrash': false,
        'userId': userId, // Asegurar que esté incluido
      };

      // Eliminar campos que no deben copiarse o que serán actualizados
      newTransactionData.remove('trashedAt');
      newTransactionData.remove('id'); // Remover ID original si existe

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

        // También añadir a la caché local
        await _addToLocalTransactionsCache(
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

  // Método para mover a papelera todas las transacciones de una cuenta
  Future<void> moveAccountTransactionsToTrash(
    String userId,
    String accountId,
  ) async {
    try {
      final isConnected = await _connectivityService.checkConnectivity();

      if (isConnected) {
        // Obtener todas las transacciones activas de esta cuenta
        final transactions =
            await _firestore
                .collection('transactions')
                .where('userId', isEqualTo: userId)
                .where('accountId', isEqualTo: accountId)
                .where('isInTrash', isNotEqualTo: true)
                .get();

        // También las transacciones donde esta cuenta es la cuenta de origen
        final fromAccountTransactions =
            await _firestore
                .collection('transactions')
                .where('userId', isEqualTo: userId)
                .where('fromAccountId', isEqualTo: accountId)
                .where('isInTrash', isNotEqualTo: true)
                .get();

        // Usar batch para mover todas a papelera
        final batch = _firestore.batch();
        final now = FieldValue.serverTimestamp();

        for (var doc in transactions.docs) {
          batch.update(doc.reference, {'isInTrash': true, 'trashedAt': now});
        }

        for (var doc in fromAccountTransactions.docs) {
          batch.update(doc.reference, {'isInTrash': true, 'trashedAt': now});
        }

        // Ejecutar el batch
        if (transactions.docs.isNotEmpty ||
            fromAccountTransactions.docs.isNotEmpty) {
          await batch.commit();
          print(
            'Movidas ${transactions.docs.length + fromAccountTransactions.docs.length} transacciones a papelera',
          );
        }
      } else {
        // Si no hay conexión, guardar la operación para sincronización posterior
        await _savePendingOperation(
          'moveAccountToTrash',
          userId,
          accountId,
          {},
        );
      }
    } catch (e) {
      print('Error al mover transacciones de cuenta a papelera: $e');
      throw e;
    }
  }

  // Método para eliminar permanentemente todas las transacciones en papelera de una cuenta
  Future<void> deleteAccountTrashTransactions(
    String userId,
    String accountId,
  ) async {
    try {
      final isConnected = await _connectivityService.checkConnectivity();

      if (isConnected) {
        // Obtener todas las transacciones en papelera de esta cuenta
        final transactions =
            await _firestore
                .collection('transactions')
                .where('userId', isEqualTo: userId)
                .where('accountId', isEqualTo: accountId)
                .where('isInTrash', isEqualTo: true)
                .get();

        // También las transacciones donde esta cuenta es la cuenta de origen
        final fromAccountTransactions =
            await _firestore
                .collection('transactions')
                .where('userId', isEqualTo: userId)
                .where('fromAccountId', isEqualTo: accountId)
                .where('isInTrash', isEqualTo: true)
                .get();

        // Usar batch para eliminar permanentemente
        final batch = _firestore.batch();

        for (var doc in transactions.docs) {
          batch.delete(doc.reference);
        }

        for (var doc in fromAccountTransactions.docs) {
          batch.delete(doc.reference);
        }

        // Ejecutar el batch
        if (transactions.docs.isNotEmpty ||
            fromAccountTransactions.docs.isNotEmpty) {
          await batch.commit();
          print(
            'Eliminadas ${transactions.docs.length + fromAccountTransactions.docs.length} transacciones permanentemente',
          );
        }
      } else {
        // Si no hay conexión, guardar la operación para sincronización posterior
        await _savePendingOperation(
          'deleteAccountTrash',
          userId,
          accountId,
          {},
        );
      }
    } catch (e) {
      print('Error al eliminar transacciones de cuenta: $e');
      throw e;
    }
  }

  // En TransactionService.dart

  Future<void> moveToTrash(
    String userId,
    String transactionId, {
    bool sync = true,
  }) async {
    final isConnected = await _connectivityService.checkConnectivity();

    try {
      // Primero, intentar obtener los datos de la transacción
      // para poder restaurar la UI en caso de error
      Map<String, dynamic>? transactionData;

      // Para un ID temporal, buscar en la caché local
      if (transactionId.startsWith('temp_')) {
        final localTransactions = await getLocalTransactions(userId);
        transactionData = localTransactions.firstWhere(
          (t) => t['id'] == transactionId,
          orElse: () => {},
        );
      } else {
        try {
          // Para un ID normal, intentar obtener de Firestore
          final doc =
              await _firestore
                  .collection('transactions')
                  .doc(transactionId)
                  .get();
          if (doc.exists) {
            transactionData = doc.data();
          }
        } catch (e) {
          print('Error al obtener datos de transacción: $e');
        }
      }

      // Actualizar la caché local primero para mejor UX
      await _updateLocalTransactionTrashStatus(userId, transactionId, true);

      if (isConnected) {
        try {
          // Para IDs temporales, eliminar localmente
          if (transactionId.startsWith('temp_')) {
            await _handleTemporaryIdDeletion(userId, transactionId);
            return;
          }

          final transactionRef = _firestore
              .collection('transactions')
              .doc(transactionId);

          // Intentar una operación más simple primero
          await transactionRef.update({
            'isInTrash': true,
            'trashedAt': FieldValue.serverTimestamp(),
          });

          // Si llegamos aquí, la operación básica tuvo éxito
          // Ahora intentamos ajustar los balances
          try {
            final transactionDoc = await transactionRef.get();
            if (transactionDoc.exists) {
              await _adjustBalanceForTrash(userId, transactionDoc);
            }
          } catch (balanceError) {
            print('Error al ajustar balances: $balanceError');
            // No interrumpir el flujo por errores en ajuste de balances
          }
        } catch (firestoreError) {
          print('Error en Firestore: $firestoreError');
          if (sync) {
            await _savePendingOperation(
              'trash',
              userId,
              transactionId,
              transactionData ?? {},
            );
          }
        }
      } else {
        // Modo offline
        print(
          'Modo offline: Guardando operación de papelera para sincronización',
        );
        if (sync) {
          await _savePendingOperation(
            'trash',
            userId,
            transactionId,
            transactionData ?? {},
          );
        }
      }
    } catch (e) {
      print('Error general al mover a papelera: $e');
      if (sync) {
        await _savePendingOperation('trash', userId, transactionId, {});
      }
      rethrow; // Re-lanzar el error para que el llamador pueda manejarlo
    }
  }

  Future<void> deletePermanently(
    String userId,
    String transactionId, {
    bool sync = true,
  }) async {
    final isConnected = await _connectivityService.checkConnectivity();

    try {
      final transactionRef = _firestore
          .collection('transactions')
          .doc(transactionId);

      if (isConnected) {
        try {
          // Si es un ID temporal, simplemente eliminar localmente
          if (transactionId.startsWith('temp_')) {
            await _handleTemporaryIdDeletion(userId, transactionId);
            return;
          }

          // Para IDs regulares, realizar la transacción en Firestore
          await _firestore.runTransaction((transaction) async {
            // 1. Obtener la transacción actual
            final transactionDoc = await transaction.get(transactionRef);

            if (!transactionDoc.exists) {
              throw Exception("La transacción no existe");
            }

            final transactionData =
                transactionDoc.data() as Map<String, dynamic>;
            final accountId = transactionData['accountId'];
            final categoryId = transactionData['categoryId'] ?? '';
            final amount = (transactionData['amount'] ?? 0.0).toDouble();
            final type = transactionData['type'] ?? 'expense';

            // 2. Identificar si es parte de una transferencia
            final bool isTransferTransaction =
                categoryId == 'transfer_out' || categoryId == 'transfer_in';

            // Si es parte de una transferencia, buscar la transacción relacionada
            if (isTransferTransaction) {
              // Determinar si es la transacción de salida o entrada
              final relatedCategoryId =
                  categoryId == 'transfer_out' ? 'transfer_in' : 'transfer_out';

              // Buscar la transacción relacionada
              final relatedTransactionsQuery =
                  await _firestore
                      .collection('transactions')
                      .where('userId', isEqualTo: userId)
                      .where(
                        'fromAccountId',
                        isEqualTo: transactionData['accountId'],
                      )
                      .where('categoryId', isEqualTo: relatedCategoryId)
                      .where('amount', isEqualTo: transactionData['amount'])
                      .where('dateTime', isEqualTo: transactionData['dateTime'])
                      .get();

              // Eliminar la transacción relacionada
              if (relatedTransactionsQuery.docs.isNotEmpty) {
                final relatedTransactionRef =
                    relatedTransactionsQuery.docs.first.reference;
                transaction.delete(relatedTransactionRef);
              }
            }

            // 3. Ajustar los balances de la cuenta si no estaba en papelera
            final isInTrash = transactionData['isInTrash'] == true;

            if (!isInTrash) {
              // Obtener la cuenta
              final accountRef = _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('accounts')
                  .doc(accountId);

              final accountDoc = await transaction.get(accountRef);

              if (accountDoc.exists) {
                final accountData = accountDoc.data() as Map<String, dynamic>;
                final isCreditCard = accountData['isCreditCard'] ?? false;
                double currentBalance =
                    (accountData['balance'] ?? 0.0).toDouble();

                // Ajustar balance según tipo de cuenta y transacción
                if (isCreditCard) {
                  if (type == 'expense') {
                    currentBalance -= amount; // Revertir un gasto en tarjeta
                  } else {
                    currentBalance += amount; // Revertir un pago en tarjeta
                  }
                } else {
                  if (type == 'expense') {
                    currentBalance += amount; // Revertir un gasto
                  } else {
                    currentBalance -= amount; // Revertir un ingreso
                  }
                }

                // Actualizar el balance de la cuenta
                transaction.update(accountRef, {'balance': currentBalance});
              }
            }

            // 4. Proceder con la eliminación de la transacción original
            transaction.delete(transactionRef);
          });
        } catch (e) {
          print('Error en transacción Firestore al eliminar: $e');
          if (sync) {
            await _savePendingOperation('delete', userId, transactionId, {});
          }
          rethrow;
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

  // Nuevo método auxiliar para manejar IDs temporales
  Future<void> _handleTemporaryIdDeletion(String userId, String tempId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_transactions_$userId';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> transactions = jsonDecode(cachedJson) as List;
        final newTransactions =
            transactions.where((t) => (t as Map)['id'] != tempId).toList();
        await prefs.setString(cacheKey, jsonEncode(newTransactions));
        print('ID temporal $tempId eliminado localmente');

        // También verificar si hay operaciones pendientes para este ID y eliminarlas
        final pendingOpsKey = 'pending_transactions_$userId';
        final pendingJson = prefs.getString(pendingOpsKey);

        if (pendingJson != null && pendingJson.isNotEmpty) {
          final List<dynamic> pendingOps = jsonDecode(pendingJson) as List;
          final newPendingOps =
              pendingOps.where((op) => (op as Map)['docId'] != tempId).toList();

          if (pendingOps.length != newPendingOps.length) {
            await prefs.setString(pendingOpsKey, jsonEncode(newPendingOps));
            print('Operaciones pendientes para ID $tempId eliminadas');
          }
        }
      }
    } catch (e) {
      print('Error al eliminar ID temporal: $e');
      throw e;
    }
  }

  // Nueva función auxiliar para ajustar balances
  Future<void> _adjustBalanceForTrash(
    String userId,
    DocumentSnapshot transactionDoc,
  ) async {
    try {
      final transactionData = transactionDoc.data() as Map<String, dynamic>;

      final accountId = transactionData['accountId'];
      final categoryId = transactionData['categoryId'] ?? '';
      final isCreditCardPayment = categoryId == 'credit_card_payment';
      final fromAccountId = transactionData['fromAccountId'];
      final amount = (transactionData['amount'] ?? 0.0).toDouble();
      final transactionType = transactionData['type'] ?? 'expense';

      // Obtener datos de la cuenta principal
      final accountRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(accountId);

      final accountDoc = await accountRef.get();
      if (!accountDoc.exists) return;

      final accountData = accountDoc.data() as Map<String, dynamic>;
      final isCreditCard = accountData['isCreditCard'] ?? false;
      double currentBalance = (accountData['balance'] ?? 0.0).toDouble();

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

      // Actualizar la cuenta principal
      await accountRef.update({'balance': currentBalance});

      // Manejar cuenta de origen si es pago de tarjeta
      if (isCreditCardPayment && fromAccountId != null) {
        final fromAccountRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('accounts')
            .doc(fromAccountId);

        final fromAccountDoc = await fromAccountRef.get();
        if (fromAccountDoc.exists) {
          final fromAccountData = fromAccountDoc.data() as Map<String, dynamic>;
          final fromBalance = (fromAccountData['balance'] ?? 0.0).toDouble();
          final newFromBalance = fromBalance + amount;

          await fromAccountRef.update({'balance': newFromBalance});
        }
      }

      // Actualizar presupuestos si es necesario
      if (transactionType == 'expense' && categoryId != 'credit_card_payment') {
        final dateTime = (transactionData['dateTime'] as Timestamp).toDate();
        await _budgetService.updateBudgetsForTransaction(
          userId,
          amount,
          categoryId,
          dateTime,
          false, // quitar
        );
      }
    } catch (e) {
      print('Error al ajustar balances: $e');
      // No relanzamos error para no interrumpir el flujo
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
