import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/publicaciones_service.dart';
import '../services/imagen_service.dart';

class CrearPublicacionScreen extends StatefulWidget {
  const CrearPublicacionScreen({super.key});

  @override
  State<CrearPublicacionScreen> createState() => _CrearPublicacionScreenState();
}

class _CrearPublicacionScreenState extends State<CrearPublicacionScreen> {
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _publicacionesService = PublicacionesService();
  final _imagenService = ImagenService();
  final _picker = ImagePicker();

  String? _categoriaSeleccionada;
  File? _imagenSeleccionada;
  bool _cargando = false;
  bool _subiendoImagen = false;

  static const Color _magenta = Color(0xFFCC00FF);
  static const Color _cian = Color(0xFF00DDFF);
  static const Color _fondo = Color(0xFF0A0E1A);

  final List<String> _categorias = [
    'Electrónica',
    'Ropa y accesorios',
    'Hogar',
    'Deportes',
    'Libros',
    'Juguetes',
    'Herramientas',
    'Otros',
  ];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (imagen != null) {
      setState(() => _imagenSeleccionada = File(imagen.path));
    }
  }

  Future<void> _publicar() async {
    final titulo = _tituloCtrl.text.trim();
    final descripcion = _descripcionCtrl.text.trim();

    if (titulo.isEmpty || descripcion.isEmpty || _categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos y selecciona una categoría'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      String? fotoUrl;

      if (_imagenSeleccionada != null) {
        setState(() => _subiendoImagen = true);
        fotoUrl = await _imagenService.subirImagen(_imagenSeleccionada!);
        setState(() => _subiendoImagen = false);
      }

      await _publicacionesService.crearPublicacion(
        titulo: titulo,
        descripcion: descripcion,
        categoria: _categoriaSeleccionada!,
        fotoUrl: fotoUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Publicación creada! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al publicar: $e'),
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
            'Nueva publicación',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de imagen
            GestureDetector(
              onTap: _seleccionarImagen,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1422),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: _imagenSeleccionada != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _imagenSeleccionada!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(colors: [_magenta, _cian])
                                    .createShader(bounds),
                            child: const Icon(Icons.add_photo_alternate_outlined,
                                size: 48, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Agregar foto (opcional)',
                            style: TextStyle(color: Colors.white38, fontSize: 14),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Título
            _buildTextField(
              controller: _tituloCtrl,
              label: 'Título del objeto',
              icon: Icons.title,
            ),
            const SizedBox(height: 16),

            // Descripción
            _buildTextField(
              controller: _descripcionCtrl,
              label: 'Descripción',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Categoría
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _categoriaSeleccionada,
                  dropdownColor: const Color(0xFF0F1422),
                  hint: const Text(
                    'Selecciona una categoría',
                    style: TextStyle(color: Colors.white54),
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
                  items: _categorias
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _categoriaSeleccionada = val),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botón publicar
            SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_magenta, _cian]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _cargando ? null : _publicar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _subiendoImagen ? 'Subiendo imagen...' : 'Publicar',
                          style: const TextStyle(
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
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