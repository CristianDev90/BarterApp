import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/bloqueo_service.dart';
import '../services/reportes_service.dart';
import 'detalle_publicacion_screen.dart';
import 'reporte_screen.dart';
 
class PerfilUsuarioScreen extends StatefulWidget {
  final String userId;
 
  const PerfilUsuarioScreen({super.key, required this.userId});
 
  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}
 
class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  static const Color _magenta = Color(0xFFCC00FF);
  static const Color _cian = Color(0xFF00DDFF);
  static const Color _fondo = Color(0xFF0A0E1A);
 
  final _bloqueoService = BloqueoService();
  final _miUid = FirebaseAuth.instance.currentUser?.uid ?? '';
 
  Map<String, dynamic>? _usuario;
  bool _cargando = true;
  bool _estaBloqueado = false;
 
  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _verificarBloqueo();
  }
 
  Future<void> _cargarUsuario() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .get();
    if (mounted) {
      setState(() {
        _usuario = doc.data();
        _cargando = false;
      });
    }
  }
 
  Future<void> _verificarBloqueo() async {
    final bloqueado = await _bloqueoService.estaBloqueado(widget.userId);
    if (mounted) setState(() => _estaBloqueado = bloqueado);
  }
 
  Future<void> _toggleBloqueo() async {
    final nombre = _usuario?['nombre'] ?? 'este usuario';
    final accion = _estaBloqueado ? 'desbloquear' : 'bloquear';
 
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F1422),
        title: Text(
          '¿$accion a $nombre?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          _estaBloqueado
              ? 'Volverás a ver sus publicaciones y podrá contactarte.'
              : 'No verás sus publicaciones ni podrá contactarte.',
          style: const TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              accion[0].toUpperCase() + accion.substring(1),
              style: TextStyle(
                color: _estaBloqueado ? _cian : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
 
    if (confirmar != true) return;
 
    try {
      if (_estaBloqueado) {
        await _bloqueoService.desbloquearUsuario(widget.userId);
      } else {
        await _bloqueoService.bloquearUsuario(widget.userId);
      }
      await _verificarBloqueo();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_estaBloqueado
              ? '$nombre fue desbloqueado'
              : '$nombre fue bloqueado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
 
  String _formatFecha(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $hora:$min';
  }
 
  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E1A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00DDFF))),
      );
    }
 
    final nombre = _usuario?['nombre'] ?? 'Usuario';
    final bio = _usuario?['bio'] ?? '';
    final fotoUrl = _usuario?['fotoUrl'] ?? '';
 
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
          shaderCallback: (bounds) =>
              const LinearGradient(colors: [_magenta, _cian]).createShader(bounds),
          child: Text(
            nombre,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
          ),
        ),
        // ── MENÚ DE TRES PUNTOS ──────────────────────────────────────────────
        actions: [
          if (widget.userId != _miUid)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              color: const Color(0xFF0F1422),
              onSelected: (value) {
                if (value == 'reportar') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReporteScreen(
                        usuarioReportadoId: widget.userId,
                        usuarioReportadoNombre: nombre,
                      ),
                    ),
                  );
                } else if (value == 'bloquear') {
                  _toggleBloqueo();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'reportar',
                  child: Row(
                    children: const [
                      Icon(Icons.flag_outlined, color: Colors.orangeAccent, size: 20),
                      SizedBox(width: 10),
                      Text('Reportar usuario',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'bloquear',
                  child: Row(
                    children: [
                      Icon(
                        _estaBloqueado ? Icons.lock_open_outlined : Icons.block,
                        color: _estaBloqueado ? _cian : Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _estaBloqueado ? 'Desbloquear usuario' : 'Bloquear usuario',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
 
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
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: fotoUrl.isNotEmpty
                          ? Image.network(fotoUrl,
                              fit: BoxFit.cover, width: 100, height: 100)
                          : Center(
                              child: Text(
                                nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(nombre,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(bio,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.white60, fontSize: 13)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
 
            // Card trueques realizados
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1422),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        const LinearGradient(colors: [_magenta, _cian])
                            .createShader(bounds),
                    child: const Icon(Icons.swap_horiz,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text('Trueques realizados',
                        style:
                            TextStyle(color: Colors.white60, fontSize: 14)),
                  ),
                  const Text('0',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
 
            // Card calificación
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('calificaciones')
                  .where('para_userId', isEqualTo: widget.userId)
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
                        shaderCallback: (bounds) =>
                            const LinearGradient(colors: [_magenta, _cian])
                                .createShader(bounds),
                        child: const Icon(Icons.star_outline,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Calificación',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 14)),
                            if (total > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < promedio.round()
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: Colors.amber,
                                    size: 16,
                                  );
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        total == 0
                            ? '—'
                            : '${promedio.toStringAsFixed(1)} ($total)',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
 
            // Reseñas recibidas
            ShaderMask(
              shaderCallback: (bounds) =>
                  const LinearGradient(colors: [_magenta, _cian])
                      .createShader(bounds),
              child: const Text('Reseñas recibidas',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 14),
 
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('calificaciones')
                  .where('para_userId', isEqualTo: widget.userId)
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF00DDFF)));
                }
 
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 32, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1422),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Center(
                      child: Text('Aún no tiene reseñas',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 14)),
                    ),
                  );
                }
 
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        snap.data!.docs[index].data() as Map<String, dynamic>;
                    final puntuacion =
                        (data['puntuacion'] as num).toDouble();
                    final comentario = data['comentario'] ?? '';
                    final fecha = data['fecha'] as Timestamp?;
                    final deUserId = data['de_userId'] ?? '';
 
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(deUserId)
                          .get(),
                      builder: (context, snapUser) {
                        final nombreDe =
                            snapUser.data?.get('nombre') ?? '...';
                        final fotoDe =
                            snapUser.data?.get('fotoUrl') ?? '';
 
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1422),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                          colors: [_magenta, _cian]),
                                      borderRadius:
                                          BorderRadius.circular(19),
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(19),
                                      child: fotoDe.isNotEmpty
                                          ? Image.network(fotoDe,
                                              fit: BoxFit.cover)
                                          : Center(
                                              child: Text(
                                                nombreDe.isNotEmpty
                                                    ? nombreDe[0]
                                                        .toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(nombreDe,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14)),
                                        Text(_formatFecha(fecha),
                                            style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < puntuacion.round()
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: Colors.amber,
                                        size: 18,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(comentario,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        height: 1.4)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
 
            // Publicaciones del usuario
            ShaderMask(
              shaderCallback: (bounds) =>
                  const LinearGradient(colors: [_magenta, _cian])
                      .createShader(bounds),
              child: Text('Publicaciones de $nombre',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 14),
 
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('publicaciones')
                  .where('userId', isEqualTo: widget.userId)
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF00DDFF)));
                }
 
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 32, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1422),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Center(
                      child: Text('No tiene publicaciones aún',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 14)),
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
                          pageBuilder: (_, animation, __) =>
                              DetallePublicacionScreen(
                                  pub: pub, pubId: pubId),
                          transitionsBuilder:
                              (_, animation, __, child) =>
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
                                  ? Image.network(fotoUrl,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover)
                                  : Container(
                                      width: 90,
                                      height: 90,
                                      color: Colors.white10,
                                      child: const Icon(
                                          Icons.image_outlined,
                                          color: Colors.white24,
                                          size: 32)),
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
                                    Text(pub['titulo'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(pub['descripcion'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                            colors: [_magenta, _cian]),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(pub['categoria'] ?? '',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}