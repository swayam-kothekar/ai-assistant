import 'package:ai_assistant/screens/qr_screen.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // For date formatting
// import 'package:contacts_service/contacts_service.dart'; // For accessing contacts
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Callback types for updating UI state
typedef TaskStartCallback = void Function(String taskTitle, List<String> steps);
typedef TaskProgressCallback = void Function(int completedStepIndex);
typedef ErrorCallback = void Function(String message);

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

  final FlutterTts _flutterTts = FlutterTts();

  // Future<void> _initTts() async {
  //   await _flutterTts.setLanguage("en-US"); // Set language
  //   await _flutterTts.setSpeechRate(0.5); // Set speech rate (optional)
  // }

  // Provide voice feedback
  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  static final RegExp _callPattern = RegExp(
    r'^call\s+(.+)$',
    caseSensitive: false,
  );

  static final RegExp _paymentPattern = RegExp(
  r'^pay\s+(?:rs|rupees?)?\s*(\d+)\s+(?:rs|rupees?)?\s+to\s+(.+)$',
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

  // Regular expressions for detecting YouTube commands
  static final RegExp _youtubeSearchPattern = RegExp(
    r'^(?:open\s+youtube\s+and\s+search|search\s+(?:on|in)\s+youtube\s+for|youtube\s+search)(?:\s+for)?\s+(.+)$',
    caseSensitive: false,
  );

  static final RegExp _youtubeOpenPattern = RegExp(
    r'^open\s+youtube$',
    caseSensitive: false,
  );

  // Regular expression for detecting Google search commands
  static final RegExp _googleSearchPattern = RegExp(
    r'^(?:search\s+(?:on|in)\s+google\s+for|google\s+search)(?:\s+for)?\s+(.+)$',
    caseSensitive: false,
  );

  // Calendar patterns for various calendar commands
  static final RegExp _calendarOpenPattern = RegExp(
    r'^open\s+(?:my\s+)?calendar$',
    caseSensitive: false,
  );

  static final RegExp _addEventPattern = RegExp(
    r'^(?:add|create|schedule)(?:\s+a)?(?:\s+new)?(?:\s+meeting|event|appointment)(?:\s+(?:on|in|to)(?:\s+my)?(?:\s+calendar))?\s+(.+)$',
    caseSensitive: false,
  );

  static final RegExp _viewDatePattern = RegExp(
    r'^(?:show|view|open|check)(?:\s+my)?(?:\s+calendar)(?:\s+for)?\s+(.+)$',
    caseSensitive: false,
  );

  // Regular expressions for detecting app-specific commands
  static final RegExp _mapsOpenPattern = RegExp(
    r'^open\s+(?:google\s+)?maps$',
    caseSensitive: false,
  );

  static final RegExp _gmailOpenPattern = RegExp(
    r'^open\s+gmail$',
    caseSensitive: false,
  );

  static final RegExp _settingsOpenPattern = RegExp(
    r'^open\s+settings$',
    caseSensitive: false,
  );

  static final RegExp _cameraOpenPattern = RegExp(
    r'^open\s+camera$',
    caseSensitive: false,
  );

  static final RegExp _galleryOpenPattern = RegExp(
    r'^open\s+(?:gallery|photos)$',
    caseSensitive: false,
  );

  // Helper method to extract date, time, and title from meeting description
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

  // Process search input and determine appropriate action
  Future<void> processSearch({
    required String searchText,
    required TaskStartCallback onTaskStart,
    required TaskProgressCallback onTaskProgress,
    required ErrorCallback onError,
    required BuildContext context,
  }) async {
    // Translate Hinglish to English
    final translatedText = _translateHinglishToEnglish(searchText);
    final trimmedText = translatedText.trim();

    // Check if text matches call pattern
    final callMatch = _callPattern.firstMatch(trimmedText);

    // Check if text matches payment pattern
    final paymentMatch = _paymentPattern.firstMatch(trimmedText);

    // Check if text matches Google search pattern
    final googleSearchMatch = _googleSearchPattern.firstMatch(trimmedText);

    // Check if text matches YouTube patterns
    final youtubeSearchMatch = _youtubeSearchPattern.firstMatch(trimmedText);
    final isYoutubeOpen = _youtubeOpenPattern.hasMatch(trimmedText);

    // Check if text matches Calendar patterns
    final isCalendarOpen = _calendarOpenPattern.hasMatch(trimmedText);
    final addEventMatch = _addEventPattern.firstMatch(trimmedText);
    final viewDateMatch = _viewDatePattern.firstMatch(trimmedText);

    // Check if text matches app-specific patterns
    final isMapsOpen = _mapsOpenPattern.hasMatch(trimmedText);
    final isGmailOpen = _gmailOpenPattern.hasMatch(trimmedText);
    final isSettingsOpen = _settingsOpenPattern.hasMatch(trimmedText);
    final isCameraOpen = _cameraOpenPattern.hasMatch(trimmedText);
    final isGalleryOpen = _galleryOpenPattern.hasMatch(trimmedText);

    if (callMatch != null) {
      final name = callMatch.group(1)?.trim() ?? '';
      await _handleCall(
        name: name,
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (paymentMatch != null) {
      final amount = paymentMatch.group(1);
      // final name = paymentMatch.group(2)?.trim() ?? '';
      await _handlePayment(
        amount: amount ?? '',
        // name: name,
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
      } else if (googleSearchMatch != null) {
      await _handleGoogleSearch(
        searchQuery: googleSearchMatch.group(1)?.trim() ?? '',
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (youtubeSearchMatch != null) {
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
    } else if (isMapsOpen) {
      await _handleMapsOpen(
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (isGmailOpen) {
      await _handleGmailOpen(
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (isSettingsOpen) {
      await _handleSettingsOpen(
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (isCameraOpen) {
      await _handleCameraOpen(
        onTaskStart: onTaskStart,
        onTaskProgress: onTaskProgress,
        onError: onError,
        context: context,
      );
    } else if (isGalleryOpen) {
      await _handleGalleryOpen(
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

 Future<void> _handleCall({
  required String name,
  required TaskStartCallback onTaskStart,
  required TaskProgressCallback onTaskProgress,
  required ErrorCallback onError,
  required BuildContext context,
}) async {
  onTaskStart("Processing Call", [
    "Finding contacts matching: $name",
    "Selecting contact",
    "Initiating call",
  ]);

  onTaskProgress(0);

  // Request contact permissions
  if (!await FlutterContacts.requestPermission()) {
    onError("Permission denied to access contacts");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission denied to access contacts')),
      );
    }
    return;
  }

  // Fetch all contacts
  final contacts = await FlutterContacts.getContacts(withProperties: true);

  // Filter contacts by name
  final matchingContacts = contacts.where((contact) {
    return contact.displayName.toLowerCase().contains(name.toLowerCase());
  }).toList();

  onTaskProgress(1);

  if (matchingContacts.isEmpty) {
    onError("No contacts found matching: $name");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No contacts found matching: $name')),
      );
    }
    return;
  }

  Contact? selectedContact;

  // If only one matching contact is found, skip the selection dialog
  if (matchingContacts.length == 1) {
    selectedContact = matchingContacts.first;
  } else {
    // Prompt user to select a contact if multiple matches are found
    selectedContact = await _showContactSelectionDialog(
      context: context,
      contacts: matchingContacts,
    );
  }

  if (selectedContact == null) {
    onError("No contact selected");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No contact selected')),
      );
    }
    return;
  }

  onTaskProgress(2);

  // Confirm the call
  final shouldCall = await _showCallConfirmationDialog(
    context: context,
    contactName: selectedContact.displayName,
  );

  if (!shouldCall) {
    onError("Call cancelled");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call cancelled')),
      );
    }
    return;
  }

  // Get the phone number from the selected contact
  final phoneNumber = selectedContact.phones.isNotEmpty
      ? selectedContact.phones.first.number
      : '';

  if (phoneNumber.isEmpty) {
    onError("No phone number found for selected contact");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No phone number found for selected contact')),
      );
    }
    return;
  }

  var status = await Permission.phone.status;
  if (!status.isGranted) {
    status = await Permission.phone.request();
    if (!status.isGranted) {
      onError("Permission denied to make phone calls");
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission denied to make phone calls')),
        );
      }
      return;
    }
  }

  // Initiate the call directly
  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.CALL',
      data: 'tel:$phoneNumber',
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
    onTaskProgress(3);

    // Provide voice feedback
    await _speak("Calling ${selectedContact.displayName}");
  } catch (e) {
    onError("Could not initiate call: $e");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not initiate call: $e')),
      );
    }
  }
}

