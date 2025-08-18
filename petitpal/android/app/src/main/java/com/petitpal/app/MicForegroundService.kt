package com.petitpal.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo // ⬅️ added
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.util.Base64
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL

class MicForegroundService : Service() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var mediaRecorder: MediaRecorder? = null
    private var mediaPlayer: MediaPlayer? = null
    private var isRecording = false

    private val channelId = "petitpal_mic"
    private val notificationId = 1001

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    // ⬇️ helper to satisfy Android 14 (API 34) service-type requirement
    private fun startFg(text: String) {
        val notif = buildNotif(text)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                val types = ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE or
                            ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                startForeground(notificationId, notif, types)
            } else {
                startForeground(notificationId, notif)
            }
        } catch (_: Exception) {
            // last-ditch fallback so we never crash here
            try { startForeground(notificationId, notif) } catch (_: Exception) {}
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "com.petitpal.app.ACTION_TOGGLE" -> {
                if (isRecording) {
                    stopRecordingAndProcess()
                } else {
                    // instant visual feedback
                    updateWidgetState("listening")

                    // guardrails: mic + config
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                        checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED
                    ) {
                        updateWidgetState("idle")
                        startFg("Microphone permission required")
                        stopSelfSafely("Mic permission missing")
                        return START_NOT_STICKY
                    }
                    val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                    val oaiKey = prefs.getString("pp_oai_key", null)
                    val workerBase = prefs.getString("pp_worker_base", null)
                    if (oaiKey.isNullOrBlank() || workerBase.isNullOrBlank()) {
                        updateWidgetState("idle")
                        startFg("Set API key in PetitPal Settings")
                        stopSelfSafely("Missing key or worker")
                        return START_NOT_STICKY
                    }

                    // start foreground + record
                    startFg("Listening… tap again to stop")
                    startRecording()
                }
            }
            else -> {
                updateWidgetState("listening")
                startFg("Listening… tap again to stop")
                startRecording()
            }
        }
        return START_NOT_STICKY
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val chan = NotificationChannel(
                channelId,
                "PetitPal Voice",
                NotificationManager.IMPORTANCE_LOW
            )
            chan.setSound(null, null)
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(chan)
        }
    }

    private fun buildNotif(text: String): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("PetitPal")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun updateWidgetState(state: String) {
        val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        prefs.edit().putString("mic_widget_state", state).apply()

        val appWidgetManager = AppWidgetManager.getInstance(this)
        val cn = ComponentName(this, MicWidgetProvider::class.java)
        val ids = appWidgetManager.getAppWidgetIds(cn)
        val intent = Intent(this, MicWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        sendBroadcast(intent)
    }

    private fun startRecording() {
        try {
            val outFile = File(cacheDir, "pp_widget_rec.m4a")
            if (outFile.exists()) outFile.delete()

            mediaRecorder = MediaRecorder().apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioSamplingRate(44100)
                setAudioEncodingBitRate(128000)
                setOutputFile(outFile.absolutePath)
                prepare()
                start()
            }
            isRecording = true

            scope.launch {
                delay(8000)
                if (isRecording) stopRecordingAndProcess()
            }
        } catch (e: Exception) {
            stopSelfSafely("Mic error: $e")
        }
    }

    private fun stopRecordingAndProcess() {
        try {
            mediaRecorder?.apply {
                try { stop() } catch (_: Exception) {}
                reset()
                release()
            }
        } catch (_: Exception) {}
        mediaRecorder = null
        isRecording = false
        updateWidgetState("thinking")
        scope.launch { processAndRespond() }
    }

    private suspend fun processAndRespond() {
        try {
            val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val oaiKey = prefs.getString("pp_oai_key", null)
            val workerBase = prefs.getString("pp_worker_base", null)
            if (oaiKey.isNullOrBlank() || workerBase.isNullOrBlank()) {
                stopSelfSafely("Missing API key or Worker base URL")
                return
            }

            val file = File(cacheDir, "pp_widget_rec.m4a")
            if (!file.exists()) {
                stopSelfSafely("No audio file")
                return
            }

            val url = URL("$workerBase/api/voice_chat")
            val conn = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                doOutput = true
                setRequestProperty("Authorization", "Bearer $oaiKey")
                setRequestProperty("Content-Type", "audio/m4a")
                connectTimeout = 20000
                readTimeout = 60000
            }
            file.inputStream().use { ins ->
                conn.outputStream.use { outs -> ins.copyTo(outs) }
            }

            val code = conn.responseCode
            val bodyStream = if (code in 200..299) conn.inputStream else conn.errorStream
            val body = bodyStream.bufferedReader().use { it.readText() }
            if (code !in 200..299) {
                stopSelfSafely("Upstream error $code: $body")
                return
            }

            val json = JSONObject(body)
            val audioB64 = json.optString("audio_b64", null)
            val answerText = json.optString("text", "")
            if (audioB64 == null) {
                stopSelfSafely("No audio in response")
                return
            }

            val mp3File = File(cacheDir, "pp_widget_tts.mp3")
            val audioBytes = Base64.decode(audioB64, Base64.DEFAULT)
            FileOutputStream(mp3File).use { it.write(audioBytes) }

            playAudio(mp3File) {
                updateWidgetState("idle")
                stopSelfSafely("Done")
            }

            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(notificationId, buildNotif("Speaking: $answerText"))

        } catch (e: Exception) {
            stopSelfSafely("Error: $e")
        }
    }

    private fun playAudio(file: File, onDone: () -> Unit) {
        try {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                setDataSource(file.absolutePath)
                setOnCompletionListener { onDone() }
                prepare()
                start()
            }
        } catch (e: Exception) {
            onDone()
        }
    }

    private fun stopSelfSafely(reason: String) {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(notificationId)
        } catch (_: Exception) {}
        updateWidgetState("idle")
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        super.onDestroy()
        try { mediaRecorder?.release() } catch (_: Exception) {}
        try { mediaPlayer?.release() } catch (_: Exception) {}
        scope.cancel()
    }
}
