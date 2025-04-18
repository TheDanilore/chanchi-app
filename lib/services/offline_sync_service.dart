import 'dart:convert';

import 'package:chanchi_app/services/connectivity_service.dart';
import 'package:chanchi_app/services/transaction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Este servicio es un adaptador que conecta el ConnectivityService
// con el TransactionService para mantener compatibilidad con el código existente
class OfflineSyncService {
  final ConnectivityService _connectivityService = ConnectivityService();
  final TransactionService _transactionService = TransactionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final OfflineSyncService _instance = OfflineSyncService._internal();

  factory OfflineSyncService() {
    return _instance;
  }

  OfflineSyncService._internal();

  // Verificar si hay conexión a internet (delegamos al ConnectivityService)
  // Getter rápido que no hace verificación de red
  bool get isConnected => _connectivityService.isConnected;

  // Método async que sí hace verificación de red
  Future<bool> checkConnection() async {
    return await _connectivityService.checkConnectivity();
  }

  // Método para intentar sincronizar
   Future<bool> attemptSync() async {
    final isConnected = await _connectivityService.checkConnectivity();
    
    if (!isConnected) {
      return false;
    }
    
    try {
      // Obtener el usuario actual
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }
      
      // Sincronizar transacciones pendientes
      await _transactionService.syncPendingOperations(user.uid);
      
      // Opcional: limpiar caché de transacciones temporales después de sincronizar
      await _cleanTemporaryTransactionsCache(user.uid);
      
      return true;
    } catch (e) {
      print('Error durante la sincronización: $e');
      return false;
    }
  }

   Future<void> _cleanTemporaryTransactionsCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_transactions_$userId';
      final cachedJson = prefs.getString(cacheKey);
      
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<Map<String, dynamic>> transactions = 
            List<Map<String, dynamic>>.from(jsonDecode(cachedJson) as List);
        
        // Eliminar transacciones con ID temporal
        final cleanedTransactions = transactions.where((t) {
          return !t['id'].toString().startsWith('temp_');
        }).toList();
        
        // Guardar la lista limpia
        await prefs.setString(cacheKey, jsonEncode(cleanedTransactions));
      }
    } catch (e) {
      print('Error al limpiar caché de transacciones temporales: $e');
    }
  }

  // Verificar si hay operaciones pendientes para sincronizar
  Future<bool> hasPendingOperations() async {
    if (_auth.currentUser == null) return false;

    return await _transactionService.hasPendingOperations(
      _auth.currentUser!.uid,
    );
  }

  // Obtener el número de operaciones pendientes
  Future<int> getPendingOperationsCount() async {
    if (_auth.currentUser == null) return 0;

    return await _transactionService.getPendingOperationsCount(
      _auth.currentUser!.uid,
    );
  }
}