// Show a dialog to confirm the call
   Future<bool> _showCallConfirmationDialog({
  required BuildContext context,
  required String contactName,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Call'),
        content: Text('Do you want to call $contactName?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Cancel
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Confirm
            },
            child: Text('Call'),
          ),
        ],
      );
    },
  ) ?? false; // Default to false if the dialog is dismissed
}

  // Handle payment command
  Future<void> _handlePayment({
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

  // Open the QR code scanner screen
  final String? qrData = await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (context) => QRCodeScannerScreen(
        onScanComplete: (data) {
          Navigator.of(context).pop(data); // Return the scanned data
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

  // Extract UPI payment details from the QR code
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

  // Add the amount to the payment URI if it's not already present
  final updatedUri = paymentUri.replace(queryParameters: {
    ...paymentUri.queryParameters,
    'am': amount,
  });

  onTaskProgress(2);

  // Initiate the payment
  try {
    await launchUrl(updatedUri, mode: LaunchMode.externalApplication);
    onTaskProgress(3);

    // Provide voice feedback
    await _speak("Initiating payment of $amount");
  } catch (e) {
    onError("Could not initiate payment: $e");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not initiate payment: $e')),
      );
    }
  }
}

  // Show a dialog to select a contact
  Future<Contact?> _showContactSelectionDialog({
  required BuildContext context,
  required List<Contact> contacts,
}) async {
  return await showDialog<Contact>(
  context: context,
  builder: (BuildContext context) {
    return AlertDialog(
      title: Text('Select a contact'),
      content: SingleChildScrollView(
        child: ListBody(
          children: contacts.map((contact) {
            return ListTile(
              title: Text(contact.displayName), // Use displayName instead of contact.name
              onTap: () {
                Navigator.of(context).pop(contact);
              },
            );
          }).toList(),
        ),
      ),
    );
  },
);
}

  // Handle Google search command
  Future<void> _handleGoogleSearch({
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
      onTaskProgress(1);

      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.android.chrome', // You can use any browser package name
        data: 'https://www.google.com/search?q=${Uri.encodeComponent(searchQuery)}',
      );
      await intent.launch();

      onTaskProgress(2);

       // Provide voice feedback
    await _speak("Searching on Google");
    } on PlatformException {
      final Uri webUri = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(searchQuery)}');
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        onTaskProgress(2);
        await _speak("Searching on Google");
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

  // Handle YouTube search command
  Future<void> _handleYoutubeSearch({
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
      onTaskProgress(1);

      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.google.android.youtube',
        data: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(searchQuery)}',
      );
      await intent.launch();

      onTaskProgress(2);

      await _speak("Searching on YouTube");
    } on PlatformException {
      final Uri webUri = Uri.parse('https://www.youtube.com/results?search_query=${Uri.encodeComponent(searchQuery)}');
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        onTaskProgress(2);

        await _speak("Searching on YouTube");
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

  // Handle command to just open YouTube
  Future<void> _handleYoutubeOpen({
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

    // Provide voice feedback
    await _speak("Opening YouTube");
  } on PlatformException {
    final Uri webUri = Uri.parse('https://www.youtube.com/');
    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      onTaskProgress(1);

      // Provide voice feedback
      await _speak("Opening YouTube");
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

  // Handle command to open calendar
  Future<void> _handleCalendarOpen({
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

      await _speak("Opening Calendar");
    } on PlatformException {
      try {
        final calendarUri = Uri.parse('content://com.android.calendar/time/');
        await launchUrl(calendarUri);
        onTaskProgress(1);

        await _speak("Opening Calendar");
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

    // Provide voice feedback
    await _speak("Event '$title' scheduled for $formattedDate at $formattedTime");

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

  // Helper method to get the next occurrence of a weekday
  DateTime _getNextWeekday(int weekday) {
    DateTime date = DateTime.now();
    int daysUntil = weekday - date.weekday;
    if (daysUntil <= 0) daysUntil += 7;
    return date.add(Duration(days: daysUntil));
  }

  // Handle command to open Google Maps
  Future<void> _handleMapsOpen({
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

  // Handle command to open Gmail
  Future<void> _handleGmailOpen({
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

      await _speak("Opening Gmail");
    } on PlatformException catch (e) {
      onError("Could not open Gmail: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Gmail: $e')),
        );
      }
    }
  }

  // Handle command to open Settings
  Future<void> _handleSettingsOpen({
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

      await _speak("Opening Settings");
    } on PlatformException catch (e) {
      onError("Could not open Settings: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Settings: $e')),
        );
      }
    }
  }

  // Handle command to open Camera
  Future<void> _handleCameraOpen({
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

      await _speak("Opening Camera");
    } on PlatformException catch (e) {
      onError("Could not open Camera: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Camera: $e')),
        );
      }
    }
  }

  // Handle command to open Gallery/Photos
  Future<void> _handleGalleryOpen({
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

      await _speak("Opening Photos");
    } on PlatformException catch (e) {
      onError("Could not open Gallery: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Gallery: $e')),
        );
      }
    }
  }

  // Handle unrecognized commands
  Future<void> _handleUnrecognizedCommand({
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
}