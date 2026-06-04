import 'package:flutter/material.dart';
import '../services/reputacion_service.dart';

class CalificacionScreen extends StatefulWidget {
  final String paraUserId;
  final String nombreUsuario;
  final String propuestaId; // NUEVO

  const CalificacionScreen({
    super.key,
    required this.paraUserId,
    required this.nombreUsuario,
    required this.propuestaId, // NUEVO
  });

  @override
  State<CalificacionScreen> createState() => _CalificacionScreenState();
}

class _CalificacionScreenState extends State<CalificacionScreen> {
  final _comentarioCtrl = TextEditingController();
  final _reputacionService = ReputacionService();
  double _puntuacion = 3;
  bool _cargando = false;

  static const Color _magenta = Color(0xFFCC00FF);
  static const Color _cian = Color(0xFF00DDFF);
  static const Color _fondo = Color(0xFF0A0E1A);

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarCalificacion() async {
    if (_comentarioCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un comentario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      final yaCalifique =
          await _reputacionService.yaCalifique(widget.propuestaId); // CAMBIADO

      if (yaCalifique) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya calificaste este trueque'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await _reputacionService.calificarUsuario(
        paraUserId: widget.paraUserId,
        puntuacion: _puntuacion,
        comentario: _comentarioCtrl.text.trim(),
        propuestaId: widget.propuestaId, // NUEVO
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('┬íCalificaci├│n enviada! Ô¡É'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... igual que antes, no cambia nada visual
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEBE6D6),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2D5A27).withValues(alpha: 0.5)),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_magenta, _cian],
          ).createShader(bounds),
          child: Text(
            'Calificar usuario',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF2D5A27),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEBE6D6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF2D5A27).withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_magenta, _cian],
                    ).createShader(bounds),
                    child: Icon(Icons.person, size: 40, color: Color(0xFF2D5A27)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '┬┐C├│mo fue tu experiencia con',
                    style: TextStyle(color: Color(0xFF2D5A27).withValues(alpha: 0.5), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.nombreUsuario,
                    style: TextStyle(
                      color: Color(0xFF2D5A27),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Puntuaci├│n',
              style: TextStyle(
                color: Color(0xFF2D5A27).withValues(alpha: 0.7),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _puntuacion = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      index < _puntuacion
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: index < _puntuacion ? Colors.amber : Color(0xFF2D5A27).withValues(alpha: 0.2),
                      size: 48,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),
            Text(
              'Comentario',
              style: TextStyle(
                color: Color(0xFF2D5A27).withValues(alpha: 0.7),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comentarioCtrl,
              maxLines: 4,
              style: TextStyle(color: Color(0xFF2D5A27)),
              decoration: InputDecoration(
                hintText: '┬┐C├│mo fue el trueque? ┬┐Lleg├│ en buen estado?',
                hintStyle: TextStyle(color: Color(0xFF2D5A27).withValues(alpha: 0.2), fontSize: 13),
                filled: true,
                fillColor: Color(0xFF2D5A27).withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _cian, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_magenta, _cian]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _cargando ? null : _enviarCalificacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Color(0xFF2D5A27))
                      : Text(
                          'Enviar calificaci├│n',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D5A27),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
