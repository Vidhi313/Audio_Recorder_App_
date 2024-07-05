package com.example.audio_app

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Bundle
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "audio_recorder"
    private var recorder: MediaRecorder? = null
    private var audioManager: AudioManager? = null
    private var mediaPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    if (checkPermission()) {
                        startRecording()
                        result.success("Recording Started")
                    } else {
                        requestPermission()
                        result.error("PERMISSION_DENIED", "Microphone permission denied", null)
                    }
                }
                "stopRecording" -> {
                    stopRecording()
                    result.success("Recording Stopped")
                }
                "getRecordings" -> {
                    val recordings = getRecordings()
                    result.success(recordings)
                }
                "playRecording" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        playRecording(filePath)
                        result.success("Playing recording")
                    } else {
                        result.error("PATH_NOT_FOUND", "File path not provided", null)
                    }
                }
                "stopPlayback" -> {
                    stopPlayback()
                    result.success("Playback Stopped")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startRecording() {
        audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        audioManager?.mode = AudioManager.MODE_IN_COMMUNICATION
        audioManager?.isMicrophoneMute = false

        val outputFile = File(externalCacheDir?.absolutePath, "audiorecordtest_${System.currentTimeMillis()}.3gp")
        recorder = MediaRecorder().apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
            setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
            setOutputFile(outputFile.absolutePath)
            prepare()
            start()
        }
    }

    private fun stopRecording() {
        recorder?.apply {
            stop()
            release()
        }
        recorder = null
        audioManager?.mode = AudioManager.MODE_NORMAL
        audioManager?.isMicrophoneMute = true
    }

    private fun getRecordings(): ArrayList<String> {
        val recordings = ArrayList<String>()
        val directory = externalCacheDir ?: return recordings
        val files = directory.listFiles()
        files?.forEach { file ->
            if (file.isFile && file.extension == "3gp") {
                recordings.add(file.absolutePath)
            }
        }
        return recordings
    }

    private fun playRecording(filePath: String) {
        stopPlayback()
        mediaPlayer = MediaPlayer().apply {
            setDataSource(filePath)
            prepare()
            start()
        }
    }

    private fun stopPlayback() {
        mediaPlayer?.apply {
            if (isPlaying) {
                stop()
            }
            release()
        }
        mediaPlayer = null
    }

    private fun checkPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestPermission() {
        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), 200)
    }
}
