import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Add this dependency for date formatting

// Callback types for updating UI state - moved to top level
typedef TaskStartCallback = void Function(String taskTitle, List<String> steps);
typedef TaskProgressCallback = void Function(int completedStepIndex);
typedef ErrorCallback = void Function(String message);

class SearchService {
  // Regular expressions for detecting YouTube commands
  static final RegExp _youtubeSearchPattern = RegExp(
    r'^(?:open\s+youtube\s+and\s+search|search\s+(?:on|in)\s+youtube\s+for|youtube\s+search)(?:\s+for)?\s+(.+)$',
    caseSensitive: false
  );
  
  static final RegExp _youtubeOpenPattern = RegExp(
    r'^open\s+youtube$',
    caseSensitive: false
  );
  
  // Calendar patterns for various calendar commands
  static final RegExp _calendarOpenPattern = RegExp(
    r'^open\s+(?:my\s+)?calendar$',
    caseSensitive: false
  );
  
  static final RegExp _addEventPattern = RegExp(
    r'^(?:add|create|schedule)(?:\s+a)?(?:\s+new)?(?:\s+meeting|event|appointment)(?:\s+(?:on|in|to)(?:\s+my)?(?:\s+calendar))?\s+(.+)$',
    caseSensitive: false
  );
  
  static final RegExp _viewDatePattern = RegExp(
    r'^(?:show|view|open|check)(?:\s+my)?(?:\s+calendar)(?:\s+for)?\s+(.+)$',
    caseSensitive: false
  );
  
  // Helper method to extract date, time, and title from meeting description
  Map<String, dynamic> _extractEventDetails(String description) {
    // Default event details
    DateTime now = DateTime.now();
    DateTime eventDate = now;
    TimeOfDay eventTime = TimeOfDay(hour: now.hour, minute: now.minute);
    String title = description;
    String location = '';
    
    // Regular expressions for dates and times
    final datePattern = RegExp(
      r'(?:on|for|at)\s+(tomorrow|today|(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[.,]?\s+\d{1,2}(?:st|nd|rd|th)?(?:[.,]?\s+\d{4})?|\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?)',
      caseSensitive: false
    );
    
    final timePattern = RegExp(
      r'(?:at|from)\s+(\d{1,2}(?::\d{2})?\s*(?:am|pm)|noon|midnight)',
      caseSensitive: false
    );
    
    final locationPattern = RegExp(
      r'(?:at|in)\s+(.+?)(?:from|at|on|with|\.|\z)',
      caseSensitive: false
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
        // For more complex date parsing, you would expand this logic
        // or use a dedicated date parsing library
        try {
          // Try to handle common date formats
          if (dateStr.contains('/') || dateStr.contains('-')) {
            // MM/DD/YYYY or MM-DD-YYYY
            final parts = dateStr.split(RegExp(r'[/-]'));
            if (parts.length >= 2) {
              int month = int.tryParse(parts[0]) ?? 1;
              int day = int.tryParse(parts[1]) ?? 1;
              int year = parts.length > 2 ? (int.tryParse(parts[2]) ?? now.year) : now.year;
              // Handle 2-digit years
              if (year < 100) year += 2000;
              eventDate = DateTime(year, month, day);
            }
          }
        } catch (e) {
          // Keep default date if parsing fails
        }
      }
      
      // Remove date part from title
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
        // Parse time like "3:30pm" or "2pm"
        timeStr = timeStr.replaceAll(' ', '');
        bool isPM = timeStr.contains('pm');
        timeStr = timeStr.replaceAll(RegExp(r'[apm]'), '');
        
        final timeParts = timeStr.split(':');
        int hour = int.tryParse(timeParts[0]) ?? 12;
        int minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
        
        // Convert to 24-hour format if PM
        if (isPM && hour < 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
        
        eventTime = TimeOfDay(hour: hour, minute: minute);
      }
      
      // Remove time part from title
      title = title.replaceAll(timeMatch.group(0)!, '');
    }
    
    // Extract location if present
    final locationMatch = locationPattern.firstMatch(description);
    if (locationMatch != null && locationMatch.group(1) != null) {
      location = locationMatch.group(1)!.trim();
      
      // Remove location part from title
      title = title.replaceAll(locationMatch.group(0)!, '');
    }
    
    // Clean up the title
    title = title
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(RegExp(r'^with\s+'), '')  // Remove "with" prefix
      .replaceAll(RegExp(r'\.+$'), '');     // Remove trailing periods
    
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
  
