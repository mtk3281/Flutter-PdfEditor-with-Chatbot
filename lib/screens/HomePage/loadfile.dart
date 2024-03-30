import 'package:flutter/services.dart';

class FileSystemService {
  static const platform = const MethodChannel('com.example.app/files');

  static Future<List<String>?> getAllFilePaths() async {
    List<String>? paths;
    try {
      paths = await platform.invokeListMethod('getAllFilePaths');
    } on PlatformException catch (e) {
      print("Failed to get file paths: '${e.message}'.");
    }
    return paths;
  }
}
