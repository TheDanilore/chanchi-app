import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

// Importa la instancia global y la bandera de disponibilidad
import 'package:chanchi_app/main.dart'
    show flutterLocalNotificationsPlugin, areNotificationsAvailable;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _isInitialized = false;

  // Cache para evitar notificaciones duplicadas de presupuesto
  final Map<String, DateTime> _sentBudgetNotifications = {};

  // Tiempo mínimo entre notificaciones del mismo presupuesto (24 horas)
  static const Duration _budgetNotificationCooldown = Duration(hours: 24);

  // Método de inicialización básica
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Inicializar zonas horarias
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('America/Lima'));
      } catch (e) {
        print('Error al configurar zona horaria: $e');
        tz.setLocalLocation(tz.UTC);
      }

      // 2. Crear canales de notificación solo si las notificaciones están disponibles
      if (areNotificationsAvailable) {
        await _setupNotificationChannels();
      } else {
        print('Notificaciones locales no disponibles - canales no creados');
      }

      // 3. Configurar manejadores de mensajes FCM
      await _setupMessageHandlers();

      // 4. Verificar si hay recordatorios diarios configurados y recuperarlos
      _restoreDailyReminderIfEnabled();

      _isInitialized = true;
      print('NotificationService: inicialización básica completada');
    } catch (e) {
      print('Error en la inicialización de NotificationService: $e');
      // No propagar el error para permitir que la app funcione
    }
  }

  // Método para crear canales de notificación
  Future<void> _setupNotificationChannels() async {
    if (!areNotificationsAvailable) return;

    try {
      final plugin =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (plugin != null) {
        // Canal para recordatorio diario
        await plugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'daily_reminder',
            'Recordatorio diario de transacciones',
            description: 'Notificaciones diarias para registrar transacciones',
            importance: Importance.high,
          ),
        );

        // Canal para notificaciones de presupuesto
        await plugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'budget_notifications',
            'Notificaciones de Presupuesto',
            description: 'Alertas cuando alcanzas o excedes un presupuesto',
            importance: Importance.high,
          ),
        );

        // Canal general
        await plugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'chanchi_app_channel',
            'Chanchi App Notifications',
            description: 'Canal general de notificaciones',
            importance: Importance.high,
          ),
        );

        print('Canales de notificación creados correctamente');
      } else {
        print('Plugin de Android no disponible para crear canales');
      }
    } catch (e) {
      print('Error al crear canales de notificación: $e');
    }
  }

  // Configurar manejadores de mensajes FCM
  Future<void> _setupMessageHandlers() async {
    // Solicitar token FCM y guardar si el usuario está autenticado
    String? token = await _fcm.getToken();
    print('Token FCM: $token');

    // Configurar manejo cuando el token se actualiza
    _fcm.onTokenRefresh.listen((newToken) {
      print('Token FCM actualizado: $newToken');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _saveTokenToDatabase(user.uid, newToken);
      }
    });

    // Notificación abierta desde segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notificación abierta desde segundo plano: ${message.messageId}');
      // Aquí podrías agregar lógica para navegar basada en los datos del mensaje
    });

    // Notificación recibida en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje recibido en primer plano: ${message.notification?.title}');

      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title ?? 'Notificación',
          message.notification!.body ?? '',
          message
              .data, // Pasar los datos para poder procesarlos si es necesario
        );
      }
    });

    // Guardar token cuando el usuario inicia sesión
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && token != null) {
        _saveTokenToDatabase(user.uid, token);
      }
    });

    // Configurar opciones para las notificaciones en primer plano
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _showLocalNotification(
    String title,
    String body, [
    Map<String, dynamic>? payload,
  ]) async {
    if (!areNotificationsAvailable) {
      print('Notificaciones no disponibles - no se puede mostrar: $title');
      return;
    }

    try {
      // Generar un ID único para cada notificación
      final int notificationId = DateTime.now().millisecondsSinceEpoch
          .remainder(100000);

      // Convertir payload a string si existe
      String? payloadStr;
      if (payload != null) {
        payloadStr = payload.toString();
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'chanchi_app_channel',
            'Chanchi App Notifications',
            channelDescription: 'Canal general de notificaciones',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: payloadStr,
      );
    } catch (e) {
      print('Error al mostrar notificación: $e');
    }
  }

  // Método para solicitar permisos
  Future<bool> requestNotificationPermissions() async {
    try {
      // Verificar configuración actual de notificaciones
      NotificationSettings currentSettings =
          await _fcm.getNotificationSettings();

      // Si ya están autorizadas, retornar true
      if (currentSettings.authorizationStatus ==
          AuthorizationStatus.authorized) {
        print('Permisos de notificación ya concedidos');
        return true;
      }

      // Solicitar permisos con diálogo explicativo
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
      );

      // Manejar diferentes estados de autorización
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          print('Permisos de notificación concedidos');
          return true;
        case AuthorizationStatus.provisional:
          print('Permisos de notificación provisionales');
          return true;
        default:
          print('Permisos de notificación denegados');
          return false;
      }
    } catch (e) {
      print('Error al solicitar permisos de notificación: $e');
      return false;
    }
  }

  // Modificación del método scheduleDailyReminder para aceptar hora personalizada
  Future<bool> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    try {
      // Verificar si el servicio está inicializado
      if (!_isInitialized) {
        await initialize();
      }

      // Verificar permisos de notificación
      bool hasNotificationPermission = await requestNotificationPermissions();
      if (!hasNotificationPermission) {
        return false;
      }

      // Cancelar cualquier recordatorio existente para evitar duplicados
      await cancelDailyReminder();

      // Verificar disponibilidad de notificaciones
      if (!areNotificationsAvailable) {
        return false;
      }

      // Solicitar permiso de alarmas exactas
      if (!(await _checkAndRequestExactAlarmPermission())) {
        return false;
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'daily_reminder',
            'Recordatorio diario de transacciones',
            channelDescription:
                'Notificaciones diarias para registrar transacciones',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      // Programar la notificación para la hora personalizada
      await flutterLocalNotificationsPlugin.zonedSchedule(
        1, // ID específico para el recordatorio diario
        'Registra tus movimientos',
        '¿Olvidaste registrar tus ingresos y gastos de hoy?',
        _nextInstanceOfTime(hour, minute),
        platformChannelSpecifics,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      // Guardar estado de recordatorio y la hora configurada
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('daily_reminder_enabled', true);
      await prefs.setInt('daily_reminder_hour', hour);
      await prefs.setInt('daily_reminder_minute', minute);
      await prefs.setString(
        'daily_reminder_time',
        '$hour:${minute.toString().padLeft(2, '0')}',
      );

      print(
        'Recordatorio diario programado con éxito para las $hour:${minute.toString().padLeft(2, '0')}',
      );
      return true;
    } catch (e) {
      print('Error al programar recordatorio: $e');
      return false;
    }
  }

  // Nuevo método para calcular la próxima instancia de una hora personalizada
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Si la hora ya pasó, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Restaurar recordatorio diario con la hora guardada
  Future<void> _restoreDailyReminderIfEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('daily_reminder_enabled') ?? false;

      if (isEnabled) {
        // Obtener la hora guardada o usar valores predeterminados
        final hour = prefs.getInt('daily_reminder_hour') ?? 20;
        final minute = prefs.getInt('daily_reminder_minute') ?? 0;

        print(
          'Restaurando recordatorio diario previamente habilitado para las $hour:${minute.toString().padLeft(2, '0')}',
        );
        await scheduleDailyReminder(hour: hour, minute: minute);
      }
    } catch (e) {
      print('Error al restaurar recordatorio diario: $e');
    }
  }

  // Método para obtener la hora configurada del recordatorio
  Future<TimeOfDay> getConfiguredReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('daily_reminder_hour') ?? 20;
    final minute = prefs.getInt('daily_reminder_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _saveTokenToDatabase(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc(token)
          .set({
            'token': token,
            'createdAt': FieldValue.serverTimestamp(),
            'platform': 'android',
            'lastUpdated': FieldValue.serverTimestamp(),
          });
      print("✅ Token guardado en Firestore: $token");
    } catch (error) {
      print("⚠️ Error al guardar el token en Firestore: $error");
    }
  }

  Future<bool> _checkAndRequestExactAlarmPermission() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        final bool? canScheduleExactAlarms =
            await androidImplementation.canScheduleExactNotifications();

        if (canScheduleExactAlarms == false) {
          // Solicitar permiso de alarmas exactas
          await androidImplementation.requestExactAlarmsPermission();

          // Verificar nuevamente después de solicitar
          return await androidImplementation.canScheduleExactNotifications() ??
              false;
        }
        return canScheduleExactAlarms ?? false;
      }
      return false;
    } catch (e) {
      print('Error al verificar permisos de alarmas exactas: $e');
      return false;
    }
  }

  tz.TZDateTime _nextInstanceOfEightPM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20, // 8 PM
      0,
    );

    // Si la hora ya pasó, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Método para cancelar la notificación diaria
  Future<void> cancelDailyReminder() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(
        1,
      ); // Usar el mismo ID específico

      // Guardar estado de recordatorio
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('daily_reminder_enabled', false);

      print('Recordatorio diario cancelado');
    } catch (e) {
      print('Error al cancelar recordatorio diario: $e');
    }
  }

  // Método para obtener el estado actual del recordatorio
  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('daily_reminder_enabled') ?? false;
  }

  // Método para enviar notificación de presupuesto con control de frecuencia
  Future<void> sendBudgetNotification(
    String budgetId,
    String title,
    String body,
  ) async {
    if (!areNotificationsAvailable) return;

    // Verificar si ya enviamos una notificación para este presupuesto recientemente
    final lastNotification = _sentBudgetNotifications[budgetId];
    final now = DateTime.now();

    if (lastNotification != null) {
      final timeSinceLastNotification = now.difference(lastNotification);
      if (timeSinceLastNotification < _budgetNotificationCooldown) {
        print(
          'Notificación de presupuesto $budgetId omitida - enfriamiento activo',
        );
        return;
      }
    }

    try {
      // Registrar esta notificación
      _sentBudgetNotifications[budgetId] = now;

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'budget_notifications',
            'Notificaciones de Presupuesto',
            channelDescription:
                'Alertas cuando alcanzas o excedes un presupuesto',
            importance: Importance.high,
            priority: Priority.high,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      // Generar un ID único para cada notificación
      final int notificationId = int.parse(
        budgetId.hashCode.toString().substring(0, 5).padLeft(5, '0'),
      );

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: 'budget:$budgetId',
      );

      print('Notificación de presupuesto enviada para $budgetId');
    } catch (e) {
      print('Error al enviar notificación de presupuesto: $e');
    }
  }

  // Método para limpiar el cache de notificaciones (útil para pruebas)
  void clearNotificationCache() {
    _sentBudgetNotifications.clear();
  }
}