  // Process search input and determine appropriate action
  Future<void> processSearch({
    required String searchText,
    required TaskStartCallback onTaskStart,
    required TaskProgressCallback onTaskProgress,
    required ErrorCallback onError,
    required BuildContext context,
  }) async {
    final trimmedText = searchText.trim();
    
    // Check if text matches YouTube patterns
    final youtubeSearchMatch = _youtubeSearchPattern.firstMatch(trimmedText);
    final isYoutubeOpen = _youtubeOpenPattern.hasMatch(trimmedText);
    
    // Check if text matches Calendar patterns
    final isCalendarOpen = _calendarOpenPattern.hasMatch(trimmedText);
    final addEventMatch = _addEventPattern.firstMatch(trimmedText);
    final viewDateMatch = _viewDatePattern.firstMatch(trimmedText);
    
    if (youtubeSearchMatch != null) {
      await _handleYoutubeSearch(
        searchQuery: youtubeSearchMatch.group(1)?.trim() ?? '',
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (isYoutubeOpen) {
      await _handleYoutubeOpen(
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (isCalendarOpen) {
      await _handleCalendarOpen(
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (addEventMatch != null) {
      await _handleAddCalendarEvent(
        eventDescription: addEventMatch.group(1)?.trim() ?? '',
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (viewDateMatch != null) {
      await _handleViewCalendarDate(
        dateDescription: viewDateMatch.group(1)?.trim() ?? '',
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else {
      await _handleUnrecognizedCommand(
        command: trimmedText,
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        context: context,
      );
    }
  }

  // Handle YouTube search command
  Future<void> _handleYoutubeSearch({
    required String searchQuery,
    required TaskStartCallback onTaskStart,
    required TaskProgressCallback onTaskProgress,
    required ErrorCallback onError,
    required BuildContext context,
  }) async {
    if (searchQuery.isEmpty) return;
    
    // Start task with steps for YouTube search
    onTaskStart("Searching YouTube", [
      "Processing your request",
      "Connecting to YouTube",
      "Searching for: $searchQuery"
    ]);
    
    // Update task progress
    onTaskProgress(0); // Mark first step complete
    
    try {
      // Use AndroidIntent to launch YouTube with search
      onTaskProgress(1); // Mark second step complete
      
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.google.android.youtube',
        data: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(searchQuery)}',
      );
      await intent.launch();
      
      onTaskProgress(2); // Mark third step complete
      
    } on PlatformException {
      // Fall back to web if the app isn't installed
      final Uri webUri = Uri.parse('https://www.youtube.com/results?search_query=${Uri.encodeComponent(searchQuery)}');
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        onTaskProgress(2); // Mark third step complete
      } catch (e) {
        onError("Could not launch YouTube: $e");
        
        // Show error in UI
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch YouTube: $e')),
          );
        }
      }
    }
  }

  // Handle command to just open YouTube
  Future<void> _handleYoutubeOpen({
    required TaskStartCallback onTaskStart,
    required TaskProgressCallback onTaskProgress,
    required ErrorCallback onError,
    required BuildContext context,
  }) async {
    // Just open YouTube homepage
    onTaskStart("Opening YouTube", [
      "Processing your request",
      "Launching YouTube app"
    ]);
    
    onTaskProgress(0); // Mark first step complete
    
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.google.android.youtube',
        data: 'https://www.youtube.com/',
      );
      await intent.launch();
      
      onTaskProgress(1); // Mark second step complete
      
    } on PlatformException {
      // Fall back to web if the app isn't installed
      final Uri webUri = Uri.parse('https://www.youtube.com/');
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        onTaskProgress(1); // Mark second step complete
      } catch (e) {
        onError("Could not launch YouTube: $e");
        
        // Show error in UI
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch YouTube: $e')),
          );
        }
      }
    }
  }

