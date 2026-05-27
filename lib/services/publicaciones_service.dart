import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PublicacionesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Crear una publicación nueva
  Future<void> crearPublicacion({
    required String titulo,
    required String descripcion,
    required String categoria,
    String? fotoUrl,
  }) async {
    final userId = _auth.currentUser!.uid;
    await _db.collection('publicaciones').add({
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoria,
      'userId': userId,
      'fotoUrl': fotoUrl ?? '',
      'fecha': FieldValue.serverTimestamp(),
      'activa': true,
    });
  }

  // Obtener todas las publicaciones en tiempo real
  Stream<QuerySnapshot> obtenerPublicaciones() {
    return _db
        .collection('publicaciones')
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // Eliminar una publicación
  Future<void> eliminarPublicacion(String publicacionId) async {
    await _db.collection('publicaciones').doc(publicacionId).delete();
  }
}