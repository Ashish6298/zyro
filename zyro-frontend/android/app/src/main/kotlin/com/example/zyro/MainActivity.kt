package com.example.zyro

import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.graphics.pdf.PdfDocument
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView

class MainActivity : FlutterActivity() {
    private val channelName = "zyro/downloads"
    private val openWebAppAction = "com.example.zyro.OPEN_WEB_APP"
    private var webAppChannel: MethodChannel? = null
    private var pendingWebAppUrl: String? = null
    private var initialShortcutUrl: String? = null
    private var flutterEngineReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleWebAppShortcutIntent(intent, fromNewIntent = false)
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enqueueDownload" -> enqueueDownload(call, result)
                    "queryDownload" -> queryDownload(call, result)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zyro/screenshot_pro")
            .setMethodCallHandler { call, result ->
                if (call.method == "exportWebViewPdf") {
                    exportWebViewPdf(call.argument<String>("title") ?: "Zyro page", result)
                } else {
                    result.notImplemented()
                }
            }

        webAppChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zyro/web_apps")
        webAppChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "pinWebAppShortcut" -> pinWebAppShortcut(call, result)
                "getPinnedShortcutIds" -> getPinnedShortcutIds(result)
                "getInitialShortcutUrl" -> result.success(initialShortcutUrl)
                else -> result.notImplemented()
            }
        }
        flutterEngineReady = true
        android.util.Log.d("WEB_APPS", "Flutter engine ready")
        deliverPendingWebAppUrl()

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

    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleWebAppShortcutIntent(intent, fromNewIntent = true)
        deliverPendingWebAppUrl()
    }

    private fun handleWebAppShortcutIntent(intent: Intent?, fromNewIntent: Boolean) {
        if (intent == null) return

        val action = intent.action
        val source = intent.getStringExtra("web_app_source")
        val shortcutUrl = intent.getStringExtra("web_app_url")
            ?: intent.getStringExtra("zyro_web_app_url")
        val isWebAppShortcut = action == openWebAppAction ||
            source == "home_screen_shortcut" ||
            !shortcutUrl.isNullOrBlank()

        if (!isWebAppShortcut) return

        android.util.Log.d("WEB_APPS", "Shortcut launch received in MainActivity")
        if (shortcutUrl.isNullOrBlank() || !isValidWebAppUrl(shortcutUrl)) {
            android.util.Log.e("WEB_APPS", "Invalid shortcut URL fallback to normal launch")
            return
        }

        android.util.Log.d("WEB_APPS", "Shortcut URL extracted: $shortcutUrl")
        pendingWebAppUrl = shortcutUrl
        initialShortcutUrl = shortcutUrl
        if (!fromNewIntent) {
            android.util.Log.d("WEB_APPS", "Pending shortcut URL cached for Flutter")
        }
    }

    private fun deliverPendingWebAppUrl() {
        val shortcutUrl = pendingWebAppUrl
        if (shortcutUrl.isNullOrBlank()) return

        if (!flutterEngineReady || webAppChannel == null) {
            android.util.Log.d("WEB_APPS", "Flutter engine not ready, keeping pending shortcut URL")
            return
        }

        pendingWebAppUrl = null
        android.util.Log.d("WEB_APPS", "Pending shortcut URL delivered")
        webAppChannel?.invokeMethod("webAppShortcutLaunched", mapOf("url" to shortcutUrl))
    }

    private fun isValidWebAppUrl(url: String): Boolean {
        return try {
            val parsed = Uri.parse(url)
            parsed.scheme == "http" || parsed.scheme == "https"
        } catch (error: Exception) {
            false
        }
    }

    private fun pinWebAppShortcut(call: MethodCall, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(mapOf("supported" to false, "message" to "Home screen shortcuts are not supported on this device"))
            return
        }

        val shortcutManager = getSystemService(ShortcutManager::class.java)
        if (shortcutManager == null || !shortcutManager.isRequestPinShortcutSupported) {
            result.success(mapOf("supported" to false, "message" to "Home screen shortcuts are not supported on this device"))
            return
        }

        val id = call.argument<String>("id") ?: "zyro_webapp_${System.currentTimeMillis()}"
        val name = cleanShortcutLabel(call.argument<String>("name") ?: "Zyro App", 40)
        val shortLabel = cleanShortcutLabel(name, 10)
        val longLabel = buildShortcutLongLabel(name)
        val url = call.argument<String>("url") ?: run {
            result.error("INVALID_URL", "Missing web app URL", null)
            return
        }
        val iconPath = call.argument<String>("iconPath")

        val launchIntent = Intent(this, MainActivity::class.java).apply {
            action = openWebAppAction
            putExtra("web_app_id", id)
            putExtra("web_app_name", name)
            putExtra("web_app_url", url)
            putExtra("web_app_source", "home_screen_shortcut")
            putExtra("zyro_web_app_url", url)
            putExtra("zyro_web_app_id", id)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        android.util.Log.d("WEB_APPS", "Shortcut intent created with URL: $url")

        val iconBitmap = decodeShortcutIcon(name, iconPath)
        val shortcut = ShortcutInfo.Builder(this, id)
            .setShortLabel(shortLabel)
            .setLongLabel(longLabel)
            .setIcon(Icon.createWithBitmap(iconBitmap))
            .setIntent(launchIntent)
            .build()

        try {
            val requested = shortcutManager.requestPinShortcut(shortcut, null)
            android.util.Log.d("WEB_APPS", "Shortcut created/requested")
            result.success(mapOf("supported" to true, "requested" to requested))
        } catch (error: Exception) {
            result.error("SHORTCUT_FAILED", error.message ?: "Unable to pin shortcut", null)
        }
    }

    private fun getPinnedShortcutIds(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            android.util.Log.d("WEB_APPS", "Unsupported launcher shortcut query, skipping sync")
            result.success(mapOf("supported" to false, "ids" to emptyList<String>()))
            return
        }

        try {
            val shortcutManager = getSystemService(ShortcutManager::class.java)
            if (shortcutManager == null) {
                android.util.Log.d("WEB_APPS", "Unsupported launcher shortcut query, skipping sync")
                result.success(mapOf("supported" to false, "ids" to emptyList<String>()))
                return
            }

            val pinnedIds = shortcutManager.pinnedShortcuts.map { it.id }
            android.util.Log.d("WEB_APPS", "Pinned shortcut ids fetched: $pinnedIds")
            result.success(mapOf("supported" to true, "ids" to pinnedIds))
        } catch (error: Exception) {
            android.util.Log.e("WEB_APPS", "Shortcut sync failed, no apps removed", error)
            result.success(mapOf("supported" to false, "ids" to emptyList<String>()))
        }
    }

    private fun decodeShortcutIcon(name: String, iconPath: String?): Bitmap {
        if (!iconPath.isNullOrBlank()) {
            val raw = BitmapFactory.decodeFile(iconPath)
            if (raw != null) {
                android.util.Log.d("WEB_APPS", "Decoded shortcut bitmap size=${raw.width}x${raw.height}")
                val sourceBlank = isBlankBitmap(raw)
                val sourceTooSmall = raw.width < 32 || raw.height < 32
                android.util.Log.d("WEB_APPS", "Shortcut source bitmap blank=$sourceBlank tooSmall=$sourceTooSmall")
                if (!sourceBlank && !sourceTooSmall) {
                    val normalized = normalizeShortcutBitmap(raw)
                    android.util.Log.d("WEB_APPS", "Shortcut created with real icon")
                    return normalized
                }
            } else {
                android.util.Log.d("WEB_APPS", "Shortcut icon decode failed for path=$iconPath")
            }
        }
        android.util.Log.d("WEB_APPS", "Fallback icon used")
        return createFallbackIcon(name)
    }

    private fun normalizeShortcutBitmap(source: Bitmap): Bitmap {
        val size = 512
        val padding = 56f
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val background = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.rgb(244, 246, 255) }
        canvas.drawRoundRect(0f, 0f, size.toFloat(), size.toFloat(), 112f, 112f, background)

        val crop = source.width.coerceAtMost(source.height).coerceAtLeast(1)
        val left = ((source.width - crop) / 2f).coerceAtLeast(0f)
        val top = ((source.height - crop) / 2f).coerceAtLeast(0f)
        val src = RectF(left, top, left + crop, top + crop)
        val dst = RectF(padding, padding, size - padding, size - padding)
        val matrix = Matrix().apply { setRectToRect(src, dst, Matrix.ScaleToFit.CENTER) }
        val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG or Paint.DITHER_FLAG)
        canvas.drawBitmap(source, matrix, paint)
        return output
    }

    private fun isBlankBitmap(bitmap: Bitmap): Boolean {
        val stepX = (bitmap.width / 24).coerceAtLeast(1)
        val stepY = (bitmap.height / 24).coerceAtLeast(1)
        var visible = 0
        var varied = 0
        var first: Int? = null
        var nonWhite = 0
        var y = 0
        while (y < bitmap.height) {
            var x = 0
            while (x < bitmap.width) {
                val color = bitmap.getPixel(x, y)
                val alpha = Color.alpha(color)
                if (alpha > 12) visible++
                first = first ?: color
                if (color != first) varied++
                if (alpha > 12 && colorDistanceFromWhite(color) > 18) nonWhite++
                x += stepX
            }
            y += stepY
        }
        return visible < 6 || varied < 2 || nonWhite < 3
    }

    private fun colorDistanceFromWhite(color: Int): Int {
        return (255 - Color.red(color)) + (255 - Color.green(color)) + (255 - Color.blue(color))
    }

    private fun createFallbackIcon(name: String): Bitmap {
        val size = 512
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val background = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.rgb(91, 79, 242) }
        canvas.drawRoundRect(0f, 0f, size.toFloat(), size.toFloat(), 112f, 112f, background)
        val accent = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.rgb(22, 197, 178) }
        canvas.drawCircle(size * 0.78f, size * 0.22f, size * 0.18f, accent)
        val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textAlign = Paint.Align.CENTER
            textSize = 220f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }
        val letter = name.trim().firstOrNull()?.uppercaseChar()?.toString() ?: "Z"
        val y = size / 2f - (text.descent() + text.ascent()) / 2f
        canvas.drawText(letter, size / 2f, y, text)
        return bitmap
    }

    private fun cleanShortcutLabel(raw: String, maxLength: Int): String {
        val cleaned = raw.trim().replace(Regex("\\s+"), " ")
        val label = if (cleaned.isBlank() || cleaned.equals("Zyro App", ignoreCase = true)) {
            "Web App"
        } else {
            cleaned
        }
        return label.take(maxLength).trim().ifBlank { "Web App" }
    }

    private fun buildShortcutLongLabel(name: String): String {
        val label = cleanShortcutLabel(name, 40)
        val withBrowser = "$label - Zyro Browser"
        return if (withBrowser.length <= 40) withBrowser else label
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

    private fun exportWebViewPdf(title: String, result: MethodChannel.Result) {
        val webView = findWebView(window.decorView)
        if (webView == null) {
            result.error("WEBVIEW_UNAVAILABLE", "Active WebView is unavailable", null)
            return
        }
        val folder = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "zyro/screenshots")
        if (!folder.exists() && !folder.mkdirs()) {
            result.error("STORAGE_UNAVAILABLE", "Unable to create screenshots folder", null)
            return
        }
        val safeTitle = title.replace(Regex("[^A-Za-z0-9._-]"), "_").take(48)
        val fileName = "zyro_page_${safeTitle}_${System.currentTimeMillis()}.pdf"
        val output = File(folder, fileName)
        try {
            val width = webView.width.coerceAtLeast(1)
            val height = webView.height.coerceAtLeast(1)
            val document = PdfDocument()
            val page = document.startPage(PdfDocument.PageInfo.Builder(width, height, 1).create())
            webView.draw(page.canvas)
            document.finishPage(page)
            output.outputStream().use { document.writeTo(it) }
            document.close()
            result.success(mapOf("filePath" to output.absolutePath, "fileName" to fileName))
        } catch (error: Exception) {
            result.error("PDF_EXPORT_FAILED", error.message ?: "PDF export failed", null)
        }
    }

    private fun findWebView(view: View): WebView? {
        if (view is WebView) return view
        if (view is ViewGroup) {
            for (index in 0 until view.childCount) {
                findWebView(view.getChildAt(index))?.let { return it }
            }
        }
        return null
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
