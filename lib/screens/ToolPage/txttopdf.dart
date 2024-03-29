import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncPdf;
import 'dart:ui'; // Import Rect from dart:ui
import 'package:pdfeditor/widget/snackbar.dart';

class TextPdfGenerator {
  final BuildContext context;

  TextPdfGenerator(this.context);

  Future<String?> pickAndConvertTextToPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final textFile = File(result.files.single.path!);

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
