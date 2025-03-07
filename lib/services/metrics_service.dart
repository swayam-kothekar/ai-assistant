import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// import 'dart:io';

class DeviceMetricsService {
  // Singleton pattern
  static final DeviceMetricsService _instance = DeviceMetricsService._internal();
  factory DeviceMetricsService() => _instance;
  DeviceMetricsService._internal();
  
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  static const platform = MethodChannel('com.example.ai_assistant/system_metrics');
  
  // Get real system performance data
  Future<Map<String, dynamic>> getSystemPerformance() async {
    Map<String, dynamic> cpuData = await _getRealCpuMetrics();
    Map<String, dynamic> memoryData = await _getRealMemoryMetrics();
    Map<String, dynamic> networkData = await _getRealNetworkMetrics();
    
    // Battery level
    int batteryLevel = 0;
    try {
      batteryLevel = await _battery.batteryLevel;
    } catch (e) {
      debugPrint('Error getting battery level: $e');
    }
    
    // Network connectivity
    ConnectivityResult connectivityResult = ConnectivityResult.none;
    try {
      connectivityResult = await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('Error getting connectivity: $e');
    }
    
    return {
      'cpu': cpuData,
      'memory': memoryData,
      'battery': {
        'level': batteryLevel,
      },
      'network': {
        'type': connectivityResult.toString().split('.').last,
        ...networkData,
      }
    };
  }
  
  // Get real CPU metrics
  Future<Map<String, dynamic>> _getRealCpuMetrics() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return _getFallbackCpuMetrics();
    }

    try {
      // Use method channel to call native code
      final Map<dynamic, dynamic> result = await platform.invokeMethod('getCpuMetrics');
      final Map<String, dynamic> cpuHistory = Map<String, dynamic>.from(result['history'] ?? {});
      
      return {
        'usage': result['usage'] ?? 0.0,
        'cores': List<double>.from(result['cores'] ?? []),
        'history': cpuHistory,
      };
    } catch (e) {
      debugPrint('Error getting CPU metrics: $e');
      return _getFallbackCpuMetrics();
    }
  }
  
  // Get real memory metrics
  Future<Map<String, dynamic>> _getRealMemoryMetrics() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return _getFallbackMemoryMetrics();
    }
    
    try {
      // Use method channel to call native code
      final Map<dynamic, dynamic> result = await platform.invokeMethod('getMemoryMetrics');
      
      return {
        'total': result['total'] ?? 0.0,
        'used': result['used'] ?? 0.0,
        'available': result['available'] ?? 0.0,
      };
    } catch (e) {
      debugPrint('Error getting memory metrics: $e');
      return _getFallbackMemoryMetrics();
    }
  }
  
  // Get real network metrics
  Future<Map<String, dynamic>> _getRealNetworkMetrics() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return _getFallbackNetworkMetrics();
    }
    
    try {
      // Use method channel to call native code
      final Map<dynamic, dynamic> result = await platform.invokeMethod('getNetworkMetrics');
      final Map<String, dynamic> dataUsage = Map<String, dynamic>.from(result['dataUsage'] ?? {});
      
      return {
        'download': result['download'] ?? 0.0,
        'upload': result['upload'] ?? 0.0,
        'latency': result['latency'] ?? 0.0,
        'packetLoss': result['packetLoss'] ?? 0.0,
        'signalStrength': result['signalStrength'] ?? 'Unknown',
        'networkName': result['networkName'] ?? 'Unknown',
        'dataUsage': dataUsage,
      };
    } catch (e) {
      debugPrint('Error getting network metrics: $e');
      return _getFallbackNetworkMetrics();
    }
  }
  
  // Fallback methods in case native calls fail
  Map<String, dynamic> _getFallbackCpuMetrics() {
    return {
      'usage': 50.0, // Default value
      'cores': [45.0, 50.0, 55.0, 60.0], // Default values
      'history': {'00:00': 50.0}, // Minimal history
    };
  }
  
  Map<String, dynamic> _getFallbackMemoryMetrics() {
    return {
      'total': 4.0, // 4GB default
      'used': 2.0,  // 2GB used
      'available': 2.0, // 2GB available
    };
  }
  
  Map<String, dynamic> _getFallbackNetworkMetrics() {
    return {
      'download': 2.0, // 2 Mbps
      'upload': 1.0,   // 1 Mbps
      'latency': 50.0, // 50ms
      'packetLoss': 1.0, // 1%
      'signalStrength': 'Unknown',
      'networkName': 'Unknown',
      'dataUsage': {
        'downloaded': 0.5, // 0.5 GB
        'uploaded': 0.1,   // 0.1 GB
        'sessions': 10,
        'activeTime': '1h 0m',
      },
    };
  }
  
  // Get device information
  Future<Map<String, dynamic>> getDeviceInfo() async {
    Map<String, dynamic> deviceData = {};
    
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        
        // Get CPU details via method channel
        Map<String, dynamic> cpuDetails = await _getAndroidCpuDetails();
        
        deviceData = {
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'androidVersion': androidInfo.version.release,
          'sdkVersion': androidInfo.version.sdkInt.toString(),
          'product': androidInfo.product,
          'cpuModel': cpuDetails['model'] ?? 'Unknown',
          'cpuCores': cpuDetails['cores'] ?? 'Unknown',
          'memoryType': cpuDetails['memoryType'] ?? 'Unknown',
          'memorySpeed': cpuDetails['memorySpeed'] ?? 'Unknown',
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        deviceData = {
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'localizedModel': iosInfo.localizedModel,
          'cpuModel': 'Apple Silicon',
          'cpuCores': 'Unknown',
          'memoryType': 'LPDDR4X',
          'memorySpeed': 'Unknown',
        };
      } else {
        deviceData = {
          'model': 'Desktop/Unknown',
          'systemName': defaultTargetPlatform.toString(),
          'cpuModel': 'Unknown',
          'cpuCores': 'Unknown',
          'memoryType': 'Unknown',
          'memorySpeed': 'Unknown',
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    
    return deviceData;
  }
  
  // Get detailed CPU info from Android
  Future<Map<String, dynamic>> _getAndroidCpuDetails() async {
    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod('getCpuDetails');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      debugPrint('Error getting CPU details: $e');
      return {
        'model': 'Unknown',
        'cores': 'Unknown',
        'memoryType': 'Unknown',
        'memorySpeed': 'Unknown',
      };
    }
  }
  
  // Get network stats
  Future<Map<String, dynamic>> getNetworkStats() async {
    ConnectivityResult connectivityType = ConnectivityResult.none;
    bool isConnected = false;
    
    try {
      connectivityType = await _connectivity.checkConnectivity();
      isConnected = connectivityType != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
    
    Map<String, dynamic> networkMetrics = await _getRealNetworkMetrics();
    
    return {
      'type': connectivityType.toString().split('.').last,
      'isConnected': isConnected,
      ...networkMetrics,
    };
  }
}