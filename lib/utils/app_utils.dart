import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> isAppInstalled(String packageName) async {
  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      package: packageName,
    );
    await intent.launch();
    return true;
  } catch (e) {
    return false;
  }
}

Future<void> launchAppOrWeb({
  required String packageName,
  required String webUrl,
  required BuildContext context,
}) async {
  if (await isAppInstalled(packageName)) {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      package: packageName,
    );
    await intent.launch();
  } else {
    final Uri uri = Uri.parse(webUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}