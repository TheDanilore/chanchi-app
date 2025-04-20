// lib/services/notification_service.dart
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

// Importamos directamente los elementos necesarios en vez de usar import show
import 'package:chanchi_app/core/initializers/app_initializer.dart';

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
      await _initializeTimeZones();

      // 2. Crear canales de notificación solo si las notificaciones están disponibles
      if (areNotificationsAvailable) {
        await _setupNotificationChannels();
      } else {
        print('Notificaciones locales no disponibles - canales no creados');
      }

      // 3. Configurar manejadores de mensajes FCM
      await _setupMessageHandlers();

      // 4. Verificar si hay recordatorios diarios configurados y recuperarlos
      await _restoreDailyReminderIfEnabled();

      _isInitialized = true;
      print('NotificationService: inicialización básica completada');
    } catch (e) {
      print('Error en la inicialización de NotificationService: $e');
      // No propagar el error para permitir que la app funcione
    }
  }

  Future<void> _initializeTimeZones() async {
    tz.initializeTimeZones();

    try {
      // Try to get the local timezone using the device's timezone name
      final String timeZoneName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print('Zona horaria configurada: $timeZoneName');
    } catch (e) {
      print('Error al configurar zona horaria por nombre: $e');

      try {
        // Fallback to a custom location based on offset
        final now = DateTime.now();
        final offset = now.timeZoneOffset.inMilliseconds ~/ 1000;

        // Try to find a timezone with matching offset
        final availableTimezones = tz.timeZoneDatabase.locations.keys.toList();
        for (final zoneName in availableTimezones) {
          final location = tz.getLocation(zoneName);
          final currentTime = tz.TZDateTime.now(location);
          if (currentTime.timeZoneOffset.inSeconds == offset) {
            tz.setLocalLocation(location);
            print('Encontrada zona horaria coincidente: $zoneName');
            return;
          }
        }

        // If all else fails, use UTC
        tz.setLocalLocation(tz.UTC);
        print('Usando UTC como zona horaria de respaldo');
      } catch (e) {
        print('Error en fallback de zona horaria: $e');
        tz.setLocalLocation(tz.UTC);
      }
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

        await plugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'test_channel',
            'Canal de Pruebas',
            description: 'Canal para pruebas de notificaciones',
            importance: Importance.max,
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

  // Implementar el método que falta
  // Versión mejorada
  void checkPermissions() {
    // Verificar todos los permisos necesarios
    checkAllNotificationPermissions().then((hasPermissions) {
      if (!hasPermissions) {
        print('No se tienen todos los permisos necesarios para notificaciones');
        // Opcionalmente, aquí podrías mostrar un mensaje al usuario
      }
    });
  }

  // RESTO DEL CÓDIGO SIMPLIFICADO PARA MAYOR LEGIBILIDAD
  Future<void> _setupMessageHandlers() async {
    await _fcm.getToken().then((token) {
      print('Token FCM: $token');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && token != null) {
        _saveTokenToDatabase(user.uid, token);
      }
    });

    // Setup listeners
    _fcm.onTokenRefresh.listen(_onTokenRefresh);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    FirebaseMessaging.onMessage.listen(_onMessageReceived);
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _onTokenRefresh(String newToken) {
    print('Token FCM actualizado: $newToken');
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _saveTokenToDatabase(user.uid, newToken);
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    print('Notificación abierta desde segundo plano: ${message.messageId}');
    // Aquí podrías agregar lógica para navegar basada en los datos del mensaje
  }

  void _onMessageReceived(RemoteMessage message) {
    print('Mensaje recibido en primer plano: ${message.notification?.title}');

    if (message.notification != null) {
      _showLocalNotification(
        message.notification!.title ?? 'Notificación',
        message.notification!.body ?? '',
        message.data, // Pasar los datos para poder procesarlos si es necesario
      );
    }
  }

  void _onAuthStateChanged(User? user) {
    if (user != null) {
      _fcm.getToken().then((token) {
        if (token != null) {
          _saveTokenToDatabase(user.uid, token);
        }
      });
    }
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
        payloadStr = jsonEncode(payload);
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

        // Reactivar el recordatorio
        await scheduleDailyReminder(hour: hour, minute: minute);
      }
    } catch (e) {
      print('Error al restaurar recordatorio diario: $e');
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

  Future<bool> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    try {
      // Verificar si el servicio está inicializado
      if (!_isInitialized) {
        await initialize();
      }

      // Primero cancela cualquier recordatorio existente
      await cancelDailyReminder();

      // Verificar todos los permisos
      bool hasAllPermissions = await checkAllNotificationPermissions();
      if (!hasAllPermissions) {
        print('No se tienen todos los permisos necesarios');
        await showLocalNotification(
          'Permisos de notificación',
          'No se pudieron obtener todos los permisos necesarios para programar el recordatorio diario',
        );
        return false;
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'daily_reminder',
            'Recordatorio diario de transacciones',
            channelDescription:
                'Notificaciones diarias para registrar transacciones',
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            ledColor: Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 1000,
            ledOffMs: 500,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.reminder,
          );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      // Calcular la próxima hora de notificación
      final scheduledTime = _nextInstanceOfTime(hour, minute);

      // Programar la notificación
      await flutterLocalNotificationsPlugin.zonedSchedule(
        1, // ID específico
        'Registra tus movimientos',
        '¿Olvidaste registrar tus ingresos y gastos de hoy?',
        scheduledTime,
        platformDetails,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      // Guardar la configuración
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('daily_reminder_enabled', true);
      await prefs.setInt('daily_reminder_hour', hour);
      await prefs.setInt('daily_reminder_minute', minute);
      await prefs.setString(
        'daily_reminder_time',
        '$hour:${minute.toString().padLeft(2, '0')}',
      );

      return true;
    } catch (e) {
      print('Error al programar recordatorio diario: $e');
      return false;
    }
  }

  // Mejoras en el método _nextInstanceOfTime para garantizar que la zona horaria se maneje correctamente
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    // Obtener fecha/hora actual en la zona horaria configurada
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    print('Hora actual del dispositivo (tz.local): $now');
    print('Offset de la zona horaria: ${now.timeZoneOffset}');

    // Crear la fecha objetivo para hoy usando explícitamente la zona horaria local
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Para depuración, muestra la hora programada y la compara con la actual
    print(
      'Intentando programar para: $scheduledDate (hora: $hour, minuto: $minute)',
    );
    final difference = scheduledDate.difference(now).inMinutes;
    print('Diferencia en minutos con hora actual: $difference');

    // Si la hora ya pasó, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      print('Hora ya pasada, reprogramando para mañana: $scheduledDate');
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

  // Verificar permisos de alarmas exactas
  Future<bool> _checkAndRequestExactAlarmPermission() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        // Verificar si podemos programar alarmas exactas
        final bool? canScheduleExactAlarms =
            await androidImplementation.canScheduleExactNotifications();

        print('Permiso de alarmas exactas: $canScheduleExactAlarms');

        if (canScheduleExactAlarms == false) {
          // Solicitar permiso de alarmas exactas
          print('Solicitando permiso de alarmas exactas...');
          try {
            await androidImplementation.requestExactAlarmsPermission();
            final bool? newStatus =
                await androidImplementation.canScheduleExactNotifications();
            print('Nuevo estado de permiso de alarmas exactas: $newStatus');
            return newStatus ?? false;
          } catch (e) {
            print('Error al solicitar permiso de alarmas exactas: $e');
            return false;
          }
        }
        return canScheduleExactAlarms ?? false;
      }

      print('Implementación Android de notificaciones no disponible');
      return false;
    } catch (e) {
      print('Error al verificar permisos de alarmas exactas: $e');
      return false;
    }
  }

  // Añadir este método para verificar todos los permisos necesarios para notificaciones
  Future<bool> checkAllNotificationPermissions() async {
    try {
      // 1. Verificar permisos básicos de notificación
      bool hasBasicPermission = await requestNotificationPermissions();
      if (!hasBasicPermission) {
        print('Permisos básicos de notificación denegados');
        return false;
      }

      // 2. Verificar permisos de alarmas exactas (necesarios para notificaciones programadas)
      bool hasExactAlarmPermission =
          await _checkAndRequestExactAlarmPermission();
      if (!hasExactAlarmPermission) {
        print('Permisos de alarmas exactas denegados');
        return false;
      }

      // 3. Verificar que el plugin de notificaciones esté disponible
      if (!areNotificationsAvailable) {
        print('Plugin de notificaciones no disponible');
        return false;
      }

      print('Todos los permisos para notificaciones están concedidos');
      return true;
    } catch (e) {
      print('Error al verificar todos los permisos de notificación: $e');
      return false;
    }
  }

  // Método para obtener el estado actual del recordatorio
  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('daily_reminder_enabled') ?? false;
  }

  // Método para obtener la hora configurada del recordatorio
  Future<TimeOfDay> getConfiguredReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('daily_reminder_hour') ?? 20;
    final minute = prefs.getInt('daily_reminder_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  // Método para guardar token en la base de datos
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

  // Método público para mostrar una notificación inmediata
  Future<void> showLocalNotification(
    String title,
    String body, [
    Map<String, dynamic>? payload,
  ]) async {
    await _showLocalNotification(title, body, payload);
  }

  // Método para programar una notificación
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required int seconds,
    Map<String, dynamic>? payload,
  }) async {
    if (!areNotificationsAvailable) {
      print('Notificaciones no disponibles - no se puede programar');
      return;
    }

    try {
      // Verificar permisos
      bool hasPermissions = await checkAllNotificationPermissions();
      if (!hasPermissions) {
        print('No se tienen todos los permisos para programar notificaciones');
        throw Exception('Permisos insuficientes para programar notificaciones');
      }

      // Usar ID basado en timestamp
      final int notificationId = DateTime.now().millisecondsSinceEpoch
          .remainder(100000);

      // Configuración de la notificación
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'test_channel',
            'Canal de Pruebas',
            channelDescription: 'Canal para pruebas de notificaciones',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      // Establecer zona horaria local correctamente
      final now = tz.TZDateTime.now(tz.local);
      final scheduledDate = now.add(Duration(seconds: seconds));

      // Programar la notificación
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload != null ? jsonEncode(payload) : null,
      );

      // Notificación inmediata de confirmación
      await showLocalNotification(
        '📱 Notificación programada',
        'Programada para llegar en $seconds segundos (${DateFormat('HH:mm:ss').format(scheduledDate.toLocal())})',
      );
    } catch (e) {
      print('Error al programar notificación: $e');
      throw e;
    }
  }

  // Método para limpiar el cache de notificaciones (útil para pruebas)
  void clearNotificationCache() {
    _sentBudgetNotifications.clear();
  }

  // Método para obtener información de depuración
  Future<Map<String, dynamic>> debugNotificationStatus() async {
    final Map<String, dynamic> status = {};

    try {
      // Verificar si las notificaciones están disponibles
      status['areNotificationsAvailable'] = areNotificationsAvailable;

      // Verificar permisos de notificación
      final settings = await _fcm.getNotificationSettings();
      status['authorizationStatus'] = settings.authorizationStatus.toString();

      // Verificar permisos de alarmas exactas
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        status['canScheduleExactAlarms'] =
            await androidImplementation.canScheduleExactNotifications();
      } else {
        status['canScheduleExactAlarms'] = 'No disponible en esta plataforma';
      }

      // Verificar recordatorio diario
      final prefs = await SharedPreferences.getInstance();
      status['isDailyReminderEnabled'] =
          prefs.getBool('daily_reminder_enabled') ?? false;
      status['dailyReminderHour'] = prefs.getInt('daily_reminder_hour') ?? 20;
      status['dailyReminderMinute'] =
          prefs.getInt('daily_reminder_minute') ?? 0;

      // Verificar token FCM
      status['fcmToken'] = await _fcm.getToken() ?? 'No disponible';

      // Verificar zona horaria
      status['currentTimeZone'] = tz.local.name;
      status['currentLocalTime'] = DateTime.now().toString();
      status['currentTZTime'] = tz.TZDateTime.now(tz.local).toString();

      return status;
    } catch (e) {
      print('Error al verificar estado de notificaciones: $e');
      status['error'] = e.toString();
      return status;
    }
  }
}
