import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
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
  final _service        = PublicacionesService();
  final _refreshKey     = GlobalKey<RefreshIndicatorState>();
  final _searchController = TextEditingController();

  String? _categoriaSeleccionada;
  String  _busqueda = '';
  List<String> _bloqueados = [];
  StreamSubscription? _bloqueoSub;

  final List<Map<String, dynamic>> _categorias = [
    {'label': 'Todos',            'icon': Icons.eco_outlined},
    {'label': 'Electrónica',      'icon': Icons.devices_outlined},
    {'label': 'Ropa y accesorios','icon': Icons.checkroom_outlined},
    {'label': 'Hogar',            'icon': Icons.house_outlined},
    {'label': 'Deportes',         'icon': Icons.sports_soccer_outlined},
    {'label': 'Libros',           'icon': Icons.menu_book_outlined},
    {'label': 'Juguetes',         'icon': Icons.toys_outlined},
    {'label': 'Herramientas',     'icon': Icons.build_outlined},
    {'label': 'Otros',            'icon': Icons.category_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _escucharBloqueados();
  }

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

  Future<void> _refrescar() async => setState(() {});

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
      backgroundColor: AppColors.fondo,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.acento,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Text('🌿', style: TextStyle(fontSize: 17)),
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Barter',
                    style: TextStyle(
                      color: AppColors.textoP,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: 'App',
                    style: TextStyle(
                      color: AppColors.acentoClaro,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Intercambios con burbuja
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
                    icon: const Icon(Icons.swap_horiz_rounded,
                        color: AppColors.textoS),
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
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          color: AppColors.acento,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: AppColors.appBar, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            pendientes > 9 ? '9+' : '$pendientes',
                            style: const TextStyle(
                              color: AppColors.fondo,
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
            icon: const Icon(Icons.person_outline_rounded,
                color: AppColors.textoS),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerfilScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ── Body ────────────────────────────────────────────────────────────
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textoP),
              onChanged: (val) =>
                  setState(() => _busqueda = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar publicaciones...',
                hintStyle: const TextStyle(color: AppColors.textoH),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.acento, size: 20),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textoH, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _busqueda = '');
                        },
                      )
                    : const Padding(
                        padding: EdgeInsets.only(right: 14),
                        child: Text('🌱',
                            style: TextStyle(fontSize: 18)),
                      ),
                filled: true,
                fillColor: AppColors.superficie,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: const BorderSide(color: AppColors.borde),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: const BorderSide(
                      color: AppColors.acento, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Chips de categoría
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final cat = _categorias[index];
                final label = cat['label'] as String;
                final icon  = cat['icon'] as IconData;
                final seleccionada = _categoriaSeleccionada == label ||
                    (label == 'Todos' && _categoriaSeleccionada == null);
                return GestureDetector(
                  onTap: () => setState(() {
                    _categoriaSeleccionada =
                        label == 'Todos' ? null : label;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: seleccionada
                          ? AppColors.acento
                          : AppColors.superficie,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: seleccionada
                            ? AppColors.acento
                            : AppColors.bordeAlt,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            size: 14,
                            color: seleccionada
                                ? AppColors.fondo
                                : AppColors.textoS),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: TextStyle(
                            color: seleccionada
                                ? AppColors.fondo
                                : AppColors.textoS,
                            fontSize: 12,
                            fontWeight: seleccionada
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Lista de publicaciones
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: 4,
                    itemBuilder: (_, _) => const _SkeletonCard(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final publicaciones = snapshot.data!.docs.where((doc) {
                  final pub = doc.data() as Map<String, dynamic>;
                  final userId = pub['userId'] as String? ?? '';
                  if (_bloqueados.contains(userId)) return false;
                  if (_busqueda.isEmpty) return true;
                  final titulo      = (pub['titulo'] ?? '').toLowerCase();
                  final descripcion = (pub['descripcion'] ?? '').toLowerCase();
                  return titulo.contains(_busqueda) ||
                      descripcion.contains(_busqueda);
                }).toList();

                if (publicaciones.isEmpty) {
                  return _buildNoResults();
                }

                return RefreshIndicator(
                  key: _refreshKey,
                  onRefresh: _refrescar,
                  color: AppColors.acento,
                  backgroundColor: AppColors.superficie,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: publicaciones.length,
                    itemBuilder: (context, index) {
                      final pub = publicaciones[index].data()
                          as Map<String, dynamic>;
                      final pubId    = publicaciones[index].id;
                      final fotoUrl  = pub['fotoUrl'] ?? '';
                      final esElDueno = pub['userId'] == miId;

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, animation, _) =>
                                DetallePublicacionScreen(
                                    pub: pub, pubId: pubId),
                            transitionsBuilder:
                                (_, animation, _, child) =>
                                    FadeTransition(
                                        opacity: animation, child: child),
                            transitionDuration:
                                const Duration(milliseconds: 300),
                          ),
                        ),
                        child: _buildCard(
                          pub: pub,
                          pubId: pubId,
                          fotoUrl: fotoUrl,
                          esElDueno: esElDueno,
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

      // ── FAB + BottomNav ─────────────────────────────────────────────────
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.acento,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.acento.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, _) =>
                  const CrearPublicacionScreen(),
              transitionsBuilder: (_, animation, _, child) =>
                  SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOut)),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded,
              color: AppColors.fondo, size: 30),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.appBar,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Inicio',
                activo: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.swap_horiz_rounded,
                label: 'Trueques',
                activo: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const IntercambiosScreen()),
                ),
              ),
              const SizedBox(width: 48), // espacio FAB
              _NavItem(
                icon: Icons.notifications_outlined,
                label: 'Alertas',
                activo: false,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Perfil',
                activo: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PerfilScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tarjeta de publicación ───────────────────────────────────────────────
  Widget _buildCard({
    required Map<String, dynamic> pub,
    required String pubId,
    required String fotoUrl,
    required bool esElDueno,
  }) {
    final service = PublicacionesService();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        children: [
          // Imagen lado izquierdo
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20)),
            child: fotoUrl.isNotEmpty
                ? Image.network(
                    fotoUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 120,
                    height: 120,
                    color: AppColors.superficieAlt,
                    child: const Icon(Icons.image_outlined,
                        color: AppColors.textoH, size: 36),
                  ),
          ),
          // Info lado derecho
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          pub['titulo'] ?? '',
                          style: const TextStyle(
                            color: AppColors.textoP,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (esElDueno)
                        GestureDetector(
                          onTap: () async {
                            final confirmar = await _confirmarEliminar();
                            if (confirmar == true) {
                              await service.eliminarPublicacion(pubId);
                            }
                          },
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 18),
                        )
                      else
                        const Icon(Icons.favorite_border_rounded,
                            color: AppColors.textoH, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pub['descripcion'] ?? '',
                    style: const TextStyle(
                        color: AppColors.textoH, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.borde, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.superficieAlt,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: AppColors.bordeAlt),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.eco_outlined,
                                size: 11, color: AppColors.acentoClaro),
                            const SizedBox(width: 4),
                            Text(
                              pub['categoria'] ?? '',
                              style: const TextStyle(
                                color: AppColors.acentoClaro,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmarEliminar() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.superficie,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar publicación',
            style: TextStyle(color: AppColors.textoP)),
        content: const Text('¿Estás seguro?',
            style: TextStyle(color: AppColors.textoH)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textoH)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _refrescar,
      color: AppColors.acento,
      backgroundColor: AppColors.superficie,
      child: ListView(children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.superficie,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppColors.borde),
                  ),
                  child: const Center(
                    child: Text('🌿', style: TextStyle(fontSize: 46)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sin publicaciones aún',
                  style: TextStyle(
                    color: AppColors.textoP,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sé el primero en publicar\nalgo para intercambiar',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textoH, fontSize: 14),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CrearPublicacionScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.acento,
                    foregroundColor: AppColors.fondo,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Crear publicación',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.borde),
            ),
            child: const Icon(Icons.search_off_rounded,
                color: AppColors.textoH, size: 38),
          ),
          const SizedBox(height: 20),
          Text(
            'Sin resultados para\n"$_busqueda"',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textoS,
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _busqueda = '');
            },
            child: const Text('Limpiar búsqueda',
                style: TextStyle(color: AppColors.acentoClaro)),
          ),
        ],
      ),
    );
  }
}

// ── Nav item ────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: activo ? AppColors.acentoClaro : AppColors.textoH,
              size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: activo ? AppColors.acentoClaro : AppColors.textoH,
              fontSize: 10,
              fontWeight:
                  activo ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton card ───────────────────────────────────────────────────────────
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
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
      builder: (_, _) {
        final color = Color.lerp(
          AppColors.superficie,
          AppColors.superficieAlt,
          _anim.value,
        )!;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.superficie,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borde),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20)),
                child: Container(width: 120, height: 120, color: color),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(7)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 11,
                        width: 120,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(7)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 22,
                        width: 70,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}