import 'dart:io';
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

  static const Color _magenta = Color(0xFFCC00FF);
  static const Color _cian = Color(0xFF00DDFF);
  static const Color _fondo = Color(0xFF0A0E1A);

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
      imageQuality: 80,
    );
    if (imagen != null) {
      setState(() => _imagenSeleccionada = File(imagen.path));
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

      if (_imagenSeleccionada != null) {
        nuevaFotoUrl = await _imagenService.subirImagen(_imagenSeleccionada!);
      }

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .update({
        'nombre': nombre,
        'bio': _bioCtrl.text.trim(),
        if (nuevaFotoUrl != null) 'fotoUrl': nuevaFotoUrl,
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
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1422),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_magenta, _cian],
          ).createShader(bounds),
          child: const Text(
            'Editar perfil',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar con botón de cambiar foto
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
                        colors: [_magenta, _cian],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: _imagenSeleccionada != null
                          ? Image.file(_imagenSeleccionada!,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100)
                          : _fotoUrl != null
                              ? Image.network(_fotoUrl!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100)
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
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 38,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ),
                  // Ícono de cámara
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [_magenta, _cian]),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: const Color(0xFF0A0E1A), width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toca para cambiar foto',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 28),

            // Campo nombre
            _buildTextField(
              controller: _nombreCtrl,
              label: 'Nombre completo',
              icon: Icons.person_outline,
              capitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Campo biografía
            _buildTextField(
              controller: _bioCtrl,
              label: 'Biografía',
              icon: Icons.info_outline,
              maxLines: 3,
              hint: 'Cuéntanos algo sobre ti...',
            ),
            const SizedBox(height: 32),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_magenta, _cian]),
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Guardar cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38),
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