  // Handle command to open calendar
  Future<void> _handleCalendarOpen({
    required TaskStartCallback onTaskStart,
    required TaskProgressCallback onTaskProgress,
    required ErrorCallback onError,
    required BuildContext context,
  }) async {
    onTaskStart("Opening Calendar", [
      "Processing your request",
      "Launching Calendar app"
    ]);
    
    onTaskProgress(0); // Mark first step complete
    
    try {
      // Try to launch the calendar app
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.APP_CALENDAR',
      );
      await intent.launch();
      
      onTaskProgress(1); // Mark second step complete
      
    } on PlatformException {
      // Try alternate method for opening calendar
      try {
        final calendarUri = Uri.parse('content://com.android.calendar/time/');
        await launchUrl(calendarUri);
        onTaskProgress(1); // Mark second step complete
      } catch (e) {
        onError("Could not open Calendar: $e");
        
        // Show error in UI
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open Calendar: $e')),
          );
        }
      }
    }
  }

  // Handle command to add calendar event
  Future<void> _handleAddCalendarEvent({
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
      "Adding to calendar"
    ]);
    
    onTaskProgress(0); // Mark first step complete
    
    // Extract event details from the description
    final eventDetails = _extractEventDetails(eventDescription);
    final String title = eventDetails['title'];
    final DateTime dateTime = eventDetails['dateTime'];
    final String location = eventDetails['location'];
    
    onTaskProgress(1); // Mark second step complete
    
    // Format date and time for display
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('h:mm a');
    final formattedDate = dateFormatter.format(dateTime);
    final formattedTime = timeFormatter.format(dateTime);
    
    try {
      // Create calendar event intent
      final endTime = dateTime.add(const Duration(hours: 1)); // Default 1 hour duration
      
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
      
      onTaskProgress(2); // Mark third step complete
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event "$title" scheduled for $formattedDate at $formattedTime')),
        );
      }
      
    } catch (e) {
      onError("Could not create calendar event: $e");
      
      // Show error in UI
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create calendar event: $e')),
        );
      }
    }
  }

  // Handle command to view calendar for a specific date
  Future<void> _handleViewCalendarDate({
    required String dateDescription,
    required TaskStartCallback onTaskStart,
    required TaskProgressCallback onTaskProgress,
    required ErrorCallback onError,
    required BuildContext context,
  }) async {
    onTaskStart("Opening Calendar Date", [
      "Processing your request",
      "Determining date",
      "Opening calendar"
    ]);
    
    onTaskProgress(0); // Mark first step complete
    
    // Parse the date description
    DateTime targetDate = DateTime.now();
    
    if (dateDescription.toLowerCase().contains('tomorrow')) {
      targetDate = targetDate.add(const Duration(days: 1));
    } else if (dateDescription.toLowerCase().contains('next week')) {
      targetDate = targetDate.add(const Duration(days: 7));
    } else {
      // Try to parse other date formats (this is simplified)
      try {
        // For a more robust solution, you might want to use a dedicated date parsing library
        if (dateDescription.toLowerCase().contains('monday')) {targetDate = _getNextWeekday(DateTime.monday);}
        else if (dateDescription.toLowerCase().contains('tuesday')){ targetDate = _getNextWeekday(DateTime.tuesday);}
        else if (dateDescription.toLowerCase().contains('wednesday')){ targetDate = _getNextWeekday(DateTime.wednesday);}
        else if (dateDescription.toLowerCase().contains('thursday')){ targetDate = _getNextWeekday(DateTime.thursday);}
        else if (dateDescription.toLowerCase().contains('friday')){ targetDate = _getNextWeekday(DateTime.friday);}
        else if (dateDescription.toLowerCase().contains('saturday')){ targetDate = _getNextWeekday(DateTime.saturday);}
        else if (dateDescription.toLowerCase().contains('sunday')){ targetDate = _getNextWeekday(DateTime.sunday);}
      } catch (e) {
        // Keep default date if parsing fails
      }
    }
    
    onTaskProgress(1); // Mark second step complete
    
    // Format date for display
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final formattedDate = dateFormatter.format(targetDate);
    
    try {
      // Open calendar at specific date
      final millis = targetDate.millisecondsSinceEpoch;
      
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'content://com.android.calendar/time/$millis',
      );
      await intent.launch();
      
      onTaskProgress(2); // Mark third step complete
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening calendar for $formattedDate')),
        );
      }
      
    } catch (e) {
      onError("Could not open calendar for specific date: $e");
      
      // Show error in UI
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open calendar for $formattedDate: $e')),
        );
      }
    }
  }

  // Helper method to get the next occurrence of a weekday
  DateTime _getNextWeekday(int weekday) {
    DateTime date = DateTime.now();
    int daysUntil = weekday - date.weekday;
    if (daysUntil <= 0) daysUntil += 7; // Next week if today or already past
    return date.add(Duration(days: daysUntil));
  }

  // Handle unrecognized commands
  Future<void> _handleUnrecognizedCommand({
    required String command,
    required TaskStartCallback onTaskStart,
    required TaskProgressCallback onTaskProgress,
    required BuildContext context,
  }) async {
    // Not a recognized command - show processing message
    onTaskStart("Processing Input", [
      "Analyzing your request",
      "Command not recognized"
    ]);
    
    onTaskProgress(0); // Mark first step complete
    
    // Simulate some processing time
    await Future.delayed(const Duration(milliseconds: 500));
    onTaskProgress(1); // Mark second step complete
    
    // Show info message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('I understand: "$command" (not a recognized command)')),
      );
    }
  }
}