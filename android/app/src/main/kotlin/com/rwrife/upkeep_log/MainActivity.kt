package com.rwrife.upkeeplog

import android.Manifest
import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.time.ZoneId

class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingSource: String? = null
    private var pendingCameraFile: File? = null
    private var pendingReminderPermissionResult: MethodChannel.Result? = null
    private var pendingImportResult: MethodChannel.Result? = null
    private var pendingExportResult: MethodChannel.Result? = null
    private var pendingExportPath: String? = null
    private var exportInteractionPausedActivity = false

    override fun onPause() {
        if (pendingExportResult != null) exportInteractionPausedActivity = true
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        if (pendingExportResult != null && exportInteractionPausedActivity) {
            val result = pendingExportResult
            val path = pendingExportPath
            pendingExportResult = null
            pendingExportPath = null
            exportInteractionPausedActivity = false
            // Android does not report whether the receiving app retained the
            // content. The only knowable success is the prepared local path.
            result?.success(path)
        }
    }

    override fun onDestroy() {
        val export = pendingExportResult
        val import = pendingImportResult
        pendingExportResult = null
        pendingExportPath = null
        pendingImportResult = null
        exportInteractionPausedActivity = false
        export?.error("transfer_interrupted", "Export was interrupted by an activity restart", null)
        import?.error("transfer_interrupted", "Import was interrupted by an activity restart", null)
        super.onDestroy()
    }

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
            "upkeep_log/data_transfer",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "export" -> exportData(call.argument("suggestedName") ?: "upkeep-export", call.argument("mediaType") ?: "application/octet-stream", call.argument<ByteArray>("bytes") ?: byteArrayOf(), result)
                "import" -> importBackup(result)
                else -> result.notImplemented()
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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "upkeep_log/reminders",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTimeZoneId" -> result.success(ZoneId.systemDefault().id)
                "getPermissionStatus" -> result.success(notificationPermissionStatus())
                "requestPermission" -> requestNotificationPermission(result)
                "replaceAll" -> {
                    try {
                        val reminders = call.argument<List<Map<String, Any?>>>("reminders")
                            ?: emptyList()
                        val count = ReminderScheduler.replaceAll(this, reminders)
                        result.success(
                            mapOf(
                                "scheduledCount" to count,
                                "limitation" to "Android may delay inexact alarms because of battery and device policy.",
                            ),
                        )
                    } catch (error: Exception) {
                        result.error("schedule_failed", error.message, null)
                    }
                }
                "openSettings" -> {
                    val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun notificationPermissionStatus(): String {
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            val requested = getSharedPreferences(REMINDER_PERMISSION_PREFERENCES, MODE_PRIVATE)
                .getBoolean(REMINDER_PERMISSION_REQUESTED, false)
            return if (requested) "denied" else "notDetermined"
        }
        return if (NotificationManagerCompat.from(this).areNotificationsEnabled()) "granted" else "denied"
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < 33 ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(notificationPermissionStatus())
            return
        }
        if (pendingReminderPermissionResult != null) {
            result.error("permission_busy", "A notification permission request is already active", null)
            return
        }
        pendingReminderPermissionResult = result
        getSharedPreferences(REMINDER_PERMISSION_PREFERENCES, MODE_PRIVATE)
            .edit()
            .putBoolean(REMINDER_PERMISSION_REQUESTED, true)
            .apply()
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION,
        )
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
        if (requestCode == NOTIFICATION_PERMISSION) {
            pendingReminderPermissionResult?.success(notificationPermissionStatus())
            pendingReminderPermissionResult = null
            return
        }
        if (requestCode != CAMERA_PERMISSION) return
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) openCamera()
        else finishError("permission_denied", "Camera permission was denied")
    }

    @Deprecated("Deprecated in Android API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == IMPORT_BACKUP) {
            val result = pendingImportResult
            pendingImportResult = null
            if (resultCode != Activity.RESULT_OK) { result?.success(null); return }
            try {
                val source = data?.data ?: throw IllegalStateException("Picker returned no file")
                contentResolver.openAssetFileDescriptor(source, "r")?.use {
                    if (it.length > MAX_BACKUP_ARCHIVE_BYTES) throw IllegalArgumentException("Backup archive exceeds the 256 MiB size limit")
                }
                val file = File.createTempFile("upkeep-import-", ".zip", cacheDir)
                try {
                    contentResolver.openInputStream(source).use { input ->
                        requireNotNull(input) { "Could not open backup" }
                        file.outputStream().use { output ->
                            val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                            var total = 0L
                            while (true) {
                                val read = input.read(buffer)
                                if (read < 0) break
                                total += read
                                if (total > MAX_BACKUP_ARCHIVE_BYTES) throw IllegalArgumentException("Backup archive exceeds the 256 MiB size limit")
                                output.write(buffer, 0, read)
                            }
                        }
                    }
                } catch (error: Exception) {
                    file.delete()
                    throw error
                }
                result?.success(file.absolutePath)
            } catch (error: Exception) {
                val code = if (error is IllegalArgumentException && error.message?.contains("256 MiB") == true) "archive_too_large" else "import_failed"
                result?.error(code, error.message ?: "Could not import backup", null)
            }
            return
        }
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

    private fun exportData(name: String, mediaType: String, bytes: ByteArray, result: MethodChannel.Result) {
        if (pendingExportResult != null || pendingImportResult != null) {
            result.error("transfer_busy", "Another data transfer is already active", null)
            return
        }
        try {
            val safeName = name.replace(Regex("[^A-Za-z0-9._-]"), "_")
            val suffix = safeName.substringAfterLast('.', "").let { if (it.isEmpty()) null else ".$it" }
            val file = File.createTempFile("upkeep-export-", suffix, cacheDir)
            file.writeBytes(bytes)
            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = mediaType
                putExtra(Intent.EXTRA_STREAM, uri)
                clipData = ClipData.newRawUri(name, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            pendingExportResult = result
            pendingExportPath = file.absolutePath
            exportInteractionPausedActivity = false
            startActivity(Intent.createChooser(intent, "Export Upkeep Log data"))
        } catch (error: Exception) {
            pendingExportResult = null
            pendingExportPath = null
            exportInteractionPausedActivity = false
            result.error("export_failed", error.message, null)
        }
    }

    private fun importBackup(result: MethodChannel.Result) {
        if (pendingImportResult != null || pendingExportResult != null) {
            result.error("transfer_busy", "Another data transfer is already active", null)
            return
        }
        pendingImportResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/zip"
        }
        try { startActivityForResult(intent, IMPORT_BACKUP) }
        catch (error: Exception) { pendingImportResult = null; result.error("picker_unavailable", error.message, null) }
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
        private const val MAX_BACKUP_ARCHIVE_BYTES = 256L * 1024L * 1024L
        private const val CAMERA_PERMISSION = 801
        private const val PICK_CAMERA = 802
        private const val PICK_DOCUMENT = 803
        private const val NOTIFICATION_PERMISSION = 804
        private const val IMPORT_BACKUP = 805
        private const val REMINDER_PERMISSION_PREFERENCES = "upkeep_reminders"
        private const val REMINDER_PERMISSION_REQUESTED = "permission_requested"
    }
}
