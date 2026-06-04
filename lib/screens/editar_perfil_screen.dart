import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/imagen_service.dart';

class EditarPerfilScreen extends StatefulWidget {
  final String nombreActual;
  final String bioActual;
  final String fotoActual;

  const EditarPerfilScreen({
    super.key,
    required this.nombreActual,
    this.bioActual = '',
    this.fotoActual = '',
  });

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _bioCtrl;
  bool _cargando = false;
  File? _imagenSeleccionada;
  String? _fotoUrl;
  final _picker = ImagePicker();
  final _imagenService = ImagenService();

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.nombreActual);
    _bioCtrl = TextEditingController(text: widget.bioActual);
    _fotoUrl = widget.fotoActual.isNotEmpty ? widget.fotoActual : null;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (imagen == null || !mounted) return;

    final File? recortada = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (_) => _CropScreen(imagePath: imagen.path),
      ),
    );

    if (recortada != null && mounted) {
      setState(() => _imagenSeleccionada = recortada);
    }
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre no puede estar vacío'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      String? nuevaFotoUrl = _fotoUrl;

      if (_imagenSeleccionada case final img?) {
        nuevaFotoUrl = await _imagenService.subirImagen(img);
      }

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .update({
        'nombre': nombre,
        'bio': _bioCtrl.text.trim(),
        'fotoUrl': ?nuevaFotoUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado ✅'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, {
        'nombre': nombre,
        'bio': _bioCtrl.text.trim(),
        'fotoUrl': nuevaFotoUrl ?? '',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
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
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2D5A27).withValues(alpha: 0.5)),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF2D5A27), Color(0xFF2D5A27)],
          ).createShader(bounds),
          child: Text(
            'Editar perfil',
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
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _seleccionarFoto,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2D5A27), Color(0xFF2D5A27)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: _imagenSeleccionada != null
                          ? Image.file(_imagenSeleccionada!,
                              fit: BoxFit.cover, width: 100, height: 100)
                          : _fotoUrl != null
                              ? Image.network(_fotoUrl!,
                                  fit: BoxFit.cover, width: 100, height: 100)
                              : Center(
                                  child: ValueListenableBuilder(
                                    valueListenable: _nombreCtrl,
                                    builder: (context, value, _) {
                                      final letra =
                                          _nombreCtrl.text.trim().isNotEmpty
                                              ? _nombreCtrl.text
                                                  .trim()[0]
                                                  .toUpperCase()
                                              : 'U';
                                      return Text(
                                        letra,
                                        style: TextStyle(
                                          color: Color(0xFF2D5A27),
                                          fontSize: 38,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF2D5A27), Color(0xFF2D5A27)]),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: const Color(0xFFEBE6D6), width: 2),
                      ),
                      child: Icon(Icons.camera_alt,
                          color: Color(0xFF2D5A27), size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca para cambiar foto',
              style: TextStyle(color: Color(0xFF2D5A27).withValues(alpha: 0.35), fontSize: 12),
            ),
            const SizedBox(height: 28),
            _buildTextField(
              controller: _nombreCtrl,
              label: 'Nombre completo',
              icon: Icons.person_outline,
              capitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _bioCtrl,
              label: 'Biografía',
              icon: Icons.info_outline,
              maxLines: 3,
              hint: 'Cuéntanos algo sobre ti...',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2D5A27), Color(0xFF2D5A27)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _cargando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Color(0xFFEBE6D6))
                      : Text(
                          'Guardar cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEBE6D6),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? hint,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: capitalization,
      style: TextStyle(color: Color(0xFF2D5A27)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Color(0xFF2D5A27).withValues(alpha: 0.35)),
        labelStyle: TextStyle(color: Color(0xFF2D5A27).withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Color(0xFF2D5A27).withValues(alpha: 0.35)),
        filled: true,
        fillColor: const Color(0xFFEBE6D6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2D5A27), width: 1.5),
        ),
      ),
    );
  }
}

