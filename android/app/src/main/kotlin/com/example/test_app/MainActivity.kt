package com.example.test_app

import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.smartdairy/native_pdf"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "savePdfToDownloads" -> {
                    try {
                        val fileName = call.argument<String>("fileName") ?: "SmartDairy_Document.pdf"
                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes == null || bytes.isEmpty()) {
                            result.error("EMPTY_BYTES", "PDF byte array is empty", null)
                            return@setMethodCallHandler
                        }

                        // 1. Always cache in internal app cache for immediate opening/sharing
                        val cacheFile = File(cacheDir, fileName)
                        cacheFile.writeBytes(bytes)

                        var savedToDownloads = false
                        var finalPath = cacheFile.absolutePath

                        // 2. Modern Android Q+ (API 29+) MediaStore.Downloads (Public Downloads folder)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            try {
                                val contentValues = ContentValues().apply {
                                    put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                                    put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
                                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                                }
                                val resolver = applicationContext.contentResolver
                                val downloadUri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                                if (downloadUri != null) {
                                    resolver.openOutputStream(downloadUri)?.use { os ->
                                        os.write(bytes)
                                        os.flush()
                                    }
                                    contentValues.clear()
                                    contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
                                    resolver.update(downloadUri, contentValues, null, null)
                                    savedToDownloads = true
                                    finalPath = "/storage/emulated/0/Download/$fileName"
                                }
                            } catch (e: Exception) {
                                e.printStackTrace()
                            }
                        }

                        // 3. Fallback / Direct External Storage Downloads writing & MediaScanner registration
                        try {
                            val pubDownloadDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                            if (!pubDownloadDir.exists()) {
                                pubDownloadDir.mkdirs()
                            }
                            val pubFile = File(pubDownloadDir, fileName)
                            pubFile.writeBytes(bytes)
                            MediaScannerConnection.scanFile(
                                applicationContext,
                                arrayOf(pubFile.absolutePath),
                                arrayOf("application/pdf")
                            ) { _, _ -> }
                            savedToDownloads = true
                            finalPath = pubFile.absolutePath
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }

                        val resultMap = hashMapOf<String, Any>(
                            "success" to true,
                            "filePath" to finalPath,
                            "fileName" to fileName,
                            "fileSize" to bytes.size,
                            "isPublicDownload" to savedToDownloads
                        )
                        result.success(resultMap)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.localizedMessage, null)
                    }
                }

                "openPdf" -> {
                    try {
                        val fileName = call.argument<String>("fileName") ?: "SmartDairy_Document.pdf"
                        val bytes = call.argument<ByteArray>("bytes")

                        val file = File(cacheDir, fileName)
                        if (bytes != null && bytes.isNotEmpty()) {
                            file.writeBytes(bytes)
                        }

                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "PDF file does not exist", null)
                            return@setMethodCallHandler
                        }

                        val uri: Uri = FileProvider.getUriForFile(
                            applicationContext,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )

                        val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/pdf")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }

                        startActivity(Intent.createChooser(viewIntent, "Open PDF with..."))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OPEN_FAILED", e.localizedMessage, null)
                    }
                }

                "sharePdf" -> {
                    try {
                        val fileName = call.argument<String>("fileName") ?: "SmartDairy_Document.pdf"
                        val bytes = call.argument<ByteArray>("bytes")
                        val summaryText = call.argument<String>("summaryText")

                        val file = File(cacheDir, fileName)
                        if (bytes != null && bytes.isNotEmpty()) {
                            file.writeBytes(bytes)
                        }

                        val uri: Uri = FileProvider.getUriForFile(
                            applicationContext,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )

                        val shareIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "application/pdf"
                            putExtra(Intent.EXTRA_STREAM, uri)
                            if (!summaryText.isNullOrBlank()) {
                                putExtra(Intent.EXTRA_TEXT, summaryText)
                            }
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }

                        val chooser = Intent.createChooser(shareIntent, "Share PDF Statement...").apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(chooser)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SHARE_FAILED", e.localizedMessage, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
