import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import '../widgets/task_item.dart';
import '../widgets/action_item.dart';
import '../widgets/quick_action_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
    });
  }

  void _onFocusChanged() {
    setState(() {
      // This will update the UI when focus changes
    });
  }


Future<void> _sendSearch() async {
  final searchText = _searchController.text.trim();
  
  // Regex patterns to detect YouTube commands
  final RegExp youtubeSearchPattern = RegExp(
    r'^(?:open\s+youtube\s+and\s+search|search\s+(?:on|in)\s+youtube\s+for|youtube\s+search)(?:\s+for)?\s+(.+)$',
    caseSensitive: false
  );
  
  final RegExp youtubeOpenPattern = RegExp(
    r'^open\s+youtube$',
    caseSensitive: false
  );
  
  // Check if text matches YouTube search pattern
  final youtubeSearchMatch = youtubeSearchPattern.firstMatch(searchText);
  final isYoutubeOpen = youtubeOpenPattern.hasMatch(searchText);
  
  if (youtubeSearchMatch != null) {
    // Extract the search query from the command
    final searchQuery = youtubeSearchMatch.group(1)?.trim() ?? '';
    
    if (searchQuery.isNotEmpty) {
      try {
        // Use AndroidIntent to launch YouTube with search
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          package: 'com.google.android.youtube',
          data: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(searchQuery)}',
        );
        await intent.launch();
        
        // Show confirmation
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Searching YouTube for: $searchQuery')),
        );
      } on PlatformException {
        // Fall back to web if the app isn't installed
        final Uri webUri = Uri.parse('https://www.youtube.com/results?search_query=${Uri.encodeComponent(searchQuery)}');
        try {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        } catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch YouTube: $e')),
          );
        }
      }
    }
  } else if (isYoutubeOpen) {
    // Just open YouTube homepage
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.google.android.youtube',
        data: 'https://www.youtube.com/',
      );
      await intent.launch();
      
      // Show confirmation
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening YouTube')),
      );
    } on PlatformException {
      // Fall back to web if the app isn't installed
      final Uri webUri = Uri.parse('https://www.youtube.com/');
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch YouTube: $e')),
        );
      }
    }
  } else {
    // Not a YouTube command - handle differently or show message
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('I understand: "$searchText" (not a YouTube command)')),
    );
    
    // Here you would add your NLP processing in the future
  }
  
  // Clear the search field and unfocus to hide keyboard
  _searchController.clear();
  _searchFocusNode.unfocus();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar with YouTube integration
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  height: 50,
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: 'How can I help you today?',
                            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 16),
                          onSubmitted: (_) => _sendSearch(),
                        ),
                      ),
                      if (_isSearching)
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: _sendSearch,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Current Task Section
                const Text(
                  'Current Task',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 15),
                
                // Task Steps
                const TaskItem(
                  icon: Icons.assignment_turned_in,
                  text: 'Analyzing expense patterns',
                  isCompleted: true,
                  isCurrent: false,
                ),
                const TaskItem(
                  icon: Icons.lightbulb_outline,
                  text: 'Generating insights',
                  isCompleted: false,
                  isCurrent: true,
                ),
                const TaskItem(
                  icon: Icons.recommend,
                  text: 'Preparing recommendations',
                  isCompleted: false,
                  isCurrent: false,
                ),
                
                const SizedBox(height: 30),
                
                // Recent Actions Section
                const Text(
                  'Recent Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 15),
                
                // Meeting Action
                ActionItem(
                  icon: Icons.calendar_today,
                  color: Colors.blue[100]!,
                  title: 'Meeting scheduled',
                  subtitle: 'Tomorrow, 2:00 PM',
                  actionButton: TextButton(
                    onPressed: () {},
                    child: const Text('View', style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 10),
                
                // Payment Action
                ActionItem(
                  icon: Icons.attach_money,
                  color: Colors.green[100]!,
                  title: 'Payment sent',
                  subtitle: 'To: Sarah Wilson',
                  actionButton: TextButton(
                    onPressed: () {},
                    child: const Text('Details', style: TextStyle(color: Colors.black)),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Quick Actions Section
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 15),
                
                // Quick Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    QuickActionButton(
                      icon: Icons.mic,
                      color: Colors.purple[100]!,
                      label: 'Voice',
                    ),
                    QuickActionButton(
                      icon: Icons.calendar_today,
                      color: Colors.blue[100]!,
                      label: 'Calendar',
                    ),
                    QuickActionButton(
                      icon: Icons.credit_card,
                      color: Colors.green[100]!,
                      label: 'Payment',
                    ),
                    QuickActionButton(
                      icon: Icons.pie_chart,
                      color: Colors.orange[100]!,
                      label: 'Analytics',
                    ),
                  ],
                ),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.black,
        child: const Icon(Icons.mic, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}