import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
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

class _DetallePublicacionScreenState
    extends State<DetallePublicacionScreen> {
  final _miId = FirebaseAuth.instance.currentUser?.uid;
  String? _propietarioNombre;
  String? _propuestaAceptadaId;
  bool _yaCalifique = false;
  bool _cargando    = true;

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
          _yaCalifique         = yaCalifique;
          _propietarioNombre   = nombre;
          _cargando            = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl    = widget.pub['fotoUrl'] ?? '';
    final esElDueno  = widget.pub['userId'] == _miId;
    final service    = PublicacionesService();

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textoS, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detalle',
            style: TextStyle(
                color: AppColors.textoP, fontWeight: FontWeight.bold)),
        actions: [
          if (esElDueno)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              onPressed: () async {
                final confirmar = await _confirmarEliminar();
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
            // Imagen principal
            if (fotoUrl.isNotEmpty)
              Image.network(fotoUrl,
                  width: double.infinity, height: 280, fit: BoxFit.cover)
            else
              Container(
                width: double.infinity,
                height: 200,
                color: AppColors.superficie,
                child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 60)),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge categoría
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.superficieAlt,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: AppColors.bordeAlt),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco_outlined,
                            size: 13, color: AppColors.acentoClaro),
                        const SizedBox(width: 5),
                        Text(
                          widget.pub['categoria'] ?? '',
                          style: const TextStyle(
                            color: AppColors.acentoClaro,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Título
                  Text(
                    widget.pub['titulo'] ?? '',
                    style: const TextStyle(
                      color: AppColors.textoP,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Descripción
                  Text(
                    widget.pub['descripcion'] ?? '',
                    style: const TextStyle(
                      color: AppColors.textoS,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ver perfil
                  if (!esElDueno)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PerfilUsuarioScreen(
                              userId: widget.pub['userId']),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.superficie,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borde),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                color: AppColors.acento, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Ver perfil de ${_propietarioNombre ?? 'usuario'}',
                                style: const TextStyle(
                                  color: AppColors.acentoClaro,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: AppColors.textoH, size: 14),
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

  Future<bool?> _confirmarEliminar() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.superficie,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
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

  Widget _buildBotonAccion(BuildContext context) {
    if (_cargando) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.acento));
    }

    if (_propuestaAceptadaId != null) {
      if (_yaCalifique) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.greenAccent, size: 20),
              SizedBox(width: 8),
              Text('Ya calificaste este trueque',
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }

      return Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.superficie,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.bordeAlt),
          ),
          child: Column(children: [
            const Text('¡Trueque completado!',
                style: TextStyle(
                    color: AppColors.acentoClaro,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              '¿Cómo fue tu experiencia con $_propietarioNombre?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textoH, fontSize: 13),
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
          ]),
        ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CalificacionScreen(
                    paraUserId:    widget.pub['userId'],
                    nombreUsuario: _propietarioNombre ?? 'Usuario',
                    propuestaId:   _propuestaAceptadaId!,
                  ),
                ),
              );
              _verificarEstado();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.acento,
              foregroundColor: AppColors.fondo,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.star_outline_rounded),
            label: Text('Calificar a $_propietarioNombre',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ]);
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProponerIntercambioScreen(
              publicacionId: widget.pubId,
              propietarioId: widget.pub['userId'],
              tituloPub:     widget.pub['titulo'] ?? '',
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.acento,
          foregroundColor: AppColors.fondo,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: const Text('Proponer trueque',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}