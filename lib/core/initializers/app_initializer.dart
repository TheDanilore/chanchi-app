// lib/core/initializers/app_initializer.dart
import 'package:chanchi_app/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:chanchi_app/core/utils/error_handler.dart';

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
}

// Manejador de notificaciones en segundo plano
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print(
    'Notificación manejada en segundo plano: ${notificationResponse.payload}',
  );

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

class AppInitializer {
  static Future<bool> initialize() async {
    try {
      // Asegurar que Flutter esté inicializado
      WidgetsFlutterBinding.ensureInitialized();

      // Inicializar Firebase
      await Firebase.initializeApp();

      // Configurar Firebase Cloud Messaging para mensajes en segundo plano
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Inicializar notificaciones locales
      await _initializeLocalNotifications();

      // Inicializar servicio de notificaciones (sin esperar)
      NotificationService()
          .initialize()
          .then((_) {
            print('Servicio de notificaciones inicializado');
          })
          .catchError((error) {
            ErrorHandler.logError(
              'Error al inicializar servicio de notificaciones',
              error,
            );
          });

      // Todo inicializado correctamente
      return true;
    } catch (e) {
      ErrorHandler.logError('Error crítico de inicialización', e);
      return false;
    }
  }

  // Inicializar notificaciones locales
  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      areNotificationsAvailable = true;
      print('Plugin de notificaciones locales inicializado correctamente');
    } catch (e) {
      // Si falla la inicialización de notificaciones, registrar el error pero continuar
      areNotificationsAvailable = false;
      ErrorHandler.logError('Error al inicializar notificaciones', e);
    }
  }

  // Manejar respuesta de notificación
  static void _handleNotificationResponse(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null) {
      // Acción específica basada en el payload
      if (payload.startsWith('budget:')) {
        // Implementar navegación cuando la app esté lista
        print('Notificación local recibida: $payload');
      }
    }
  }
}
