import 'package:ai_assistant/screens/metrics_screen.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../widgets/task_item.dart';
import '../services/search_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _isListening = false;

  // Animation controller for the mic button
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _secondPulseAnimation;

  // Speech to text instance
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;

  // Search service instance
  final SearchService _searchService = SearchService();

  List<Map<String, dynamic>> _taskSteps = [];
  bool _taskRunning = false;
  String _currentTaskTitle = "";

  // Command suggestions
  final List<Map<String, dynamic>> _commandSuggestions = [
    {'icon': Icons.bar_chart, 'text': 'Metrics', 'isNavigationItem': true},
    {'icon': Icons.calendar_today, 'text': 'Schedule Meeting'},
    {'icon': Icons.alarm, 'text': 'Set a reminder'},
    {'icon': Icons.search, 'text': 'Search in Google'},
    {'icon': Icons.play_arrow, 'text': 'Open Youtube'},
    {'icon': Icons.map, 'text': 'Open Maps'},
  ];

  // Define neon colors
  final Color _neonGreen = Color.fromARGB(110, 11, 245, 139);
  final Color _neonPink = Color(0xFFFF10F0);
  final Color _neonBlue = Color.fromARGB(110, 11, 245, 139);
  final Color _darkBackground = Color(0xFF121212);
  final Color _darkSurface = Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    // Initialize with "no tasks" message
    _setNoTasksMessage();
    // Initialize speech recognition
    _initSpeech();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _secondPulseAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut)
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
            _animationController.stop();
            _animationController.reset();
          });
        }
      },
      onError: (errorNotification) {
        // Handle errors
        setState(() {
          _isListening = false;
          _animationController.stop();
          _animationController.reset();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _darkSurface,
            content: Text(
              'Speech recognition error: ${errorNotification.errorMsg}',
              style: TextStyle(color: _neonPink),
            ),
          ),
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
      _animationController.repeat(reverse: true);
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _searchController.text = result.recognizedWords;
          if (result.finalResult) {
            _isListening = false;
            _animationController.stop();
            _animationController.reset();
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
      _animationController.stop();
      _animationController.reset();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
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

  // Handle command suggestion tap
  void _onCommandTap(String commandText, bool isNavigationItem) {
    if (isNavigationItem) {
      // Navigate to metrics screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MetricsScreen(),
        ),
      );
    } else {
      // Use the search bar as before
      _searchController.text = commandText;
      _sendSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      backgroundColor: _darkBackground,
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
                Center(
                  child: Text(
                    'My Assistant',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _neonBlue,
                      shadows: [
                        BoxShadow(
                          color: _neonBlue.withOpacity(0.7),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                Center(
                  child: Text(
                    'Hello how can I help today?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[400],
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Search Bar with neon styling
                Container(
                  decoration: BoxDecoration(
                    color: _darkSurface,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: _isListening ? _neonPink : _neonGreen.withOpacity(0.7),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isListening ? _neonPink.withOpacity(0.3) : _neonGreen.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  height: 50,
                  child: Row(
                    children: [
                      Icon(
                        Icons.search, 
                        color: _isListening ? _neonPink : _neonGreen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: _isListening 
                                ? 'Listening...' 
                                : 'Try something...',
                            hintStyle: TextStyle(
                              color: _isListening ? _neonPink.withOpacity(0.7) : Colors.grey[500], 
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _sendSearch(),
                        ),
                      ),
                      if (_isSearching)
                        IconButton(
                          icon: Icon(
                            Icons.send, 
                            color: _neonGreen,
                            size: 20,
                          ),
                          onPressed: _sendSearch,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 55),
                
                // Command suggestions section - horizontal scrolling
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 5, bottom: 10),
                      child: Text(
                        'Try asking:',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _commandSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _commandSuggestions[index];
                          final bool isNavigationItem = suggestion['isNavigationItem'] ?? false;
                          
                          return GestureDetector(
                            onTap: () => _onCommandTap(suggestion['text'], isNavigationItem),
                            child: Container(
                              width: 110,
                              margin: EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: _darkSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isNavigationItem ? _neonBlue.withOpacity(0.5) : _neonGreen.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isNavigationItem ? _neonBlue.withOpacity(0.2) : _neonGreen.withOpacity(0.1),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    suggestion['icon'],
                                    color: isNavigationItem ? _neonBlue : _neonGreen,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    suggestion['text'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),

                // Current Task Section
                Text(
                  _taskRunning ? 'Current Task: $_currentTaskTitle' : 'Current Task',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _neonBlue,
                    shadows: [
                      BoxShadow(
                        color: _neonBlue.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                
                // Task Steps
                if (_taskSteps.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Text(
                      'No tasks currently running',
                      style: TextStyle(
                        color: Colors.grey[500],
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
                      // Pass theme colors to TaskItem
                      iconColor: step['isCompleted'] 
                          ? _neonGreen
                          : (step['isCurrent'] ? _neonPink : Colors.grey[400]!),
                      textColor: Colors.white,
                      backgroundColor: _darkSurface,
                    );
                  }),

                const SizedBox(height: 30),
                  
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer ripple effect (only when listening)
              if (_isListening)
                Transform.scale(
                  scale: _secondPulseAnimation.value,
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      color: _neonPink.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                
              // Inner ripple effect (only when listening)
              if (_isListening)
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      color: _neonPink.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                
              // Main FAB with animation
              Transform.scale(
                scale: _isListening ? _scaleAnimation.value : 1.0,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: _isListening 
                      ? LinearGradient(
                          colors: [_neonPink, _neonPink.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [_neonGreen.withOpacity(0.9), _neonGreen.withOpacity(0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _isListening 
                            ? _neonPink.withOpacity(0.5) 
                            : _neonGreen.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isListening ? _stopListening : _startListening,
                      customBorder: CircleBorder(),
                      child: Center(
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.black,
                          size: 45,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// Simple Metrics Screen to navigate to
