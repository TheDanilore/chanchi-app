import 'dart:io';

import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/presentation/pages/auth_check.dart';
import 'package:chanchi_app/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // Inicializar la aplicación
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Configurar Firestore para trabajar offline
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Verificar estado de conexión y guardar en preferencias
      bool isConnected = false;
      try {
        final result = await InternetAddress.lookup('google.com');
        isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        print('Conectado a internet: $isConnected');

        // Guardar el estado de conexión para uso en toda la app
        await _saveConnectionStatus(isConnected);
      } on SocketException catch (_) {
        print('Sin conexión a internet');
        await _saveConnectionStatus(false);

        // Mostrar mensaje de modo offline
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Modo sin conexión. Los cambios se sincronizarán cuando vuelvas a estar online.',
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.amber[700],
            ),
          );
        }
      }

      // Inicializar servicio de notificaciones
      final notificationService = NotificationService();
      await notificationService.initialize();

      // Inicializar formato de fechas en español
      await initializeDateFormatting('es', null);

      // Verificar autenticación actual
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No hay usuario autenticado');
      } else {
        print('Usuario autenticado: ${user.uid}');
      }

      // Simular un tiempo mínimo de carga para mostrar la animación
      await Future.delayed(const Duration(milliseconds: 2000));

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Navegar a la siguiente pantalla
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthCheck()));
      }
    } on FirebaseException catch (e) {
      print('Error de Firebase: ${e.code}');
      print('Mensaje de error: ${e.message}');

      if (mounted) {
        setState(() {
          _errorMessage = "Error de Firebase: ${e.message}";
        });
      }
    } catch (e) {
      print('Error detallado: $e');

      if (mounted) {
        setState(() {
          _errorMessage = "Error al inicializar la app: $e";
        });
      }
    }
  }

  // Método para guardar el estado de conexión
  Future<void> _saveConnectionStatus(bool isConnected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isConnected', isConnected);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo de la app
                    Image.asset('assets/logo.png', width: 200),
                    const SizedBox(height: 24),
                    // Nombre de la app
                    Text(
                      'Chanchi App',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(color: AppTheme.lightBackgroundColor),
                    ),
                    const SizedBox(height: 8),
                    // Eslogan
                    Text(
                      'Gestiona tus Finanzas Personales',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightBackgroundColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Mostrar error o indicador de carga
                    if (_errorMessage != null) ...[
                      Icon(Icons.error, color: Colors.red[300], size: 32),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[300]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.lightBackgroundColor,
                          foregroundColor: AppTheme.primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _initializeApp();
                          });
                        },
                        child: const Text('Reintentar'),
                      ),
                    ] else ...[
                      // Indicador de carga
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.lightBackgroundColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando aplicación...',
                        style: TextStyle(
                          color: AppTheme.lightBackgroundColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
