import 'package:flutter/material.dart';
import '../services/reportes_service.dart';

class ReporteScreen extends StatefulWidget {
  final String usuarioReportadoId;
  final String usuarioReportadoNombre;

  const ReporteScreen({
    super.key,
    required this.usuarioReportadoId,
    required this.usuarioReportadoNombre,
  });

  @override
  State<ReporteScreen> createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen> {
  final _reportesService = ReportesService();
  final _descripcionCtrl = TextEditingController();
  String? _motivoSeleccionado;
  bool _cargando = false;

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarReporte() async {
    if (_motivoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un motivo')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      await _reportesService.reportarUsuario(
        usuarioReportadoId: widget.usuarioReportadoId,
        motivo: _motivoSeleccionado!,
        descripcion: _descripcionCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte enviado. Gracias por avisar.'),
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
      appBar: AppBar(title: Text('Reportar usuario')),
body: SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
            Text(
              'Reportando a: ${widget.usuarioReportadoNombre}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text('Motivo del reporte:'),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _motivoSeleccionado,
              onChanged: (value) => setState(() => _motivoSeleccionado = value),
              child: Column(
                children: _reportesService.motivos
                    .map((motivo) => RadioListTile<String>(
                          title: Text(motivo),
                          value: motivo,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción adicional (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _cargando
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _enviarReporte,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: const Color(0xFF2D5A27),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Enviar reporte'),
                  ),
          ],
        ),
      ),
    );
  }
}