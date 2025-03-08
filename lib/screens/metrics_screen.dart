import 'package:flutter/material.dart';
import 'package:ai_assistant/services/metrics_service.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DeviceMetricsService _metricsService = DeviceMetricsService();

  // Data from service
  Map<String, dynamic> _systemMetrics = {};
  Map<String, dynamic> _deviceInfo = {};
  Map<String, dynamic> _networkStats = {};
  bool _isLoading = true;

  // Define neon colors
  final Color _neonGreen = Color.fromARGB(110, 11, 245, 139);
  // final Color _neonPink = Color(0xFFFF10F0);
  final Color _neonBlue = Color.fromARGB(110, 11, 245, 139);
  final Color _darkBackground = Color(0xFF121212);
  final Color _darkSurface = Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRealData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load data from the service
  Future<void> _loadRealData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final systemMetrics = await _metricsService.getSystemPerformance();
      final deviceInfo = await _metricsService.getDeviceInfo();
      final networkStats = await _metricsService.getNetworkStats();

      setState(() {
        _systemMetrics = systemMetrics;
        _deviceInfo = deviceInfo;
        _networkStats = networkStats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading metrics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _refreshMetrics() {
    _loadRealData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        backgroundColor: _darkSurface,
        title: Text(
          'System Metrics',
          style: TextStyle(
            color: _neonBlue,
            fontWeight: FontWeight.bold,
            shadows: [
              BoxShadow(
                color: _neonBlue.withOpacity(0.7),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _neonGreen),
            onPressed: _refreshMetrics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _neonGreen,
          labelColor: _neonGreen,
          unselectedLabelColor: Colors.grey[400],
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'CPU'),
            Tab(text: 'Memory'),
            Tab(text: 'Network'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: _neonGreen,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                _buildOverviewTab(),
                // CPU Tab
                _buildCpuTab(),
                // Memory Tab
                _buildMemoryTab(),
                // Network Tab
                _buildNetworkTab(),
              ],
            ),
    );
  }

  // Build the overview tab with summary of all metrics
  Widget _buildOverviewTab() {
    final cpuData = _systemMetrics['cpu'] as Map<String, dynamic>? ?? {};
    final memoryData = _systemMetrics['memory'] as Map<String, dynamic>? ?? {};
    final networkData = _systemMetrics['network'] as Map<String, dynamic>? ?? {};

    // Get CPU current value and average from history
    final cpuValue = cpuData['usage'] as double? ?? 0.0;
    final cpuHistory = cpuData['history'] as Map<String, dynamic>? ?? {};
    double cpuAverage = 0.0;
    if (cpuHistory.isNotEmpty) {
      cpuAverage = cpuHistory.values.fold(0.0, (sum, value) => sum + (value as double)) / cpuHistory.length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Performance Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _neonBlue,
            ),
          ),
          const SizedBox(height: 20),

          // CPU Card
          _buildMetricCard(
            'CPU Usage',
            'Current: ${cpuValue.toStringAsFixed(1)}%',
            'Average: ${cpuAverage.toStringAsFixed(1)}%',
            Icons.memory,
            _neonBlue,
            cpuValue / 100,
          ),

          const SizedBox(height: 16),

          // Memory Card
          _buildMetricCard(
            'Memory Usage',
            'Used: ${memoryData['used']?.toStringAsFixed(1) ?? "0"} GB',
            'Available: ${memoryData['available']?.toStringAsFixed(1) ?? "0"} GB',
            Icons.storage,
            _neonGreen,
            memoryData['total'] != null && memoryData['total'] > 0
                ? (memoryData['used'] ?? 0) / (memoryData['total'] ?? 1)
                : 0,
          ),

          const SizedBox(height: 16),

          // Network Card
          _buildMetricCard(
            'Network Stats',
            'Download: ${networkData['download']?.toStringAsFixed(1) ?? "0"} Mbps',
            'Upload: ${networkData['upload']?.toStringAsFixed(1) ?? "0"} Mbps',
            Icons.network_check,
            _neonGreen,
            0.7, // Fixed progress for network visualization
          ),

          const SizedBox(height: 20),

          // System Health Score
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _neonGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.health_and_safety, size: 50, color: _neonGreen),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Health Score',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _neonGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _calculateHealthScore(cpuValue, memoryData),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _neonGreen,
                        ),
                      ),
                      Text(
                        _getHealthDescription(cpuValue, memoryData),
                        style: TextStyle(
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build CPU metrics tab
  Widget _buildCpuTab() {
    final cpuData = _systemMetrics['cpu'] as Map<String, dynamic>? ?? {};
    final cpuUsage = cpuData['usage'] as double? ?? 0.0;
    final cpuCores = cpuData['cores'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CPU Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _neonBlue,
            ),
          ),
          const SizedBox(height: 20),

          // CPU Core Information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _neonGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CPU Core Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _neonGreen,
                  ),
                ),
                const SizedBox(height: 16),

                // CPU cores from actual data
                if (cpuCores.isEmpty)
                  Text(
                    'No CPU core data available',
                    style: TextStyle(
                      color: Colors.grey[400],
                    ),
                  )
                else
                  ...List.generate(cpuCores.length, (index) {
                    final coreUsage = cpuCores[index] as double? ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Text(
                            'Core ${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: coreUsage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getColorForCpuUsage(coreUsage),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${coreUsage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // CPU Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _neonGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CPU Statistics',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _neonGreen,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow('CPU Model', _deviceInfo['cpuModel'] ?? 'Unknown'),
                _buildStatRow('CPU Cores', _deviceInfo['cpuCores'] ?? 'Unknown'),
                _buildStatRow('Current Usage', '${cpuUsage.toStringAsFixed(1)}%'),
                _buildStatRow('System', _deviceInfo['systemName'] ?? 'Unknown'),
                _buildStatRow('Temperature', 'Not available'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build Memory metrics tab
  Widget _buildMemoryTab() {
    final memoryData = _systemMetrics['memory'] as Map<String, dynamic>? ?? {};
    final totalMemory = memoryData['total'] as double? ?? 0.0;
    final usedMemory = memoryData['used'] as double? ?? 0.0;
    final availableMemory = memoryData['available'] as double? ?? 0.0;

    final memoryUsedPercent = totalMemory > 0 ? usedMemory / totalMemory : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Memory Usage',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _neonBlue,
            ),
          ),
          const SizedBox(height: 20),

          // Memory Usage Circle
          Center(
  child: Container(
    width: 200,
    height: 200,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _darkSurface,
      border: Border.all(
        color: _neonGreen.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        // CircularProgressIndicator (Pie Chart)
        SizedBox(
          width: 200, // Match the container size
          height: 200, // Match the container size
          child: CircularProgressIndicator(
            value: memoryUsedPercent,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              memoryUsedPercent < 0.7 ? _neonGreen : memoryUsedPercent < 0.9 ? Colors.orange : Colors.red,
            ),
            strokeWidth: 20, // Adjust stroke width as needed
          ),
        ),
        // Percentage and "Used" Text
        Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center the text vertically
          children: [
            Text(
              '${(memoryUsedPercent * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _neonGreen,
              ),
            ),
            const SizedBox(height: 8), // Spacing between percentage and "Used" text
            Text(
              'Used: ${usedMemory.toStringAsFixed(1)} GB',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
),
          const SizedBox(height: 30),

          // Memory Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _neonGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Memory Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _neonGreen,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow('Total Memory', '${totalMemory.toStringAsFixed(1)} GB'),
                _buildStatRow('Used Memory', '${usedMemory.toStringAsFixed(1)} GB'),
                _buildStatRow('Available Memory', '${availableMemory.toStringAsFixed(1)} GB'),
                _buildStatRow('Memory Type', _deviceInfo['memoryType'] ?? 'Unknown'),
                _buildStatRow('Memory Speed', _deviceInfo['memorySpeed'] ?? 'Unknown'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build Network metrics tab
  Widget _buildNetworkTab() {
    final download = _networkStats['download'] as double? ?? 0.0;
    final upload = _networkStats['upload'] as double? ?? 0.0;
    final latency = _networkStats['latency'] as double? ?? 0.0;
    final packetLoss = _networkStats['packetLoss'] as double? ?? 0.0;
    final networkType = _networkStats['type'] as String? ?? 'Unknown';
    final networkName = _networkStats['networkName'] as String? ?? 'Unknown Network';
    final signalStrength = _networkStats['signalStrength'] as String? ?? 'Unknown';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _neonBlue,
            ),
          ),
          const SizedBox(height: 20),

          // Download/Upload Graph
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _neonGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Network Activity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _neonGreen,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNetworkSpeedIndicator(
                        'Download',
                        Icons.arrow_downward,
                        _neonGreen,
                        '${download.toStringAsFixed(1)} Mbps',
                      ),
                      _buildNetworkSpeedIndicator(
                        'Upload',
                        Icons.arrow_upward,
                        _neonBlue,
                        '${upload.toStringAsFixed(1)} Mbps',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Network Statistics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _neonGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Network Statistics',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _neonGreen,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow('Connection Type', networkType),
                _buildStatRow('Network Name', networkName),
                _buildStatRow('Latency', '${latency.toStringAsFixed(1)} ms'),
                _buildStatRow('Packet Loss', '${packetLoss.toStringAsFixed(2)}%'),
                _buildStatRow('Signal Strength', signalStrength),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for UI components

  // Build a metric card for the overview tab
  Widget _buildMetricCard(String title, String value1, String value2, IconData icon, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value1,
                style: TextStyle(
                  color: Colors.grey[400],
                ),
              ),
              Text(
                value2,
                style: TextStyle(
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build a stat row for details sections
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Build network speed indicator
  Widget _buildNetworkSpeedIndicator(String label, IconData icon, Color color, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 16),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Calculate a health score based on actual metrics
  String _calculateHealthScore(double cpuUsage, Map<String, dynamic> memoryData) {
    double memoryUsagePercent = memoryData['total'] != null && memoryData['total'] > 0
        ? (memoryData['used'] ?? 0) / (memoryData['total'] ?? 1) * 100
        : 50;

    double healthScore = 100 - (0.4 * cpuUsage + 0.4 * memoryUsagePercent);
    return '${healthScore.round()}%';
  }

  // Get health description based on metrics
  String _getHealthDescription(double cpuUsage, Map<String, dynamic> memoryData) {
    double memoryUsagePercent = memoryData['total'] != null && memoryData['total'] > 0
        ? (memoryData['used'] ?? 0) / (memoryData['total'] ?? 1) * 100
        : 50;

    if (cpuUsage > 80 || memoryUsagePercent > 80) {
      return 'System is under heavy load';
    } else if (cpuUsage > 60 || memoryUsagePercent > 60) {
      return 'System is running normally';
    } else {
      return 'System is running optimally';
    }
  }

  // Get color for CPU usage based on value
  Color _getColorForCpuUsage(double value) {
    if (value < 50) {
      return _neonGreen;
    } else if (value < 80) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Get color for progress indicators
  Color _getProgressColor(double progress) {
    if (progress < 0.6) {
      return _neonGreen;
    } else if (progress < 0.8) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}