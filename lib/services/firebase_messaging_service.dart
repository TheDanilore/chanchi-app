import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    await _messaging.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message.notification?.title ?? "", message.notification?.body ?? "");
    });
  }

  Future<void> _showNotification(String title, String body) async {
    var androidDetails = AndroidNotificationDetails('channel_id', 'channel_name');
    var notificationDetails = NotificationDetails(android: androidDetails);
    await _notifications.show(0, title, body, notificationDetails);
  }
}
