import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdfeditor/widget/snackbar.dart';

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class PasswordDialog extends StatefulWidget {
  final File file;
  final bool isAddingPassword; // Flag to determine add/remove password

  const PasswordDialog(
      {Key? key, required this.file, this.isAddingPassword = true})
      : super(key: key);

  @override
  _PasswordDialogState createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
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
                        Text(
                          widget.isAddingPassword
                              ? 'Set Password'
                              : 'Remove Password',
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Enter Password',
                            border: OutlineInputBorder(
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
                              onPressed: () => _performAction(context),
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
                              child: Text(
                                widget.isAddingPassword ? 'Apply' : 'Remove',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
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

  Future<void> _performAction(BuildContext context) async {
    String password = _passwordController.text;
    if (password.isNotEmpty) {
      try {
        if (widget.isAddingPassword) {
          List<int> bytes = await widget.file.readAsBytes();
          PdfDocument document = PdfDocument(inputBytes: bytes);
          document.security.ownerPassword = password;
          document.security.userPassword = password;
          document.security.permissions.addAll([
            PdfPermissionsFlags.print,
            PdfPermissionsFlags.fullQualityPrint,
            PdfPermissionsFlags.copyContent
          ]);
          final List<int> outputBytes = await document.save();

          final downloadsDirectory = Directory('/storage/emulated/0/Download');
          String name = path.basename(widget.file.path);
          final File outputFile = File(
              '${downloadsDirectory.path}/$name _${widget.isAddingPassword ? 'protected' : 'unprotected'}.pdf');
          await outputFile.writeAsBytes(outputBytes, flush: true);

          document.dispose();
        } else {
          List<int> bytes = await widget.file.readAsBytes();

          PdfDocument document =
              PdfDocument(inputBytes: bytes, password: password);
          document.security.userPassword = '';

          File('Output.pdf').writeAsBytes(await document.save());

          document.security.ownerPassword = '';
          document.security.userPassword = '';
          document.security.permissions.clear();
          final List<int> outputBytes = await document.save();

          final downloadsDirectory = Directory('/storage/emulated/0/Download');
          String name = path.basename(widget.file.path);
          final File outputFile = File(
              '${downloadsDirectory.path}/$name _${widget.isAddingPassword ? 'protected' : 'unprotected'}.pdf');
          await outputFile.writeAsBytes(outputBytes, flush: true);

          document.dispose();
        }
        if (widget.isAddingPassword) {
          ScaffoldMessenger.of(context).showSnackBar(
            buildCustomSnackBar(
              'Password set successfully',
              250, // Width of the SnackBar
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            buildCustomSnackBar(
              'Password removed successfully',
              270, // Width of the SnackBar
            ),
          );
        }
        await Future.delayed(Duration(milliseconds: 500));
        Navigator.of(context).pop();
      } catch (e) {
        print('Error setting password: $e');
        // Handle errors appropriately
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar(
          "Please enter a password.",
          230, // Width of the SnackBar
        ),
      );
    }
  }
}
