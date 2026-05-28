import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReputacionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Calificar a un usuario
  Future<void> calificarUsuario({
    required String paraUserId,
    required double puntuacion,
    required String comentario,
  }) async {
    final deUserId = _auth.currentUser?.uid;
    if (deUserId == null) throw Exception('Usuario no autenticado');
    if (deUserId == paraUserId) throw Exception('No puedes calificarte a ti mismo');

    // Guardar calificación
    await _db.collection('calificaciones').add({
      'de_userId': deUserId,
      'para_userId': paraUserId,
      'puntuacion': puntuacion,
      'comentario': comentario,
      'fecha': FieldValue.serverTimestamp(),
    });

    // Actualizar promedio del usuario
    await _actualizarPromedio(paraUserId);
  }

  // Calcular y actualizar promedio
  Future<void> _actualizarPromedio(String userId) async {
    final calificaciones = await _db
        .collection('calificaciones')
        .where('para_userId', isEqualTo: userId)
        .get();

    if (calificaciones.docs.isEmpty) return;

    double total = 0;
    for (var doc in calificaciones.docs) {
      total += (doc.data()['puntuacion'] as num).toDouble();
    }

    final promedio = total / calificaciones.docs.length;

    await _db.collection('usuarios').doc(userId).update({
      'calificacion_promedio': promedio,
      'total_calificaciones': calificaciones.docs.length,
    });
  }

  // Obtener calificaciones de un usuario
  Stream<QuerySnapshot> obtenerCalificaciones(String userId) {
    return _db
        .collection('calificaciones')
        .where('para_userId', isEqualTo: userId)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // Verificar si ya calificaste a un usuario
  Future<bool> yaCalifique(String paraUserId) async {
    final deUserId = _auth.currentUser?.uid;
    if (deUserId == null) return false;

    final resultado = await _db
        .collection('calificaciones')
        .where('de_userId', isEqualTo: deUserId)
        .where('para_userId', isEqualTo: paraUserId)
        .get();

    return resultado.docs.isNotEmpty;
  }
}