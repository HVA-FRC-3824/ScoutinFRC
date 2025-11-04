// ignore_for_file: unused_import, depend_on_referenced_packages, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class TeamComparisonScreen extends StatefulWidget {
  const TeamComparisonScreen({super.key});

  @override
  _TeamComparisonScreenState createState() => _TeamComparisonScreenState();
}

class _TeamComparisonScreenState extends State<TeamComparisonScreen> {
  final String _baseUrl = 'https://www.thebluealliance.com/api/v3';
  final String _authKey = 'XKgCGALe7EzYqZUeKKONsQ45iGHVUZYlN0F6qQzchKQrLxED5DFWrYi9pcjxIzGY'; 
  final TextEditingController _team1Controller = TextEditingController();
  final TextEditingController _team2Controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _team1Data;
  Map<String, dynamic>? _team2Data;
  List<dynamic>? _team1Events;
  List<dynamic>? _team2Events;
  List<dynamic>? _team1Media;
  List<dynamic>? _team2Media;
  
  String _currentEventKey = "2025alhu"; // Default event key
  bool _isLoading = false;
  
  // Firebase scouting data
  List<Map<Object?, Object?>> _team1ScoutingData = [];
  List<Map<Object?, Object?>> _team2ScoutingData = [];
  
  // Performance metrics
  Map<String, dynamic> _team1Metrics = {};
  Map<String, dynamic> _team2Metrics = {};

  @override
  void initState() {
    super.initState();
    _loadEventKey();
  }
  
