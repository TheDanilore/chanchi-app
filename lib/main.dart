import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/config/theme_manager.dart';
import 'package:chanchi_app/presentation/pages/splash_screen.dart';
import 'package:chanchi_app/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';

// Manejador de mensajes en segundo plano
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Mensaje recibido en segundo plano: ${message.messageId}');
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData _themeData = AppTheme.lightTheme;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Firebase.initializeApp();

      // Configurar Firestore para trabajar offline
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Configurar Firebase Cloud Messaging (FCM)
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Inicializar servicio de notificaciones
      final notificationService = NotificationService();
      await notificationService.initialize();

      // Inicializar formato de fechas en español
      await initializeDateFormatting('es', null);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error al inicializar la app: $e";
        });
      }
    }
  }

  void _onThemeChanged(ThemeData theme) {
    setState(() {
      _themeData = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                SizedBox(height: 16),
                ElevatedButton(
                  style: AppTheme.buildElevatedButtonStyle(AppTheme.primaryColor, Colors.white),
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _initializeApp();
                    });
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    return ThemeManager(
      themeData: _themeData,
      onThemeChanged: _onThemeChanged,
      child: MaterialApp(
        title: 'ChanchiApp',
        theme: _themeData,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
