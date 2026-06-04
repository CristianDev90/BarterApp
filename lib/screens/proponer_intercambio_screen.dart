import 'package:flutter/material.dart';
import '../services/intercambio_service.dart';

class ProponerIntercambioScreen extends StatefulWidget {
  final String publicacionId;      // ID de la publicación que le interesa
  final String propietarioId;      // ID del dueño de esa publicación
  final String tituloPub;          // Título de la publicación (para mostrarlo)

  const ProponerIntercambioScreen({
    super.key,
    required this.publicacionId,
    required this.propietarioId,
    required this.tituloPub,
  });

  @override
  State<ProponerIntercambioScreen> createState() =>
      _ProponerIntercambioScreenState();
}

class _ProponerIntercambioScreenState
    extends State<ProponerIntercambioScreen> {
  final _mensajeCtrl = TextEditingController();
  final _intercambioService = IntercambioService();
  bool _cargando = false;

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarPropuesta() async {
    final mensaje = _mensajeCtrl.text.trim();

    if (mensaje.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un mensaje para tu propuesta'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      await _intercambioService.proponerIntercambio(
        publicacionId: widget.publicacionId,
        propietarioId: widget.propietarioId,
        mensajePropuesta: mensaje,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Propuesta enviada! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBE6D6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEBE6D6),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color(0xFF2D5A27).withValues(alpha: 0.5),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Proponer trueque',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: const Color(0xFF2D5A27),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Tarjeta que muestra qué publicación quiere el usuario
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEBE6D6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF2D5A27).withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quieres intercambiar por:',
                    style: TextStyle(color: Color(0xFF2D5A27).withValues(alpha: 0.35), fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.tituloPub,
                    style: TextStyle(
                      color: Color(0xFF2D5A27),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Instrucción
            Text(
              'Cuéntale al dueño qué ofreces a cambio:',
              style: TextStyle(color: Color(0xFF2D5A27).withValues(alpha: 0.7), fontSize: 15),
            ),
            const SizedBox(height: 12),

            // Campo de mensaje
            TextField(
              controller: _mensajeCtrl,
              maxLines: 5,
              style: TextStyle(color: Color(0xFF2D5A27)),
              decoration: InputDecoration(
                hintText:
                    'Ej: Tengo una mochila azul casi nueva, te la cambio por tu chaqueta...',
                hintStyle: TextStyle(color: Color(0xFF2D5A27).withValues(alpha: 0.2), fontSize: 14),
                filled: true,
                fillColor: Color(0xFF2D5A27).withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFF2D5A27), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botón enviar
            SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5A27),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _cargando ? null : _enviarPropuesta,
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
                          'Enviar propuesta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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