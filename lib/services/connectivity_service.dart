import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Actualizar el tipo para que coincida con la nueva API de Connectivity
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isConnected = false;

  factory ConnectivityService() => _instance;

  ConnectivityService._internal() {
    // Inicializar estado de conexión
    _loadConnectionStatus();

    // Configurar listener de conectividad
    _initConnectivityListener();

    // Asegurar que Firestore tenga habilitada la persistencia
    _enableOfflineCapabilities();
  }

  Future<void> _enableOfflineCapabilities() async {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      print('Firebase offline capabilities enabled');
    } catch (e) {
      print('Error enabling offline capabilities: $e');
    }
  }

  // Verificar si hay conexión a internet - método público
  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      bool connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      // Actualizamos el estado para uso inmediato
      _isConnected = connected;
      await saveConnectionStatus(connected);
      return connected;
    } on SocketException catch (_) {
      // Actualizamos el estado para uso inmediato
      _isConnected = false;
      await saveConnectionStatus(false);
      return false;
    }
  }

  // Getter para obtener rápidamente el estado actual sin hacer una comprobación de red
  bool get isConnected => _isConnected;

  // Métodos para gestionar el estado de la conexión
  Future<void> _loadConnectionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isConnected = prefs.getBool('isConnected') ?? false;
    } catch (e) {
      print('Error loading connection status: $e');
      _isConnected = false;
    }
  }

  // Método corregido para manejar la nueva API de Connectivity
  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        // Tomar el primer resultado si existe
        if (results.isNotEmpty) {
          _handleConnectivityChange(results.first);
        } else {
          _handleConnectivityChange(ConnectivityResult.none);
        }
      },
    );
  }

  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    bool wasConnected = _isConnected;

    if (result == ConnectivityResult.none) {
      _isConnected = false;
    } else {
      // Verificar conexión real
      try {
        final response = await InternetAddress.lookup('google.com');
        _isConnected = response.isNotEmpty && response[0].rawAddress.isNotEmpty;
      } on SocketException {
        _isConnected = false;
      }
    }

    // Guardar estado
    await saveConnectionStatus(_isConnected);

    print(
      'Connectivity changed: ${wasConnected ? 'online' : 'offline'} -> ${_isConnected ? 'online' : 'offline'}',
    );
  }

  Future<void> saveConnectionStatus(bool isConnected) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isConnected', isConnected);
    } catch (e) {
      print('Error saving connection status: $e');
    }
  }

  // Obtener el último estado de conexión guardado
  Future<bool> getLastConnectionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isConnected') ?? false;
    } catch (e) {
      print('Error getting last connection status: $e');
      return false;
    }
  }

  // Sincronización
  Future<bool> attemptSync() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final hasConnection =
          result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (hasConnection) {
        await _firestore.disableNetwork();
        await _firestore.enableNetwork();
        _isConnected = true;
        await saveConnectionStatus(true);
      } else {
        _isConnected = false;
        await saveConnectionStatus(false);
      }

      return hasConnection;
    } on SocketException {
      _isConnected = false;
      await saveConnectionStatus(false);
      return false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}