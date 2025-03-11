import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // For date formatting

typedef TaskStartCallback = void Function(String taskTitle, List<String> steps);
typedef TaskProgressCallback = void Function(int completedStepIndex);
typedef ErrorCallback = void Function(String message);

Future<void> handleCalendarOpen({
  required TaskStartCallback onTaskStart,
  required TaskProgressCallback onTaskProgress,
  required ErrorCallback onError,
  required BuildContext context,
}) async {
  onTaskStart("Opening Calendar", [
    "Processing your request",
    "Launching Calendar app",
  ]);

  onTaskProgress(0);

  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      category: 'android.intent.category.APP_CALENDAR',
    );
    await intent.launch();
    onTaskProgress(1);
  } on PlatformException {
    try {
      final calendarUri = Uri.parse('content://com.android.calendar/time/');
      await launchUrl(calendarUri);
      onTaskProgress(1);
    } catch (e) {
      onError("Could not open Calendar: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Calendar: $e')),
        );
      }
    }
  }
}

Future<void> handleAddCalendarEvent({
  required String eventDescription,
  required TaskStartCallback onTaskStart,
  required TaskProgressCallback onTaskProgress,
  required ErrorCallback onError,
  required BuildContext context,
}) async {
  if (eventDescription.isEmpty) {
    onError("Event description is required");
    return;
  }

  onTaskStart("Creating Calendar Event", [
    "Processing your request",
    "Extracting event details",
    "Adding to calendar",
  ]);

  onTaskProgress(0);

  final eventDetails = _extractEventDetails(eventDescription);
  final String title = eventDetails['title'];
  final DateTime dateTime = eventDetails['dateTime'];
  final String location = eventDetails['location'];

  onTaskProgress(1);

  final dateFormatter = DateFormat('MMM dd, yyyy');
  final timeFormatter = DateFormat('h:mm a');
  final formattedDate = dateFormatter.format(dateTime);
  final formattedTime = timeFormatter.format(dateTime);

  try {
    final endTime = dateTime.add(const Duration(hours: 1));

    final intent = AndroidIntent(
      action: 'android.intent.action.INSERT',
      data: 'content://com.android.calendar/events',
      arguments: <String, dynamic>{
        'title': title,
        'beginTime': dateTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'eventLocation': location,
        'description': 'Created via voice command: "$eventDescription"',
      },
    );
    await intent.launch();

    onTaskProgress(2);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event "$title" scheduled for $formattedDate at $formattedTime')),
      );
    }
  } catch (e) {
    onError("Could not create calendar event: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create calendar event: $e')),
      );
    }
  }
}

Future<void> handleViewCalendarDate({
  required String dateDescription,
  required TaskStartCallback onTaskStart,
  required TaskProgressCallback onTaskProgress,
  required ErrorCallback onError,
  required BuildContext context,
}) async {
  onTaskStart("Opening Calendar Date", [
    "Processing your request",
    "Determining date",
    "Opening calendar",
  ]);

  onTaskProgress(0);

  DateTime targetDate = DateTime.now();

  if (dateDescription.toLowerCase().contains('tomorrow')) {
    targetDate = targetDate.add(const Duration(days: 1));
  } else if (dateDescription.toLowerCase().contains('next week')) {
    targetDate = targetDate.add(const Duration(days: 7));
  } else {
    try {
      if (dateDescription.toLowerCase().contains('monday')) {
        targetDate = _getNextWeekday(DateTime.monday);
      } else if (dateDescription.toLowerCase().contains('tuesday')) {
        targetDate = _getNextWeekday(DateTime.tuesday);
      } else if (dateDescription.toLowerCase().contains('wednesday')) {
        targetDate = _getNextWeekday(DateTime.wednesday);
      } else if (dateDescription.toLowerCase().contains('thursday')) {
        targetDate = _getNextWeekday(DateTime.thursday);
      } else if (dateDescription.toLowerCase().contains('friday')) {
        targetDate = _getNextWeekday(DateTime.friday);
      } else if (dateDescription.toLowerCase().contains('saturday')) {
        targetDate = _getNextWeekday(DateTime.saturday);
      } else if (dateDescription.toLowerCase().contains('sunday')) {
        targetDate = _getNextWeekday(DateTime.sunday);
      }
    } catch (e) {
      // Keep default date if parsing fails
    }
  }

  onTaskProgress(1);

  final dateFormatter = DateFormat('MMM dd, yyyy');
  final formattedDate = dateFormatter.format(targetDate);

  try {
    final millis = targetDate.millisecondsSinceEpoch;

    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data: 'content://com.android.calendar/time/$millis',
    );
    await intent.launch();

    onTaskProgress(2);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening calendar for $formattedDate')),
      );
    }
  } catch (e) {
    onError("Could not open calendar for specific date: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open calendar for $formattedDate: $e')),
      );
    }
  }
}

