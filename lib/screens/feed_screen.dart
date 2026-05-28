import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/publicaciones_service.dart';
import 'crear_publicacion_screen.dart';
import 'perfil_screen.dart';
import 'detalle_publicacion_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _service = PublicacionesService();
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  final _searchController = TextEditingController();

  static const Color _magenta = Color(0xFFCC00FF);
  static const Color _cian = Color(0xFF00DDFF);
  static const Color _fondo = Color(0xFF0A0E1A);

  String? _categoriaSeleccionada;
  String _busqueda = '';

  final List<String> _categorias = [
    'Todos',
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refrescar() async {
    setState(() {});
  }

  Stream<QuerySnapshot> _getStream() {
    if (_categoriaSeleccionada != null && _categoriaSeleccionada != 'Todos') {
      return _service.obtenerPorCategoria(_categoriaSeleccionada!);
    }
    return _service.obtenerPublicaciones();
  }

  @override
  Widget build(BuildContext context) {
    final miId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1422),
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_magenta, _cian],
          ).createShader(bounds),
          child: const Text(
            'BarterApp',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white54),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerfilScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => _busqueda = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar publicaciones...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _busqueda = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF0F1422),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _cian, width: 1.5),
                ),
              ),
            ),
          ),

          // Filtros de categoría
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final cat = _categorias[index];
                final seleccionada = _categoriaSeleccionada == cat ||
                    (cat == 'Todos' && _categoriaSeleccionada == null);
                return GestureDetector(
                  onTap: () => setState(() {
                    _categoriaSeleccionada = cat == 'Todos' ? null : cat;
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: seleccionada
                          ? const LinearGradient(colors: [_magenta, _cian])
                          : null,
                      color: seleccionada ? null : const Color(0xFF0F1422),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: seleccionada ? Colors.transparent : Colors.white12,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: seleccionada ? Colors.white : Colors.white54,
                          fontSize: 13,
                          fontWeight: seleccionada
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Lista de publicaciones
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00DDFF)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return RefreshIndicator(
                    key: _refreshKey,
                    onRefresh: _refrescar,
                    color: _cian,
                    backgroundColor: const Color(0xFF0F1422),
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [_magenta, _cian],
                                  ).createShader(bounds),
                                  child: const Icon(Icons.swap_horiz,
                                      size: 64, color: Colors.white),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No hay publicaciones',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filtrar por búsqueda local
                final publicaciones = snapshot.data!.docs.where((doc) {
                  if (_busqueda.isEmpty) return true;
                  final pub = doc.data() as Map<String, dynamic>;
                  final titulo = (pub['titulo'] ?? '').toLowerCase();
                  final descripcion = (pub['descripcion'] ?? '').toLowerCase();
                  return titulo.contains(_busqueda) ||
                      descripcion.contains(_busqueda);
                }).toList();

                if (publicaciones.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            color: Colors.white38, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Sin resultados para "$_busqueda"',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  key: _refreshKey,
                  onRefresh: _refrescar,
                  color: _cian,
                  backgroundColor: const Color(0xFF0F1422),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: publicaciones.length,
                    itemBuilder: (context, index) {
                      final pub = publicaciones[index].data()
                          as Map<String, dynamic>;
                      final pubId = publicaciones[index].id;
                      final fotoUrl = pub['fotoUrl'] ?? '';
                      final esElDueno = pub['userId'] == miId;

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, animation, __) =>
                                DetallePublicacionScreen(
                              pub: pub,
                              pubId: pubId,
                            ),
                            transitionsBuilder: (_, animation, __, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 300),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1422),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (fotoUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  child: Image.network(
                                    fotoUrl,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            pub['titulo'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (esElDueno)
                                          GestureDetector(
                                            onTap: () async {
                                              final confirmar =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  backgroundColor:
                                                      const Color(0xFF0F1422),
                                                  title: const Text(
                                                    'Eliminar publicación',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  content: const Text(
                                                    '¿Estás seguro?',
                                                    style: TextStyle(
                                                        color: Colors.white54),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child: const Text(
                                                          'Cancelar',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white54)),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child: const Text(
                                                          'Eliminar',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirmar == true) {
                                                await _service
                                                    .eliminarPublicacion(pubId);
                                              }
                                            },
                                            child: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 20),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      pub['descripcion'] ?? '',
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                            colors: [_magenta, _cian]),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        pub['categoria'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_magenta, _cian]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, __) =>
                  const CrearPublicacionScreen(),
              transitionsBuilder: (_, animation, __, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}