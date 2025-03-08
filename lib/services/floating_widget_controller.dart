// lib/services/floating_widget_controller.dart

import 'package:flutter/services.dart';

class FloatingWidgetController {
  static const MethodChannel _channel = MethodChannel('com.example.ai_assistant/floating_widget');
  static bool _isInitialized = false;

  // Initialize the controller and set up method call handler
  static Future<void> initialize(Function(String) onVoiceCommand) async {
    if (_isInitialized) return;
    
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onVoiceCommand') {
        final String command = call.arguments;
        onVoiceCommand(command);
      }
    });
    
    _isInitialized = true;
  }
  
  // Start the floating widget service
  static Future<bool> startFloatingWidget() async {
    try {
      final bool result = await _channel.invokeMethod('startFloatingWidget');
      return result;
    } on PlatformException catch (e) {
      print("Failed to start floating widget: ${e.message}");
      return false;
    }
  }
  
  // Stop the floating widget service
  static Future<bool> stopFloatingWidget() async {
    try {
      final bool result = await _channel.invokeMethod('stopFloatingWidget');
      return result;
    } on PlatformException catch (e) {
      print("Failed to stop floating widget: ${e.message}");
      return false;
    }
  }
  
  // Check if SYSTEM_ALERT_WINDOW permission is granted
  static Future<bool> checkOverlayPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkOverlayPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print("Failed to check overlay permission: ${e.message}");
      return false;
    }
  }
  
  // Open settings to request SYSTEM_ALERT_WINDOW permission
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      print("Failed to request overlay permission: ${e.message}");
    }
  }
}