import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reportar a un usuario
  Future<void> reportarUsuario({
    required String usuarioReportadoId,
    required String motivo,
    String? descripcion,
  }) async {
    final reportadorId = _auth.currentUser!.uid;

    // Evitar que un usuario se reporte a sí mismo
    if (reportadorId == usuarioReportadoId) {
      throw Exception('No puedes reportarte a ti mismo.');
    }

    // Verificar si ya reportó a este usuario
    final reporte = await _db
        .collection('reportes')
        .where('de_userId', isEqualTo: reportadorId)
        .where('para_userId', isEqualTo: usuarioReportadoId)
        .get();

    if (reporte.docs.isNotEmpty) {
      throw Exception('Ya reportaste a este usuario.');
    }

    await _db.collection('reportes').add({
      'de_userId': reportadorId,
      'para_userId': usuarioReportadoId,
      'motivo': motivo,
      'descripcion': descripcion ?? '',
      'fecha': FieldValue.serverTimestamp(),
      'revisado': false,
    });
  }

  // Obtener motivos disponibles
  List<String> get motivos => [
        'Comportamiento inapropiado',
        'Publicación falsa o engañosa',
        'Spam',
        'Acoso',
        'Contenido ofensivo',
        'Otro',
      ];
}