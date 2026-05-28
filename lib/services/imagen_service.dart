import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImagenService {
  final cloudinary = CloudinaryPublic(
    'dsc613qmy',
    'barterapp_uploads',
    cache: false,
  );

  // Comprimir imagen antes de subir
  Future<File?> comprimirImagen(File imagen) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      imagen.path,
      targetPath,
      quality: 70,
      minWidth: 800,
      minHeight: 800,
    );

    if (result == null) return null;
    return File(result.path);
  }

  // Subir imagen comprimida a Cloudinary
  Future<String> subirImagen(File imagen) async {
    try {
      // Comprimir primero
      final imagenComprimida = await comprimirImagen(imagen);
      final imagenFinal = imagenComprimida ?? imagen;

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imagenFinal.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }
}