package com.example.zyro

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class FloatingVideoChannelHandler(private val pipManager: FloatingVideoPipManager) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "zyro/floating_video"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FloatingVideo", "onMethodCall: ${call.method}")
        pipManager.wrapWebChromeClient()
        when (call.method) {
            "isCustomVideoViewActive" -> {
                val isActive = pipManager.customVideoView != null
                Log.d("FloatingVideo", "isCustomVideoViewActive query: $isActive")
                result.success(isActive)
            }
            "setVideoPlaying" -> {
                pipManager.isPlaying = call.argument<Boolean>("isPlaying") ?: false
                pipManager.isVideoPlaying = pipManager.isPlaying
                pipManager.videoWidth = call.argument<Int>("videoWidth") ?: 0
                pipManager.videoHeight = call.argument<Int>("videoHeight") ?: 0
                pipManager.videoTitle = call.argument<String>("videoTitle") ?: ""
                pipManager.pageUrl = call.argument<String>("pageUrl") ?: ""
                pipManager.duration = call.argument<Double>("duration") ?: 0.0
                pipManager.currentTime = call.argument<Double>("currentTime") ?: 0.0
                pipManager.isVisible = call.argument<Boolean>("isVisible") ?: true
                
                // Read coordinates
                pipManager.videoX = call.argument<Double>("videoX") ?: 0.0
                pipManager.videoY = call.argument<Double>("videoY") ?: 0.0
                pipManager.videoRectWidth = call.argument<Double>("videoRectWidth") ?: 0.0
                pipManager.videoRectHeight = call.argument<Double>("videoRectHeight") ?: 0.0
                
                Log.d("FloatingVideo", "setVideoPlaying received: isPlaying=${pipManager.isPlaying}, dimensions=${pipManager.videoWidth}x${pipManager.videoHeight}")
                result.success(null)
            }
            "setVideoStopped" -> {
                pipManager.isPlaying = false
                pipManager.isVideoPlaying = false
                Log.d("FloatingVideo", "setVideoStopped received")
                result.success(null)
            }
            "setFloatingVideoEnabled", "setExtensionEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                pipManager.isFloatingVideosEnabled = enabled
                Log.d("FloatingVideo", "extension enabled state received: $enabled")
                result.success(null)
            }
            "isPipSupported", "isSupported" -> {
                val supported = pipManager.isPipSupported()
                Log.d("FloatingVideo", "PiP supported true/false: $supported")
                result.success(supported)
            }
            "enterPipMode", "enterPiP" -> {
                Log.d("FloatingVideo", "enterPipMode/enterPiP method call received")
                val success = pipManager.enterPipIfPossible()
                result.success(success)
            }
            "updateVideoInfo", "updateVideoMetadata" -> {
                pipManager.videoTitle = call.argument<String>("videoTitle") ?: ""
                pipManager.pageUrl = call.argument<String>("pageUrl") ?: ""
                pipManager.duration = call.argument<Double>("duration") ?: 0.0
                pipManager.currentTime = call.argument<Double>("currentTime") ?: 0.0
                Log.d("FloatingVideo", "updateVideoInfo received: title=${pipManager.videoTitle}")
                result.success(null)
            }
            else -> {
                Log.w("FloatingVideo", "Unknown method: ${call.method}")
                result.notImplemented()
            }
        }
    }
}
