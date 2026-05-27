import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  AuthService();

  // Registrar usuario nuevo
  Future<void> registrar(String nombre, String email, String password) async {
    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        await _db.collection('usuarios').doc(cred.user!.uid).set({
          'nombre': nombre,
          'email': email,
          'fecha_registro': FieldValue.serverTimestamp(),
        });
      }
    } catch (e, st) {
      _logger.e('Error al registrar', e, st);
      rethrow;
    }
  }

  // Iniciar sesión
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e, st) {
      _logger.e('Error al iniciar sesión', e, st);
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e, st) {
      _logger.e('Error al cerrar sesión', e, st);
      rethrow;
    }
  }

  // Usuario actual
  User? get usuarioActual => _auth.currentUser;
}
