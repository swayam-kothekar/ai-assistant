import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/floating_widget_controller.dart'; // This will be the new file we create

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Important for platform channels
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize floating widget controller
    _initializeFloatingWidget();
  }

  Future<void> _initializeFloatingWidget() async {
    await FloatingWidgetController.initialize((command) {
      // Process the voice command
      // This will handle commands even when app is in background
      print("Received voice command: $command");
      
      // You can add logic here to process the command
      // or route it to appropriate handler in your app
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kairii',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}