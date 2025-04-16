import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/config/theme_manager.dart';
import 'package:chanchi_app/presentation/pages/splash_screen.dart';
import 'package:chanchi_app/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Crear una instancia global de FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Variable global para saber si las notificaciones están disponibles
bool areNotificationsAvailable = false;

// Manejador de mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializar Firebase primero
  await Firebase.initializeApp();
  
  // Registrar información detallada para diagnóstico
  print('==== MENSAJE RECIBIDO EN SEGUNDO PLANO ====');
  print('ID del mensaje: ${message.messageId}');
  print('Título: ${message.notification?.title}');
  print('Cuerpo: ${message.notification?.body}');
  print('Datos: ${message.data}');
  
  // No intentar mostrar UI o hacer navegación desde aquí
  // Solo procesar datos si es necesario
}

// Manejador de notificaciones en segundo plano
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('Notificación manejada en segundo plano: ${notificationResponse.payload}');
  
  // Procesar acciones basadas en el payload de la notificación
  final String? payload = notificationResponse.payload;
  if (payload != null) {
    // Acción específica basada en el payload
    if (payload.startsWith('budget:')) {
      // Podría almacenar información para luego navegar a la pantalla de presupuestos
      // cuando la aplicación se abra
      print('Notificación de presupuesto tocada: ${payload.split(':')[1]}');
    }
  }
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  // Asegurarse de que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Inicializar Firebase primero
    await Firebase.initializeApp();
    print('Firebase inicializado correctamente');

    // 2. Configurar Firebase Cloud Messaging para mensajes en segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // 3. Inicializar notificaciones locales con manejo de errores
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notificación local recibida: ${response.payload}');
          
          // Aquí podrías agregar lógica para manejar la notificación cuando la app está abierta
          final String? payload = response.payload;
          if (payload != null) {
            // Acción específica basada en el payload
            if (payload.startsWith('budget:')) {
              // Navegar a la pantalla de presupuestos
              print('Navegar a presupuesto: ${payload.split(':')[1]}');
              // Implementar navegación cuando la app esté lista
            }
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      
      areNotificationsAvailable = true;
      print('Plugin de notificaciones locales inicializado correctamente');
    } catch (notificationError) {
      // Si falla la inicialización de notificaciones, registrar el error pero continuar
      areNotificationsAvailable = false;
      print('Error al inicializar notificaciones: $notificationError');
      print('La aplicación continuará sin funcionalidad de notificaciones locales');
    }
    
    // 4. Inicializar servicio de notificaciones (sin esperar)
    NotificationService().initialize().then((_) {
      print('Servicio de notificaciones inicializado');
    }).catchError((error) {
      print('Error al inicializar servicio de notificaciones: $error');
    });

    // Ejecutar la aplicación incluso si las notificaciones fallaron
    runApp(const MyApp());
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
      // La app vuelve a primer plano - verificar y restaurar notificaciones si es necesario
      NotificationService().initialize();
    }
  }

  void _onThemeChanged(ThemeData theme) {
    setState(() {
      _themeData = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeManager(
      themeData: _themeData,
      onThemeChanged: _onThemeChanged,
      child: MaterialApp(
        title: 'ChanchiApp',
        theme: _themeData,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: scaffoldMessengerKey,
      ),
    );
  }
}