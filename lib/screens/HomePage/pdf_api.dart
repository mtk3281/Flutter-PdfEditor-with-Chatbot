import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class PDFApi {
  static Future<File?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return null;
    return File(result.paths.first!);
  }
}
