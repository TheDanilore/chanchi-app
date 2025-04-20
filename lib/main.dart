// lib/main.dart
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/core/config/theme_manager.dart';
import 'package:chanchi_app/core/initializers/app_initializer.dart';
import 'package:chanchi_app/features/pages/splash_screen.dart';
import 'package:chanchi_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
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
                    onPressed: () => main(),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // La app vuelve a primer plano - inicializar notificaciones si es necesario
    }
  }

  void _onThemeChanged(ThemeData theme) {
    setState(() {
      _themeData = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Añade al menos un provider
        Provider<NotificationService>(create: (_) => NotificationService()),
        // O si no tienes ningún provider disponible, puedes crear uno temporal:
        Provider<String>(create: (_) => 'dummy'),
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
