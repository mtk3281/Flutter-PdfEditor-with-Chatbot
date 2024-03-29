import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdfeditor/widget/snackbar.dart';

class MultiImagePdfGenerator {
  final BuildContext context; // Add a context parameter

  MultiImagePdfGenerator(this.context);

  Future<String?> pickAndConvertImagesToPdf() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) {
      return null; // Handle user cancellation or no files selected
    }

    final List<File> imageFiles =
        result.paths.map((path) => File(path!)).toList();

    try {
      final pdfDocument = PdfDocument();

      for (final imageFile in imageFiles) {
        final page = pdfDocument.pages.add();

        // Read image bytes
        final imageBytes = await imageFile.readAsBytes();

        // Load the image using PdfBitmap
        final PdfBitmap image = PdfBitmap(imageBytes);

        // Draw the image on the page with appropriate scaling
        final double imageAspectRatio = image.width / image.height;
        final double pageAspectRatio =
            page.getClientSize().width / page.getClientSize().height;
        double imageWidth, imageHeight;
        if (imageAspectRatio > pageAspectRatio) {
          imageWidth = page.getClientSize().width;
          imageHeight = imageWidth / imageAspectRatio;
        } else {
          imageHeight = page.getClientSize().height;
          imageWidth = imageHeight * imageAspectRatio;
        }

        final double x = (page.getClientSize().width - imageWidth) / 2;
        final double y = (page.getClientSize().height - imageHeight) / 2;

        page.graphics.drawImage(
          image,
          Rect.fromLTWH(x, y, imageWidth, imageHeight),
        );
      }

      // Get the base Download folder
      final downloadsDirectory = Directory("/storage/emulated/0/Download");
      final outputFile = File(
        '${downloadsDirectory.path}/image-to-pdf_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      // Save the PDF bytes to the Download folder
      await outputFile.writeAsBytes(await pdfDocument.save());

      print('PDF saved successfully to Download folder: ${outputFile.path}');

      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar(
          "Image to PDF converted successfully",
          310, // Width of the SnackBar
        ),
      );

      pdfDocument.dispose(); // Dispose of the PDF document

      return outputFile.path
          .toString(); // Return the path of the saved PDF file
    } catch (e) {
      print('Error converting images to PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar(
          "Unexpected error occurred while converting",
          330, // Width of the SnackBar
        ),
      );
      return null; // Return null in case of error
    }
  }
}
