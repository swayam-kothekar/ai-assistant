package com.example.ai_assistant
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.ActivityManager
import android.content.Context
import android.net.TrafficStats
import java.io.BufferedReader
import java.io.FileReader
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.ai_assistant/system_metrics"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCpuMetrics" -> result.success(getCpuMetrics())
                "getMemoryMetrics" -> result.success(getMemoryMetrics())
                "getNetworkMetrics" -> result.success(getNetworkMetrics())
                else -> result.notImplemented()
            }
        }
    }
    
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