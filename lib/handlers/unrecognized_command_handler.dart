import 'package:flutter/material.dart';

typedef TaskStartCallback = void Function(String taskTitle, List<String> steps);
typedef TaskProgressCallback = void Function(int completedStepIndex);

Future<void> handleUnrecognizedCommand({
  required String command,
  required TaskStartCallback onTaskStart,
  required TaskProgressCallback onTaskProgress,
  required BuildContext context,
}) async {
  onTaskStart("Processing Input", [
    "Analyzing your request",
    "Command not recognized",
  ]);

  onTaskProgress(0);

  await Future.delayed(const Duration(milliseconds: 500));
  onTaskProgress(1);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('I understand: "$command" (not a recognized command)')),
    );
  }
}