import 'package:ai_assistant/handlers/app_opening_handler.dart';
import 'package:ai_assistant/handlers/calendar_handler.dart';
import 'package:ai_assistant/handlers/call_handler.dart';
import 'package:ai_assistant/handlers/google_search_handler.dart';
import 'package:ai_assistant/handlers/payment_handler.dart';
import 'package:ai_assistant/handlers/unrecognized_command_handler.dart';
import 'package:ai_assistant/handlers/youtube_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Callback types for updating UI state
typedef TaskStartCallback = void Function(String taskTitle, List<String> steps);
typedef TaskProgressCallback = void Function(int completedStepIndex);
typedef ErrorCallback = void Function(String message);

class GeminiService {
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final String baseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent';

  // Process input to match regex patterns
  String processInput(String input) {
    // Define commands and their standard formats
    final Map<String, RegExp> patterns = {
      'youtube_search': RegExp(r'^(?:open\s+youtube\s+and\s+search|search\s+(?:on|in)\s+youtube\s+for|youtube\s+search)(?:\s+for)?\s+(.+)$', caseSensitive: false),
      'youtube_open': RegExp(r'^open\s+youtube$', caseSensitive: false),
      'calendar_open': RegExp(r'^open\s+(?:my\s+)?calendar$', caseSensitive: false),
      'add_event': RegExp(r'^(?:add|create|schedule)(?:\s+a)?(?:\s+new)?(?:\s+meeting|event|appointment|birthday)(?:\s+(?:on|in|to)(?:\s+my)?(?:\s+calendar))?\s+(.+)$', caseSensitive: false),
      'view_date': RegExp(r'^(?:show|view|open|check)(?:\s+my)?(?:\s+calendar)(?:\s+for)?\s+(.+)$', caseSensitive: false),
      'maps_open': RegExp(r'^open\s+(?:google\s+)?maps$', caseSensitive: false),
      'gmail_open': RegExp(r'^open\s+gmail$', caseSensitive: false),
      'settings_open': RegExp(r'^open\s+settings$', caseSensitive: false),
      'camera_open': RegExp(r'^open\s+camera$', caseSensitive: false),
      'gallery_open': RegExp(r'^open\s+(?:gallery|photos)$', caseSensitive: false),
    };

    // Check if input matches any pattern and standardize it
    for (var entry in patterns.entries) {
      final match = entry.value.firstMatch(input);
      if (match != null) {
        switch (entry.key) {
          case 'youtube_search':
            final query = match.group(1) ?? '';
            return 'search on youtube for $query';
          case 'youtube_open':
            return 'open youtube';
          case 'calendar_open':
            return 'open calendar';
          case 'add_event':
            final details = match.group(1) ?? '';
            return 'add event $details';
          case 'view_date':
            final date = match.group(1) ?? '';
            return 'view calendar for $date';
          case 'maps_open':
            return 'open maps';
          case 'gmail_open':
            return 'open gmail';
          case 'settings_open':
            return 'open settings';
          case 'camera_open':
            return 'open camera';
          case 'gallery_open':
            return 'open gallery';
        }
      }
    }

    // If no pattern matches, return the original input
    return input;
  }

  // Method to send processed user input to the Gemini API
  Future<String> getResponse(String input) async {
    // Process the input before sending to Gemini
    final processedInput = processInput(input);
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': processedInput}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        // Parse the API response
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('Failed to load response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the API: $e');
    }
  }
}

class SearchService {
  // Translation map for Hinglish to English
  static final Map<String, String> _hinglishToEnglishMap = {
    'kal ka plan batao': 'show plan for tomorrow',
    'aaj kya hai': 'what is today',
    'google par search karo': 'search on google for',
    'google per search karo': 'search on google for',
    'youtube kholo aur search karo': 'open youtube and search',
    'YouTube kholo aur search karo': 'open youtube and search',
    'youtube kholo': 'open youtube',
    'YouTube kholo': 'open youtube',
    'calendar dikhao': 'open calendar',
    'event add karo': 'add event',
    'maps kholo': 'open maps',
    'gmail kholo': 'open gmail',
    'settings kholo': 'open settings',
    'camera kholo': 'open camera',
    'photos dikhao': 'open gallery',
    'time kya hua hai': 'what is the time',
    'date kya hai': 'what is the date',
    'meeting schedule karo': 'schedule meeting',
    'location dikhao': 'show location',
    'kal meeting hai': 'meeting tomorrow',
    'aaj ka plan batao': 'show plan for today',
  };

  final GeminiService _geminiService;
  
  // Add a constructor to initialize the field
  SearchService() : _geminiService = GeminiService();
  // Future<void> _initTts() async {
  //   await _flutterTts.setLanguage("en-US"); // Set language
  //   await _flutterTts.setSpeechRate(0.5); // Set speech rate (optional)
  // }

  static final RegExp _callPattern = RegExp(
    r'^call\s+(.+)$',
    caseSensitive: false,
  );



  // Method to translate Hinglish to English
  String _translateHinglishToEnglish(String input) {
    String translatedText = input.toLowerCase();
    _hinglishToEnglishMap.forEach((hinglish, english) {
      translatedText = translatedText.replaceAll(hinglish, english);
    });
    return translatedText.trim();
  }


  static final RegExp _youtubeOpenPattern = RegExp(
    r'^open\s+youtube$',
    caseSensitive: false,
  );

