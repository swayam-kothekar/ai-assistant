import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';

typedef TaskStartCallback = void Function(String taskTitle, List<String> steps);
typedef TaskProgressCallback = void Function(int completedStepIndex);
typedef ErrorCallback = void Function(String message);

Future<void> handleCall({
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

  if (!await FlutterContacts.requestPermission()) {
    onError("Permission denied to access contacts");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission denied to access contacts')),
      );
    }
    return;
  }

  final contacts = await FlutterContacts.getContacts(withProperties: true);
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
  if (matchingContacts.length == 1) {
    selectedContact = matchingContacts.first;
  } else if (context.mounted) {
    selectedContact = await showContactSelectionDialog(context: context, contacts: matchingContacts);
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

  bool shouldCall = false;
  if (context.mounted) {
    shouldCall = await showCallConfirmationDialog(context: context, contactName: selectedContact.displayName);
  }

  if (!shouldCall) {
    onError("Call cancelled");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call cancelled')),
      );
    }
    return;
  }

  final phoneNumber = selectedContact.phones.isNotEmpty ? selectedContact.phones.first.number : '';

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

  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.CALL',
      data: 'tel:$phoneNumber',
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
    onTaskProgress(3);
  } catch (e) {
    onError("Could not initiate call: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not initiate call: $e')),
      );
    }
  }
}

Future<bool> showCallConfirmationDialog({
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
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Call'),
          ),
        ],
      );
    },
  ) ?? false;
}

Future<Contact?> showContactSelectionDialog({
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
                title: Text(contact.displayName),
                onTap: () => Navigator.of(context).pop(contact),
              );
            }).toList(),
          ),
        ),
      );
    },
  );
}