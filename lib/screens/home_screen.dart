import 'package:ai_assistant/screens/qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../widgets/task_item.dart';
import '../widgets/quick_action_button.dart';
import '../services/search_service.dart';
import './metrics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _isListening = false;

  // Speech to text instance
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;

  // Search service instance
  final SearchService _searchService = SearchService();

  List<Map<String, dynamic>> _taskSteps = [];
  bool _taskRunning = false;
  String _currentTaskTitle = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    // Initialize with "no tasks" message
    _setNoTasksMessage();
    // Initialize speech recognition
    _initSpeech();
  }

  void _openQRScannerForPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodeScannerScreen(
          onScanComplete: (String qrData) {
            // Use the existing search service to process payment
            _searchService.processSearch(
              searchText: "pay using qr: $qrData", // Format the command for SearchService
              onTaskStart: _startTask,
              onTaskProgress: _updateTaskProgress,
              onError: _handleSearchError,
              context: context,
            );
          },
        ),
      ),
    );
  }

  // Initialize speech recognition
  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        // Update UI when speech status changes
        if (status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (errorNotification) {
        // Handle errors
        setState(() {
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition error: ${errorNotification.errorMsg}')),
        );
      },
    );
    setState(() {});
  }

  // Start listening for speech
  void _startListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
    }

    setState(() {
      _isListening = true;
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _searchController.text = result.recognizedWords;
          if (result.finalResult) {
            _isListening = false;
            // If we have a final result, automatically send the search
            if (_searchController.text.isNotEmpty) {
              _sendSearch();
            }
          }
        });
      },
    );
  }

  // Stop listening for speech
  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setNoTasksMessage() {
    setState(() {
      _taskSteps = [];
      _taskRunning = false;
      _currentTaskTitle = "No tasks currently running";
    });
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

  void _startTask(String taskTitle, List<String> steps) {
    List<Map<String, dynamic>> newTaskSteps = [];
    
    // Create task steps with initial states
    for (int i = 0; i < steps.length; i++) {
      newTaskSteps.add({
        'text': steps[i],
        'isCompleted': false,
        'isCurrent': i == 0, // First step is current
      });
    }
    
    setState(() {
      _taskSteps = newTaskSteps;
      _taskRunning = true;
      _currentTaskTitle = taskTitle;
    });
  }

  void _updateTaskProgress(int completedStepIndex) {
    if (!_taskRunning || _taskSteps.isEmpty) return;
    
    setState(() {
      // Mark the completed step
      if (completedStepIndex < _taskSteps.length) {
        _taskSteps[completedStepIndex]['isCompleted'] = true;
        _taskSteps[completedStepIndex]['isCurrent'] = false;
      }
      
      // Set the next step as current
      if (completedStepIndex + 1 < _taskSteps.length) {
        _taskSteps[completedStepIndex + 1]['isCurrent'] = true;
      } else {
        // All steps completed
        Future.delayed(const Duration(seconds: 3), () {
          _setNoTasksMessage();
        });
      }
    });
  }

  void _handleSearchError(String errorMessage) {
    // Update task to show error
    setState(() {
      // Find the current step and update it with error
      for (int i = 0; i < _taskSteps.length; i++) {
        if (_taskSteps[i]['isCurrent']) {
          _taskSteps[i]['text'] = "Error: $errorMessage";
          _taskSteps[i]['isCurrent'] = false;
          _taskSteps[i]['isCompleted'] = true;
          break;
        }
      }
    });
  }

  Future<void> _sendSearch() async {
    final searchText = _searchController.text.trim();
    
    if (searchText.isEmpty) return;
    
    // Use the search service to process the input
    await _searchService.processSearch(
      searchText: searchText,
      onTaskStart: _startTask,
      onTaskProgress: _updateTaskProgress,
      onError: _handleSearchError,
      context: context,
    );
    
    // Clear the search field and unfocus to hide keyboard
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  // Navigate to metrics screen
  void _navigateToMetrics() {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MetricsScreen()),
      );
    } catch (e) {
      // Show an error message to the user if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error navigating to metrics: $e')),
      );
    }
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
                const SizedBox(height: 30),
                // Title Bar
                const Center(
                  child: Text(
                    'My Assistant',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

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
                            hintText: _isListening 
                                ? 'Listening...' 
                                : 'How can I help you today?',
                            hintStyle: TextStyle(
                              color: _isListening ? Colors.blue : Colors.grey[600], 
                              fontSize: 16
                            ),
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
                const SizedBox(height: 40),

                // Current Task Section
                Text(
                  _taskRunning ? 'Current Task: $_currentTaskTitle' : 'Current Task',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 15),
                
                // Task Steps
                if (_taskSteps.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Text(
                      'No tasks currently running',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ...List.generate(_taskSteps.length, (index) {
                    final step = _taskSteps[index];
                    return TaskItem(
                      icon: step['isCompleted'] 
                          ? Icons.assignment_turned_in 
                          : (step['isCurrent'] ? Icons.lightbulb_outline : Icons.recommend),
                      text: step['text'],
                      isCompleted: step['isCompleted'],
                      isCurrent: step['isCurrent'],
                    );
                  }),

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
                      icon: Icons.call,
                      color: Colors.purple[100]!,
                      label: 'Call',
                      onTap: () {
                        // Implement call feature here
                      },
                    ),
                    QuickActionButton(
                      icon: Icons.calendar_today,
                      color: Colors.blue[100]!,
                      label: 'Calendar',
                      onTap: () {
                        // Implement calendar feature here
                      },
                    ),
                    QuickActionButton(
                      icon: Icons.qr_code_scanner,
                      color: Colors.green[100]!,
                      label: 'Scan QR',
                      onTap: _openQRScannerForPayment,
                    ),
                    QuickActionButton(
                      icon: Icons.auto_graph,
                      color: Colors.red[100]!,
                      label: 'Metrics',
                      onTap: _navigateToMetrics,
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
        onPressed: _isListening ? _stopListening : _startListening,
        backgroundColor: _isListening ? Colors.red : Colors.black,
        child: Icon(
          _isListening ? Icons.stop : Icons.mic, 
          color: Colors.white
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}