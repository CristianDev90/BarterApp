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
  String _categoriaSeleccionada = 'General';
  final _service = PublicacionesService();
  final _imagenService = ImagenService();
  bool _cargando = false;
  File? _imagenSeleccionada;

  final List<String> _categorias = [
    'General', 'Electrónica', 'Ropa',
    'Deportes', 'Hogar', 'Libros', 'Juguetes', 'Otros',
  ];

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() => _imagenSeleccionada = File(imagen.path));
    }
  }

  Future<void> _publicar() async {
    if (_tituloCtrl.text.isEmpty || _descripcionCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')));
      return;
    }
    setState(() => _cargando = true);
    try {
      String? fotoUrl;
      if (_imagenSeleccionada != null) {
        fotoUrl = await _imagenService.subirImagen(_imagenSeleccionada!);
      }
      await _service.crearPublicacion(
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        categoria: _categoriaSeleccionada,
        fotoUrl: fotoUrl,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Publicación creada!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Publicación')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Selector de imagen
          GestureDetector(
            onTap: _seleccionarImagen,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: _imagenSeleccionada != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imagenSeleccionada!, fit: BoxFit.cover))
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                      Text('Toca para agregar una foto', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tituloCtrl,
            decoration: const InputDecoration(labelText: 'Título del artículo'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descripcionCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _categoriaSeleccionada,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: _categorias.map((cat) =>
              DropdownMenuItem(value: cat, child: Text(cat))
            ).toList(),
            onChanged: (val) => setState(() => _categoriaSeleccionada = val!),
          ),
          const SizedBox(height: 24),
          _cargando
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _publicar,
                child: const Text('Publicar')),
        ]),
      ),
    );
  }
}