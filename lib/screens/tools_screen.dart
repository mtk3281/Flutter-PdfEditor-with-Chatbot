import 'package:flutter/material.dart';
import 'package:pdfeditor/screens/ToolPage/imgtopdf.dart'; // Import the file containing MultiImagePdfGenerator
import 'package:pdfeditor/screens/ToolPage/txttopdf.dart';
import 'package:pdfeditor/screens/ToolPage/setPassword.dart'; // Import the file containing PasswordProtectPDF
import 'HomePage/pdf_viewer_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:pdfeditor/screens/home_screen.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:pdfeditor/widget/listview.dart';

final prefs = SharedPreferences.getInstance();

final GlobalKey<PdfEditorState> _pdfEditorKeys = GlobalKey<PdfEditorState>();

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 0, 0, 0),
          title: const Text(
            'ToolBox',
            style: TextStyle(fontFamily: 'Lato', color: Colors.white),
          ),
          toolbarHeight: 65.0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                buildToolSection(
                  context: context,
                  title: 'Create PDF',
                  icons: [
                    Icons.image,
                    Icons.text_snippet,
                  ],
                  names: [
                    'Create from Images',
                    'Text to PDF',
                  ],
                ),
                const SizedBox(height: 24),
                buildToolSection(
                  context: context,
                  title: 'Security',
                  icons: [
                    Icons.lock,
                    Icons.lock_open,
                  ],
                  names: [
                    'Add Password',
                    'Remove Password',
                  ],
                ),
                const SizedBox(height: 24),
                buildToolSection(
                  context: context,
                  title: 'Edit PDF',
                  icons: [
                    Icons.merge_type,
                    Icons.image,
                    Icons.sort,
                  ],
                  names: [
                    'Combine Files',
                    'Export to Pictures',
                    'Arrange Pages',
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildToolSection({
  required BuildContext context,
  required String title,
  required List<IconData> icons,
  required List<String> names,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Lato',
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 15, // Space buttons evenly
        children: List.generate(
          icons.length,
          (index) => buildToolButton(
            context,
            icons[index],
            names[index],
          ),
        ),
      ),
    ],
  );
}

Widget buildToolButton(BuildContext context, IconData icon, String name) {
  return InkWell(
    borderRadius: BorderRadius.circular(16.0),
    splashColor: const Color.fromARGB(255, 167, 197, 250),
    onTap: () async {
      print('Button Pressed: $name');

      if (name == 'Create from Images') {
        final generator = MultiImagePdfGenerator(context);
        String? filepath = await generator.pickAndConvertImagesToPdf();
        if (filepath != null) {
          openPDF(context, File(filepath));
        }
      }

      if (name == 'Text to PDF') {
        final generator = TextPdfGenerator(context);
        String? filepath = await generator.pickAndConvertTextToPdf();
        if (filepath != null) {
          openPDF(context, File(filepath));
        }
      }

      if (name == 'Add Password') {
        String? result; // Initialize as nullable
        final prefs = await SharedPreferences.getInstance();
        List<String> pdf_files  = prefs.getStringList('pdfFiles') ?? [];
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FileSelectionPage(filepaths: pdf_files,type: "Add Password"),
          ),
        ).then((selectedFilePath) {
          if (selectedFilePath != null) {
            result = selectedFilePath;
          }
        });

        if (result != null && result!.isNotEmpty) {
          File file = File(result!);
          showDialog(
            context: context,
            builder: (context) =>
                PasswordDialog(file: file, isAddingPassword: true),
          );
        }
      }

      if (name == 'Remove Password') {
       String? result; // Initialize as nullable
        final prefs = await SharedPreferences.getInstance();
        List<String> pdf_files  = prefs.getStringList('pdfFiles') ?? [];
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FileSelectionPage(filepaths: pdf_files,type: "Remove Password",),
          ),
        ).then((selectedFilePath) {
          if (selectedFilePath != null) {
            result = selectedFilePath;
          }
        });

        if (result != null && result!.isNotEmpty) {
          File file = File(result!);
          showDialog(
            context: context,
            builder: (context) =>
                PasswordDialog(file: file, isAddingPassword: false),
          );
        }
      }
    },
    child: Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: const Color.fromARGB(171, 228, 242, 255),
      ),
      padding: const EdgeInsets.fromLTRB(6, 26, 6, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 35),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Lato', fontSize: 14),
          ),
        ],
      ),
    ),
  );
}

void openPDF(BuildContext context, File file) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? recentFiles = prefs.getStringList('recentFiles') ?? [];
  recentFiles.insert(0, file.path);
  await prefs.setStringList('recentFiles', recentFiles);
  await _pdfEditorKeys.currentState?.loadFiles();

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => PDFViewerPage(file: file, key: UniqueKey()),
    ),
  );
}
