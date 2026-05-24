import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'publicaciones_service.dart';
import 'crear_publicacion_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PublicacionesService();

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

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mostrar foto si existe
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
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => service.eliminarPublicacion(pubId),
                      ),
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
