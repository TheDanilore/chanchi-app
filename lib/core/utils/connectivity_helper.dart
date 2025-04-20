// lib/core/utils/connectivity_helper.dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityHelper {
  final Connectivity _connectivity;
  
  ConnectivityHelper({Connectivity? connectivity}) 
      : _connectivity = connectivity ?? Connectivity();
  
  // Verificar si hay conexión a internet
  Future<bool> isConnected() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      // En caso de error, asumir que no hay conexión
      return false;
    }
  }
  
  // Obtener un stream para escuchar cambios en la conectividad
  Stream<bool> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }
}