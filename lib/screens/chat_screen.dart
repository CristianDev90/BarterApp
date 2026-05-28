import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/intercambio_service.dart';
import 'perfil_usuario_screen.dart';
 
class ChatScreen extends StatefulWidget {
  final String propuestaId;
  final String otroUsuarioNombre;
  final String otroUsuarioFoto;
  // Bug 5: nuevo parámetro para navegar al perfil desde el chat
  final String otroUsuarioId;
 
  const ChatScreen({
    super.key,
    required this.propuestaId,
    required this.otroUsuarioNombre,
    required this.otroUsuarioFoto,
    required this.otroUsuarioId,
  });
 
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}
 
class _ChatScreenState extends State<ChatScreen> {
  final _service = IntercambioService();
  final _mensajeCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _miUid = FirebaseAuth.instance.currentUser?.uid ?? '';
 
  static const Color _magenta = Color(0xFFCC00FF);
  static const Color _cian = Color(0xFF00DDFF);
  static const Color _fondo = Color(0xFF0A0E1A);
 
  @override
  void dispose() {
    _mensajeCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
 
  void _scrollAbajo() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
 
  Future<void> _enviar() async {
    final texto = _mensajeCtrl.text.trim();
    if (texto.isEmpty) return;
    _mensajeCtrl.clear();
    await _service.enviarMensaje(
      propuestaId: widget.propuestaId,
      texto: texto,
    );
    _scrollAbajo();
  }
 
  // Bug 5: navegar al perfil del otro usuario
  void _irAlPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PerfilUsuarioScreen(userId: widget.otroUsuarioId),
      ),
    );
  }
 
  Widget _buildMensaje(Map<String, dynamic> data) {
    final esMio = data['de_userId'] == _miUid;
    final texto = data['texto'] ?? '';
    final fecha = data['fecha'] as Timestamp?;
    final hora = fecha != null
        ? '${fecha.toDate().hour.toString().padLeft(2, '0')}:${fecha.toDate().minute.toString().padLeft(2, '0')}'
        : '';
 
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          gradient: esMio
              ? const LinearGradient(colors: [_magenta, _cian])
              : null,
          color: esMio ? null : const Color(0xFF0F1422),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(esMio ? 16 : 4),
            bottomRight: Radius.circular(esMio ? 4 : 16),
          ),
          border: esMio ? null : Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment:
              esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              texto,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              hora,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
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
        // Bug 5: todo el título es tappable para ir al perfil
        title: GestureDetector(
          onTap: _irAlPerfil,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_magenta, _cian]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: widget.otroUsuarioFoto.isNotEmpty
                      ? Image.network(widget.otroUsuarioFoto, fit: BoxFit.cover)
                      : Center(
                          child: Text(
                            widget.otroUsuarioNombre.isNotEmpty
                                ? widget.otroUsuarioNombre[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          const LinearGradient(colors: [_magenta, _cian])
                              .createShader(bounds),
                      child: Text(
                        widget.otroUsuarioNombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      'Ver perfil',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.mensajesDeChat(widget.propuestaId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00DDFF)),
                  );
                }
 
                final mensajes = snap.data?.docs ?? [];
 
                if (mensajes.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aún no hay mensajes.\n¡Saluda al otro usuario! 👋',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  );
                }
 
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollAbajo());
 
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: mensajes.length,
                  itemBuilder: (_, i) {
                    final data = mensajes[i].data() as Map<String, dynamic>;
                    return _buildMensaje(data);
                  },
                );
              },
            ),
          ),
 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1422),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeCtrl,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white10,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _enviar,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(colors: [_magenta, _cian]),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}