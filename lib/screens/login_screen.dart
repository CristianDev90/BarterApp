import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'registro_screen.dart';
import 'feed_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading     = false;
  bool _verPassword = false;
  bool _canLogin    = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateCanLogin);
    _passwordController.addListener(_updateCanLogin);
  }

  void _updateCanLogin() {
    setState(() {
      _canLogin = _emailController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await widget.authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // ── CAMBIO: después del login exitoso, navegar al Feed y limpiar la pila ──
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const FeedScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.authService.traducirError(e)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _mostrarDialogoRestablecer() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFEBE6D6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restablecer contraseña',
            style: TextStyle(color: Color(0xFF2D5A27))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
              style: TextStyle(color: const Color(0xFF2D5A27).withValues(alpha: 0.35), fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: emailCtrl,
              label: 'Correo electrónico',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(color: const Color(0xFF2D5A27).withValues(alpha: 0.35))),
          ),
          TextButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(context);
              try {
                await widget.authService.restablecerContrasena(email);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Correo enviado. Revisa tu bandeja.'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ));
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(widget.authService.traducirError(e)),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Enviar',
                style: TextStyle(
                    color: Color(0xFF2D5A27),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBE6D6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBE6D6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2D5A27).withValues(alpha: 0.08), width: 1.5),
                ),
                child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 46)),
                ),
              ),
              const SizedBox(height: 20),

              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Barter',
                      style: TextStyle(
                        color: Color(0xFF2D5A27),
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: 'App',
                      style: TextStyle(
                        color: Color(0xFF2D5A27),
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Intercambia lo que no usas',
                style: TextStyle(color: const Color(0xFF2D5A27).withValues(alpha: 0.35), fontSize: 14),
              ),
              const SizedBox(height: 48),

              _buildTextField(
                controller: _emailController,
                label: 'Correo electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              _buildTextField(
                controller: _passwordController,
                label: 'Contraseña',
                icon: Icons.lock_outline,
                obscureText: !_verPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _verPassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF2D5A27).withValues(alpha: 0.35),
                  ),
                  onPressed: () =>
                      setState(() => _verPassword = !_verPassword),
                ),
              ),
              const SizedBox(height: 6),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _mostrarDialogoRestablecer,
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(color: const Color(0xFF2D5A27).withValues(alpha: 0.35), fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Botón iniciar sesión
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canLogin && !_loading ? _login : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canLogin
                        ? const Color(0xFF2D5A27)
                        : const Color(0xFFEBE6D6),
                    foregroundColor: const Color(0xFFEBE6D6),
                    disabledBackgroundColor: const Color(0xFFEBE6D6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Color(0xFFEBE6D6),
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿No tienes cuenta?',
                      style: TextStyle(color: const Color(0xFF2D5A27).withValues(alpha: 0.35))),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RegistroScreen(authService: widget.authService),
                      ),
                    ),
                    child: const Text(
                      'Regístrate',
                      style: TextStyle(
                        color: Color(0xFF2D5A27),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
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
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF2D5A27)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: const Color(0xFF2D5A27).withValues(alpha: 0.35)),
        prefixIcon: Icon(icon, color: const Color(0xFF2D5A27).withValues(alpha: 0.5), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFEBE6D6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: const Color(0xFF2D5A27).withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2D5A27), width: 1.5),
        ),
      ),
    );
  }
}
