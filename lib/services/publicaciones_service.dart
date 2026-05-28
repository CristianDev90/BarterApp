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

  // Todas las publicaciones activas ordenadas por fecha
  Stream<QuerySnapshot> obtenerPublicaciones() {
    return _db
        .collection('publicaciones')
        .where('activa', isEqualTo: true)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // Publicaciones filtradas por categoría
  Stream<QuerySnapshot> obtenerPorCategoria(String categoria) {
    return _db
        .collection('publicaciones')
        .where('activa', isEqualTo: true)
        .where('categoria', isEqualTo: categoria)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // Publicaciones del usuario actual
  Stream<QuerySnapshot> obtenerMisPublicaciones() {
    final userId = _auth.currentUser!.uid;
    return _db
        .collection('publicaciones')
        .where('userId', isEqualTo: userId)
        .where('activa', isEqualTo: true)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // Buscar publicaciones por título
  Future<List<QueryDocumentSnapshot>> buscarPorTitulo(String texto) async {
    final texto_lower = texto.toLowerCase();
    final resultado = await _db
        .collection('publicaciones')
        .where('activa', isEqualTo: true)
        .orderBy('titulo')
        .startAt([texto_lower])
        .endAt(['$texto_lower\uf8ff'])
        .get();
    return resultado.docs;
  }

  // Eliminar (desactivar) una publicación
  Future<void> eliminarPublicacion(String publicacionId) async {
    await _db
        .collection('publicaciones')
        .doc(publicacionId)
        .update({'activa': false});
  }

  // Obtener una publicación por ID
  Future<DocumentSnapshot> obtenerPublicacion(String publicacionId) async {
    return await _db.collection('publicaciones').doc(publicacionId).get();
  }
}