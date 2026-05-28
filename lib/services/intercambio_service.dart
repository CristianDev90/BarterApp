import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IntercambioService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── PROPONER UN INTERCAMBIO ───────────────────────────────────────────────
  // Se llama cuando el usuario toca "Proponer trueque" en el detalle
  // de una publicación. Guarda la propuesta en Firebase con estado "pendiente".
  Future<void> proponerIntercambio({
    required String publicacionId,       // ID de la publicación que quiere
    required String propietarioId,       // ID del dueño de esa publicación
    required String mensajePropuesta,    // Mensaje que escribe quien propone
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    if (user.uid == propietarioId) throw Exception('No puedes intercambiar contigo mismo');

    // Revisar si ya enviaste una propuesta para esta publicación
    final yaExiste = await _db
        .collection('intercambios')
        .where('solicitanteId', isEqualTo: user.uid)
        .where('publicacionId', isEqualTo: publicacionId)
        .where('estado', isEqualTo: 'pendiente')
        .get();

    if (yaExiste.docs.isNotEmpty) {
      throw Exception('Ya tienes una propuesta pendiente para este objeto');
    }

    await _db.collection('intercambios').add({
      'publicacionId': publicacionId,      // qué publicación quiere
      'propietarioId': propietarioId,      // a quién le está proponiendo
      'solicitanteId': user.uid,           // quién propone
      'mensajePropuesta': mensajePropuesta,
      'estado': 'pendiente',               // pendiente / aceptado / rechazado
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  // ─── ACEPTAR UNA PROPUESTA ─────────────────────────────────────────────────
  // Solo el propietario de la publicación puede aceptar.
  Future<void> aceptarIntercambio(String intercambioId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final doc = await _db.collection('intercambios').doc(intercambioId).get();
    if (doc['propietarioId'] != user.uid) {
      throw Exception('Solo el propietario puede aceptar');
    }

    await _db.collection('intercambios').doc(intercambioId).update({
      'estado': 'aceptado',
      'fechaRespuesta': FieldValue.serverTimestamp(),
    });
  }

  // ─── RECHAZAR UNA PROPUESTA ────────────────────────────────────────────────
  Future<void> rechazarIntercambio(String intercambioId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final doc = await _db.collection('intercambios').doc(intercambioId).get();
    if (doc['propietarioId'] != user.uid) {
      throw Exception('Solo el propietario puede rechazar');
    }

    await _db.collection('intercambios').doc(intercambioId).update({
      'estado': 'rechazado',
      'fechaRespuesta': FieldValue.serverTimestamp(),
    });
  }

  // ─── CANCELAR UNA PROPUESTA ────────────────────────────────────────────────
  // Solo quien la envió puede cancelarla, y solo si sigue pendiente.
  Future<void> cancelarIntercambio(String intercambioId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final doc = await _db.collection('intercambios').doc(intercambioId).get();
    if (doc['solicitanteId'] != user.uid) {
      throw Exception('Solo quien propuso puede cancelar');
    }
    if (doc['estado'] != 'pendiente') {
      throw Exception('Solo se pueden cancelar propuestas pendientes');
    }

    await _db.collection('intercambios').doc(intercambioId).update({
      'estado': 'cancelado',
      'fechaRespuesta': FieldValue.serverTimestamp(),
    });
  }

  // ─── MIS INTERCAMBIOS ENVIADOS ─────────────────────────────────────────────
  // Los que yo propuse a otros (yo soy el solicitante)
  Stream<QuerySnapshot> misIntercambiosEnviados() {
    final uid = _auth.currentUser?.uid;
    return _db
        .collection('intercambios')
        .where('solicitanteId', isEqualTo: uid)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // ─── MIS INTERCAMBIOS RECIBIDOS ────────────────────────────────────────────
  // Los que otros me enviaron a mí (yo soy el propietario)
  Stream<QuerySnapshot> misIntercambiosRecibidos() {
    final uid = _auth.currentUser?.uid;
    return _db
        .collection('intercambios')
        .where('propietarioId', isEqualTo: uid)
        .orderBy('fecha', descending: true)
        .snapshots();
  }
}