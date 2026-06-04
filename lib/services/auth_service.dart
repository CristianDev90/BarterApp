import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Logger _logger = Logger();

  AuthService();

  // Stream para escuchar cambios de sesión en tiempo real
  Stream<User?> get estadoAuth => _auth.authStateChanges();

  // Usuario actual
  User? get usuarioActual => _auth.currentUser;

  // ─── REGISTRO ────────────────────────────────────────────────────────────────
  Future<void> registrar(String nombre, String email, String password) async {
    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        final token = await _messaging.getToken();
        await _db.collection('usuarios').doc(cred.user!.uid).set({
          'nombre': nombre,
          'email': email,
          'fecha_registro': FieldValue.serverTimestamp(),
          'fcm_token': token ?? '',
        });
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      _logger.e('Error al registrar: $e');
      rethrow;
    }
  }

  // ─── LOGIN ────────────────────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    try {
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        final token = await _messaging.getToken();
        await _db.collection('usuarios').doc(cred.user!.uid).update({
          'fcm_token': token ?? '',
          'ultimo_login': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      _logger.e('Error al iniciar sesión: $e');
      rethrow;
    }
  }

  // ─── LOGOUT ───────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _db.collection('usuarios').doc(userId).update({
          'fcm_token': '',
        });
      }
      await _auth.signOut();
    } catch (e) {
      _logger.e('Error al cerrar sesión: $e');
      rethrow;
    }
  }

  // ─── RESTABLECER CONTRASEÑA ───────────────────────────────────────────────────
  Future<void> restablecerContrasena(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      _logger.e('Error al restablecer contraseña: $e');
      rethrow;
    }
  }

  // ─── TRADUCIR ERRORES ─────────────────────────────────────────────────────────
  String traducirError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      default:
        return 'Ocurrió un error. Intenta de nuevo.';
    }
  }
}