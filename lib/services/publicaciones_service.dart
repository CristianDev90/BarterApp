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
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    await _db.collection('publicaciones').add({
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoria,
      'userId': user.uid,
      'fotoUrl': fotoUrl ?? '',
      'fecha': FieldValue.serverTimestamp(),
      'activa': true,
    });
  }

  // Obtener todas las publicaciones en tiempo real
  Stream<QuerySnapshot> obtenerPublicaciones() {
    return _db
        .collection('publicaciones')
        .where('activa', isEqualTo: true)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // Obtener publicaciones del usuario actual
  Stream<QuerySnapshot> misPublicaciones() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');
    return _db
        .collection('publicaciones')
        .where('userId', isEqualTo: userId)
        .where('activa', isEqualTo: true)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // Actualizar una publicación
  Future<void> actualizarPublicacion(
      String publicacionId, Map<String, dynamic> datos) async {
    await _db
        .collection('publicaciones')
        .doc(publicacionId)
        .update(datos);
  }

  // Eliminar una publicación (desactivar)
  Future<void> eliminarPublicacion(String publicacionId) async {
    await _db
        .collection('publicaciones')
        .doc(publicacionId)
        .update({'activa': false});
  }
}