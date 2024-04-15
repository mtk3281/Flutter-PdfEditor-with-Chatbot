import 'package:flutter/services.dart';

class PdfUtils {
  static const MethodChannel _channel = MethodChannel('com.example.app/pdf');

  static Future<String?> combinePdfFiles(List<String> pdfPaths, String combinedPdfPath) async {
    try {
      final String? result = await _channel.invokeMethod('combinePdfFiles', {
        'pdfPaths': pdfPaths,
        'combinedPdfPath': combinedPdfPath,
      });
      return result;
    } on PlatformException catch (e) {
      print("Error combining PDF files: ${e.message}");
      return null;
    }
  }
}