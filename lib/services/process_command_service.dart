import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String?> processCommand(String userInput) async {
  final url = Uri.parse('http://127.0.0.1:5000/process_command');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'command': userInput}),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['command'];
  } else {
    throw Exception('Failed to process command');
  }
}