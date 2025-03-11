import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';

typedef TaskStartCallback = void Function(String taskTitle, List<String> steps);
typedef TaskProgressCallback = void Function(int completedStepIndex);
typedef ErrorCallback = void Function(String message);

Future<void> handleGmailOpen({
  required TaskStartCallback onTaskStart,
  required TaskProgressCallback onTaskProgress,
  required ErrorCallback onError,
  required BuildContext context,
}) async {
  onTaskStart("Opening Gmail", [
    "Processing your request",
    "Launching Gmail",
  ]);

  onTaskProgress(0);

  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      package: 'com.google.android.gm',
      data: 'https://mail.google.com/',
    );
    await intent.launch();
    onTaskProgress(1);
  } on PlatformException catch (e) {
    onError("Could not open Gmail: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Gmail: $e')),
      );
    }
  }
}

Future<void> handleMapsOpen({
  required TaskStartCallback onTaskStart,
  required TaskProgressCallback onTaskProgress,
  required ErrorCallback onError,
  required BuildContext context,
}) async {
  onTaskStart("Opening Google Maps", [
    "Processing your request",
    "Launching Google Maps",
  ]);

  onTaskProgress(0);

  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      package: 'com.google.android.apps.maps',
      data: 'https://www.google.com/maps',
    );
    await intent.launch();
    onTaskProgress(1);
  } on PlatformException catch (e) {
    onError("Could not open Google Maps: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Google Maps: $e')),
      );
    }
  }
}

Future<void> handleSettingsOpen({
  required TaskStartCallback onTaskStart,
  required TaskProgressCallback onTaskProgress,
  required ErrorCallback onError,
  required BuildContext context,
}) async {
  onTaskStart("Opening Settings", [
    "Processing your request",
    "Launching Settings",
  ]);

  onTaskProgress(0);

  try {
    final intent = AndroidIntent(
      action: 'android.settings.SETTINGS',
    );
    await intent.launch();
    onTaskProgress(1);
  } on PlatformException catch (e) {
    onError("Could not open Settings: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Settings: $e')),
      );
    }
  }
}

Future<void> handleCameraOpen({
  required TaskStartCallback onTaskStart,
  required TaskProgressCallback onTaskProgress,
  required ErrorCallback onError,
  required BuildContext context,
}) async {
  onTaskStart("Opening Camera", [
    "Processing your request",
    "Launching Camera",
  ]);

  onTaskProgress(0);

  try {
    final intent = AndroidIntent(
      action: 'android.media.action.IMAGE_CAPTURE',
    );
    await intent.launch();
    onTaskProgress(1);
  } on PlatformException catch (e) {
    onError("Could not open Camera: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Camera: $e')),
      );
    }
  }
}

Future<void> handleGalleryOpen({
  required TaskStartCallback onTaskStart,
  required TaskProgressCallback onTaskProgress,
  required ErrorCallback onError,
  required BuildContext context,
}) async {
  onTaskStart("Opening Gallery", [
    "Processing your request",
    "Launching Gallery",
  ]);

  onTaskProgress(0);

  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      type: 'image/*',
    );
    await intent.launch();
    onTaskProgress(1);
  } on PlatformException catch (e) {
    onError("Could not open Gallery: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Gallery: $e')),
      );
    }
  }
}