  // Load saved event key from SharedPreferences
  Future<void> _loadEventKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEventKey = prefs.getString('eventKey');
      if (savedEventKey != null && savedEventKey.isNotEmpty) {
        setState(() {
          _currentEventKey = savedEventKey;
        });
      }
    } catch (e) {
      developer.log('Error loading event key: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(
                Icons.menu,
                color: Color.fromRGBO(165, 176, 168, 1),
                size: 50,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Color.fromRGBO(165, 176, 168, 1),
              size: 50,
            ),
          )
        ],
        backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/images/rohawktics.png',
              width: 75,
              height: 75,
            ),
            Text(
              'Event: $_currentEventKey',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input fields for team numbers
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _team1Controller,
                    style: const TextStyle(color: Colors.white), 
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Team 1 Number',
                      labelStyle: TextStyle(color: Colors.white), 
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white), 
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2), 
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _team2Controller,
                    style: const TextStyle(color: Colors.white), 
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Team 2 Number',
                      labelStyle: TextStyle(color: Colors.white), 
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white), 
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2), 
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            
            // Compare button
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _compareTeams,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, 
                  backgroundColor: Colors.blue.shade800, 
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: _isLoading 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text('Compare Teams'),
              ),
            ),

            const SizedBox(height: 20),
            
            // Results section
            Expanded(
              child: _team1Data == null || _team2Data == null
                ? Center(
                    child: Text(
                      'Enter team numbers and press "Compare Teams"\nUsing Event Key: $_currentEventKey',
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _buildComparisonView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonView() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          // Team info cards
          Row(
            children: [
              Expanded(child: _buildTeamInfoCard(_team1Data, _team1Media, '1')),
              const SizedBox(width: 8),
              Expanded(child: _buildTeamInfoCard(_team2Data, _team2Media, '2')),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Performance comparison
          _buildPerformanceComparison(),
          
          const SizedBox(height: 20),
          
          // Event history section
          _buildEventsComparison(),
          
          const SizedBox(height: 20),
          
          // Scouting data stats
          _buildScoutingDataComparison(),
        ],
      ),
    );
  }

  Widget _buildTeamInfoCard(Map<String, dynamic>? teamData, List<dynamic>? teamMedia, String teamNum) {
    if (teamData == null) {
      return const Card(
        color: Color.fromRGBO(75, 78, 83, 1),
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Center(child: Text('No data', style: TextStyle(color: Colors.white))),
        ),
      );
    }
    
    return Card(
      color: const Color.fromRGBO(75, 78, 83, 1),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team $teamNum: ${teamData['team_number']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${teamData['nickname']}',
              style: const TextStyle(fontSize: 16, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Rookie Year: ${teamData['rookie_year']}',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            
            if (teamMedia != null && teamMedia.isNotEmpty)
              Center(
                child: CachedNetworkImage(
                  imageUrl: _getTeamImageUrl(teamMedia),
                  height: 120,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.white54)
                  ),
                ),
              )
            else
              const Center(
                child: Icon(Icons.image_not_supported, size: 50, color: Colors.white54)
              ),
          ],
        ),
      ),
    );
  }

  String _getTeamImageUrl(List<dynamic> teamMedia) {
    // Try to find imgur image first
    var imgurMedia = teamMedia.firstWhere(
      (media) => media['type'] == 'imgur' || media['type'] == 'instagram-image',
      orElse: () => null
    );
    
    if (imgurMedia != null) {
      return '${imgurMedia['direct_url'] ?? ''}.png';
    }
    
    // Try other image types
    var otherMedia = teamMedia.firstWhere(
      (media) => media['type'] == 'avatar' || media['type'] == 'cdphotothread',
      orElse: () => null
    );
    
    if (otherMedia != null) {
      return otherMedia['direct_url'] ?? '';
    }
    
    return 'https://via.placeholder.com/150?text=No+Image';
  }

  Widget _buildPerformanceComparison() {
    if (_team1Metrics.isEmpty || _team2Metrics.isEmpty) {
      return const Card(
        color: Color.fromRGBO(75, 78, 83, 1),
        child: Padding(
          padding: EdgeInsets.all(15.0),
          child: Center(
            child: Text(
              'Performance data not available',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }
    
    return Card(
      color: const Color.fromRGBO(75, 78, 83, 1),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 15),
            
            // Average scores
            _buildPerformanceRow(
              'Average Score', 
              _team1Metrics['avgScore']?.toStringAsFixed(1) ?? 'N/A', 
              _team2Metrics['avgScore']?.toStringAsFixed(1) ?? 'N/A',
              Icons.score
            ),
            
            _buildPerformanceRow(
              'Auto Scoring', 
              _team1Metrics['avgAutoScore']?.toStringAsFixed(1) ?? 'N/A', 
              _team2Metrics['avgAutoScore']?.toStringAsFixed(1) ?? 'N/A',
              Icons.play_arrow
            ),
            
            _buildPerformanceRow(
              'Teleop Scoring', 
              _team1Metrics['avgTeleopScore']?.toStringAsFixed(1) ?? 'N/A', 
              _team2Metrics['avgTeleopScore']?.toStringAsFixed(1) ?? 'N/A',
              Icons.sports_esports
            ),
            
            _buildPerformanceRow(
              'Climb Success Rate', 
              '${(_team1Metrics['climbSuccessRate'] * 100).toStringAsFixed(0)}%', 
              '${(_team2Metrics['climbSuccessRate'] * 100).toStringAsFixed(0)}%',
              Icons.trending_up
            ),
            
            const SizedBox(height: 15),
            const Text(
              'Total Matches Scouted',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Team ${_team1Controller.text}: ${_team1ScoutingData.length}',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Team ${_team2Controller.text}: ${_team2ScoutingData.length}',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceRow(String metric, String team1Value, String team2Value, IconData icon) {
    Color team1Color = Colors.white;
    Color team2Color = Colors.white;
    
    // Determine which team has better performance for this metric
    if (team1Value != 'N/A' && team2Value != 'N/A') {
      double? value1 = double.tryParse(team1Value.replaceAll('%', ''));
      double? value2 = double.tryParse(team2Value.replaceAll('%', ''));
      
      if (value1 != null && value2 != null) {
        if (value1 > value2) {
          team1Color = Colors.green;
          team2Color = Colors.red.shade200;
        } else if (value2 > value1) {
          team2Color = Colors.green;
          team1Color = Colors.red.shade200;
        }
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              metric,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: Text(
              team1Value,
              style: TextStyle(
                color: team1Color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              team2Value,
              style: TextStyle(
                color: team2Color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsComparison() {
    return Card(
      color: const Color.fromRGBO(75, 78, 83, 1),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildEventsList(_team1Events, _team1Controller.text),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildEventsList(_team2Events, _team2Controller.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(List<dynamic>? events, String teamNumber) {
    if (events == null || events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'No event data',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    
    // Sort events by date
    events.sort((a, b) {
      DateTime dateA = DateTime.parse(a['start_date']);
      DateTime dateB = DateTime.parse(b['start_date']);
      return dateB.compareTo(dateA); // Most recent first
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team $teamNumber Events',
          style: const TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            color: Colors.white
          ),
        ),
        const SizedBox(height: 5),
        ...events.take(3).map((event) {
          final eventName = event['name'] ?? 'Unknown Event';
          final String shortName = eventName.length > 25 
              ? '${eventName.substring(0, 22)}...' 
              : eventName;
          
          return Card(
            color: const Color.fromRGBO(85, 88, 93, 1),
            margin: const EdgeInsets.only(bottom: 5),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shortName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),
                  Text(
                    '${event['city']}, ${event['state_prov'] ?? event['country']}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    'Date: ${event['start_date']} to ${event['end_date']}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        }),
        if (events.length > 3)
          Center(
            child: TextButton(
              onPressed: () {
                // Show full events dialog
                _showFullEventsDialog(events, teamNumber);
              },
              child: const Text(
                'Show more...',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
      ],
    );
  }

  void _showFullEventsDialog(List<dynamic> events, String teamNumber) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team $teamNumber - All Events',
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      color: const Color.fromRGBO(85, 88, 93, 1),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          event['name'] ?? 'Unknown Event',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${event['city']}, ${event['state_prov'] ?? event['country']}\n'
                          'Date: ${event['start_date']} to ${event['end_date']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoutingDataComparison() {
    return Card(
      color: const Color.fromRGBO(75, 78, 83, 1),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scouting Data Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 15),
            
            // Performance charts
            _buildPerformanceCharts(),
            
            const SizedBox(height: 15),
            
            // Stats tables
            if (_team1ScoutingData.isNotEmpty || _team2ScoutingData.isNotEmpty)
              _buildStatsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCharts() {
    return Column(
      children: [
        const Text(
          'Match Score Comparison',
          style: TextStyle(fontSize: 16, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 250,
          child: (_team1ScoutingData.isEmpty && _team2ScoutingData.isEmpty)
              ? const Center(
                  child: Text(
                    'No scouting data available',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : _buildScoreLineChart(),
        ),
      ],
    );
  }

  Widget _buildScoreLineChart() {
    // Convert scouting data to chart data points
    final List<FlSpot> team1Spots = [];
    final List<FlSpot> team2Spots = [];
    
    double maxY = 0;
    double maxX = 0;
    
    // Process team 1 data
    if (_team1ScoutingData.isNotEmpty) {
      for (int i = 0; i < _team1ScoutingData.length; i++) {
        final match = _team1ScoutingData[i];
        final matchNumber = match['match_number'] as int? ?? i + 1;
        final score = _calculateTotalScore(match);
        
        team1Spots.add(FlSpot(matchNumber.toDouble(), score.toDouble()));
        
        if (matchNumber > maxX) maxX = matchNumber.toDouble();
        if (score > maxY) maxY = score.toDouble();
      }
    }
    
    // Process team 2 data
    if (_team2ScoutingData.isNotEmpty) {
      for (int i = 0; i < _team2ScoutingData.length; i++) {
        final match = _team2ScoutingData[i];
        final matchNumber = match['match_number'] as int? ?? i + 1;
        final score = _calculateTotalScore(match);
        
        team2Spots.add(FlSpot(matchNumber.toDouble(), score.toDouble()));
        
        if (matchNumber > maxX) maxX = matchNumber.toDouble();
        if (score > maxY) maxY = score.toDouble();
      }
    }
    
    // Ensure we have at least some range for the chart
    if (maxY < 10) maxY = 10;
    if (maxX < 5) maxX = 5;
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Colors.white10,
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => const FlLine(
            color: Colors.white10,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(color: Colors.white70, fontSize: 9),
              ),
              reservedSize: 28,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(color: Colors.white70, fontSize: 9),
              ),
              reservedSize: 18,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white24),
        ),
        minX: 0,
        maxX: maxX + 1,
        minY: 0,
        maxY: maxY * 1.1, // Add 10% padding at the top
        lineBarsData: [
          // Team 1 data
          if (team1Spots.isNotEmpty)
            LineChartBarData(
              spots: team1Spots,
              isCurved: false,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          
          // Team 2 data
          if (team2Spots.isNotEmpty)
            LineChartBarData(
              spots: team2Spots,
              isCurved: false,
              color: Colors.red,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final teamText = spot.barIndex == 0 
                    ? 'Team ${_team1Controller.text}'
                    : 'Team ${_team2Controller.text}';
                
                return LineTooltipItem(
                  '$teamText\nMatch: ${spot.x.toInt()}\nScore: ${spot.y.toInt()}',
                  const TextStyle(color: Colors.white, fontSize: 10),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Stats',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Table(
          border: TableBorder.all(color: Colors.white24),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
          },
          children: [
            // Table header
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade800),
              children: [
                const TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Metric',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Team ${_team1Controller.text}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Team ${_team2Controller.text}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            
            // Data rows
            _buildStatRow('Total Matches', 
                _team1Metrics['avgTeleopCoral']?.toStringAsFixed(1) ?? 'N/A', 
                _team2Metrics['avgTeleopCoral']?.toStringAsFixed(1) ?? 'N/A'),
            
            _buildStatRow('Algae Accuracy', 
                '${(_team1Metrics['algaeAccuracy'] * 100).toStringAsFixed(0)}%', 
                '${(_team2Metrics['algaeAccuracy'] * 100).toStringAsFixed(0)}%'),
            
            _buildStatRow('Deep Climb Rate', 
                '${(_team1Metrics['deepClimbRate'] * 100).toStringAsFixed(0)}%', 
                '${(_team2Metrics['deepClimbRate'] * 100).toStringAsFixed(0)}%'),
                
            _buildStatRow('Floor/Station Cycles', 
                _team1Metrics['avgFloorStationCycles']?.toStringAsFixed(1) ?? 'N/A', 
                _team2Metrics['avgFloorStationCycles']?.toStringAsFixed(1) ?? 'N/A'),
          ],
        ),
      ],
    );
  }

  TableRow _buildStatRow(String metric, String team1Value, String team2Value) {
    Color team1Color = Colors.white;
    Color team2Color = Colors.white;
    
    // Determine which team has better performance for this metric
    if (team1Value != 'N/A' && team2Value != 'N/A' && 
        metric != 'Total Matches') { // Don't highlight match count
      
      double? value1 = double.tryParse(team1Value.replaceAll('%', ''));
      double? value2 = double.tryParse(team2Value.replaceAll('%', ''));
      
      if (value1 != null && value2 != null) {
        if (value1 > value2) {
          team1Color = Colors.green;
          team2Color = Colors.red.shade200;
        } else if (value2 > value1) {
          team2Color = Colors.green;
          team1Color = Colors.red.shade200;
        }
      }
    }
    
    return TableRow(
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              metric,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              team1Value,
              style: TextStyle(color: team1Color),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              team2Value,
              style: TextStyle(color: team2Color),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  void _compareTeams() async {
    final team1Num = _team1Controller.text.trim();
    final team2Num = _team2Controller.text.trim();

    if (team1Num.isEmpty || team2Num.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both team numbers')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _team1Data = null;
      _team2Data = null;
      _team1Events = null;
      _team2Events = null;
      _team1Media = null;
      _team2Media = null;
      _team1ScoutingData = [];
      _team2ScoutingData = [];
      _team1Metrics = {};
      _team2Metrics = {};
    });

    try {
      // The Blue Alliance data
      final team1Key = 'frc$team1Num';
      final team2Key = 'frc$team2Num';
      
      await Future.wait([
        // Fetch TBA data
        _fetchTBAData(team1Key, team2Key),
        
        // Fetch scouting data from Firebase
        _fetchScoutingData(team1Num, team2Num),
      ]);
      
      // Calculate metrics
      _calculateTeamMetrics();
      
      // Reset loading state
      setState(() {
        _isLoading = false;
      });
      
      // Scroll to top of the comparison view
      if (_scrollController.hasClients) {
  _scrollController.animateTo(
    0,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );
}
    } catch (e) {
      developer.log('Error in comparison: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error comparing teams: $e')),
      );
    }
  }
  
  Future<void> _fetchTBAData(String team1Key, String team2Key) async {
    try {
      // Fetch basic team data
      final team1Future = _getTeamData(team1Key);
      final team2Future = _getTeamData(team2Key);
      
      // Fetch events for teams (2025 season)
      final team1EventsFuture = _getTeamEvents(team1Key, 2025);
      final team2EventsFuture = _getTeamEvents(team2Key, 2025);
      
      // Fetch media for teams
      final team1MediaFuture = _getTeamMedia(team1Key, 2025);
      final team2MediaFuture = _getTeamMedia(team2Key, 2025);
      
      // Wait for all requests to complete
      final results = await Future.wait([
        team1Future, team2Future,
        team1EventsFuture, team2EventsFuture,
        team1MediaFuture, team2MediaFuture,
      ]);
      
      // Update state with results
      setState(() {
        _team1Data = results[0] as Map<String, dynamic>?;
        _team2Data = results[1] as Map<String, dynamic>?;
        _team1Events = results[2] as List?;
        _team2Events = results[3] as List?;
        _team1Media = results[4] as List?;
        _team2Media = results[5] as List?;
      });
    } catch (e) {
      developer.log('Error fetching TBA data: $e');
      rethrow;
    }
  }
  
  Future<void> _fetchScoutingData(String team1Num, String team2Num) async {
    try {
      final dbRef = FirebaseDatabase.instance.ref('$_currentEventKey/matches');
      final snapshot = await dbRef.get();
      
      if (snapshot.exists) {
        final List<Map<Object?, Object?>> team1Matches = [];
        final List<Map<Object?, Object?>> team2Matches = [];
        
        // Handle the snapshot value which could be a Map or a List
        if (snapshot.value is Map<Object?, Object?>) {
          final allMatches = snapshot.value as Map<Object?, Object?>;
          
          allMatches.forEach((matchId, matchData) {
            _processMatchDataForTeam(matchId, matchData, team1Num, team2Num, team1Matches, team2Matches);
          });
        } else if (snapshot.value is List<Object?>) {
          final allMatches = snapshot.value as List<Object?>;
          
          for (int i = 0; i < allMatches.length; i++) {
            if (allMatches[i] != null) {
              _processMatchDataForTeam(i.toString(), allMatches[i], team1Num, team2Num, team1Matches, team2Matches);
            }
          }
        }
        
        setState(() {
          _team1ScoutingData = team1Matches;
          _team2ScoutingData = team2Matches;
        });
      }
    } catch (e) {
      developer.log('Error fetching scouting data: $e');
      // Don't rethrow here to allow TBA data to still be shown
    }
  }
  
  void _processMatchDataForTeam(
      Object? matchId, 
      Object? matchData, 
      String team1Num, 
      String team2Num,
      List<Map<Object?, Object?>> team1Matches,
      List<Map<Object?, Object?>> team2Matches) {
    
    if (matchData == null) return;
    
    // Process as Map
    if (matchData is Map<Object?, Object?>) {
      // Check direct match data
      _checkTeamMatch(matchData, matchId, team1Num, team2Num, team1Matches, team2Matches);
      
      // Check nested team data
      matchData.forEach((key, value) {
        if (value is Map<Object?, Object?>) {
          _checkTeamMatch(value, matchId, team1Num, team2Num, team1Matches, team2Matches);
        }
      });
    }
    // Process as List
    else if (matchData is List<Object?>) {
      for (var item in matchData) {
        if (item is Map<Object?, Object?>) {
          _checkTeamMatch(item, matchId, team1Num, team2Num, team1Matches, team2Matches);
        }
      }
    }
  }
  
  void _checkTeamMatch(
      Map<Object?, Object?> data, 
      Object? matchId, 
      String team1Num, 
      String team2Num,
      List<Map<Object?, Object?>> team1Matches,
      List<Map<Object?, Object?>> team2Matches) {
    
    final teamNum = data['robotNum']?.toString() ?? '';
    
    // Calculate match number
    int matchNum = 0;
    if (data['matchNum'] != null) {
      matchNum = int.tryParse(data['matchNum'].toString()) ?? 0;
    } else if (matchId is String) {
      matchNum = int.tryParse(matchId) ?? 0;
    }
    
    // Create match data object
    final matchData = {
      'match_id': matchId,
      'match_number': matchNum,
      'auto': data['auto'],
      'teleop': data['teleop'],
      'endgame': data['endgame'],
    };
    
    // Add to appropriate team's matches
    if (teamNum == team1Num) {
      team1Matches.add(matchData);
    } else if (teamNum == team2Num) {
      team2Matches.add(matchData);
    }
  }
  
  void _calculateTeamMetrics() {
    _team1Metrics = _calculateMetricsForTeam(_team1ScoutingData);
    _team2Metrics = _calculateMetricsForTeam(_team2ScoutingData);
  }
  
  Map<String, dynamic> _calculateMetricsForTeam(List<Map<Object?, Object?>> matches) {
    if (matches.isEmpty) {
      return {
        'avgScore': 0.0,
        'avgAutoScore': 0.0,
        'avgTeleopScore': 0.0,
        'climbSuccessRate': 0.0,
        'deepClimbRate': 0.0,
        'algaeAccuracy': 0.0,
        'avgAutoCoral': 0.0,
        'avgTeleopCoral': 0.0,
        'avgFloorStationCycles': 0.0,
      };
    }
    
    // Calculate metrics
    double totalScore = 0;
    double totalAutoScore = 0;
    double totalTeleopScore = 0;
    int climbAttempts = 0;
    int successfulClimbs = 0;
    int deepClimbs = 0;
    
    double totalAlgaeAccuracy = 0;
    double totalAutoCoral = 0;
    double totalTeleopCoral = 0;
    double totalFloorStationCycles = 0;
    
    for (var match in matches) {
      // Calculate total score
      final score = _calculateTotalScore(match);
      totalScore += score;
      
      // Auto and teleop scores
      totalAutoScore += _calculateAutoScore(match);
      totalTeleopScore += _calculateTeleopScore(match);
      
      // Climb success rate
      final endgame = match['endgame'] as Map<Object?, Object?>?;
      if (endgame != null) {
        final climbStatus = endgame['cageParkStatus']?.toString().toLowerCase() ?? '';
        final failed = endgame['failed'] == true || 
                      endgame['failed']?.toString().toLowerCase() == 'true';
        
        if (climbStatus.isNotEmpty && climbStatus != 'none') {
          climbAttempts++;
          
          if (!failed) {
            successfulClimbs++;
            
            if (climbStatus.contains('deep')) {
              deepClimbs++;
            }
          }
        }
      }
      
      // Algae accuracy 
      totalAlgaeAccuracy += _calculateAlgaeAccuracy(match);
      
      // Coral scores
      totalAutoCoral += _calculateAutoCoralScore(match);
      totalTeleopCoral += _calculateTeleopCoralScore(match);
      
      // Floor/Station cycles
      totalFloorStationCycles += _calculateFloorStationCycles(match);
    }
    
    final count = matches.length.toDouble();
    final climbRate = climbAttempts > 0 ? successfulClimbs / climbAttempts : 0.0;
    final deepRate = climbAttempts > 0 ? deepClimbs / climbAttempts : 0.0;
    
    return {
      'avgScore': totalScore / count,
      'avgAutoScore': totalAutoScore / count,
      'avgTeleopScore': totalTeleopScore / count,
      'climbSuccessRate': climbRate,
      'deepClimbRate': deepRate,
      'algaeAccuracy': totalAlgaeAccuracy / count,
      'avgAutoCoral': totalAutoCoral / count,
      'avgTeleopCoral': totalTeleopCoral / count,
      'avgFloorStationCycles': totalFloorStationCycles / count,
    };
  }
  
  double _calculateAlgaeAccuracy(Map<Object?, Object?> match) {
    try {
      final auto = match['auto'] as Map<Object?, Object?>?;
      final teleop = match['teleop'] as Map<Object?, Object?>?;
      
      if (auto == null || teleop == null) return 0.0;
      
      int totalScore = 0;
      int totalMisses = 0;
      
      // Auto algae
      if (auto['algae'] is Map) {
        final algae = auto['algae'] as Map<Object?, Object?>;
        totalScore += int.tryParse(algae['score']?.toString() ?? '0') ?? 0;
        totalMisses += int.tryParse(algae['miss']?.toString() ?? '0') ?? 0;
      }
      
      // Teleop algae
      if (teleop['algae'] is Map) {
        final algae = teleop['algae'] as Map<Object?, Object?>;
        totalScore += int.tryParse(algae['score']?.toString() ?? '0') ?? 0;
        totalMisses += int.tryParse(algae['miss']?.toString() ?? '0') ?? 0;
      }
      
      final total = totalScore + totalMisses;
      return total > 0 ? totalScore / total : 0.0;
    } catch (e) {
      return 0.0;
    }
  }
  
  int _calculateAutoCoralScore(Map<Object?, Object?> match) {
    try {
      final auto = match['auto'] as Map<Object?, Object?>?;
      if (auto == null) return 0;
      
      int score = 0;
      
      if (auto['coral'] is Map) {
        final coral = auto['coral'] as Map<Object?, Object?>;
        final levels = {'L1': 4, 'L2': 5, 'L3': 6, 'L4': 7};
        
        for (var level in levels.keys) {
          if (coral[level] is Map) {
            final levelData = coral[level] as Map<Object?, Object?>;
            final levelScore = int.tryParse(levelData['score']?.toString() ?? '0') ?? 0;
            score += levelScore * (levels[level] ?? 0);
          }
        }
      }
      
      return score;
    } catch (e) {
      return 0;
    }
  }
  
  int _calculateTeleopCoralScore(Map<Object?, Object?> match) {
    try {
      final teleop = match['teleop'] as Map<Object?, Object?>?;
      if (teleop == null) return 0;
      
      int score = 0;
      
      if (teleop['coral'] is Map) {
        final coral = teleop['coral'] as Map<Object?, Object?>;
        final levels = {'L1': 2, 'L2': 3, 'L3': 4, 'L4': 5};
        
        for (var level in levels.keys) {
          if (coral[level] is Map) {
            final levelData = coral[level] as Map<Object?, Object?>;
            final levelScore = int.tryParse(levelData['score']?.toString() ?? '0') ?? 0;
            score += levelScore * (levels[level] ?? 0);
          }
        }
      }
      
      return score;
    } catch (e) {
      return 0;
    }
  }
  
  int _calculateFloorStationCycles(Map<Object?, Object?> match) {
    try {
      final auto = match['auto'] as Map<Object?, Object?>?;
      final teleop = match['teleop'] as Map<Object?, Object?>?;
      
      if (auto == null || teleop == null) return 0;
      
      int total = 0;
      
      // Auto floor/station
      if (auto['floorStation'] is Map) {
        final fs = auto['floorStation'] as Map<Object?, Object?>;
        total += int.tryParse(fs['floor']?.toString() ?? '0') ?? 0;
        total += int.tryParse(fs['station']?.toString() ?? '0') ?? 0;
      }
      
      // Teleop floor/station
      if (teleop['floorStation'] is Map) {
        final fs = teleop['floorStation'] as Map<Object?, Object?>;
        total += int.tryParse(fs['floor']?.toString() ?? '0') ?? 0;
        total += int.tryParse(fs['station']?.toString() ?? '0') ?? 0;
      }
      
      return total;
    } catch (e) {
      return 0;
    }
  }
  
  int _calculateAutoScore(Map<Object?, Object?> match) {
    try {
      final auto = match['auto'] as Map<Object?, Object?>?;
      if (auto == null) return 0;
      
      int autoCoral = _calculateAutoCoralScore(match);
      
      int algae = 0;
      if (auto['algae'] is Map) {
        final algaeData = auto['algae'] as Map<Object?, Object?>;
        final isProcessor = algaeData['isProcessor']?.toString().toLowerCase() == 'true';
        final score = int.tryParse(algaeData['score']?.toString() ?? '0') ?? 0;
        algae += score * (isProcessor ? 6 : 4);
      }
      
      int floorStation = 0;
      if (auto['floorStation'] is Map) {
        final fsData = auto['floorStation'] as Map<Object?, Object?>;
        final floor = int.tryParse(fsData['floor']?.toString() ?? '0') ?? 0;
        final station = int.tryParse(fsData['station']?.toString() ?? '0') ?? 0;
        floorStation += floor * 2;
        floorStation += station * 3;
      }
      
      return autoCoral + algae + floorStation;
    } catch (e) {
      return 0;
    }
  }
  
  int _calculateTeleopScore(Map<Object?, Object?> match) {
    try {
      final teleop = match['teleop'] as Map<Object?, Object?>?;
      final endgame = match['endgame'] as Map<Object?, Object?>?;
      
      if (teleop == null || endgame == null) return 0;
      
      int teleopCoral = _calculateTeleopCoralScore(match);
      
      int algae = 0;
      if (teleop['algae'] is Map) {
        final algaeData = teleop['algae'] as Map<Object?, Object?>;
        final isProcessor = algaeData['isProcessor']?.toString().toLowerCase() == 'true';
        final score = int.tryParse(algaeData['score']?.toString() ?? '0') ?? 0;
        algae += score * (isProcessor ? 6 : 4);
      }
      
      int floorStation = 0;
      if (teleop['floorStation'] is Map) {
        final fsData = teleop['floorStation'] as Map<Object?, Object?>;
        final floor = int.tryParse(fsData['floor']?.toString() ?? '0') ?? 0;
        final station = int.tryParse(fsData['station']?.toString() ?? '0') ?? 0;
        floorStation += floor;
        floorStation += station * 2;
      }
      
      int climbPoints = 0;
      final climbStatus = endgame['cageParkStatus']?.toString().toLowerCase() ?? '';
      final failed = endgame['failed'] == true || 
                    endgame['failed']?.toString().toLowerCase() == 'true';
      
      if (!failed) {
        if (climbStatus.contains('park')) {
          climbPoints = 2;
        } else if (climbStatus.contains('shallow')) {
          climbPoints = 6;
        } else if (climbStatus.contains('deep')) {
          climbPoints = 12;
        }
      }
      
      return teleopCoral + algae + floorStation + climbPoints;
    } catch (e) {
      return 0;
    }
  }

  int _calculateTotalScore(Map<Object?, Object?> match) {
    return _calculateAutoScore(match) + _calculateTeleopScore(match);
  }

  Future<Map<String, dynamic>> _getTeamData(String teamKey) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/team/$teamKey'),
      headers: {'X-TBA-Auth-Key': _authKey},
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      } else {
        throw Exception('Unexpected response type for team data');
      }
    } else {
      throw Exception('Failed to load team data for $teamKey: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> _getTeamEvents(String teamKey, int year) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/team/$teamKey/events/$year'),
      headers: {'X-TBA-Auth-Key': _authKey},
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      
      if (data is List) {
        return data;
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load events for team $teamKey: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> _getTeamMedia(String teamKey, int year) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/team/$teamKey/media/$year'),
      headers: {'X-TBA-Auth-Key': _authKey},
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      if (data is List) {
        return data;
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load media for team $teamKey: ${response.statusCode}');
    }
  }
}