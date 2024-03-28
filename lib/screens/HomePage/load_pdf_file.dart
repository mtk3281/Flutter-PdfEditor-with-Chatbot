import 'dart:io';

class FileFinder {
  static Future<Map<String, List<String>>> findFiles(
      String directoryPath, List<String> extensions) async {
    Map<String, List<String>> foundFiles = {};
    if (!await Directory(directoryPath).exists()) {
      print('Directory does not exist: $directoryPath');
      return foundFiles;
    }
    try {
      await _traverseDirectory(
          Directory(directoryPath), extensions, foundFiles);
    } catch (e) {
      print('Error while listing directory contents: $e');
    }
    return foundFiles;
  }

  static Future<void> _traverseDirectory(Directory directory,
      List<String> extensions, Map<String, List<String>> foundFiles) async {
    try {
      var entities = await directory.list().toList();
      for (var entity in entities) {
        if (entity is Directory) {
          await _traverseDirectory(entity, extensions, foundFiles);
        } else if (entity is File) {
          _processFile(entity, extensions, foundFiles);
        }
      }
    } catch (e) {
      print('Skipping inaccessible directory: ${directory.path}');
    }
  }

  static void _processFile(File file, List<String> extensions,
      Map<String, List<String>> foundFiles) {
    var filename = file.path.split('/').last;
    for (var extension in extensions) {
      if (filename.toLowerCase().endsWith(extension) ||
          filename.startsWith('.') &&
              filename.substring(1).toLowerCase().endsWith(extension)) {
        foundFiles.putIfAbsent(extension, () => []).add(file.path);
      }
    }
  }
}
