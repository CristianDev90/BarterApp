import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notificaciones_service.dart';

class IntercambioService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificacionesService _notifs = NotificacionesService();

  // ─── PROPONER UN INTERCAMBIO ───────────────────────────────────────────────
  Future<void> proponerIntercambio({
    required String publicacionId,
    required String propietarioId,
    required String mensajePropuesta,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    if (user.uid == propietarioId) {
      throw Exception('No puedes intercambiar contigo mismo');
    }

    final yaExiste = await _db
        .collection('propuestas')
        .where('de_userId', isEqualTo: user.uid)
        .where('publicacionId', isEqualTo: publicacionId)
        .where('estado', isEqualTo: 'pendiente')
        .get();

    if (yaExiste.docs.isNotEmpty) {
      throw Exception('Ya tienes una propuesta pendiente para este objeto');
    }

    final ref = await _db.collection('propuestas').add({
      'publicacionId': publicacionId,
      'para_userId': propietarioId,
      'de_userId': user.uid,
      'mensajePropuesta': mensajePropuesta,
      'estado': 'pendiente',
      'fecha': FieldValue.serverTimestamp(),
      'ocultoPara': [],
    });

    // Obtener nombre del que propone
    final userDoc = await _db.collection('usuarios').doc(user.uid).get();
    final nombre = userDoc.data()?['nombre'] ?? 'Alguien';

    await _notifs.guardarNotificacion(
      paraUserId: propietarioId,
      tipo: 'intercambio',
      titulo: 'Nueva propuesta de intercambio',
      cuerpo: '$nombre quiere intercambiar contigo',
      refId: ref.id,
    );
  }

  // ─── ACEPTAR UNA PROPUESTA ─────────────────────────────────────────────────
  Future<void> aceptarIntercambio(String propuestaId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final doc = await _db.collection('propuestas').doc(propuestaId).get();
    if (doc['para_userId'] != user.uid) {
      throw Exception('Solo el propietario puede aceptar');
    }

    await _db.collection('propuestas').doc(propuestaId).update({
      'estado': 'aceptado',
      'fechaRespuesta': FieldValue.serverTimestamp(),
    });

    final userDoc = await _db.collection('usuarios').doc(user.uid).get();
    final nombre = userDoc.data()?['nombre'] ?? 'Alguien';

    await _notifs.guardarNotificacion(
      paraUserId: doc['de_userId'],
      tipo: 'intercambio',
      titulo: '¡Propuesta aceptada!',
      cuerpo: '$nombre aceptó tu propuesta de intercambio',
      refId: propuestaId,
    );
  }

  // ─── RECHAZAR UNA PROPUESTA ────────────────────────────────────────────────
  Future<void> rechazarIntercambio(String propuestaId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final doc = await _db.collection('propuestas').doc(propuestaId).get();
    if (doc['para_userId'] != user.uid) {
      throw Exception('Solo el propietario puede rechazar');
    }

    await _db.collection('propuestas').doc(propuestaId).update({
      'estado': 'rechazado',
      'fechaRespuesta': FieldValue.serverTimestamp(),
    });

    final userDoc = await _db.collection('usuarios').doc(user.uid).get();
    final nombre = userDoc.data()?['nombre'] ?? 'Alguien';

    await _notifs.guardarNotificacion(
      paraUserId: doc['de_userId'],
      tipo: 'intercambio',
      titulo: 'Propuesta rechazada',
      cuerpo: '$nombre rechazó tu propuesta de intercambio',
      refId: propuestaId,
    );
  }

  // ─── CANCELAR UNA PROPUESTA ────────────────────────────────────────────────
  Future<void> cancelarIntercambio(String propuestaId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final doc = await _db.collection('propuestas').doc(propuestaId).get();
    if (doc['de_userId'] != user.uid) {
      throw Exception('Solo quien propuso puede cancelar');
    }
    if (doc['estado'] != 'pendiente') {
      throw Exception('Solo se pueden cancelar propuestas pendientes');
    }

    await _db.collection('propuestas').doc(propuestaId).update({
      'estado': 'cancelado',
      'fechaRespuesta': FieldValue.serverTimestamp(),
    });
  }

  // ─── OCULTAR PROPUESTA (soft delete) ──────────────────────────────────────
  Future<void> eliminarPropuesta(String propuestaId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final doc = await _db.collection('propuestas').doc(propuestaId).get();
    final data = doc.data();
    if (data == null) throw Exception('Propuesta no encontrada');

    if (data['de_userId'] != user.uid && data['para_userId'] != user.uid) {
      throw Exception('No tienes permiso');
    }

    await _db.collection('propuestas').doc(propuestaId).update({
      'ocultoPara': FieldValue.arrayUnion([user.uid]),
    });
  }

  // ─── MIS INTERCAMBIOS ENVIADOS ─────────────────────────────────────────────
  Stream<QuerySnapshot> misIntercambiosEnviados() {
    final uid = _auth.currentUser?.uid;
    return _db
        .collection('propuestas')
        .where('de_userId', isEqualTo: uid)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // ─── MIS INTERCAMBIOS RECIBIDOS ────────────────────────────────────────────
  Stream<QuerySnapshot> misIntercambiosRecibidos() {
    final uid = _auth.currentUser?.uid;
    return _db
        .collection('propuestas')
        .where('para_userId', isEqualTo: uid)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // ─── ENVIAR MENSAJE ────────────────────────────────────────────────────────
  Future<void> enviarMensaje({
    required String propuestaId,
    required String texto,
    required String paraUserId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    await _db
        .collection('propuestas')
        .doc(propuestaId)
        .collection('mensajes')
        .add({
      'de_userId': user.uid,
      'texto': texto,
      'fecha': FieldValue.serverTimestamp(),
    });

    final userDoc = await _db.collection('usuarios').doc(user.uid).get();
    final nombre = userDoc.data()?['nombre'] ?? 'Alguien';

    await _notifs.guardarNotificacion(
      paraUserId: paraUserId,
      tipo: 'mensaje',
      titulo: 'Nuevo mensaje de $nombre',
      cuerpo: texto.length > 50 ? '${texto.substring(0, 50)}...' : texto,
      refId: propuestaId,
    );
  }

  // ─── STREAM DE MENSAJES ────────────────────────────────────────────────────
  Stream<QuerySnapshot> mensajesDeChat(String propuestaId) {
    return _db
        .collection('propuestas')
        .doc(propuestaId)
        .collection('mensajes')
        .orderBy('fecha', descending: false)
        .snapshots();
  }
}