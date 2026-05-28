import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/publicaciones_service.dart';
import 'crear_publicacion_screen.dart';
import 'perfil_screen.dart';
import 'detalle_publicacion_screen.dart';
import 'intercambios_screen.dart';
 
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
 
  // ── BUG 4: lista de usuarios bloqueados ─────────────────────────────────
  List<String> _bloqueados = [];
  StreamSubscription? _bloqueoSub;
 
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
  void initState() {
    super.initState();
    _escucharBloqueados();
  }
 
  // ── BUG 4: escuchar en tiempo real la lista de bloqueados ────────────────
  void _escucharBloqueados() {
    final miId = FirebaseAuth.instance.currentUser?.uid;
    if (miId == null) return;
    _bloqueoSub = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(miId)
        .collection('bloqueados')
        .snapshots()
        .listen((snap) {
      if (mounted) {
        setState(() {
          _bloqueados = snap.docs.map((d) => d.id).toList();
        });
      }
    });
  }
 
  @override
  void dispose() {
    _searchController.dispose();
    _bloqueoSub?.cancel();
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
          // ── BUG 2: burbuja de notificaciones en intercambios ─────────────
          StreamBuilder<QuerySnapshot>(
            stream: miId == null
                ? const Stream.empty()
                : FirebaseFirestore.instance
                    .collection('intercambios')
                    .where('para_userId', isEqualTo: miId)
                    .where('estado', isEqualTo: 'pendiente')
                    .snapshots(),
            builder: (context, snap) {
              final pendientes = snap.data?.docs.length ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, color: Colors.white54),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const IntercambiosScreen()),
                    ),
                  ),
                  if (pendientes > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: const Color(0xFF0F1422), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            pendientes > 9 ? '9+' : '$pendientes',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) =>
                  setState(() => _busqueda = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar publicaciones...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white38),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: seleccionada
                          ? const LinearGradient(
                              colors: [_magenta, _cian])
                          : null,
                      color: seleccionada
                          ? null
                          : const Color(0xFF0F1422),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: seleccionada
                            ? Colors.transparent
                            : Colors.white12,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: seleccionada
                              ? Colors.white
                              : Colors.white54,
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
 
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8),
                    itemCount: 4,
                    itemBuilder: (_, __) => const _SkeletonCard(),
                  );
                }
 
                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return RefreshIndicator(
                    key: _refreshKey,
                    onRefresh: _refrescar,
                    color: _cian,
                    backgroundColor: const Color(0xFF0F1422),
                    child: ListView(
                      children: [
                        SizedBox(
                          height:
                              MediaQuery.of(context).size.height *
                                  0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color:
                                        const Color(0xFF0F1422),
                                    borderRadius:
                                        BorderRadius.circular(55),
                                    border: Border.all(
                                        color: Colors.white10),
                                  ),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                      colors: [_magenta, _cian],
                                    ).createShader(bounds),
                                    child: const Icon(
                                        Icons.swap_horiz,
                                        size: 52,
                                        color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [_magenta, _cian],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'Sin publicaciones aún',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Sé el primero en publicar\nalgo para intercambiar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 32),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient:
                                        const LinearGradient(
                                            colors: [
                                          _magenta,
                                          _cian
                                        ]),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const CrearPublicacionScreen()),
                                    ),
                                    style:
                                        ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.transparent,
                                      shadowColor:
                                          Colors.transparent,
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add,
                                        color: Colors.white),
                                    label: const Text(
                                      'Crear publicación',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
 
                // ── BUG 4: filtrar publicaciones de bloqueados ───────────
                final publicaciones =
                    snapshot.data!.docs.where((doc) {
                  final pub =
                      doc.data() as Map<String, dynamic>;
                  final userId =
                      pub['userId'] as String? ?? '';
                  // Ocultar publicaciones de usuarios bloqueados
                  if (_bloqueados.contains(userId)) return false;
                  if (_busqueda.isEmpty) return true;
                  final titulo =
                      (pub['titulo'] ?? '').toLowerCase();
                  final descripcion =
                      (pub['descripcion'] ?? '').toLowerCase();
                  return titulo.contains(_busqueda) ||
                      descripcion.contains(_busqueda);
                }).toList();
 
                if (publicaciones.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1422),
                            borderRadius:
                                BorderRadius.circular(45),
                            border: Border.all(
                                color: Colors.white10),
                          ),
                          child: const Icon(Icons.search_off,
                              color: Colors.white24, size: 40),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Sin resultados para\n"$_busqueda"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _busqueda = '');
                          },
                          child: const Text(
                            'Limpiar búsqueda',
                            style: TextStyle(
                                color: Color(0xFF00DDFF)),
                          ),
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 8),
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
                            transitionsBuilder:
                                (_, animation, __, child) =>
                                    FadeTransition(
                                        opacity: animation,
                                        child: child),
                            transitionDuration: const Duration(
                                milliseconds: 300),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1422),
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              if (fotoUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius:
                                      const BorderRadius.vertical(
                                          top: Radius.circular(
                                              16)),
                                  child: Image.network(
                                    fotoUrl,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              Padding(
                                padding:
                                    const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            pub['titulo'] ?? '',
                                            style:
                                                const TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (esElDueno)
                                          GestureDetector(
                                            onTap: () async {
                                              final confirmar =
                                                  await showDialog<
                                                      bool>(
                                                context: context,
                                                builder: (_) =>
                                                    AlertDialog(
                                                  backgroundColor:
                                                      const Color(
                                                          0xFF0F1422),
                                                  title: const Text(
                                                      'Eliminar publicación',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .white)),
                                                  content: const Text(
                                                      '¿Estás seguro?',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .white54)),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context,
                                                              false),
                                                      child: const Text(
                                                          'Cancelar',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white54)),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context,
                                                              true),
                                                      child: const Text(
                                                          'Eliminar',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .red)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirmar ==
                                                  true) {
                                                await _service
                                                    .eliminarPublicacion(
                                                        pubId);
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
                                          color: Colors.white60,
                                          fontSize: 14),
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient:
                                            const LinearGradient(
                                                colors: [
                                          _magenta,
                                          _cian
                                        ]),
                                        borderRadius:
                                            BorderRadius.circular(
                                                20),
                                      ),
                                      child: Text(
                                        pub['categoria'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.bold,
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
          gradient:
              const LinearGradient(colors: [_magenta, _cian]),
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
              transitionDuration:
                  const Duration(milliseconds: 300),
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
 
// ── Skeleton Card ────────────────────────────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();
 
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}
 
class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
 
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }
 
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final color = Color.lerp(
          const Color(0xFF0F1422),
          const Color(0xFF1E2440),
          _anim.value,
        )!;
 
        return Container(
          margin:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1422),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  color: color,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 180,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 80,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}