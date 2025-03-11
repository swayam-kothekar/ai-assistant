import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

typedef TaskStartCallback = void Function(String taskTitle, List<String> steps);
typedef TaskProgressCallback = void Function(int completedStepIndex);
typedef ErrorCallback = void Function(String message);

Future<void> handleGoogleSearch({
  required String searchQuery,
  required TaskStartCallback onTaskStart,
  required TaskProgressCallback onTaskProgress,
  required ErrorCallback onError,
  required BuildContext context,
}) async {
  if (searchQuery.isEmpty) return;

  onTaskStart("Searching Google", [
    "Processing your request",
    "Connecting to Google",
    "Searching for: $searchQuery",
  ]);

  onTaskProgress(0);

  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      package: 'com.android.chrome',
      data: 'https://www.google.com/search?q=${Uri.encodeComponent(searchQuery)}',
    );
    await intent.launch();
    onTaskProgress(1);
  } on PlatformException {
    final Uri webUri = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(searchQuery)}');
    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      onTaskProgress(1);
    } catch (e) {
      onError("Could not launch Google: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch Google: $e')),
        );
      }
    }
  }
}