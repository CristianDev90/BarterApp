import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BackupService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Exportar datos del usuario actual como JSON
  static Future<Map<String, dynamic>> exportarDatosUsuario() async {
    final userId = _auth.currentUser!.uid;
    final Map<String, dynamic> backup = {};

    // Exportar perfil
    final perfilDoc = await _db.collection('usuarios').doc(userId).get();
    backup['perfil'] = perfilDoc.data();

    // Exportar publicaciones
    final publicaciones = await _db
        .collection('publicaciones')
        .where('userId', isEqualTo: userId)
        .get();
    backup['publicaciones'] = publicaciones.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();

    // Exportar propuestas enviadas
    final propuestas = await _db
        .collection('propuestas')
        .where('de_userId', isEqualTo: userId)
        .get();
    backup['propuestas'] = propuestas.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();

    backup['fecha_backup'] = DateTime.now().toIso8601String();
    backup['userId'] = userId;

    return backup;
  }

  // Convertir backup a JSON string
  static Future<String> obtenerBackupJson() async {
    final datos = await exportarDatosUsuario();
    return jsonEncode(datos);
  }
}