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
      } catch (e) {
        _logger.e('Error al registrar: $e');
        rethrow;
      }
    }

    // Iniciar sesión
    Future<void> login(String email, String password) async {
      try {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      } catch (e) {
        _logger.e('Error al iniciar sesión: $e');
        rethrow;
      }
    }

    // Cerrar sesión
    Future<void> logout() async {
      try {
        await _auth.signOut();
      } catch (e) {
        _logger.e('Error al cerrar sesión: $e');
        rethrow;
      }
    }

    // Usuario actual
    User? get usuarioActual => _auth.currentUser;
    // Stream para escuchar cambios de sesión en tiempo real
Stream<User?> get estadoAuth => _auth.authStateChanges();

// Traducir errores de Firebase al español
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
    case 'too-many-requests':
      return 'Demasiados intentos. Espera un momento.';
    case 'network-request-failed':
      return 'Sin conexión a internet.';
    default:
      return 'Ocurrió un error. Intenta de nuevo.';
  }
}
  }
