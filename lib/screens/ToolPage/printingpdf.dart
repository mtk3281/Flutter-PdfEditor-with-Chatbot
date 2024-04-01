import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:pdfeditor/widget/snackbar.dart';

Future<void> printPDF(BuildContext context, String filePath) async {
  try {
    final bytes = File(filePath).readAsBytesSync();

    // Print the PDF
    await Printing.layoutPdf(onLayout: (_) => bytes.buffer.asUint8List());

    // Show a Snackbar to indicate successful printing
    ScaffoldMessenger.of(context).showSnackBar(
            buildCustomSnackBar(
              'PDF printed successfully!',
              260, // Width of the SnackBar
            ),
          );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
            buildCustomSnackBar(
              'Failed to print PDF',
              260, // Width of the SnackBar
            ),
          );
  }
}
