package com.example.zyro

import android.app.Activity
import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import android.util.Rational
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView

class FloatingVideoPipManager(private val activity: Activity) {
    var isFloatingVideosEnabled = false
    var isPlaying = false
    var isVideoPlaying = false
    var isVisible = false
    var videoTitle = ""
    var pageUrl = ""
    var videoWidth = 0
    var videoHeight = 0
    var duration = 0.0
    var currentTime = 0.0

    // Custom view representing the fullscreen video view from WebChromeClient
    var customVideoView: View? = null

    // Coordinates for source rect hint
    var videoX = 0.0
    var videoY = 0.0
    var videoRectWidth = 0.0
    var videoRectHeight = 0.0

    fun isPipSupported(): Boolean {
        val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                activity.packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
        Log.d("FloatingVideo", "PiP support available check: $supported")
        return supported
    }

    fun wrapWebChromeClient() {
        activity.runOnUiThread {
            try {
                val decorView = activity.window?.decorView ?: return@runOnUiThread
                val webViews = findWebViews(decorView)
                for (webView in webViews) {
                    val currentClient = webView.webChromeClient
                    if (currentClient != null && currentClient !is ZyroVideoChromeClient) {
                        webView.webChromeClient = ZyroVideoChromeClient(currentClient, this)
                        Log.d("FloatingVideo", "Wrapped WebChromeClient of WebView")
                    }
                }
            } catch (e: Exception) {
                Log.e("FloatingVideo", "Error wrapping WebChromeClient: ${e.message}")
            }
        }
    }

    private fun findWebViews(view: View): List<WebView> {
        val webViews = mutableListOf<WebView>()
        if (view is WebView) {
            webViews.add(view)
        } else if (view is ViewGroup) {
            for (i in 0 until view.childCount) {
                webViews.addAll(findWebViews(view.getChildAt(i)))
            }
        }
        return webViews
    }

    fun enterPipIfPossible(): Boolean {
        Log.d("FloatingVideo", "onUserLeaveHint called")
        Log.d("FloatingVideo", "Home/minimize detected")
        
        Log.d("FloatingVideo", "Floating Videos enabled=$isFloatingVideosEnabled")
        if (!isFloatingVideosEnabled) {
            Log.d("FloatingVideo", "PiP failed: Floating Videos extension is disabled")
            return false
        }

        Log.d("FloatingVideo", "Active video cached=$isVideoPlaying")
        if (!isVideoPlaying && customVideoView == null) {
            Log.d("FloatingVideo", "PiP failed: No active video playing")
            return false
        }

        val pipSupp = isPipSupported()
        Log.d("FloatingVideo", "PiP supported=$pipSupp")
        if (!pipSupp) {
            Log.d("FloatingVideo", "PiP failed: Device does not support PiP")
            return false
        }

        val customAvail = customVideoView != null
        Log.d("FloatingVideo", "Custom video view available=$customAvail")

        if (customAvail) {
            Log.d("FloatingVideo", "Using custom video view PiP")
        } else {
            Log.d("FloatingVideo", "Using Activity WebView PiP fallback")
        }

        var finalWidth = videoWidth
        var finalHeight = videoHeight

        if (finalWidth <= 0 || finalHeight <= 0) {
            Log.d("FloatingVideo", "Invalid video dimensions ignored")
            // Fallback to cached or standard 16:9
            finalWidth = 1920
            finalHeight = 1080
            Log.d("FloatingVideo", "Cached video dimensions used")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (activity.isInPictureInPictureMode) {
                Log.d("FloatingVideo", "PiP failed: Already in PiP mode")
                return false
            }
            try {
                // Sizing Aspect Ratio rules
                val aspectRatio = if (finalWidth > 0 && finalHeight > 0) {
                    Rational(finalWidth, finalHeight)
                } else {
                    Rational(16, 9)
                }

                Log.d("FloatingVideo", "Entering PiP with native video surface")
                Log.d("FloatingVideo", "PiP requested")

                val builder = PictureInPictureParams.Builder()
                    .setAspectRatio(aspectRatio)

                // Source rect hint for smooth zooming
                if (videoRectWidth > 0 && videoRectHeight > 0) {
                    val density = activity.resources.displayMetrics.density
                    val left = (videoX * density).toInt()
                    val top = (videoY * density).toInt()
                    val right = ((videoX + videoRectWidth) * density).toInt()
                    val bottom = ((videoY + videoRectHeight) * density).toInt()
                    builder.setSourceRectHint(android.graphics.Rect(left, top, right, bottom))
                    Log.d("FloatingVideo", "PiP source rect hint applied")
                }
                
                val success = activity.enterPictureInPictureMode(builder.build())
                if (success) {
                    Log.d("FloatingVideo", "PiP entered")
                } else {
                    Log.d("FloatingVideo", "PiP failed: enterPictureInPictureMode returned false")
                }
                return success
            } catch (e: Exception) {
                Log.e("FloatingVideo", "PiP failed: ${e.message}")
            }
        } else {
            Log.d("FloatingVideo", "PiP failed: Android API level < 26")
        }
        return false
    }
}
