package com.example.pdfeditor

import android.os.Bundle
import android.os.Environment
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import com.itextpdf.text.Document
import com.itextpdf.text.pdf.PdfCopy
import com.itextpdf.text.pdf.PdfReader
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val FILE_CHANNEL = "com.example.app/files"
    private val PDF_CHANNEL = "com.example.app/pdf"

    private val supportedExtensions = setOf("pdf", "txt", "ppt", "pptx", "doc", "docx")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Handle method channel for scanning files
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAllFilePaths") {
                val paths = getAllFilePaths()
                result.success(paths.toList())
            } else {
                result.notImplemented()
            }
        }

        // Handle method channel for combining PDF files
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PDF_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "combinePdfFiles") {
                val pdfPaths = call.argument<List<String>>("pdfPaths")
                val combinedPdfPath = call.argument<String>("combinedPdfPath")
                if (pdfPaths != null && combinedPdfPath != null) {
                    combinePdfFiles(pdfPaths, combinedPdfPath)
                    result.success(combinedPdfPath)
                } else {
                    result.error("INVALID_ARGUMENTS", "PDF paths or combined PDF path not provided", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getAllFilePaths(): List<String> {
        val paths = mutableListOf<String>()
        try {
            val root = Environment.getExternalStorageDirectory()
            getFilePaths(root, paths)
        } catch (e: SecurityException) {
            Log.e("FileSystemService", "Permission denied: ${e.message}")
        }
        return paths.toList()
    }

    private fun getFilePaths(directory: File, paths: MutableList<String>) {
        directory.listFiles()?.forEach { file ->
            if (file.isDirectory) {
                try {
                    getFilePaths(file, paths)
                } catch (e: SecurityException) {
                    Log.e("FileSystemService", "Permission denied for directory: ${file.absolutePath}")
                }
            } else if (isSupportedExtension(file.name)) {
                paths.add(file.absolutePath)
            }
        }
    }

    private fun isSupportedExtension(fileName: String): Boolean {
        val extension = fileName.substringAfterLast('.', "").lowercase() // Get extension efficiently
        return extension in supportedExtensions
    }

    private fun combinePdfFiles(pdfPaths: List<String>, combinedPdfPath: String) {
        val document = Document()
        val copy = PdfCopy(document, FileOutputStream(combinedPdfPath))
        document.open()

        for (pdfPath in pdfPaths) {
            val reader = PdfReader(pdfPath)
            copy.addDocument(reader)
            reader.close()
        }

        document.close()
    }
}
