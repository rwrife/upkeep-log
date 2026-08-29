package com.rwrife.upkeeplog

import android.Manifest
import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingSource: String? = null
    private var pendingCameraFile: File? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "upkeep_log/storage",
        ).setMethodCallHandler { call, result ->
            if (call.method == "getApplicationSupportPath") {
                result.success(filesDir.absolutePath)
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "upkeep_log/attachments",
        ).setMethodCallHandler { call, result ->
            if (call.method != "pick" || pendingResult != null) {
                if (call.method != "pick") result.notImplemented()
                else result.error("picker_busy", "Another picker is already open", null)
                return@setMethodCallHandler
            }
            pendingResult = result
            pendingSource = call.argument<String>("source")
            when (pendingSource) {
                "camera" -> openCamera()
                "photoLibrary" -> openPicker("image/*")
                "document" -> openPicker("*/*")
                else -> finishError("invalid_source", "Unknown attachment source")
            }
        }
    }

    private fun openCamera() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), CAMERA_PERMISSION)
            return
        }
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        if (intent.resolveActivity(packageManager) == null) {
            finishError("camera_unavailable", "No camera app is available")
            return
        }
        val file = try {
            File.createTempFile("upkeep-camera-", ".jpg", cacheDir)
        } catch (error: Exception) {
            finishError("camera_unavailable", error.message ?: "Could not prepare camera output")
            return
        }
        pendingCameraFile = file
        val output = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        intent.putExtra(MediaStore.EXTRA_OUTPUT, output)
        intent.clipData = ClipData.newRawUri("camera-output", output)
        intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
        try {
            startActivityForResult(intent, PICK_CAMERA)
        } catch (error: Exception) {
            cleanupCameraFile()
            finishError("camera_unavailable", error.message ?: "Could not open camera")
        }
    }

    private fun openPicker(type: String) {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            this.type = type
        }
        if (intent.resolveActivity(packageManager) == null) {
            finishError("picker_unavailable", "No compatible file picker is available")
            return
        }
        try {
            startActivityForResult(intent, PICK_DOCUMENT)
        } catch (error: Exception) {
            finishError("picker_unavailable", error.message ?: "Could not open file picker")
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != CAMERA_PERMISSION) return
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) openCamera()
        else finishError("permission_denied", "Camera permission was denied")
    }

    @Deprecated("Deprecated in Android API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_CAMERA && requestCode != PICK_DOCUMENT) return
        if (resultCode != Activity.RESULT_OK) {
            if (requestCode == PICK_CAMERA) cleanupCameraFile()
            finishSuccess(null)
            return
        }
        try {
            if (requestCode == PICK_CAMERA) {
                val file = pendingCameraFile
                    ?: throw IllegalStateException("Camera output is unavailable")
                require(file.isFile && file.length() > 0) { "Camera returned no image" }
                pendingCameraFile = null
                finishSuccess(mapOf("path" to file.absolutePath, "mediaType" to "image/jpeg", "ownedTemporary" to true))
            } else {
                copySelection(data?.data ?: throw IllegalStateException("Picker returned no file"))
            }
        } catch (error: Exception) {
            if (requestCode == PICK_CAMERA) cleanupCameraFile()
            finishError("selection_unavailable", error.message ?: "Could not read selection")
        }
    }

    private fun copySelection(uri: Uri) {
        val type = contentResolver.getType(uri) ?: "application/octet-stream"
        val extension = android.webkit.MimeTypeMap.getSingleton().getExtensionFromMimeType(type)
        val file = File.createTempFile("upkeep-selection-", extension?.let { ".$it" }, cacheDir)
        try {
            contentResolver.openInputStream(uri).use { input ->
                requireNotNull(input) { "Could not open selection" }
                file.outputStream().use { output -> input.copyTo(output) }
            }
        } catch (error: Exception) {
            file.delete()
            throw error
        }
        finishSuccess(mapOf("path" to file.absolutePath, "mediaType" to type, "ownedTemporary" to true))
    }

    private fun finishSuccess(value: Map<String, Any>?) {
        pendingResult?.success(value)
        pendingResult = null
        pendingSource = null
    }

    private fun finishError(code: String, message: String) {
        pendingResult?.error(code, message, null)
        pendingResult = null
        pendingSource = null
    }

    private fun cleanupCameraFile() {
        pendingCameraFile?.delete()
        pendingCameraFile = null
    }

    companion object {
        private const val CAMERA_PERMISSION = 801
        private const val PICK_CAMERA = 802
        private const val PICK_DOCUMENT = 803
    }
}
