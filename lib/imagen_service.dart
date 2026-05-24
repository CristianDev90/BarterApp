import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class ImagenService {
  final cloudinary = CloudinaryPublic(
    'dsc613qmy',
    'barterapp_uploads', 
    cache: false,
  );

  // Subir imagen y obtener URL
  Future<String> subirImagen(File imagen) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imagen.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }
}