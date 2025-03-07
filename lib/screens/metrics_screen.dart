import 'package:ai_assistant/services/metrics_service.dart';
import 'package:flutter/material.dart';

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
      appBar: AppBar(
        title: const Text('System Metrics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMetrics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'CPU'),
            Tab(text: 'Memory'),
            Tab(text: 'Network'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
    // final diskData = _systemMetrics['disk'] as Map<String, dynamic>? ?? {};
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
          const Text(
            'System Performance Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // CPU Card
          _buildMetricCard(
            'CPU Usage',
            'Current: ${cpuValue.toStringAsFixed(1)}%',
            'Average: ${cpuAverage.toStringAsFixed(1)}%',
            Icons.memory,
            Colors.blue,
            cpuValue / 100,
          ),
          
          const SizedBox(height: 16),
          
          // Memory Card
          _buildMetricCard(
            'Memory Usage',
            'Used: ${memoryData['used']?.toStringAsFixed(1) ?? "0"} GB',
            'Available: ${memoryData['available']?.toStringAsFixed(1) ?? "0"} GB',
            Icons.storage,
            Colors.green,
            memoryData['total'] != null && memoryData['total'] > 0
                ? (memoryData['used'] ?? 0) / (memoryData['total'] ?? 1)
                : 0,
          ),
          
          const SizedBox(height: 16),
          
          // // Disk Card
          // _buildMetricCard(
          //   'Disk Usage',
          //   'Used: ${diskData['used']?.toStringAsFixed(1) ?? "0"} GB',
          //   'Available: ${diskData['available']?.toStringAsFixed(1) ?? "0"} GB',
          //   Icons.sd_storage,
          //   Colors.amber,
          //   diskData['total'] != null && diskData['total'] > 0
          //       ? (diskData['used'] ?? 0) / (diskData['total'] ?? 1)
          //       : 0,
          // ),
          
          const SizedBox(height: 16),
          
          // Network Card
          _buildMetricCard(
            'Network Stats',
            'Download: ${networkData['download']?.toStringAsFixed(1) ?? "0"} Mbps',
            'Upload: ${networkData['upload']?.toStringAsFixed(1) ?? "0"} Mbps',
            Icons.network_check,
            Colors.purple,
            0.7, // Fixed progress for network visualization
          ),
          
          const SizedBox(height: 20),
          
          // System Health Score
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.health_and_safety, size: 50, color: Colors.green),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'System Health Score',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _calculateHealthScore(cpuValue, memoryData), //diskData
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(_getHealthDescription(cpuValue, memoryData)) //v
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

  // Calculate a health score based on actual metrics
  String _calculateHealthScore(double cpuUsage, Map<String, dynamic> memoryData) { //Map<String, dynamic> diskData
    double memoryUsagePercent = memoryData['total'] != null && memoryData['total'] > 0
        ? (memoryData['used'] ?? 0) / (memoryData['total'] ?? 1) * 100
        : 50;
    
    // double diskUsagePercent = diskData['total'] != null && diskData['total'] > 0
    //     ? (diskData['used'] ?? 0) / (diskData['total'] ?? 1) * 100
    //     : 50;
    
    // Weight factors: CPU: 40%, Memory: 40%, Disk: 20%
    double healthScore = 100 - (0.4 * cpuUsage + 0.4 * memoryUsagePercent ); //+ 0.2 * diskUsagePercent
    return '${healthScore.round()}%';
  }

  // Get health description based on metrics
  String _getHealthDescription(double cpuUsage, Map<String, dynamic> memoryData) { //Map<String, dynamic> diskData
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

  // Build CPU metrics tab
  Widget _buildCpuTab() {
    final cpuData = _systemMetrics['cpu'] as Map<String, dynamic>? ?? {};
    final cpuUsage = cpuData['usage'] as double? ?? 0.0;
    final cpuCores = cpuData['cores'] as List<dynamic>? ?? [];
    // final cpuHistory = cpuData['history'] as Map<String, dynamic>? ?? {};
    
    // Sort cpu history by key (time)
    // final sortedHistory = cpuHistory.entries.toList()
    //   ..sort((a, b) => a.key.compareTo(b.key));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CPU Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // // CPU Usage Graph
          // Container(
          //   height: 200,
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: Colors.grey[100],
          //     borderRadius: BorderRadius.circular(8),
          //   ),
          //   child: sortedHistory.isEmpty
          //       ? const Center(child: Text('No CPU history data available'))
          //       : Row(
          //           crossAxisAlignment: CrossAxisAlignment.end,
          //           children: sortedHistory.map((entry) {
          //             return Expanded(
          //               child: Column(
          //                 mainAxisAlignment: MainAxisAlignment.end,
          //                 children: [
          //                   Container(
          //                     height: ((entry.value as double) / 100) * 150,
          //                     width: 10,
          //                     decoration: BoxDecoration(
          //                       color: _getColorForCpuUsage(entry.value as double),
          //                       borderRadius: BorderRadius.circular(4),
          //                     ),
          //                   ),
          //                   const SizedBox(height: 5),
          //                   Text(
          //                     entry.key.split(':')[0],
          //                     style: const TextStyle(fontSize: 10),
          //                     overflow: TextOverflow.ellipsis,
          //                   ),
          //                 ],
          //               ),
          //             );
          //           }).toList(),
          //         ),
          // ),
          
          // const SizedBox(height: 20),
          
          // CPU Core Information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CPU Core Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                
                // CPU cores from actual data
                if (cpuCores.isEmpty)
                  const Text('No CPU core data available')
                else
                  ...List.generate(cpuCores.length, (index) {
                    final coreUsage = cpuCores[index] as double? ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Text('Core ${index + 1}'),
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
                          Text('${coreUsage.toStringAsFixed(1)}%'),
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
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CPU Statistics',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow('CPU Model', _deviceInfo['cpuModel'] ?? 'Unknown'),
                _buildStatRow('CPU Cores', _deviceInfo['cpuCores'] ?? 'Unknown'),
                _buildStatRow('Current Usage', '${cpuUsage.toStringAsFixed(1)}%'),
                _buildStatRow('System', _deviceInfo['systemName'] ?? 'Unknown'),
                _buildStatRow('Temperature', 'Not available'), // Add if you have temperature data
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
          const Text(
            'Memory Usage',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
                color: Colors.grey[200],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: memoryUsedPercent,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      memoryUsedPercent < 0.7 ? Colors.green : 
                      memoryUsedPercent < 0.9 ? Colors.orange : Colors.red
                    ),
                    strokeWidth: 20,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(memoryUsedPercent * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Used: ${usedMemory.toStringAsFixed(1)} GB',
                        style: const TextStyle(fontSize: 14),
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
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Memory Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
          
          const SizedBox(height: 20),
          
          // Memory Consumers
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Memory Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 16),
                Text('Detailed per-process memory usage information is not available.'),
                Text('This would require additional system-level access.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build Network metrics tab
  Widget _buildNetworkTab() {
    // Use actual network data
    final download = _networkStats['download'] as double? ?? 0.0;
    final upload = _networkStats['upload'] as double? ?? 0.0;
    final latency = _networkStats['latency'] as double? ?? 0.0;
    final packetLoss = _networkStats['packetLoss'] as double? ?? 0.0;
    final networkType = _networkStats['type'] as String? ?? 'Unknown';
    final networkName = _networkStats['networkName'] as String? ?? 'Unknown Network';
    final signalStrength = _networkStats['signalStrength'] as String? ?? 'Unknown';
    
    // Data usage information
    final dataUsage = _networkStats['dataUsage'] as Map<String, dynamic>? ?? {};
    final downloaded = dataUsage['downloaded'] as double? ?? 0.0;
    final uploaded = dataUsage['uploaded'] as double? ?? 0.0;
    final sessions = dataUsage['sessions'] as int? ?? 0;
    final activeTime = dataUsage['activeTime'] as String? ?? '0h 0m';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Network Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Download/Upload Graph
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Network Activity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                        Colors.green,
                        '${download.toStringAsFixed(1)} Mbps',
                      ),
                      _buildNetworkSpeedIndicator(
                        'Upload',
                        Icons.arrow_upward,
                        Colors.blue,
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
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Network Statistics',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
          
          const SizedBox(height: 20),
          
          // Data Usage
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Usage (Today)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildDataUsageItem(
                        'Downloaded',
                        '${downloaded.toStringAsFixed(2)} GB',
                        Icons.download,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildDataUsageItem(
                        'Uploaded',
                        '${uploaded.toStringAsFixed(2)} GB',
                        Icons.upload,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildDataUsageItem(
                        'Sessions',
                        sessions.toString(),
                        Icons.compare_arrows,
                        Colors.purple,
                      ),
                    ),
                    Expanded(
                      child: _buildDataUsageItem(
                        'Active Time',
                        activeTime,
                        Icons.timer,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
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
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
              Text(value1),
              Text(value2),
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
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
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
  
  // Build data usage item for network tab
  Widget _buildDataUsageItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  // Get color for CPU usage based on value
  Color _getColorForCpuUsage(double value) {
    if (value < 50) {
      return Colors.green;
    } else if (value < 80) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  // Get color for progress indicators
  Color _getProgressColor(double progress) {
    if (progress < 0.6) {
      return Colors.green;
    } else if (progress < 0.8) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}