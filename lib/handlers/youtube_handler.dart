import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

typedef TaskStartCallback = void Function(String taskTitle, List<String> steps);
typedef TaskProgressCallback = void Function(int completedStepIndex);
typedef ErrorCallback = void Function(String message);

Future<void> handleYoutubeOpen({
  required TaskStartCallback onTaskStart,
  required TaskProgressCallback onTaskProgress,
  required ErrorCallback onError,
  required BuildContext context,
}) async {
  onTaskStart("Opening YouTube", [
    "Processing your request",
    "Launching YouTube app",
  ]);

  onTaskProgress(0);

  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      package: 'com.google.android.youtube',
      data: 'https://www.youtube.com/',
    );
    await intent.launch();
    onTaskProgress(1);
  } on PlatformException {
    final Uri webUri = Uri.parse('https://www.youtube.com/');
    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      onTaskProgress(1);
    } catch (e) {
      onError("Could not launch YouTube: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch YouTube: $e')),
        );
      }
    }
  }
}

Future<void> handleYoutubeSearch({
  required String searchQuery,
  required TaskStartCallback onTaskStart,
  required TaskProgressCallback onTaskProgress,
  required ErrorCallback onError,
  required BuildContext context,
}) async {
  if (searchQuery.isEmpty) return;

  onTaskStart("Searching YouTube", [
    "Processing your request",
    "Connecting to YouTube",
    "Searching for: $searchQuery",
  ]);

  onTaskProgress(0);

  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      package: 'com.google.android.youtube',
      data: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(searchQuery)}',
    );
    await intent.launch();
    onTaskProgress(1);
  } on PlatformException {
    final Uri webUri = Uri.parse('https://www.youtube.com/results?search_query=${Uri.encodeComponent(searchQuery)}');
    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      onTaskProgress(1);
    } catch (e) {
      onError("Could not launch YouTube: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch YouTube: $e')),
        );
      }
    }
  }
}