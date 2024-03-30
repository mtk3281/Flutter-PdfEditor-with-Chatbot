import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncPdf;
import 'dart:ui';
import 'package:pdfeditor/widget/snackbar.dart';
import 'package:pdfeditor/widget/listview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextPdfGenerator {
  final BuildContext context;
  TextPdfGenerator(this.context);

  final prefs = SharedPreferences.getInstance();
  List<String> txt_files = [];
  Future<String?> pickAndConvertTextToPdf() async {
    final prefs = await SharedPreferences.getInstance();

    txt_files = prefs.getStringList('txt_files') ?? [];
    String? result; // Initialize as nullable

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileSelectionPage(filepaths: txt_files,type: "Select Text File",),
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

      // Initialize PdfText correctly
      final pdfText = syncPdf.PdfTextElement(text: textContent);

      // Customize text formatting (optional)
      pdfText.font =
          syncPdf.PdfStandardFont(syncPdf.PdfFontFamily.helvetica, 12);

      // Layout the text on the page
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
          "Image to PDF converted successfully",
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
