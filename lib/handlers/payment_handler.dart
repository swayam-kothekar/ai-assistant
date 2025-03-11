import 'package:ai_assistant/screens/qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef TaskStartCallback = void Function(String taskTitle, List<String> steps);
typedef TaskProgressCallback = void Function(int completedStepIndex);
typedef ErrorCallback = void Function(String message);

Future<void> handlePayment({
  required String amount,
  required TaskStartCallback onTaskStart,
  required TaskProgressCallback onTaskProgress,
  required ErrorCallback onError,
  required BuildContext context,
}) async {
  onTaskStart("Processing Payment", [
    "Scanning QR code",
    "Extracting payment details",
    "Initiating payment",
  ]);

  onTaskProgress(0);

  final String? qrData = await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (context) => QRCodeScannerScreen(
        onScanComplete: (data) {
          Navigator.of(context).pop(data);
        },
      ),
    ),
  );

  if (qrData == null || qrData.isEmpty) {
    onError("No QR code scanned");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No QR code scanned')),
      );
    }
    return;
  }

  onTaskProgress(1);

  final Uri? paymentUri = Uri.tryParse(qrData);
  if (paymentUri == null || paymentUri.scheme != 'upi') {
    onError("Invalid UPI QR code");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid UPI QR code')),
      );
    }
    return;
  }

  final updatedUri = paymentUri.replace(queryParameters: {
    ...paymentUri.queryParameters,
    'am': amount,
  });

  onTaskProgress(2);

  try {
    await launchUrl(updatedUri, mode: LaunchMode.externalApplication);
    onTaskProgress(3);
  } catch (e) {
    onError("Could not initiate payment: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not initiate payment: $e')),
      );
    }
  }
}