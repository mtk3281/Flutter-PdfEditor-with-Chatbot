import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncPdf;
import 'dart:ui';
import 'package:pdfeditor/widget/snackbar.dart';
import 'package:pdfeditor/widget/listview.dart';
import 'package:hive/hive.dart';

class TextPdfGenerator {
  final BuildContext context;
  TextPdfGenerator(this.context);


  List<String> txt_files = [];

  Future<String?> pickAndConvertTextToPdf() async {

    final box = await Hive.openBox('fileBox');
    txt_files = List<String>.from(box.get('txt_files', defaultValue: []));
    await box.close();

    String? result;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileSelectionPage(filepaths: txt_files,title: "Select Text File",password: false,multipleChoice: false,type:'txt'),
      ),
    ).then((selectedFilePath) {
      if (selectedFilePath != null) {
        result = selectedFilePath;
      }
    });

    if (result == null) {
      return null;
    }
    final textFile = File(result!);
    try {
      final pdfDocument = syncPdf.PdfDocument();
      final page = pdfDocument.pages.add();

      final textContent = await textFile.readAsString();

      final pdfText = syncPdf.PdfTextElement(text: textContent);

      pdfText.font =
          syncPdf.PdfStandardFont(syncPdf.PdfFontFamily.helvetica, 12);

      final layoutResult = pdfText.draw(
        page: page,
        bounds: Rect.fromLTWH(
          10,
          10,
          page.getClientSize().width - 20,
          page.getClientSize().height - 20,
        ),
      );

      // Get the base Download folder
      final downloadsDirectory = Directory('/storage/emulated/0/Download');
      final outputFile = File(
        '${downloadsDirectory.path}/text-to-pdf_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      // Save the PDF bytes to the Downloads folder
      await outputFile.writeAsBytes(await pdfDocument.save());

      print('Text PDF saved successfully: ${outputFile.path}');

      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar(
          "Text to PDF converted successfully",
          310, // Width of the SnackBar
        ),
      );

      pdfDocument.dispose();

      return outputFile.path.toString();
    } catch (e) {
      print('Error converting text to PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar(
          "Unexpected error occurred while converting",
          330, // Width of the SnackBar
        ),
      );
      return null;
    }
  }
}
