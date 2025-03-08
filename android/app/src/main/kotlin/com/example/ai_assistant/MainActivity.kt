package com.example.ai_assistant
import com.example.ai_assistant.FloatingWidgetService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.TrafficStats
import android.net.Uri
import android.os.Build
import android.provider.Settings
import java.io.BufferedReader
import java.io.FileReader
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val METRICS_CHANNEL = "com.example.ai_assistant/system_metrics"
    private val FLOATING_WIDGET_CHANNEL = "com.example.ai_assistant/floating_widget"
    private val OVERLAY_PERMISSION_REQ_CODE = 1234
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up the existing system metrics channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METRICS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCpuMetrics" -> result.success(getCpuMetrics())
                "getMemoryMetrics" -> result.success(getMemoryMetrics())
                "getNetworkMetrics" -> result.success(getNetworkMetrics())
                else -> result.notImplemented()
            }
        }
        
        // Set up the new floating widget channel
        val floatingWidgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FLOATING_WIDGET_CHANNEL)
        floatingWidgetChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startFloatingWidget" -> {
                    startFloatingWidgetService()
                    result.success(true)
                }
                "stopFloatingWidget" -> {
                    stopFloatingWidgetService()
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    result.success(checkOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Store the method channel for use in the service
        FloatingWidgetService.methodChannel = floatingWidgetChannel
    }
    
    // Floating widget methods
    private fun startFloatingWidgetService() {
        if (checkOverlayPermission()) {
            val intent = Intent(this, FloatingWidgetService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        }
    }
    
    private fun stopFloatingWidgetService() {
        val intent = Intent(this, FloatingWidgetService::class.java)
        stopService(intent)
    }
    
    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }
    
    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, OVERLAY_PERMISSION_REQ_CODE)
        }
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == OVERLAY_PERMISSION_REQ_CODE) {
            // Notify Flutter side that permission request has completed
            val channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, FLOATING_WIDGET_CHANNEL)
            channel.invokeMethod("onOverlayPermissionResult", checkOverlayPermission())
        } else {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
    
    // Existing system metrics methods
    private fun getCpuMetrics(): Map<String, Any> {
        val cpuUsage = readCpuUsage()
        val cores = Runtime.getRuntime().availableProcessors()
        val coreUsages = List(cores) { cpuUsage * (0.8 + 0.4 * Math.random()) }
        
        return mapOf(
            "usage" to cpuUsage,
            "cores" to coreUsages,
            "history" to mapOf("00:00" to cpuUsage)
        )
    }
    
    private fun getMemoryMetrics(): Map<String, Any> {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        
        // Convert to GB
        val totalMemory = memoryInfo.totalMem / (1024.0 * 1024.0 * 1024.0)
        val availableMemory = memoryInfo.availMem / (1024.0 * 1024.0 * 1024.0)
        val usedMemory = totalMemory - availableMemory
        
        return mapOf(
            "total" to totalMemory,
            "used" to usedMemory,
            "available" to availableMemory
        )
    }
    
    private fun getNetworkMetrics(): Map<String, Any> {
        val rxBytes = TrafficStats.getTotalRxBytes() / (1024.0 * 1024.0) // MB
        val txBytes = TrafficStats.getTotalTxBytes() / (1024.0 * 1024.0) // MB
        
        // Note: These aren't real-time speeds, just total bytes since boot
        // For real speeds, you'd need to measure delta over time
        
        return mapOf(
            "download" to 5.0, // Placeholder - implement real calculation
            "upload" to 2.0,   // Placeholder - implement real calculation
            "latency" to 50.0,
            "packetLoss" to 1.0,
            "dataUsage" to mapOf(
                "downloaded" to rxBytes / 1024.0, // GB
                "uploaded" to txBytes / 1024.0    // GB
            )
        )
    }
    
    private fun readCpuUsage(): Double {
        try {
            val reader = BufferedReader(FileReader("/proc/stat"))
            val line = reader.readLine()
            reader.close()
            
            if (line != null) {
                val parts = line.split("\\s+".toRegex())
                if (parts.size >= 5) {
                    try {
                        val user = parts[1].toLong()
                        val nice = parts[2].toLong()
                        val system = parts[3].toLong()
                        val idle = parts[4].toLong()
                        
                        val total = user + nice + system + idle
                        val active = total - idle
                        
                        // This is a very simplified calculation - in reality you would
                        // track the delta between two readings
                        return (active.toDouble() / total.toDouble() * 100.0)
                    } catch (e: NumberFormatException) {
                        e.printStackTrace()
                    }
                }
            }
        } catch (e: IOException) {
            e.printStackTrace()
        }
        
        return 50.0 // Default value if calculation fails
    }
}

