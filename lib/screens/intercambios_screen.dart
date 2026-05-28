import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/intercambio_service.dart';
import 'calificacion_screen.dart';

class IntercambiosScreen extends StatefulWidget {
  const IntercambiosScreen({super.key});

  @override
  State<IntercambiosScreen> createState() => _IntercambiosScreenState();
}

class _IntercambiosScreenState extends State<IntercambiosScreen>
    with SingleTickerProviderStateMixin {
  final _service = IntercambioService();
  late TabController _tabCtrl;

  static const Color _magenta = Color(0xFFCC00FF);
  static const Color _cian = Color(0xFF00DDFF);
  static const Color _fondo = Color(0xFF0A0E1A);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'aceptado':
        return Colors.greenAccent;
      case 'rechazado':
        return Colors.redAccent;
      case 'cancelado':
        return Colors.orange;
      default:
        return Colors.white38;
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'aceptado':
        return 'Aceptado';
      case 'rechazado':
        return 'Rechazado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Pendiente';
    }
  }

  Future<Map<String, String>> _datosUsuario(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    final data = doc.data();
    return {
      'nombre': data?['nombre'] ?? 'Usuario',
      'fotoUrl': data?['fotoUrl'] ?? '',
    };
  }

  Future<String> _tituloPub(String pubId) async {
    final doc = await FirebaseFirestore.instance
        .collection('publicaciones')
        .doc(pubId)
        .get();
    return doc.data()?['titulo'] ?? 'Publicación';
  }

  Widget _buildEmpty(String mensaje) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1422),
              borderRadius: BorderRadius.circular(45),
              border: Border.all(color: Colors.white10),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_magenta, _cian],
              ).createShader(bounds),
              child: const Icon(Icons.swap_horiz,
                  size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjeta({
    required DocumentSnapshot doc,
    required bool esRecibido,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final estado = data['estado'] ?? 'pendiente';
    final mensaje = data['mensajePropuesta'] ?? '';
    final otroUid = esRecibido ? data['de_userId'] : data['para_userId'];
    final pubId = data['publicacionId'] ?? '';

    return FutureBuilder<Map<String, String>>(
      future: _datosUsuario(otroUid),
      builder: (context, snapUsuario) {
        return FutureBuilder<String>(
          future: _tituloPub(pubId),
          builder: (context, snapTitulo) {
            final nombre = snapUsuario.data?['nombre'] ?? '...';
            final fotoUrl = snapUsuario.data?['fotoUrl'] ?? '';
            final titulo = snapTitulo.data ?? '...';
            final colorEstado = _colorEstado(estado);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1422),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Usuario y estado
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_magenta, _cian]),
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: fotoUrl.isNotEmpty
                                ? Image.network(fotoUrl, fit: BoxFit.cover)
                                : Center(
                                    child: Text(
                                      nombre.isNotEmpty
                                          ? nombre[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                titulo,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Badge estado — withValues en vez de withOpacity
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorEstado.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colorEstado, width: 1),
                          ),
                          child: Text(
                            _labelEstado(estado),
                            style: TextStyle(
                              color: colorEstado,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Mensaje — withValues en vez de withOpacity
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        mensaje,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Aceptar / Rechazar (recibido pendiente)
                    if (esRecibido && estado == 'pendiente')
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await _service.rechazarIntercambio(doc.id);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Rechazar',
                                  style: TextStyle(color: Colors.redAccent)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [_magenta, _cian]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  await _service.aceptarIntercambio(doc.id);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Aceptar',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Cancelar (enviado pendiente)
                    if (!esRecibido && estado == 'pendiente')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            await _service.cancelarIntercambio(doc.id);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancelar propuesta',
                              style: TextStyle(color: Colors.orange)),
                        ),
                      ),

                    // Calificar — sin const para permitir interpolación
                    if (estado == 'aceptado')
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_magenta, _cian]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CalificacionScreen(
                                    paraUserId: otroUid,
                                    nombreUsuario: nombre,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.star_outline,
                                color: Colors.white, size: 18),
                            label: Text(
                              'Calificar a $nombre',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLista(Stream<QuerySnapshot> stream, bool esRecibido) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00DDFF)),
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _buildEmpty(esRecibido
              ? 'Nadie te ha propuesto\nun trueque todavía'
              : 'No has propuesto\nningún trueque todavía');
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: snap.data!.docs.length,
          itemBuilder: (_, i) => _buildTarjeta(
            doc: snap.data!.docs[i],
            esRecibido: esRecibido,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            'Mis trueques',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _cian,
          labelColor: _cian,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Recibidos'),
            Tab(text: 'Enviados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildLista(_service.misIntercambiosRecibidos(), true),
          _buildLista(_service.misIntercambiosEnviados(), false),
        ],
      ),
    );
  }
}