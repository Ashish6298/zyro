package com.example.zyro

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.MediaMetadata
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.view.KeyEvent
import java.util.ArrayList

class BackgroundPlayerService : Service() {

    companion object {
        const val CHANNEL_ID = "zyro_background_player_channel"
        const val NOTIFICATION_ID = 90210
        
        var isServiceRunning = false
        var onMediaAction: ((String) -> Unit)? = null
        var instance: BackgroundPlayerService? = null
    }

    private var mediaSession: MediaSession? = null
    private var wakeLock: PowerManager.WakeLock? = null

    private var currentTitle: String = "Playing in Zyro Browser"
    private var currentWebsite: String = "Zyro Browser"
    private var currentIsPlaying: Boolean = false
    private var currentPositionMs: Long = 0L
    private var currentDurationMs: Long = 0L
    private var currentNextTitle: String = ""
    private var isForeground = false
    private var lastTitle: String? = null
    private var lastWebsite: String? = null
    private var lastDuration: Long? = null

    override fun onCreate() {
        super.onCreate()
        isServiceRunning = true
        instance = this
        
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Zyro::BackgroundPlayerWakeLock").apply {
                acquire(30 * 60 * 1000L)
            }
            android.util.Log.d("BackgroundPlayer", "WakeLock acquired successfully.")
        } catch (e: Exception) {
            android.util.Log.e("BackgroundPlayer", "Failed to acquire WakeLock: ${e.message}")
        }
        
        createNotificationChannel()
        setupMediaSession()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Background Player"
            val descriptionText = "Controls for background media playback"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun setupMediaSession() {
        mediaSession = MediaSession(this, "ZyroMediaSession").apply {
            setFlags(MediaSession.FLAG_HANDLES_MEDIA_BUTTONS or MediaSession.FLAG_HANDLES_TRANSPORT_CONTROLS)
            
            setCallback(object : MediaSession.Callback() {
                override fun onPlay() {
                    super.onPlay()
                    onMediaAction?.invoke("play")
                }

                override fun onPause() {
                    super.onPause()
                    onMediaAction?.invoke("pause")
                }

                override fun onSkipToNext() {
                    super.onSkipToNext()
                    onMediaAction?.invoke("next")
                }

                override fun onSkipToPrevious() {
                    super.onSkipToPrevious()
                    onMediaAction?.invoke("previous")
                }

                override fun onSeekTo(pos: Long) {
                    super.onSeekTo(pos)
                    onMediaAction?.invoke("seekTo:$pos")
                }

                override fun onMediaButtonEvent(mediaButtonIntent: Intent): Boolean {
                    val keyEvent = mediaButtonIntent.getParcelableExtra<KeyEvent>(Intent.EXTRA_KEY_EVENT)
                    if (keyEvent != null && keyEvent.action == KeyEvent.ACTION_DOWN) {
                        when (keyEvent.keyCode) {
                            KeyEvent.KEYCODE_MEDIA_PLAY -> {
                                onMediaAction?.invoke("play")
                                return true
                            }
                            KeyEvent.KEYCODE_MEDIA_PAUSE -> {
                                onMediaAction?.invoke("pause")
                                return true
                            }
                            KeyEvent.KEYCODE_MEDIA_NEXT -> {
                                onMediaAction?.invoke("next")
                                return true
                            }
                            KeyEvent.KEYCODE_MEDIA_PREVIOUS -> {
                                onMediaAction?.invoke("previous")
                                return true
                            }
                        }
                    }
                    return super.onMediaButtonEvent(mediaButtonIntent)
                }
            })
            
            isActive = true
        }
    }

    private fun formatTime(ms: Long): String {
        val totalSeconds = ms / 1000
        val seconds = totalSeconds % 60
        val minutes = (totalSeconds / 60) % 60
        val hours = totalSeconds / 3600
        return if (hours > 0) {
            String.format("%d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format("%d:%02d", minutes, seconds)
        }
    }

    private fun formatRemainingTime(currentMs: Long, totalMs: Long): String {
        val remainingMs = totalMs - currentMs
        if (remainingMs <= 0) return "0:00"
        return "-" + formatTime(remainingMs)
    }

    private fun getProgressTextBar(positionMs: Long, durationMs: Long): String {
        if (durationMs <= 0) return ""
        val totalBlocks = 15
        val progressFraction = positionMs.toDouble() / durationMs.toDouble()
        val filledBlocks = (progressFraction * totalBlocks).coerceIn(0.0, totalBlocks.toDouble()).toInt()
        val sb = StringBuilder()
        for (i in 0 until totalBlocks) {
            if (i == filledBlocks) {
                sb.append("●")
            } else if (i < filledBlocks) {
                sb.append("▬")
            } else {
                sb.append("─")
            }
        }
        return sb.toString()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == "STOP_CONFIRMED") {
            android.util.Log.d("BackgroundPlayer", "stop confirmed: removing notification and service")
            onMediaAction?.invoke("pause")
            stopForeground(true)
            isForeground = false
            stopSelf()
            android.util.Log.d("BackgroundPlayer", "notification removed")
            return START_NOT_STICKY
        } else if (action == "STOP") {
            android.util.Log.d("BackgroundPlayer", "stop service requested: removing notification and service")
            stopForeground(true)
            isForeground = false
            stopSelf()
            android.util.Log.d("BackgroundPlayer", "notification removed")
            return START_NOT_STICKY
        } else if (action == "PLAY") {
            android.util.Log.d("BackgroundPlayer", "play clicked from notification")
            onMediaAction?.invoke("play")
            return START_NOT_STICKY
        } else if (action == "PAUSE") {
            android.util.Log.d("BackgroundPlayer", "pause clicked from notification")
            onMediaAction?.invoke("pause")
            return START_NOT_STICKY
        } else if (action == "NEXT") {
            onMediaAction?.invoke("next")
            return START_NOT_STICKY
        } else if (action == "PREV") {
            onMediaAction?.invoke("previous")
            return START_NOT_STICKY
        }

        intent?.getStringExtra("title")?.let { currentTitle = it }
        intent?.getStringExtra("website")?.let { currentWebsite = it }
        if (intent != null && intent.hasExtra("isPlaying")) {
            val oldPlaying = currentIsPlaying
            currentIsPlaying = intent.getBooleanExtra("isPlaying", false)
            if (!currentIsPlaying && oldPlaying) {
                android.util.Log.d("BackgroundPlayer", "notification kept alive after pause")
            }
        }
        if (intent != null && intent.hasExtra("positionMs")) {
            currentPositionMs = intent.getLongExtra("positionMs", 0L)
            android.util.Log.d("BackgroundPlayer", "timer extracted: $currentPositionMs")
        }
        if (intent != null && intent.hasExtra("durationMs")) {
            currentDurationMs = intent.getLongExtra("durationMs", 0L)
            android.util.Log.d("BackgroundPlayer", "duration extracted: $currentDurationMs")
        }
        intent?.getStringExtra("nextTitle")?.let { currentNextTitle = it }

        android.util.Log.d("BackgroundPlayer", "progress updated: $currentPositionMs of $currentDurationMs")
        updateSessionAndNotification()

        return START_NOT_STICKY
    }

    private fun updateSessionAndNotification() {
        val mediaSession = this.mediaSession ?: return

        val timerText = if (currentDurationMs > 0) {
            "${formatTime(currentPositionMs)} / ${formatTime(currentDurationMs)}"
        } else {
            formatTime(currentPositionMs)
        }

        val subtitle = "$timerText • $currentWebsite"

        android.util.Log.d("BackgroundPlayer", "waveform/progress rendered")

        // Update MediaSession state
        val stateBuilder = PlaybackState.Builder()
            .setActions(
                PlaybackState.ACTION_PLAY or
                PlaybackState.ACTION_PAUSE or
                PlaybackState.ACTION_STOP or
                PlaybackState.ACTION_SKIP_TO_NEXT or
                PlaybackState.ACTION_SKIP_TO_PREVIOUS or
                PlaybackState.ACTION_PLAY_PAUSE or
                PlaybackState.ACTION_SEEK_TO or
                PlaybackState.ACTION_FAST_FORWARD or
                PlaybackState.ACTION_REWIND
            )
            .setState(
                if (currentIsPlaying) PlaybackState.STATE_PLAYING else PlaybackState.STATE_PAUSED,
                currentPositionMs,
                if (currentIsPlaying) 1.0f else 0.0f
            )
        mediaSession.setPlaybackState(stateBuilder.build())

        // Update MediaSession metadata only if it changed
        if (currentTitle != lastTitle || currentWebsite != lastWebsite || currentDurationMs != lastDuration) {
            val metadataBuilder = MediaMetadata.Builder()
                .putString(MediaMetadata.METADATA_KEY_TITLE, currentTitle)
                .putString(MediaMetadata.METADATA_KEY_ARTIST, currentWebsite)
            if (currentDurationMs > 0) {
                metadataBuilder.putLong(MediaMetadata.METADATA_KEY_DURATION, currentDurationMs)
            }
            mediaSession.setMetadata(metadataBuilder.build())
            lastTitle = currentTitle
            lastWebsite = currentWebsite
            lastDuration = currentDurationMs
        }

        // Build notification
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }

        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val prevPending = PendingIntent.getService(
            this, 1,
            Intent(this, BackgroundPlayerService::class.java).apply { action = "PREV" },
            pendingIntentFlags
        )
        val playPausePending = PendingIntent.getService(
            this, 2,
            Intent(this, BackgroundPlayerService::class.java).apply { action = if (currentIsPlaying) "PAUSE" else "PLAY" },
            pendingIntentFlags
        )
        val nextPending = PendingIntent.getService(
            this, 3,
            Intent(this, BackgroundPlayerService::class.java).apply { action = "NEXT" },
            pendingIntentFlags
        )
        val stopPending = PendingIntent.getActivity(
            this, 4,
            Intent(this, BackgroundPlayerConfirmActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            },
            pendingIntentFlags
        )

        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentPending = PendingIntent.getActivity(
            this, 0, openAppIntent, pendingIntentFlags
        )

        builder.setContentTitle(currentTitle)
            .setContentText(subtitle)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(contentPending)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setShowWhen(false)
            .setOngoing(true)

        builder.addAction(
            Notification.Action.Builder(
                android.R.drawable.ic_media_previous, "Previous", prevPending
            ).build()
        )

        val playPauseIcon = if (currentIsPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
        val playPauseTitle = if (currentIsPlaying) "Pause" else "Play"
        builder.addAction(
            Notification.Action.Builder(
                playPauseIcon, playPauseTitle, playPausePending
            ).build()
        )

        builder.addAction(
            Notification.Action.Builder(
                android.R.drawable.ic_media_next, "Next", nextPending
            ).build()
        )

        builder.addAction(
            Notification.Action.Builder(
                android.R.drawable.ic_menu_close_clear_cancel, "Close", stopPending
            ).build()
        )

        val mediaStyle = Notification.MediaStyle()
            .setMediaSession(mediaSession.sessionToken)
            .setShowActionsInCompactView(0, 1, 2)

        builder.setStyle(mediaStyle)

        val notification = builder.build()
        if (!isForeground) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            isForeground = true
        } else {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, notification)
        }
    }

    fun updatePlaybackStateAndMetadata(
        title: String,
        website: String,
        isPlaying: Boolean,
        positionMs: Long,
        durationMs: Long,
        nextTitle: String
    ) {
        currentTitle = title
        currentWebsite = website
        val oldPlaying = currentIsPlaying
        currentIsPlaying = isPlaying
        if (!currentIsPlaying && oldPlaying) {
            android.util.Log.d("BackgroundPlayer", "notification kept alive after pause")
        }
        currentPositionMs = positionMs
        currentDurationMs = durationMs
        currentNextTitle = nextTitle

        android.util.Log.d("BackgroundPlayer", "timer extracted: $currentPositionMs")
        android.util.Log.d("BackgroundPlayer", "duration extracted: $currentDurationMs")
        android.util.Log.d("BackgroundPlayer", "progress updated: $currentPositionMs of $currentDurationMs")

        updateSessionAndNotification()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        isServiceRunning = false
        isForeground = false
        lastTitle = null
        lastWebsite = null
        lastDuration = null
        instance = null
        mediaSession?.apply {
            isActive = false
            release()
        }
        wakeLock?.apply {
            if (isHeld) {
                release()
            }
        }
        android.util.Log.d("BackgroundPlayer", "notification removed")
        super.onDestroy()
    }
}
