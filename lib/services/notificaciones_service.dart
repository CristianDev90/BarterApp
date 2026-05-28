import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _manejarNotificacionBackground(RemoteMessage message) async {}

class NotificacionesService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _canalId = 'barterapp_canal';
  static const String _canalNombre = 'Notificaciones BarterApp';
  static const String _canalDesc = 'Notificaciones de intercambios y mensajes';

  Future<void> inicializar() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(settings);

    FirebaseMessaging.onBackgroundMessage(_manejarNotificacionBackground);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _canalId,
              _canalNombre,
              channelDescription: _canalDesc,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    await _messaging.getToken();
  }

  Future<String?> obtenerToken() async {
    return await _messaging.getToken();
  }
}