// Helper method to extract event details
Map<String, dynamic> _extractEventDetails(String description) {
  DateTime now = DateTime.now();
  DateTime eventDate = now;
  TimeOfDay eventTime = TimeOfDay(hour: now.hour, minute: now.minute);
  String title = description;
  String location = '';

  final datePattern = RegExp(
    r'(?:on|for|at)\s+(tomorrow|today|(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[.,]?\s+\d{1,2}(?:st|nd|rd|th)?(?:[.,]?\s+\d{4})?|\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?)',
    caseSensitive: false,
  );

  final timePattern = RegExp(
    r'(?:at|from)\s+(\d{1,2}(?::\d{2})?\s*(?:am|pm)|noon|midnight)',
    caseSensitive: false,
  );

  final locationPattern = RegExp(
    r'(?:at|in)\s+(.+?)(?:from|at|on|with|\.|\z)',
    caseSensitive: false,
  );

  // Extract date if present
  final dateMatch = datePattern.firstMatch(description);
  if (dateMatch != null && dateMatch.group(1) != null) {
    String dateStr = dateMatch.group(1)!.toLowerCase();

    if (dateStr.contains('tomorrow')) {
      eventDate = now.add(const Duration(days: 1));
    } else if (dateStr.contains('today')) {
      eventDate = now;
    } else {
      try {
        if (dateStr.contains('/') || dateStr.contains('-')) {
          final parts = dateStr.split(RegExp(r'[/-]'));
          if (parts.length >= 2) {
            int month = int.tryParse(parts[0]) ?? 1;
            int day = int.tryParse(parts[1]) ?? 1;
            int year = parts.length > 2 ? (int.tryParse(parts[2]) ?? now.year) : now.year;
            if (year < 100) year += 2000;
            eventDate = DateTime(year, month, day);
          }
        }
      } catch (e) {
        // Keep default date if parsing fails
      }
    }

    title = title.replaceAll(dateMatch.group(0)!, '');
  }

  // Extract time if present
  final timeMatch = timePattern.firstMatch(description);
  if (timeMatch != null && timeMatch.group(1) != null) {
    String timeStr = timeMatch.group(1)!.toLowerCase();

    if (timeStr == 'noon') {
      eventTime = const TimeOfDay(hour: 12, minute: 0);
    } else if (timeStr == 'midnight') {
      eventTime = const TimeOfDay(hour: 0, minute: 0);
    } else {
      timeStr = timeStr.replaceAll(' ', '');
      bool isPM = timeStr.contains('pm');
      timeStr = timeStr.replaceAll(RegExp(r'[apm]'), '');

      final timeParts = timeStr.split(':');
      int hour = int.tryParse(timeParts[0]) ?? 12;
      int minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;

      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      eventTime = TimeOfDay(hour: hour, minute: minute);
    }

    title = title.replaceAll(timeMatch.group(0)!, '');
  }

  // Extract location if present
  final locationMatch = locationPattern.firstMatch(description);
  if (locationMatch != null && locationMatch.group(1) != null) {
    location = locationMatch.group(1)!.trim();
    title = title.replaceAll(locationMatch.group(0)!, '');
  }

  // Clean up the title
  title = title
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(RegExp(r'^with\s+'), '')
      .replaceAll(RegExp(r'\.+$'), '');

  if (title.isEmpty) {
    title = "New Event";
  }

  // Combine date and time
  final eventDateTime = DateTime(
    eventDate.year,
    eventDate.month,
    eventDate.day,
    eventTime.hour,
    eventTime.minute,
  );

  return {
    'title': title,
    'dateTime': eventDateTime,
    'location': location,
  };
}

// Helper method to get the next occurrence of a weekday
DateTime _getNextWeekday(int weekday) {
  DateTime date = DateTime.now();
  int daysUntil = weekday - date.weekday;
  if (daysUntil <= 0) daysUntil += 7;
  return date.add(Duration(days: daysUntil));
}