import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Inicializar zonas horarias
    tz.initializeTimeZones();
    tz.setLocalLocation(
      tz.getLocation('America/Lima'),
    ); // Cambia según tu zona horaria

    // Solicitar permisos
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Configurar notificaciones locales
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notificación tocada: ${response.payload}');
      },
    );

    // Manejar mensajes en primer plano
    FirebaseMessaging.onMessage.listen(_handleMessage);

    // Manejar tap en notificación cuando la app está en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notificación abierta desde segundo plano: ${message.messageId}');
    });

    // Guardar token FCM cuando el usuario inicie sesión
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _saveTokenToDatabase(user.uid);
      }
    });
  }

  Future<void> _saveTokenToDatabase(String userId) async {
    final token = await _fcm.getToken();
    if (token == null) {
      print("⚠️ No se pudo obtener el token de Firebase Cloud Messaging.");
      return;
    }
    print("✅ Token obtenido: $token");

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tokens')
        .doc(token)
        .set({
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
          'platform': 'android',
        })
        .then((_) {
          print("✅ Token guardado en Firestore");
        })
        .catchError((error) {
          print("⚠️ Error al guardar el token en Firestore: $error");
        });
  }

  void _handleMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: message.data['task_id'],
      );
    }
  }

  Future<void> scheduleTaskReminder(
    String taskId,
    String title,
    DateTime dueDate,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.zonedSchedule(
      taskId.hashCode,
      'Recordatorio de tarea',
      'Tu tarea "$title" vence pronto',
      tz.TZDateTime.from(dueDate.subtract(const Duration(hours: 1)), tz.local),
      notificationDetails,
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle, // 🔹 NUEVO PARÁMETRO
      matchDateTimeComponents:
          DateTimeComponents
              .time, // 🔹 REEMPLAZO DE `uiLocalNotificationDateInterpretation`
      payload: taskId,
    );
  }

  Future<void> setTaskReminder(
    String taskId,
    String title,
    DateTime dueDate,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await scheduleTaskReminder(taskId, title, dueDate);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId)
        .update({
          'reminder': true,
          'reminderTime': Timestamp.fromDate(
            dueDate.subtract(const Duration(hours: 1)),
          ),
        });
  }
}