  // Helper method to extract date, time, and title from meeting description
  Map<String, dynamic> extractEventDetails(String description) {
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

  // Process search input and determine appropriate action
  Future<void> processSearch({
    required String searchText,
    required TaskStartCallback onTaskStart,
    required TaskProgressCallback onTaskProgress,
    required ErrorCallback onError,
    required BuildContext context,
  }) async {
    onTaskStart("Processing Input", [
    "Analyzing your request",
    "Determining the best action",
  ]);

  onTaskProgress(0);

  // Translate Hinglish to English if needed
  final translatedText = _translateHinglishToEnglish(searchText);
  final trimmedText = translatedText.trim();

    try {
    // Use Gemini API for NLP processing
    final prompt = '''
    Analyze this user command: "$trimmedText"
    
    Respond with ONLY ONE of these exact commands (no additional text):
    - "CALL: [name]" (if user wants to call someone)
    - "PAY: [amount]" (if user wants to make a payment)
    - "GOOGLE: [query]" (if user wants to search Google)
    - "YOUTUBE_SEARCH: [query]" (if user wants to search YouTube)
    - "OPEN_YOUTUBE" (if user wants to open YouTube)
    - "OPEN_CALENDAR" (if user wants to open the calendar)
    - "ADD_EVENT: [details]" (if user wants to add calendar event)
    - "VIEW_DATE: [date]" (if user wants to view a specific date)
    - "OPEN_MAPS" (if user wants to open Maps)
    - "OPEN_GMAIL" (if user wants to open Gmail)
    - "OPEN_SETTINGS" (if user wants to open Settings)
    - "OPEN_CAMERA" (if user wants to open Camera)
    - "OPEN_GALLERY" (if user wants to open Gallery/Photos)
    - "UNKNOWN" (if the command doesn't match any of the above)
    ''';

    final String nlpResult = await _geminiService.getResponse(prompt);
    // print("NLP Result: $nlpResult"); // Debug output
    
    onTaskProgress(1);
    
    // Parse the NLP result
    if (nlpResult.startsWith("CALL:")) {
      final name = nlpResult.substring("CALL:".length).trim();
      await handleCall(
        name: name,
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (nlpResult.startsWith("PAY:")) {
      final amount = nlpResult.substring("PAY:".length).trim();
      await handlePayment(
        amount: amount,
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (nlpResult.startsWith("GOOGLE:")) {
      final query = nlpResult.substring("GOOGLE:".length).trim();
      await handleGoogleSearch(
        searchQuery: query,
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (nlpResult.startsWith("YOUTUBE_SEARCH:")) {
      final query = nlpResult.substring("YOUTUBE_SEARCH:".length).trim();
      await handleYoutubeSearch(
        searchQuery: query,
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (nlpResult == "OPEN_YOUTUBE") {
      await handleYoutubeOpen(
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (nlpResult == "OPEN_CALENDAR") {
      await handleCalendarOpen(
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (nlpResult.startsWith("ADD_EVENT:")) {
      final details = nlpResult.substring("ADD_EVENT:".length).trim();
      await handleAddCalendarEvent(
        eventDescription: details,
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (nlpResult.startsWith("VIEW_DATE:")) {
      final date = nlpResult.substring("VIEW_DATE:".length).trim();
      await handleViewCalendarDate(
        dateDescription: date,
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (nlpResult == "OPEN_MAPS") {
      await handleMapsOpen(
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (nlpResult == "OPEN_GMAIL") {
      await handleGmailOpen(
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (nlpResult == "OPEN_SETTINGS") {
      await handleSettingsOpen(
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (nlpResult == "OPEN_CAMERA") {
      await handleCameraOpen(
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (nlpResult == "OPEN_GALLERY") {
      await handleGalleryOpen(
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else {
      // Fallback to regex patterns as a backup
      if (_tryFallbackPatterns(
        text: trimmedText,
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      )) {
        return;
      }
      
      // If all else fails, handle as unrecognized command
      await handleUnrecognizedCommand(
        command: trimmedText,
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        context: context,
      );
    }
  } catch (e) {
    print("Error processing request: $e"); // Debug output
    
    // Fallback to regex patterns if NLP fails
    if (_tryFallbackPatterns(
      text: trimmedText,
      onTaskStart: onTaskStart,
      onTaskProgress: onTaskProgress,
      onError: onError,
      context: context,
    )) {
      return;
    }
    
    onError("Failed to process your request: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process your request: $e')),
      );
    }
  }
}

bool _tryFallbackPatterns({
  required String text,
  required TaskStartCallback onTaskStart,
  required TaskProgressCallback onTaskProgress,
  required ErrorCallback onError,
  required BuildContext context,
}) {
  // Check if text matches call pattern
  final callMatch = _callPattern.firstMatch(text);
  if (callMatch != null) {
    final name = callMatch.group(1)?.trim() ?? '';
    handleCall(
      name: name,
      onTaskStart: onTaskStart,
      onTaskProgress: onTaskProgress,
      onError: onError,
      context: context,
    );
    return true;
  }

  // YouTube open pattern matching as fallback
  if (_youtubeOpenPattern.hasMatch(text)) {
    handleYoutubeOpen(
      onTaskStart: onTaskStart,
      onTaskProgress: onTaskProgress,
      onError: onError,
      context: context,
    );
    return true;
  }
  
  // Add other pattern checks here as fallbacks
  // e.g., check for _cameraOpenPattern, etc.
  
  return false; // No pattern matched
}

}