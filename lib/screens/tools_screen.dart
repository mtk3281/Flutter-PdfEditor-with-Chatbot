import 'package:flutter/material.dart';
import 'package:pdfeditor/screens/ToolPage/imgtopdf.dart'; // Import the file containing MultiImagePdfGenerator
import 'package:pdfeditor/screens/ToolPage/txttopdf.dart';
import 'package:pdfeditor/screens/ToolPage/setPassword.dart'; // Import the file containing PasswordProtectPDF
import 'HomePage/pdf_viewer_page.dart';
import 'dart:io';
import 'package:pdfeditor/screens/home_screen.dart';
import 'package:pdfeditor/widget/listview.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdfeditor/widget/snackbar.dart';
import 'ToolPage/printingpdf.dart';
import 'ToolPage/combinepdf.dart';
import 'HomePage/pdf_api.dart';
import 'package:hive/hive.dart';


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
                    Icons.print_rounded,
                    Icons.image,
                    Icons.sort,
                  ],
                  names: [
                    'Print pdf',
                    'Combine Files',
                    'Browse PDF',
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
         String? result = await selectfiles(context,name,false);

        if (result != null && result!.isNotEmpty) {
          File file = File(result!);

          bool isProtected= await isPdfPasswordProtected(file);

          if (!isProtected)
          {
            showDialog(
            context: context,
            builder: (context) =>
                PasswordDialog(file: file, isAddingPassword: true),
            );
          }
          else
          {
             ScaffoldMessenger.of(context).showSnackBar(
            buildCustomSnackBar(
              'PDF already has password',
              250, // Width of the SnackBar
            ),
          );
          }         
        }
      }

      if (name == 'Remove Password') {
       String? result = await selectfiles(context,name,true);

        if (result != null && result!.isNotEmpty) {
          File file = File(result!);
          bool isProtected= await isPdfPasswordProtected(file);

          if (isProtected)
          {
            showDialog(
            context: context,
            builder: (context) =>
                PasswordDialog(file: file, isAddingPassword: true),
            );
          }
          else
          {
             ScaffoldMessenger.of(context).showSnackBar(
            buildCustomSnackBar(
              'PDF does not have a password',
              270, // Width of the SnackBar
            ),
          );

          }
        }
      }

      if (name == 'Print pdf')
      {
        String? result = await selectfiles(context,"Select a file",false);

        if (result != null && result!.isNotEmpty) {
          printPDF(context,result!);
        }
      }
      

      if (name == "Combine Files") {
        List<String> _selectedFilePaths = await selectmultiplefiles(context, name);
        print(_selectedFilePaths);
        String? result = await PdfUtils.combinePdfFiles(_selectedFilePaths, "/storage/emulated/0/Download/combined.pdf");
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
                              buildCustomSnackBar(
                              'PDF combined successfully ',
                                270, 
                              ),
                            );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
                              buildCustomSnackBar(
                              'Failed to combine PDF files ',
                                300, 
                              ),
                            );
      }
      } 

      if (name=="Browse PDF")
      {
        final file = await PDFApi.pickFile();
        if (file == null) return;
        openPDF(context, file);
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


Future<String?> selectfiles(BuildContext context,String name,bool password) async {
  String? result;
  var box = await Hive.openBox('fileBox');
  List<String> pdf_files = List<String>.from(box.get('pdfFiles', defaultValue: []));
  print(pdf_files);
   await Navigator.push(
     context,
     MaterialPageRoute(
       builder: (context) => FileSelectionPage(filepaths: pdf_files,type: name,multipleChoice:false,password: password,),
     ),
   ).then((selectedFilePath) {
     if (selectedFilePath != null) {
       result = selectedFilePath;
     }
   });
  return result;
}

Future<List<String>> selectmultiplefiles(BuildContext context,String name) async {
  List<String> result = [];
  var box = await Hive.openBox('fileBox');
  List<String> pdfFiles = List<String>.from(box.get('pdfFiles', defaultValue: []));
  await box.close();
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FileSelectionPage(
        filepaths: pdfFiles,
        type: name,
        multipleChoice: true,
      ),
    ),
  ).then((selectedFilePath) {
    if (selectedFilePath != null) {
      result = selectedFilePath;
    } else {
      // Handle no files selected
    }
  });

  return result;
}

Future<bool> isPdfPasswordProtected(File file) async {
  bool isProtected = false;
  PdfDocument? document = null; // Assigning null as a default value

  try {
    // Attempt to load the PDF without providing a password
    document = PdfDocument(inputBytes: file.readAsBytesSync());
  } catch (e) {
    // If loading without a password throws an error, the PDF is password protected
    isProtected = true;
  }
  // Dispose the document if it was successfully loaded
  document?.dispose();
  return isProtected;
}


void openPDF(BuildContext context, File file) async {
  var box = await Hive.openBox('fileBox');
  List<String>? recentFiles =  List<String>.from(box.get('recentFiles', defaultValue: []));
  recentFiles.insert(0, file.path);
  await box.put('recentFiles', recentFiles);
  await _pdfEditorKeys.currentState?.loadFiles();

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => PDFViewerPage(file: file, key: UniqueKey()),
    ),
  );
}



