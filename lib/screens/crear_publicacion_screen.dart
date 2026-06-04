import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/publicaciones_service.dart';
import '../services/imagen_service.dart';

class CrearPublicacionScreen extends StatefulWidget {
  const CrearPublicacionScreen({super.key});

  @override
  State<CrearPublicacionScreen> createState() =>
      _CrearPublicacionScreenState();
}

class _CrearPublicacionScreenState extends State<CrearPublicacionScreen> {
  final _tituloCtrl       = TextEditingController();
  final _descripcionCtrl  = TextEditingController();
  final _publicacionesService = PublicacionesService();
  final _imagenService    = ImagenService();
  final _picker           = ImagePicker();

  String? _categoriaSeleccionada;
  File?   _imagenSeleccionada;
  bool    _cargando       = false;
  bool    _subiendoImagen = false;

  final List<Map<String, dynamic>> _categorias = [
    {'label': 'Electrónica',       'icon': Icons.devices_outlined},
    {'label': 'Ropa y accesorios', 'icon': Icons.checkroom_outlined},
    {'label': 'Hogar',             'icon': Icons.house_outlined},
    {'label': 'Deportes',          'icon': Icons.sports_soccer_outlined},
    {'label': 'Libros',            'icon': Icons.menu_book_outlined},
    {'label': 'Juguetes',          'icon': Icons.toys_outlined},
    {'label': 'Herramientas',      'icon': Icons.build_outlined},
    {'label': 'Otros',             'icon': Icons.category_outlined},
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
    final titulo      = _tituloCtrl.text.trim();
    final descripcion = _descripcionCtrl.text.trim();

    if (titulo.isEmpty || descripcion.isEmpty ||
        _categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Completa todos los campos y selecciona una categoría'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
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
        titulo:      titulo,
        descripcion: descripcion,
        categoria:   _categoriaSeleccionada!,
        fotoUrl:     fotoUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('¡Publicación creada! 🎉'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al publicar: $e'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
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
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF2D5A27).withValues(alpha: 0.5), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nueva publicación',
          style: TextStyle(
            color: Color(0xFF2D5A27),
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBE6D6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _imagenSeleccionada != null
                        ? const Color(0xFF2D5A27)
                        : Color(0xFF2D5A27).withValues(alpha: 0.1),
                    width: _imagenSeleccionada != null ? 1.5 : 1,
                  ),
                ),
                child: _imagenSeleccionada != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_imagenSeleccionada!,
                                fit: BoxFit.cover),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBE6D6)
                                      .withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit_outlined,
                                        color: Color(0xFF2D5A27),
                                        size: 14),
                                    SizedBox(width: 4),
                                    Text('Cambiar',
                                        style: TextStyle(
                                            color: Color(0xFF2D5A27),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 44, color: Color(0xFF2D5A27)),
                          SizedBox(height: 10),
                          Text(
                            'Agregar foto (opcional)',
                            style: TextStyle(
                                color: Color(0xFF2D5A27).withValues(alpha: 0.35), fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Toca para seleccionar',
                            style: TextStyle(
                                color: Color(0xFF2D5A27).withValues(alpha: 0.35), fontSize: 12),
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
              icon: Icons.title_rounded,
            ),
            const SizedBox(height: 14),

            // Descripción
            _buildTextField(
              controller: _descripcionCtrl,
              label: 'Descripción',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 14),

            // Categoría dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEBE6D6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Color(0xFF2D5A27).withValues(alpha: 0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _categoriaSeleccionada,
                  dropdownColor: const Color(0xFFEBE6D6),
                  hint: Row(children: [
                    Icon(Icons.category_outlined,
                        color: Color(0xFF2D5A27).withValues(alpha: 0.5), size: 20),
                    SizedBox(width: 12),
                    Text('Selecciona una categoría',
                        style: TextStyle(color: Color(0xFF2D5A27).withValues(alpha: 0.35))),
                  ]),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF2D5A27).withValues(alpha: 0.35)),
                  items: _categorias.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['label'] as String,
                      child: Row(
                        children: [
                          Icon(cat['icon'] as IconData,
                              color: Color(0xFF2D5A27).withValues(alpha: 0.5), size: 18),
                          const SizedBox(width: 12),
                          Text(cat['label'] as String,
                              style:
                                  TextStyle(color: Color(0xFF2D5A27))),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _categoriaSeleccionada = val),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botón publicar
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _cargando ? null : _publicar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5A27),
                  foregroundColor: const Color(0xFFEBE6D6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _cargando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Color(0xFFEBE6D6),
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _subiendoImagen
                            ? 'Subiendo imagen...'
                            : 'Publicar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
      style: TextStyle(color: Color(0xFF2D5A27)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF2D5A27).withValues(alpha: 0.35)),
        prefixIcon: Icon(icon, color: Color(0xFF2D5A27).withValues(alpha: 0.5), size: 20),
        filled: true,
        fillColor: const Color(0xFFEBE6D6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFF2D5A27).withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Color(0xFF2D5A27), width: 1.5),
        ),
      ),
    );
  }
}