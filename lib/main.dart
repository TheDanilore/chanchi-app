// lib/main.dart
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/core/config/theme_manager.dart';
import 'package:chanchi_app/core/initializers/app_initializer.dart';
import 'package:chanchi_app/features/home/presentation/providers/home_provider.dart';
import 'package:chanchi_app/features/pages/splash_screen.dart';
import 'package:chanchi_app/features/profile/domain/providers/profile_provider.dart';
import 'package:chanchi_app/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  // Esto es crucial para operaciones async en main
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar la aplicación
    final initialized = await AppInitializer.initialize();

    if (initialized) {
      runApp(const MyApp());
    } else {
      // Mostrar pantalla de error si falla la inicialización
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Error al iniciar la aplicación',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      AppInitializer.initialize().then((initialized) {
                        if (initialized) runApp(const MyApp());
                      });
                    },
                    child: Text('Intentar de nuevo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  } catch (e) {
    print('Error crítico de inicialización: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error al iniciar la aplicación: $e')),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeData _themeData = AppTheme.lightTheme;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
    _initNotifications();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('isDarkTheme') ?? false;
      setState(() {
        _themeData = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
      });
    } catch (e) {
      print('Error al cargar tema: $e');
    }
  }

  void _initNotifications() {
    _notificationService.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // La app vuelve a primer plano
      _notificationService.checkPermissions();
    }
  }

  void _onThemeChanged(ThemeData theme) {
    setState(() {
      _themeData = theme;
    });
    // Guardar preferencia de tema
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isDarkTheme', theme == AppTheme.darkTheme);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Servicios principales
        Provider<NotificationService>(create: (_) => _notificationService),

        // Añade tus otros providers aquí, como:
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(FirebaseAuth.instance.currentUser!),
        ),
      ],
      child: ThemeManager(
        themeData: _themeData,
        onThemeChanged: _onThemeChanged,
        child: MaterialApp(
          title: 'ChanchiApp',
          theme: _themeData,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: scaffoldMessengerKey,
        ),
      ),
    );
  }
}
