import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../services/auth_service.dart';

class RegistroScreen extends StatefulWidget {
  final AuthService authService;
  const RegistroScreen({super.key, required this.authService});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _nombreCtrl    = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _cargando    = false;
  bool _verPassword = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final nombre    = _nombreCtrl.text.trim();
    final email     = _emailCtrl.text.trim();
    final password  = _passwordCtrl.text.trim();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('¡Cuenta creada exitosamente! 🎉'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _mostrarError(widget.authService.traducirError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textoS, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Crear cuenta',
                style: TextStyle(
                  color: AppColors.textoP,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Únete y empieza a intercambiar',
                style: TextStyle(color: AppColors.textoH, fontSize: 14),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                controller: _nombreCtrl,
                label: 'Nombre completo',
                icon: Icons.person_outline,
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _emailCtrl,
                label: 'Correo electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _passwordCtrl,
                label: 'Contraseña',
                icon: Icons.lock_outline,
                obscureText: !_verPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _verPassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textoH,
                  ),
                  onPressed: () =>
                      setState(() => _verPassword = !_verPassword),
                ),
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _confirmarCtrl,
                label: 'Confirmar contraseña',
                icon: Icons.lock_outline,
                obscureText: !_verPassword,
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _registrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.acento,
                    foregroundColor: AppColors.fondo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _cargando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.fondo,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Registrarse',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
      style: const TextStyle(color: AppColors.textoP),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textoH),
        prefixIcon: Icon(icon, color: AppColors.textoS, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.superficie,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.acento, width: 1.5),
        ),
      ),
    );
  }
}