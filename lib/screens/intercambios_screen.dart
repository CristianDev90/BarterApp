import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../services/intercambio_service.dart';
import 'chat_screen.dart';

class IntercambiosScreen extends StatefulWidget {
  const IntercambiosScreen({super.key});

  @override
  State<IntercambiosScreen> createState() => _IntercambiosScreenState();
}

class _IntercambiosScreenState extends State<IntercambiosScreen>
    with SingleTickerProviderStateMixin {
  final _service = IntercambioService();
  late TabController _tabCtrl;
  final _miUid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
      case 'aceptado':  return Colors.greenAccent;
      case 'rechazado': return Colors.redAccent;
      case 'cancelado': return Colors.orange;
      default:          return AppColors.textoH;
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'aceptado':  return 'Aceptado';
      case 'rechazado': return 'Rechazado';
      case 'cancelado': return 'Cancelado';
      default:          return 'Pendiente';
    }
  }

  Future<Map<String, String>> _datosUsuario(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    final data = doc.data();
    return {
      'nombre':  data?['nombre']  ?? 'Usuario',
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
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(44),
              border: Border.all(color: AppColors.borde),
            ),
            child: const Center(
              child: Text('🌿', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 20),
          Text(mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textoS, fontSize: 15)),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminar(
      BuildContext context, String docId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.superficie,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar del historial',
            style: TextStyle(color: AppColors.textoP)),
        content: const Text(
          'Solo desaparecerá de tu historial.',
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
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _service.eliminarPropuesta(docId);
    }
  }

  Widget _buildTarjeta({
    required DocumentSnapshot doc,
    required bool esRecibido,
  }) {
    final data    = doc.data() as Map<String, dynamic>;
    final estado  = data['estado'] ?? 'pendiente';
    final mensaje = data['mensajePropuesta'] ?? '';

    final otroUid = esRecibido
        ? data['de_userId'] as String? ?? ''
        : data['para_userId'] as String? ?? '';
    final pubId = data['publicacionId'] ?? '';

    return FutureBuilder<Map<String, String>>(
      future: _datosUsuario(otroUid),
      builder: (context, snapUsuario) {
        return FutureBuilder<String>(
          future: _tituloPub(pubId),
          builder: (context, snapTitulo) {
            final nombre   = snapUsuario.data?['nombre']  ?? '...';
            final fotoUrl  = snapUsuario.data?['fotoUrl'] ?? '';
            final titulo   = snapTitulo.data ?? '...';
            final colorEst = _colorEstado(estado);

            return Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.superficie,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borde),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header usuario
                    Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.acento,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: fotoUrl.isNotEmpty
                              ? Image.network(fotoUrl, fit: BoxFit.cover)
                              : Center(
                                  child: Text(
                                    nombre.isNotEmpty
                                        ? nombre[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: AppColors.fondo,
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
                            Text(nombre,
                                style: const TextStyle(
                                    color: AppColors.textoP,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(titulo,
                                style: const TextStyle(
                                    color: AppColors.textoH,
                                    fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      // Badge estado
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: colorEst.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: colorEst, width: 1),
                        ),
                        child: Text(
                          _labelEstado(estado),
                          style: TextStyle(
                            color: colorEst,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // Mensaje
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.superficieAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borde),
                      ),
                      child: Text(mensaje,
                          style: const TextStyle(
                              color: AppColors.textoS, fontSize: 13)),
                    ),
                    const SizedBox(height: 14),

                    // Acciones recibidos pendientes
                    if (esRecibido && estado == 'pendiente')
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async =>
                                await _service.rechazarIntercambio(doc.id),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Rechazar',
                                style:
                                    TextStyle(color: Colors.redAccent)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async =>
                                await _service.aceptarIntercambio(doc.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.acento,
                              foregroundColor: AppColors.fondo,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Aceptar',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ]),

                    // Cancelar enviados pendientes
                    if (!esRecibido && estado == 'pendiente')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async =>
                              await _service.cancelarIntercambio(doc.id),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancelar propuesta',
                              style: TextStyle(color: Colors.orange)),
                        ),
                      ),

                    // Chat aceptados
                    if (estado == 'aceptado')
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  propuestaId:      doc.id,
                                  otroUsuarioNombre: nombre,
                                  otroUsuarioFoto:  fotoUrl,
                                  otroUsuarioId:    otroUid,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.acento,
                              foregroundColor: AppColors.fondo,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 18),
                            label: const Text('Abrir chat',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),

                    // Eliminar historial
                    if (estado != 'pendiente')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _confirmarEliminar(context, doc.id),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent, size: 16),
                            label: const Text('Eliminar del historial',
                                style: TextStyle(color: Colors.redAccent)),
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
              child: CircularProgressIndicator(color: AppColors.acento));
        }
        final docs = (snap.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final ocultoPara =
              List<String>.from(data['ocultoPara'] ?? []);
          return !ocultoPara.contains(_miUid);
        }).toList();

        if (docs.isEmpty) {
          return _buildEmpty(esRecibido
              ? 'Nadie te ha propuesto\nun trueque todavía'
              : 'No has propuesto\nningún trueque todavía');
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (_, i) =>
              _buildTarjeta(doc: docs[i], esRecibido: esRecibido),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Mis trueques',
            style: TextStyle(
                color: AppColors.textoP,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('intercambios')
                .where('para_userId', isEqualTo: _miUid)
                .where('estado', isEqualTo: 'pendiente')
                .snapshots(),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              return TabBar(
                controller: _tabCtrl,
                indicatorColor: AppColors.acento,
                indicatorWeight: 2.5,
                labelColor: AppColors.acentoClaro,
                unselectedLabelColor: AppColors.textoH,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Recibidos',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.acento,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$count',
                                style: const TextStyle(
                                    color: AppColors.fondo,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(
                    child: Text('Enviados',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
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