package com.example.zyro

import android.app.Activity
import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import android.util.Rational

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

    fun isPipSupported(): Boolean {
        val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                activity.packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
        Log.d("FloatingVideo", "PiP support available check: $supported")
        return supported
    }

    fun enterPipIfPossible(): Boolean {
        Log.d("FloatingVideo", "app minimizing, checking PiP suitability.")
        Log.d("FloatingVideo", "PiP conditions checked: enabled=$isFloatingVideosEnabled, playing=$isVideoPlaying, visible=$isVisible, width=$videoWidth, height=$videoHeight, duration=$duration")

        if (!isFloatingVideosEnabled) {
            Log.d("FloatingVideo", "PiP blocked with reason: Floating Videos extension is disabled")
            return false
        }
        if (!isVideoPlaying) {
            Log.d("FloatingVideo", "PiP blocked with reason: Video is not playing")
            return false
        }
        if (!isVisible) {
            Log.d("FloatingVideo", "PiP blocked with reason: Video is not visible")
            return false
        }
        if (videoWidth <= 0 || videoHeight <= 0) {
            Log.d("FloatingVideo", "PiP warning: Video dimensions are invalid (${videoWidth}x${videoHeight}), using 16:9 fallback")
            videoWidth = 1920
            videoHeight = 1080
        }
        if (duration <= 0) {
            Log.d("FloatingVideo", "PiP warning: Video duration is invalid ($duration), allowing PiP anyway")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (activity.isInPictureInPictureMode) {
                Log.d("FloatingVideo", "PiP blocked with reason: Already in PiP mode")
                return false
            }
            try {
                val builder = PictureInPictureParams.Builder()
                var width = videoWidth
                var height = videoHeight
                val ratio = width.toFloat() / height.toFloat()
                if (ratio > 2.39f) {
                    width = (height * 2.39f).toInt()
                } else if (ratio < 1f / 2.39f) {
                    height = (width * 2.39f).toInt()
                }
                builder.setAspectRatio(Rational(width, height))
                
                Log.d("FloatingVideo", "PiP enter requested with aspect ratio: $width:$height")
                val success = activity.enterPictureInPictureMode(builder.build())
                Log.d("FloatingVideo", "PiP entered successfully: $success")
                return success
            } catch (e: Exception) {
                Log.e("FloatingVideo", "PiP failed reason: ${e.message}")
            }
        } else {
            Log.d("FloatingVideo", "PiP blocked with reason: Android API level < 26")
        }
        return false
    }
}
