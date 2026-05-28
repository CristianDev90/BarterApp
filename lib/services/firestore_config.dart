import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreConfig {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Configuración de caché offline
  static Future<void> configurar() async {
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Obtener publicaciones por categoría
  static Stream<QuerySnapshot> publicacionesPorCategoria(String categoria) {
    return _db
        .collection('publicaciones')
        .where('categoria', isEqualTo: categoria)
        .where('activa', isEqualTo: true)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // Obtener publicaciones de un usuario
  static Stream<QuerySnapshot> publicacionesDeUsuario(String userId) {
    return _db
        .collection('publicaciones')
        .where('userId', isEqualTo: userId)
        .where('activa', isEqualTo: true)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // Paginación — cargar de 10 en 10
  static Query publicacionesPaginadas({DocumentSnapshot? ultimoDocumento}) {
    Query query = _db
        .collection('publicaciones')
        .where('activa', isEqualTo: true)
        .orderBy('fecha', descending: true)
        .limit(10);

    if (ultimoDocumento != null) {
      query = query.startAfterDocument(ultimoDocumento);
    }
    return query;
  }
}