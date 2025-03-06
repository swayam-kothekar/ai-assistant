import 'package:flutter/material.dart';
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

  void _sendSearch() {
    // Implement search functionality here
    print("Searching for: ${_searchController.text}");
    // You can add your search logic here
    
    // Optionally clear the search field after sending
    // _searchController.clear();
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use resizeToAvoidBottomInset to prevent keyboard from causing overflow
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar - Now Interactive with Send Button
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
                
                // Add extra space at the bottom to ensure everything is accessible
                // when the keyboard is open
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