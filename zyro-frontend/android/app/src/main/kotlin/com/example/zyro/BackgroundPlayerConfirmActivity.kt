package com.example.zyro

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.os.Bundle

class BackgroundPlayerConfirmActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        android.util.Log.d("BackgroundPlayer", "Close clicked: BackgroundPlayerConfirmActivity created.")
        
        android.util.Log.d("BackgroundPlayer", "Confirmation shown: displaying Stop background playback dialog.")
        AlertDialog.Builder(this)
            .setTitle("Stop Background Player")
            .setMessage("Stop background playback?")
            .setPositiveButton("Stop") { _, _ ->
                android.util.Log.d("BackgroundPlayer", "Stop confirmed by the user.")
                val intent = Intent(this, BackgroundPlayerService::class.java).apply {
                    action = "STOP_CONFIRMED"
                }
                startService(intent)
                finish()
            }
            .setNegativeButton("Cancel") { _, _ ->
                android.util.Log.d("BackgroundPlayer", "Stop cancelled by the user.")
                finish()
            }
            .setOnCancelListener {
                android.util.Log.d("BackgroundPlayer", "Stop dialog cancelled/dismissed.")
                finish()
            }
            .show()
    }
}
