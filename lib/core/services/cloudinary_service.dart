import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

/// Servicio para subir imágenes y PDFs a Cloudinary
class CloudinaryService {
  final String cloudName;
  final String apiKey;
  final String apiSecret;

  CloudinaryService({
    required this.cloudName,
    required this.apiKey,
    required this.apiSecret,
  });

  /// Subir una imagen a Cloudinary
  /// 
  /// [imageFile] - Archivo de imagen a subir
  /// [folder] - Carpeta opcional donde guardar la imagen
  /// [publicId] - ID público opcional para la imagen
  /// 
  /// Retorna la URL pública de la imagen subida
  Future<String> uploadImage(
    File imageFile, {
    String? folder,
    String? publicId,
  }) async {
    try {
      // Leer el archivo como bytes
      final imageBytes = await imageFile.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Construir parámetros para la firma
      final params = <String, String>{
        'timestamp': timestamp,
        if (folder != null) 'folder': folder,
        if (publicId != null) 'public_id': publicId,
      };

      // Generar firma
      final signature = _generateSignature(params);

      // Construir URL de upload
      final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

      // Crear request multipart
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
      if (folder != null) {
        request.fields['folder'] = folder;
      }
      if (publicId != null) {
        request.fields['public_id'] = publicId;
      }

      // Agregar el archivo
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: imageFile.path.split('/').last,
        ),
      );

      // Enviar request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String? ?? data['url'] as String;
        return secureUrl;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
          'Error al subir imagen: ${errorData['error']?['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error al subir imagen a Cloudinary: $e');
    }
  }

  /// Subir un PDF a Cloudinary
  /// 
  /// [pdfBytes] - Bytes del PDF a subir (Uint8List)
  /// [fileName] - Nombre del archivo PDF
  /// [folder] - Carpeta opcional donde guardar el PDF
  /// [publicId] - ID público opcional para el PDF
  /// 
  /// Retorna la URL pública del PDF subido
  Future<String> uploadPdf(
    Uint8List pdfBytes,
    String fileName, {
    String? folder,
    String? publicId,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Construir parámetros para la firma
      final params = <String, String>{
        'timestamp': timestamp,
        if (folder != null) 'folder': folder,
        if (publicId != null) 'public_id': publicId,
      };

      // Generar firma
      final signature = _generateSignature(params);

      // Construir URL de upload - usar raw/upload para PDFs
      final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/raw/upload';

      // Crear request multipart
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
      if (folder != null) {
        request.fields['folder'] = folder;
      }
      if (publicId != null) {
        request.fields['public_id'] = publicId;
      }

      // Agregar el archivo PDF
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          pdfBytes,
          filename: fileName,
        ),
      );

      // Enviar request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String? ?? data['url'] as String;
        return secureUrl;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
          'Error al subir PDF: ${errorData['error']?['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error al subir PDF a Cloudinary: $e');
    }
  }

  /// Generar firma para autenticación con Cloudinary
  String _generateSignature(Map<String, String> params) {
    // Ordenar parámetros alfabéticamente
    final sortedParams = params.keys.toList()..sort();
    final paramString = sortedParams
        .map((key) => '$key=${params[key]}')
        .join('&');

    // Agregar api_secret
    final signatureString = '$paramString$apiSecret';

    // Generar hash SHA1
    final bytes = utf8.encode(signatureString);
    final hash = sha1.convert(bytes);

    return hash.toString();
  }
}