// ── Pantalla de recorte circular ────────────────────────────────────────────
class _CropScreen extends StatefulWidget {
  final String imagePath;
  const _CropScreen({required this.imagePath});

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  ui.Image? _imagen;
  bool _procesando = false;
  double _scale = 1.0;
  double _baseScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _startOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _cargarImagen();
  }

  Future<void> _cargarImagen() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _imagen = frame.image);
  }

  Future<void> _confirmar() async {
    if (_imagen == null) return;
    setState(() => _procesando = true);

    try {
      const outputSize = 300.0;
      final screenSize = MediaQuery.of(context).size;
      final circleRadius = screenSize.width * 0.42;
      final circleCenterX = screenSize.width / 2;
      final circleCenterY = screenSize.height / 2;

      final srcW = _imagen!.width.toDouble();
      final srcH = _imagen!.height.toDouble();

      final baseImgScale = screenSize.width / srcW;
      final totalScale = baseImgScale * _scale;

      final renderedW = srcW * totalScale;
      final renderedH = srcH * totalScale;

      final imgLeft = (screenSize.width - renderedW) / 2 + _offset.dx;
      final imgTop = (screenSize.height - renderedH) / 2 + _offset.dy;

      final circleLeft = circleCenterX - circleRadius;
      final circleTop = circleCenterY - circleRadius;

      final srcLeft = (circleLeft - imgLeft) / totalScale;
      final srcTop = (circleTop - imgTop) / totalScale;
      final srcDiameter = (circleRadius * 2) / totalScale;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.clipPath(
        Path()..addOval(Rect.fromLTWH(0, 0, outputSize, outputSize)),
      );

      canvas.drawImageRect(
        _imagen!,
        Rect.fromLTWH(srcLeft, srcTop, srcDiameter, srcDiameter),
        Rect.fromLTWH(0, 0, outputSize, outputSize),
        Paint(),
      );

      final picture = recorder.endRecording();
      final img =
          await picture.toImage(outputSize.toInt(), outputSize.toInt());
      final pngBytes =
          await img.toByteData(format: ui.ImageByteFormat.png);

      final dir = await _getTempDir();
      final file = File('${dir.path}/avatar_crop.png');
      await file.writeAsBytes(pngBytes!.buffer.asUint8List());

      if (mounted) Navigator.pop(context, file);
    } catch (e) {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<Directory> _getTempDir() async {
    return Directory.systemTemp;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEBE6D6),
        leading: IconButton(
          icon: Icon(Icons.close, color: Color(0xFF2D5A27).withValues(alpha: 0.5)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Ajustar foto',
            style: TextStyle(color: Color(0xFF2D5A27), fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _procesando ? null : _confirmar,
            child: _procesando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Color(0xFF2D5A27), strokeWidth: 2),
                  )
                : ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFF2D5A27), Color(0xFF2D5A27)],
                    ).createShader(b),
                    child: Text(
                      'Usar',
                      style: TextStyle(
                        color: Color(0xFF2D5A27),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: _imagen == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D5A27)))
          : GestureDetector(
              onScaleStart: (details) {
                _baseScale = _scale;
                _startOffset = details.focalPoint - _offset;
              },
              onScaleUpdate: (details) {
                setState(() {
                  _scale = (_baseScale * details.scale).clamp(0.5, 5.0);
                  _offset = details.focalPoint - _startOffset;
                });
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Transform.translate(
                      offset: _offset,
                      child: Transform.scale(
                        scale: _scale,
                        child: Center(
                          child: Image.file(
                            File(widget.imagePath),
                            width: screenSize.width,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: CustomPaint(
                      size: Size(screenSize.width, screenSize.height),
                      painter: _CircleOverlayPainter(
                          screenSize.width, screenSize.height),
                    ),
                  ),
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Text(
                      'Mueve y pellizca para ajustar',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF2D5A27).withValues(alpha: 0.6), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CircleOverlayPainter extends CustomPainter {
  final double w, h;
  _CircleOverlayPainter(this.w, this.h);

  @override
  void paint(Canvas canvas, Size size) {
    final radius = w * 0.42;
    final center = Offset(w / 2, h / 2);

    final fullRect = Rect.fromLTWH(0, 0, w, h);
    final circlePath =
        Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    final overlay = Path.combine(
        PathOperation.difference, Path()..addRect(fullRect), circlePath);

    canvas.drawPath(
        overlay, Paint()..color = Colors.black.withValues(alpha: 0.6));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Color(0xFF2D5A27).withValues(alpha: 0.5)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}