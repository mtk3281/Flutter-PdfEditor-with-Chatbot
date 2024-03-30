import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncPdf;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:pdfeditor/widget/snackbar.dart';

class ExcelToPdfConverter {
  final BuildContext context;

  ExcelToPdfConverter(this.context);

  Future<String?> pickAndConvertExcelToPdf() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'], // Allow Excel extensions
    );

    if (result == null || result.files.isEmpty) {
      return null; // Handle user cancellation or no files selected
    }

    final excelFile = File(result.files.single.path!);

    try {
      // Read Excel data
      var bytes = await excelFile.readAsBytes();
      var decoder = SpreadsheetDecoder.decodeBytes(bytes);
      var sheetData = decoder.tables['Sheet1']!.rows; // Assuming sheet name

      // Create a new PDF document
      final pdfDocument = syncPdf.PdfDocument();

      // Add a new page for each row of data
      for (final dataRow in sheetData) {
        final page = pdfDocument.pages.add();

        // Draw each row on the page
        _drawRow(page, dataRow);
      }

      // Save the PDF document to the Download folder
      final downloadsDirectory = await getExternalStorageDirectory();
      final outputFile = File(
        '${downloadsDirectory!.path}/excel-to-pdf_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await outputFile.writeAsBytes(await pdfDocument.save());

      print('PDF saved successfully to Download folder: ${outputFile.path}');

      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar(
          "Excel to PDF converted successfully",
          320, // Adjust SnackBar width
        ),
      );

      return outputFile.path.toString();
    } catch (e) {
      print('Error converting Excel to PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar(
          "Excel conversion failed",
          300, // Adjust SnackBar width
        ),
      );
      return null;
    }
  }

  void _drawRow(syncPdf.PdfPage page, List<dynamic> dataRow) {
    double yPosition = 20; // Initial Y position
    final cellWidth = (page.getClientSize().width - 40) / dataRow.length;

    for (final cellData in dataRow) {
      final cellText = cellData.toString();
      final cell = Rect.fromLTWH(
        20,
        yPosition,
        cellWidth,
        20,
      ); // Define cell rectangle
      page.graphics.drawRectangle(
        pen: syncPdf.PdfPen(syncPdf.PdfColor(0, 0, 0)),
        brush: syncPdf.PdfSolidBrush(syncPdf.PdfColor(255, 255, 255)),
        bounds: cell,
      );
      page.graphics.drawString(
        cellText,
        syncPdf.PdfStandardFont(syncPdf.PdfFontFamily.helvetica, 12),
        bounds: cell.deflate(2),
        brush: syncPdf.PdfSolidBrush(syncPdf.PdfColor(0, 0, 0)),
      );

      yPosition += 20; // Increment Y position for next row
    }
  }
}
