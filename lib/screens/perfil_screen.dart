import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/bloqueo_service.dart';
import '../services/publicaciones_service.dart';
import 'detalle_publicacion_screen.dart';
import 'editar_perfil_screen.dart';
import 'crear_publicacion_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _authService         = AuthService();
  final _publicacionesService = PublicacionesService();
  final _bloqueoService      = BloqueoService();
  final _user                = FirebaseAuth.instance.currentUser;

  String _nombre  = 'Usuario';
  String _email   = '';
  String _bio     = '';
  String _fotoUrl = '';
  bool   _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_user?.uid)
        .get();
    final data = doc.data();
    if (mounted) {
      setState(() {
        _nombre  = data?['nombre']  ?? 'Usuario';
        _email   = data?['email']   ?? _user?.email ?? '';
        _bio     = data?['bio']     ?? '';
        _fotoUrl = data?['fotoUrl'] ?? '';
        _cargando = false;
      });
    }
  }

  Future<void> _irAEditar() async {
    final resultado = await Navigator.push<Map<String, String>>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => EditarPerfilScreen(
          nombreActual: _nombre,
          bioActual:    _bio,
          fotoActual:   _fotoUrl,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    if (resultado != null && mounted) {
      setState(() {
        _nombre  = resultado['nombre']  ?? _nombre;
        _bio     = resultado['bio']     ?? _bio;
        _fotoUrl = resultado['fotoUrl'] ?? _fotoUrl;
      });
    }
  }

  Future<int> _contarTrueques() async {
    final uid = _user?.uid ?? '';
    if (uid.isEmpty) return 0;
    final recibidos = await FirebaseFirestore.instance
        .collection('propuestas')
        .where('para_userId', isEqualTo: uid)
        .where('estado', isEqualTo: 'aceptado')
        .get();
    final enviados = await FirebaseFirestore.instance
        .collection('propuestas')
        .where('de_userId', isEqualTo: uid)
        .where('estado', isEqualTo: 'aceptado')
        .get();
    return recibidos.docs.length + enviados.docs.length;
  }

  Future<void> _desbloquearUsuario(
      String usuarioId, String nombreUsuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.superficie,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('¿Desbloquear a $nombreUsuario?',
            style: const TextStyle(color: AppColors.textoP)),
        content: const Text(
          'Volverás a ver sus publicaciones y podrá contactarte.',
          style: TextStyle(color: AppColors.textoH),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textoH)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desbloquear',
                style: TextStyle(
                    color: AppColors.acentoClaro,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _bloqueoService.desbloquearUsuario(usuarioId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$nombreUsuario fue desbloqueado'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: AppColors.fondo,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.acento)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        elevation: 0,
        title: const Text('Mi Perfil',
            style: TextStyle(
                color: AppColors.textoP,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textoS),
            onPressed: _irAEditar,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textoS),
            onPressed: () async => await _authService.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // ── Avatar centrado ─────────────────────────────────────────
            Center(
              child: Column(children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.acento,
                    borderRadius: BorderRadius.circular(48),
                    border: Border.all(
                        color: AppColors.bordeAlt, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(48),
                    child: _fotoUrl.isNotEmpty
                        ? Image.network(_fotoUrl,
                            fit: BoxFit.cover,
                            width: 96,
                            height: 96)
                        : Center(
                            child: Text(
                              _nombre.isNotEmpty
                                  ? _nombre[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: AppColors.fondo,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(_nombre,
                    style: const TextStyle(
                        color: AppColors.textoP,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_email,
                    style: const TextStyle(
                        color: AppColors.textoH, fontSize: 13)),
                if (_bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textoS, fontSize: 13)),
                ],
              ]),
            ),
            const SizedBox(height: 28),

            // ── Stats row ───────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: FutureBuilder<int>(
                  future: _contarTrueques(),
                  builder: (context, snap) => _buildStatCard(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Trueques',
                    valor: '${snap.data ?? 0}',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('calificaciones')
                      .where('para_userId', isEqualTo: _user?.uid ?? '')
                      .snapshots(),
                  builder: (context, snap) {
                    double promedio = 0;
                    int total = 0;
                    if (snap.hasData && snap.data!.docs.isNotEmpty) {
                      total = snap.data!.docs.length;
                      double suma = 0;
                      for (final doc in snap.data!.docs) {
                        suma += (doc['puntuacion'] as num).toDouble();
                      }
                      promedio = suma / total;
                    }
                    return _buildStatCard(
                      icon: Icons.star_rounded,
                      label: 'Calificación',
                      valor: total == 0
                          ? '—'
                          : promedio.toStringAsFixed(1),
                      sub: total == 0 ? '' : '($total reseñas)',
                    );
                  },
                ),
              ),
            ]),
            const SizedBox(height: 28),

            // ── Mis publicaciones ───────────────────────────────────────
            const Text('Mis publicaciones',
                style: TextStyle(
                    color: AppColors.textoP,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            StreamBuilder<QuerySnapshot>(
              stream: _publicacionesService
                  .obtenerMisPublicaciones(_user?.uid ?? ''),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Column(children: List.generate(
                      2, (_) => const _SkeletonPub()));
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return _buildEmptyPublicaciones();
                }
                final docs = snap.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final pub   = docs[index].data() as Map<String, dynamic>;
                    final pubId = docs[index].id;
                    final foto  = pub['fotoUrl'] ?? '';
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
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.superficie,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borde),
                        ),
                        child: Row(children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(16)),
                            child: foto.isNotEmpty
                                ? Image.network(foto,
                                    width: 88, height: 88, fit: BoxFit.cover)
                                : Container(
                                    width: 88,
                                    height: 88,
                                    color: AppColors.superficieAlt,
                                    child: const Icon(Icons.image_outlined,
                                        color: AppColors.textoH, size: 30)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pub['titulo'] ?? '',
                                      style: const TextStyle(
                                          color: AppColors.textoP,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(pub['descripcion'] ?? '',
                                      style: const TextStyle(
                                          color: AppColors.textoH,
                                          fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.superficieAlt,
                                      borderRadius: BorderRadius.circular(50),
                                      border:
                                          Border.all(color: AppColors.bordeAlt),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.eco_outlined,
                                            size: 10,
                                            color: AppColors.acentoClaro),
                                        const SizedBox(width: 4),
                                        Text(pub['categoria'] ?? '',
                                            style: const TextStyle(
                                                color: AppColors.acentoClaro,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              final confirmar =
                                  await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: AppColors.superficie,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  title: const Text('Eliminar',
                                      style: TextStyle(
                                          color: AppColors.textoP)),
                                  content: const Text('¿Estás seguro?',
                                      style: TextStyle(
                                          color: AppColors.textoH)),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar',
                                          style: TextStyle(
                                              color: AppColors.textoH)),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Eliminar',
                                          style: TextStyle(
                                              color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmar == true) {
                                await _publicacionesService
                                    .eliminarPublicacion(pubId);
                              }
                            },
                          ),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 28),

            // ── Bloqueados ──────────────────────────────────────────────
            StreamBuilder<QuerySnapshot>(
              stream: _bloqueoService.obtenerBloqueados(),
              builder: (context, snap) {
                final bloqueados = snap.data?.docs ?? [];
                if (bloqueados.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Usuarios bloqueados',
                        style: TextStyle(
                            color: AppColors.textoP,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bloqueados.length,
                      itemBuilder: (context, index) {
                        final uid = bloqueados[index].id;
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(uid)
                              .get(),
                          builder: (context, snapUser) {
                            final nombre =
                                snapUser.data?.get('nombre') ?? '...';
                            final foto =
                                snapUser.data?.get('fotoUrl') ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.superficie,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borde),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.acento,
                                    borderRadius: BorderRadius.circular(21),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(21),
                                    child: foto.isNotEmpty
                                        ? Image.network(foto,
                                            fit: BoxFit.cover)
                                        : Center(
                                            child: Text(
                                              nombre.isNotEmpty
                                                  ? nombre[0].toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                  color: AppColors.fondo,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(nombre,
                                      style: const TextStyle(
                                          color: AppColors.textoP,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _desbloquearUsuario(uid, nombre),
                                  icon: const Icon(
                                      Icons.lock_open_outlined,
                                      color: AppColors.acentoClaro,
                                      size: 16),
                                  label: const Text('Desbloquear',
                                      style: TextStyle(
                                          color: AppColors.acentoClaro,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    backgroundColor: AppColors.acento
                                        .withValues(alpha: 0.1),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                              ]),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),

            // ── Cerrar sesión ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async => await _authService.logout(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout_rounded,
                    color: Colors.redAccent, size: 18),
                label: const Text('Cerrar sesión',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String valor,
    String sub = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.acento, size: 24),
          const SizedBox(height: 10),
          Text(valor,
              style: const TextStyle(
                  color: AppColors.textoP,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(sub,
                style: const TextStyle(
                    color: AppColors.textoH, fontSize: 11)),
          ],
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textoH, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyPublicaciones() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(children: [
        const Icon(Icons.inventory_2_outlined,
            size: 44, color: AppColors.acento),
        const SizedBox(height: 14),
        const Text('Aún no tienes publicaciones',
            style: TextStyle(
                color: AppColors.textoP,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
          'Publica algo para empezar\na hacer trueques',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textoH, fontSize: 13),
        ),
        const SizedBox(height: 20),
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
                horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Crear publicación',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}

class _SkeletonPub extends StatefulWidget {
  const _SkeletonPub();

  @override
  State<_SkeletonPub> createState() => _SkeletonPubState();
}

class _SkeletonPubState extends State<_SkeletonPub>
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
            AppColors.superficie, AppColors.superficieAlt, _anim.value)!;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.superficie,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borde),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Container(width: 88, height: 88, color: color),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 13,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(7)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 11,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(7)),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}