import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/publicaciones_service.dart';
import 'proponer_intercambio_screen.dart';
import 'calificacion_screen.dart';
import 'perfil_usuario_screen.dart';

class DetallePublicacionScreen extends StatefulWidget {
  final Map<String, dynamic> pub;
  final String pubId;

  const DetallePublicacionScreen({
    super.key,
    required this.pub,
    required this.pubId,
  });

  @override
  State<DetallePublicacionScreen> createState() =>
      _DetallePublicacionScreenState();
}

class _DetallePublicacionScreenState extends State<DetallePublicacionScreen> {
  static const Color _magenta = Color(0xFFCC00FF);
  static const Color _cian = Color(0xFF00DDFF);
  static const Color _fondo = Color(0xFF0A0E1A);

  final _miId = FirebaseAuth.instance.currentUser?.uid;
  String? _propietarioNombre;
  String? _propuestaAceptadaId;
  bool _yaCalifique = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _verificarEstado();
  }

  Future<void> _verificarEstado() async {
    if (_miId == null) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('propuestas')
          .where('publicacionId', isEqualTo: widget.pubId)
          .where('estado', isEqualTo: 'aceptado')
          .get();

      String? propuestaId;
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['de_userId'] == _miId || data['para_userId'] == _miId) {
          propuestaId = doc.id;
          break;
        }
      }

      bool yaCalifique = false;
      if (propuestaId != null) {
        final calSnap = await FirebaseFirestore.instance
            .collection('calificaciones')
            .where('de_userId', isEqualTo: _miId)
            .where('propuestaId', isEqualTo: propuestaId)
            .get();
        yaCalifique = calSnap.docs.isNotEmpty;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.pub['userId'])
          .get();
      final nombre = userDoc.data()?['nombre'] ?? 'Usuario';

      if (mounted) {
        setState(() {
          _propuestaAceptadaId = propuestaId;
          _yaCalifique = yaCalifique;
          _propietarioNombre = nombre;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl = widget.pub['fotoUrl'] ?? '';
    final esElDueno = widget.pub['userId'] == _miId;
    final service = PublicacionesService();

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
            'Detalle',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          if (esElDueno)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF0F1422),
                    title: const Text('Eliminar publicación',
                        style: TextStyle(color: Colors.white)),
                    content: const Text('¿Estás seguro?',
                        style: TextStyle(color: Colors.white54)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar',
                            style: TextStyle(color: Colors.white54)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Eliminar',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirmar == true) {
                  await service.eliminarPublicacion(widget.pubId);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fotoUrl.isNotEmpty)
              Image.network(
                fotoUrl,
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: const Color(0xFF0F1422),
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_magenta, _cian],
                    ).createShader(bounds),
                    child: const Icon(Icons.image_outlined,
                        size: 80, color: Colors.white),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_magenta, _cian]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.pub['categoria'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.pub['titulo'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.pub['descripcion'] ?? '',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón ver perfil del propietario
                  if (!esElDueno)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PerfilUsuarioScreen(
                            userId: widget.pub['userId'],
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1422),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline,
                                color: Color(0xFF00DDFF), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Ver perfil de ${_propietarioNombre ?? 'usuario'}',
                              style: const TextStyle(
                                color: Color(0xFF00DDFF),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios,
                                color: Color(0xFF00DDFF), size: 12),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                  if (!esElDueno) _buildBotonAccion(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonAccion(BuildContext context) {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00DDFF)),
      );
    }

    if (_propuestaAceptadaId != null) {
      if (_yaCalifique) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.greenAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Ya calificaste este trueque',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1422),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_magenta, _cian],
                  ).createShader(bounds),
                  child: const Text(
                    '¡Trueque completado!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '¿Cómo fue tu experiencia con $_propietarioNombre?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (_) => const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 28),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_magenta, _cian]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CalificacionScreen(
                        paraUserId: widget.pub['userId'],
                        nombreUsuario: _propietarioNombre ?? 'Usuario',
                        propuestaId: _propuestaAceptadaId!,
                      ),
                    ),
                  );
                  _verificarEstado();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.star_outline, color: Colors.white),
                label: Text(
                  'Calificar a $_propietarioNombre',
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
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_magenta, _cian]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProponerIntercambioScreen(
                  publicacionId: widget.pubId,
                  propietarioId: widget.pub['userId'],
                  tituloPub: widget.pub['titulo'] ?? '',
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Proponer trueque',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}