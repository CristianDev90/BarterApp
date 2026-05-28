import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class RegistroScreen extends StatefulWidget {
  final AuthService authService;
  const RegistroScreen({super.key, required this.authService});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _cargando = false;
  bool _verPassword = false;

  static const Color _magenta = Color(0xFFCC00FF);
  static const Color _cian = Color(0xFF00DDFF);
  static const Color _fondo = Color(0xFF0A0E1A);

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirmar = _confirmarCtrl.text.trim();

    if (nombre.isEmpty || email.isEmpty || password.isEmpty) {
      _mostrarError('Por favor, completa todos los campos');
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      _mostrarError('Ingresa un correo válido');
      return;
    }

    if (password.length < 6) {
      _mostrarError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    if (password != confirmar) {
      _mostrarError('Las contraseñas no coinciden');
      return;
    }

    setState(() => _cargando = true);

    try {
      await widget.authService.registrar(nombre, email, password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada exitosamente! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _mostrarError(widget.authService.traducirError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_magenta, _cian],
                ).createShader(bounds),
                child: const Text(
                  'Crear cuenta',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Únete y empieza a intercambiar',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 36),

              _buildTextField(
                controller: _nombreCtrl,
                label: 'Nombre completo',
                icon: Icons.person_outline,
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailCtrl,
                label: 'Correo electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _passwordCtrl,
                label: 'Contraseña',
                icon: Icons.lock_outline,
                obscureText: !_verPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _verPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38,
                  ),
                  onPressed: () => setState(() => _verPassword = !_verPassword),
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _confirmarCtrl,
                label: 'Confirmar contraseña',
                icon: Icons.lock_outline,
                obscureText: !_verPassword,
              ),
              const SizedBox(height: 36),

              SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_magenta, _cian]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _registrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _cargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Registrarse',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _cian, width: 1.5),
        ),
      ),
    );
  }
}