package com.example.zyro

import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "zyro/downloads"
    
    // Dedicated Floating Videos PiP manager
    private lateinit var pipManager: FloatingVideoPipManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize PipManager
        pipManager = FloatingVideoPipManager(this)
        LogSingle.d("MainActivity", "channel registered: zyro/floating_video")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enqueueDownload" -> enqueueDownload(call, result)
                    "queryDownload" -> queryDownload(call, result)
                    else -> result.notImplemented()
                }
            }

        val backgroundPlayerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zyro/background_player")
        backgroundPlayerChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val title = call.argument<String>("title") ?: "Playing in Zyro Browser"
                    val website = call.argument<String>("website") ?: "Zyro Browser"
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    val positionMs = call.argument<Number>("positionMs")?.toLong() ?: 0L
                    val durationMs = call.argument<Number>("durationMs")?.toLong() ?: 0L
                    val nextTitle = call.argument<String>("nextTitle") ?: ""
                    
                    val intent = Intent(this, BackgroundPlayerService::class.java).apply {
                        putExtra("title", title)
                        putExtra("website", website)
                        putExtra("isPlaying", isPlaying)
                        putExtra("positionMs", positionMs)
                        putExtra("durationMs", durationMs)
                        putExtra("nextTitle", nextTitle)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "updateState" -> {
                    if (BackgroundPlayerService.isServiceRunning) {
                        val title = call.argument<String>("title")
                        val website = call.argument<String>("website")
                        val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                        val positionMs = call.argument<Number>("positionMs")?.toLong() ?: 0L
                        val durationMs = call.argument<Number>("durationMs")?.toLong() ?: 0L
                        val nextTitle = call.argument<String>("nextTitle") ?: ""
                        
                        val intent = Intent(this, BackgroundPlayerService::class.java).apply {
                            if (title != null) putExtra("title", title)
                            if (website != null) putExtra("website", website)
                            putExtra("isPlaying", isPlaying)
                            putExtra("positionMs", positionMs)
                            putExtra("durationMs", durationMs)
                            putExtra("nextTitle", nextTitle)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                    }
                    result.success(null)
                }
                "stopService" -> {
                    val intent = Intent(this, BackgroundPlayerService::class.java).apply {
                        action = "STOP"
                    }
                    startService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        BackgroundPlayerService.onMediaAction = { action ->
            runOnUiThread {
                if (action.startsWith("seekTo:")) {
                    val posMs = action.substringAfter("seekTo:").toLongOrNull()
                    if (posMs != null) {
                        backgroundPlayerChannel.invokeMethod("seekTo", mapOf("positionMs" to posMs))
                    }
                } else {
                    backgroundPlayerChannel.invokeMethod(action, null)
                }
            }
        }

        // Register Floating Videos MethodChannel
        val floatingVideoChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FloatingVideoChannelHandler.CHANNEL_NAME)
        floatingVideoChannel.setMethodCallHandler(FloatingVideoChannelHandler(pipManager))
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        android.util.Log.d("FloatingVideo", "onUserLeaveHint called")
        if (::pipManager.isInitialized) {
            pipManager.enterPipIfPossible()
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode)
        android.util.Log.d("FloatingVideo", "onPictureInPictureModeChanged: isInPictureInPictureMode = $isInPictureInPictureMode")
        runOnUiThread {
            val channel = MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger ?: return@runOnUiThread, FloatingVideoChannelHandler.CHANNEL_NAME)
            if (isInPictureInPictureMode) {
                android.util.Log.d("FloatingVideo", "PiP entered successfully")
                channel.invokeMethod("onPipEntered", null)
            } else {
                android.util.Log.d("FloatingVideo", "PiP exited")
                channel.invokeMethod("onPipExited", null)
            }
        }
    }

    private fun enqueueDownload(call: MethodCall, result: MethodChannel.Result) {
        try {
            val url = call.argument<String>("url") ?: run {
                result.error("INVALID_URL", "Missing download URL", null)
                return
            }
            val fileName = call.argument<String>("fileName") ?: run {
                result.error("INVALID_FILE", "Missing file name", null)
                return
            }
            val subDirectory = call.argument<String>("subDirectory") ?: "zyro/video"
            val title = call.argument<String>("title") ?: fileName
            val description = call.argument<String>("description") ?: title
            val mimeType = call.argument<String>("mimeType")

            val request = DownloadManager.Request(Uri.parse(url)).apply {
                setTitle(title)
                setDescription(description)
                setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                setAllowedOverMetered(true)
                setAllowedOverRoaming(true)
                allowScanningByMediaScanner()
                mimeType?.let { setMimeType(it) }
                setDestinationInExternalPublicDir(
                    Environment.DIRECTORY_DOWNLOADS,
                    "$subDirectory/$fileName"
                )
            }

            val manager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
            val downloadId = manager.enqueue(request)
            val filePath = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                "$subDirectory/$fileName"
            ).absolutePath

            result.success(
                mapOf(
                    "downloadId" to downloadId,
                    "filePath" to filePath
                )
            )
        } catch (e: Exception) {
            result.error("ENQUEUE_FAILED", e.message, null)
        }
    }

    private fun queryDownload(call: MethodCall, result: MethodChannel.Result) {
        try {
            val downloadId = call.argument<Number>("downloadId")?.toLong() ?: run {
                result.error("INVALID_ID", "Missing download ID", null)
                return
            }

            val manager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
            val query = DownloadManager.Query().setFilterById(downloadId)
            manager.query(query).use { cursor ->
                if (!cursor.moveToFirst()) {
                    result.success(
                        mapOf(
                            "status" to "FAILED",
                            "reason" to "Download record not found"
                        )
                    )
                    return
                }

                val status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
                val downloadedBytes =
                    cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR))
                val totalBytes =
                    cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES))
                val localUri =
                    cursor.getString(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_LOCAL_URI))
                val reason =
                    cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON))

                result.success(
                    mapOf(
                        "status" to statusToString(status),
                        "downloadedBytes" to downloadedBytes,
                        "totalBytes" to totalBytes,
                        "localPath" to uriToFilePath(localUri),
                        "reason" to reason.toString()
                    )
                )
            }
        } catch (e: Exception) {
            result.error("QUERY_FAILED", e.message, null)
        }
    }

    private fun statusToString(status: Int): String {
        return when (status) {
            DownloadManager.STATUS_SUCCESSFUL -> "SUCCESSFUL"
            DownloadManager.STATUS_FAILED -> "FAILED"
            DownloadManager.STATUS_RUNNING -> "RUNNING"
            DownloadManager.STATUS_PENDING -> "PENDING"
            DownloadManager.STATUS_PAUSED -> "PAUSED"
            else -> "UNKNOWN"
        }
    }

    private fun uriToFilePath(localUri: String?): String? {
        if (localUri.isNullOrBlank()) return null
        val parsed = Uri.parse(localUri)
        return if (parsed.scheme == "file") parsed.path else localUri
    }
}

// Simple Log helper object to avoid compilation issue with LogSingle
object LogSingle {
    fun d(tag: String, msg: String) {
        android.util.Log.d(tag, msg)
    }
}
