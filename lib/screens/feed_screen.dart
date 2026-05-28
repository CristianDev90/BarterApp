import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/publicaciones_service.dart';
import 'crear_publicacion_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PublicacionesService();
    final miId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BarterApp'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.obtenerPublicaciones(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay publicaciones aún. ¡Sé el primero!'),
            );
          }

          final publicaciones = snapshot.data!.docs;

          return ListView.builder(
            itemCount: publicaciones.length,
            itemBuilder: (context, index) {
              final pub = publicaciones[index].data() as Map<String, dynamic>;
              final pubId = publicaciones[index].id;
              final fotoUrl = pub['fotoUrl'] ?? '';
              final esElDueno = pub['userId'] == miId;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fotoUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Image.network(
                          fotoUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ListTile(
                      title: Text(pub['titulo'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pub['descripcion'] ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            pub['categoria'] ?? '',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: esElDueno
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Eliminar publicación'),
                                    content: const Text('¿Estás seguro de que quieres eliminar esta publicación?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
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
                                  await service.eliminarPublicacion(pubId);
                                }
                              },
                            )
                          : null,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CrearPublicacionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}