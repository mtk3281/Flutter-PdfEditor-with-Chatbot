package com.example.pdfeditor

import android.os.Bundle
import android.os.Environment
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.app/files"
    private val supportedExtensions = setOf("pdf", "txt", "ppt", "pptx", "doc", "docx")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAllFilePaths") {
                val paths = getAllFilePaths()
                result.success(paths.toList())
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
}
