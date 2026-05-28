import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
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
  static const Color _magenta = Color(0xFFCC00FF);
  static const Color _cian = Color(0xFF00DDFF);
  static const Color _fondo = Color(0xFF0A0E1A);

  final _authService = AuthService();
  final _publicacionesService = PublicacionesService();
  final _user = FirebaseAuth.instance.currentUser;

  String _nombre = 'Usuario';
  String _email = '';
  String _bio = '';
  String _fotoUrl = '';
  bool _cargando = true;

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
        _nombre = data?['nombre'] ?? 'Usuario';
        _email = data?['email'] ?? _user?.email ?? '';
        _bio = data?['bio'] ?? '';
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
          bioActual: _bio,
          fotoActual: _fotoUrl,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    if (resultado != null && mounted) {
      setState(() {
        _nombre = resultado['nombre'] ?? _nombre;
        _bio = resultado['bio'] ?? _bio;
        _fotoUrl = resultado['fotoUrl'] ?? _fotoUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00DDFF)),
        ),
      );
    }

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
            'Mi Perfil',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white54),
            onPressed: _irAEditar,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () async {
              await _authService.logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Avatar y datos
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_magenta, _cian],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: _fotoUrl.isNotEmpty
                          ? Image.network(
                              _fotoUrl,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                            )
                          : Center(
                              child: Text(
                                _nombre.isNotEmpty
                                    ? _nombre[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _email,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  if (_bio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      _bio,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Info cards
            _buildInfoCard(
              icon: Icons.swap_horiz,
              titulo: 'Trueques realizados',
              valor: '0',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.star_outline,
              titulo: 'Calificación',
              valor: '—',
            ),
            const SizedBox(height: 32),

            // Título sección
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_magenta, _cian],
              ).createShader(bounds),
              child: const Text(
                'Mis publicaciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Lista de mis publicaciones
            StreamBuilder<QuerySnapshot>(
              stream: _publicacionesService
                  .obtenerMisPublicaciones(_user?.uid ?? ''),
              builder: (context, snap) {
                // Skeleton mientras carga
                if (snap.connectionState == ConnectionState.waiting) {
                  return Column(
                    children: List.generate(
                      2,
                      (_) => const _SkeletonPublicacion(),
                    ),
                  );
                }

                // Empty state mejorado
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 40, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1422),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [_magenta, _cian],
                          ).createShader(bounds),
                          child: const Icon(Icons.inventory_2_outlined,
                              size: 48, color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Aún no tienes publicaciones',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Publica algo para empezar\na hacer trueques',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_magenta, _cian]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const CrearPublicacionScreen()),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              'Crear publicación',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snap.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final pub =
                        docs[index].data() as Map<String, dynamic>;
                    final pubId = docs[index].id;
                    final fotoUrl = pub['fotoUrl'] ?? '';

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, animation, _) =>
                              DetallePublicacionScreen(
                                  pub: pub, pubId: pubId),
                          transitionsBuilder: (_, animation, _, child) =>
                              FadeTransition(
                                  opacity: animation, child: child),
                          transitionDuration:
                              const Duration(milliseconds: 300),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1422),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(16)),
                              child: fotoUrl.isNotEmpty
                                  ? Image.network(
                                      fotoUrl,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 90,
                                      height: 90,
                                      color: Colors.white10,
                                      child: const Icon(
                                        Icons.image_outlined,
                                        color: Colors.white24,
                                        size: 32,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 4),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pub['titulo'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pub['descripcion'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                            colors: [_magenta, _cian]),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        pub['categoria'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              onPressed: () async {
                                final confirmar =
                                    await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    backgroundColor:
                                        const Color(0xFF0F1422),
                                    title: const Text(
                                        'Eliminar publicación',
                                        style: TextStyle(
                                            color: Colors.white)),
                                    content: const Text(
                                        '¿Estás seguro?',
                                        style: TextStyle(
                                            color: Colors.white54)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                            context, false),
                                        child: const Text('Cancelar',
                                            style: TextStyle(
                                                color: Colors.white54)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                            context, true),
                                        child: const Text('Eliminar',
                                            style: TextStyle(
                                                color: Colors.red)),
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
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),

            // Botón cerrar sesión
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () async {
                  await _authService.logout();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

  Widget _buildInfoCard({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1422),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_magenta, _cian],
            ).createShader(bounds),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton para publicaciones del perfil ───────────────────────────────────
class _SkeletonPublicacion extends StatefulWidget {
  const _SkeletonPublicacion();

  @override
  State<_SkeletonPublicacion> createState() => _SkeletonPublicacionState();
}

class _SkeletonPublicacionState extends State<_SkeletonPublicacion>
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
      builder: (_, _) {
        final color = Color.lerp(
          const Color(0xFF0F1422),
          const Color(0xFF1E2440),
          _anim.value,
        )!;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1422),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16)),
                child: Container(width: 90, height: 90, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 140,
                        height: 11,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        );
      },
    );
  }
}