import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _manejarNotificacionBackground(RemoteMessage message) async {}

class NotificacionesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _canalId = 'barterapp_canal';
  static const String _canalNombre = 'Notificaciones BarterApp';
  static const String _canalDesc = 'Notificaciones de intercambios y mensajes';

  // ─── INICIALIZAR ────────────────────────────────────────────────────────────
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

  // ─── GUARDAR NOTIFICACIÓN EN FIRESTORE ─────────────────────────────────────
  Future<void> guardarNotificacion({
    required String paraUserId,
    required String tipo, // 'intercambio', 'mensaje', 'sistema'
    required String titulo,
    required String cuerpo,
    String? refId, // id del documento relacionado (propuestaId, etc.)
  }) async {
    await _db
        .collection('notificaciones')
        .doc(paraUserId)
        .collection('items')
        .add({
      'tipo': tipo,
      'titulo': titulo,
      'cuerpo': cuerpo,
      'refId': refId ?? '',
      'visto': false,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  // ─── STREAM DE NOTIFICACIONES ───────────────────────────────────────────────
  Stream<QuerySnapshot> streamNotificaciones() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('notificaciones')
        .doc(uid)
        .collection('items')
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // ─── STREAM DE NO VISTAS (para la burbuja) ──────────────────────────────────
  Stream<int> streamNoVistas() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    return _db
        .collection('notificaciones')
        .doc(uid)
        .collection('items')
        .where('visto', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ─── MARCAR TODAS COMO VISTAS ───────────────────────────────────────────────
  Future<void> marcarTodasComoVistas() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final snap = await _db
        .collection('notificaciones')
        .doc(uid)
        .collection('items')
        .where('visto', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'visto': true});
    }
    await batch.commit();
  }

  // ─── ELIMINAR UNA NOTIFICACIÓN ──────────────────────────────────────────────
  Future<void> eliminarNotificacion(String notifId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db
        .collection('notificaciones')
        .doc(uid)
        .collection('items')
        .doc(notifId)
        .delete();
  }

  // ─── ELIMINAR TODAS ─────────────────────────────────────────────────────────
  Future<void> eliminarTodas() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final snap = await _db
        .collection('notificaciones')
        .doc(uid)
        .collection('items')
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}