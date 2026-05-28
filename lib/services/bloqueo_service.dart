import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BloqueoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Bloquear a un usuario
  Future<void> bloquearUsuario(String usuarioBloqueadoId) async {
    final miId = _auth.currentUser!.uid;

    if (miId == usuarioBloqueadoId) {
      throw Exception('No puedes bloquearte a ti mismo.');
    }

    await _db
        .collection('usuarios')
        .doc(miId)
        .collection('bloqueados')
        .doc(usuarioBloqueadoId)
        .set({
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  // Desbloquear a un usuario
  Future<void> desbloquearUsuario(String usuarioBloqueadoId) async {
    final miId = _auth.currentUser!.uid;

    await _db
        .collection('usuarios')
        .doc(miId)
        .collection('bloqueados')
        .doc(usuarioBloqueadoId)
        .delete();
  }

  // Verificar si tengo bloqueado a un usuario
  Future<bool> estaBloqueado(String usuarioId) async {
    final miId = _auth.currentUser!.uid;

    final doc = await _db
        .collection('usuarios')
        .doc(miId)
        .collection('bloqueados')
        .doc(usuarioId)
        .get();

    return doc.exists;
  }

  // Obtener lista de usuarios bloqueados
  Stream<QuerySnapshot> obtenerBloqueados() {
    final miId = _auth.currentUser!.uid;

    return _db
        .collection('usuarios')
        .doc(miId)
        .collection('bloqueados')
        .snapshots();
  }
}