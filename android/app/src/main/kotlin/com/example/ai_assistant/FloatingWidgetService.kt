package com.example.ai_assistant

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.Toast
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class FloatingWidgetService : Service() {
    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var params: WindowManager.LayoutParams? = null
    private var speechRecognizer: SpeechRecognizer? = null
    private val CHANNEL_ID = "FloatingWidgetChannel"
    private val NOTIFICATION_ID = 1

    companion object {
        var methodChannel: MethodChannel? = null
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        
        // Create notification channel for foreground service
        createNotificationChannel()
        
        // Start service as foreground
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // Initialize window manager and layout params
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        
        // Initialize floating view
        initializeFloatingView()
        
        // Initialize speech recognizer
        initializeSpeechRecognizer()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Floating Widget Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Voice Assistant")
            .setContentText("Voice commands are active")
            .setSmallIcon(R.drawable.ic_mic) // Make sure to have this icon in your resources
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
    
    private fun initializeFloatingView() {
        // Inflate the floating view layout
        floatingView = LayoutInflater.from(this).inflate(R.layout.layout_floating_widget, null)
        
        // Set up layout parameters for the floating view
        params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        
        // Initial position
        params?.gravity = Gravity.TOP or Gravity.START
        params?.x = 0
        params?.y = 100
        
        // Add the view to the window
        windowManager?.addView(floatingView, params)
        
        // Set up touch listener for drag movement
        setupTouchListener()
        
        // Set up click listener for microphone button
        floatingView?.findViewById<ImageView>(R.id.iv_mic)?.setOnClickListener {
            startVoiceRecognition()
        }
    }
    
    private fun setupTouchListener() {
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        
        floatingView?.setOnTouchListener { v, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params?.x ?: 0
                    initialY = params?.y ?: 0
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    params?.x = initialX + (event.rawX - initialTouchX).toInt()
                    params?.y = initialY + (event.rawY - initialTouchY).toInt()
                    windowManager?.updateViewLayout(floatingView, params)
                    true
                }
                else -> false
            }
        }
    }
    
    private fun initializeSpeechRecognizer() {
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                // UI indicator that speech recognition is ready
                floatingView?.findViewById<ImageView>(R.id.iv_mic)?.setImageResource(R.drawable.ic_mic)
            }
            
            override fun onBeginningOfSpeech() {}
            
            override fun onRmsChanged(rmsdB: Float) {}
            
            override fun onBufferReceived(buffer: ByteArray?) {}
            
            override fun onEndOfSpeech() {
                // UI indicator that speech recognition is done
                floatingView?.findViewById<ImageView>(R.id.iv_mic)?.setImageResource(R.drawable.ic_mic)
            }
            
            override fun onError(error: Int) {
                // Reset UI
                floatingView?.findViewById<ImageView>(R.id.iv_mic)?.setImageResource(R.drawable.ic_mic)
                Toast.makeText(applicationContext, "Error in voice recognition", Toast.LENGTH_SHORT).show()
            }
            
            override fun onResults(results: Bundle?) {
    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
    if (!matches.isNullOrEmpty()) {
        val command = matches[0]
        // Send recognized command to Flutter and handle it directly
        methodChannel?.invokeMethod("processVoiceCommand", command, object : MethodChannel.Result {
            override fun success(result: Any?) {
                // Command processed successfully
                Toast.makeText(applicationContext, "Command processed: $command", Toast.LENGTH_SHORT).show()
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                // Handle errors
                Toast.makeText(applicationContext, "Error processing command: $errorMessage", Toast.LENGTH_SHORT).show()
            }

            override fun notImplemented() {
                // Handle not implemented case
                Toast.makeText(applicationContext, "Command processing not implemented", Toast.LENGTH_SHORT).show()
            }
        })
    }
}
            
            override fun onPartialResults(partialResults: Bundle?) {}
            
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
    }
    
    private fun startVoiceRecognition() {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
        speechRecognizer?.startListening(intent)
    }
    
    override fun onDestroy() {
        if (floatingView != null) windowManager?.removeView(floatingView)
        speechRecognizer?.destroy()
        super.onDestroy()
    }
}