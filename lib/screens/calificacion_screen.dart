import 'package:flutter/material.dart';
import '../services/reputacion_service.dart';

class CalificacionScreen extends StatefulWidget {
  final String paraUserId;
  final String nombreUsuario;

  const CalificacionScreen({
    super.key,
    required this.paraUserId,
    required this.nombreUsuario,
  });

  @override
  State<CalificacionScreen> createState() => _CalificacionScreenState();
}

class _CalificacionScreenState extends State<CalificacionScreen> {
  final _comentarioCtrl = TextEditingController();
  final _reputacionService = ReputacionService();
  double _puntuacion = 3;
  bool _cargando = false;

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarCalificacion() async {
    if (_comentarioCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un comentario')));
      return;
    }

    setState(() => _cargando = true);
    try {
      // Verificar si ya calificó
      final yaCalifique = await _reputacionService.yaCalifique(widget.paraUserId);
      if (yaCalifique) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya calificaste a este usuario')));
        return;
      }

      await _reputacionService.calificarUsuario(
        paraUserId: widget.paraUserId,
        puntuacion: _puntuacion,
        comentario: _comentarioCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Calificación enviada!')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Calificar a ${widget.nombreUsuario}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Puntuación:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _puntuacion ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () => setState(() => _puntuacion = index + 1),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text('Comentario:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '¿Cómo fue tu experiencia con este usuario?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _enviarCalificacion,
                    child: const Text('Enviar calificación')),
            ),
          ],
        ),
      ),
    );
  }
}