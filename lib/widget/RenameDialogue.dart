import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path; // For file path manipulation

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class RenameDialog extends StatefulWidget {
  final String currentName;
  final String filePath;

  const RenameDialog({
    super.key,
    required this.currentName,
    required this.filePath,
  });

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  final _newNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _newNameController.text = widget.currentName;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Builder(builder: (context) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          body: Builder(
            builder: (context) {
              return Center(
                child: Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 25.0,
                      top: 20,
                      right: 25,
                      bottom: 25,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rename File',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          controller: _newNameController,
                          decoration: InputDecoration(
                            hintText: 'Enter new name',
                            border: OutlineInputBorder(
                              gapPadding: 0,
                              borderRadius: BorderRadius.circular(25.0),
                              borderSide: BorderSide(
                                color: Colors.grey[400]!,
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                  side: BorderSide(color: Colors.grey[400]!),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            ElevatedButton(
                              onPressed: () async {
                                final newFileName = _newNameController.text;
                                final fileExtension =
                                    path.extension(widget.filePath);
                                final newFilePath = path.join(
                                  path.dirname(widget.filePath),
                                  '$newFileName$fileExtension',
                                );
                                if (File(newFilePath).existsSync()) {
                                  showSnackBar(
                                    context,
                                    'File with the same name already exists',
                                    true,
                                    310,
                                  );
                                  return; // Return early if the file with the same name already exists
                                }

                                if (newFileName.isEmpty) {
                                  showSnackBar(
                                      context,
                                      'Please enter a valid file name',
                                      true,
                                      260);
                                  return; // Return early if the new file name is empty
                                }

                                if (newFileName ==
                                    path.basenameWithoutExtension(
                                        widget.filePath)) {
                                  showSnackBar(
                                      context,
                                      'New file name cannot be the same',
                                      true,
                                      290);
                                  return; // Return early if the new file name is the same as the current file name
                                }
                                try {
                                  // final renamedFile = File(newFilePath);

                                  File res = File(widget.filePath)
                                      .renameSync(newFilePath);

                                  Navigator.pop(
                                      context, res.path); // Return new path
                                } catch (error) {
                                  Navigator.pop(context, null);
                                  showSnackBar(context, 'Failed to rename file',
                                      true, 210);
                                }
                              },
                              // ignore: sort_child_properties_last
                              child: const Text(
                                'Rename',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                shadowColor: Colors.transparent,
                                backgroundColor: Colors.red[600],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void showSnackBar(
      BuildContext context, String message, bool isError, double width) {
    final snackBar = SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 4.0),
          if (isError)
            const Icon(Icons.error_outline_outlined, color: Colors.red),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black, // Black background color
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0),
      ),
      width: width,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
