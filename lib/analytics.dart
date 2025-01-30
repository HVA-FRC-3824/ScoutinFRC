// ignore_for_file: use_build_context_synchronously, unused_local_variable
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';

Color _getClimbColor(int index) {
  switch (index) {
    case 0: return Colors.blue; 
    case 1: return Colors.green; 
    case 2: return Colors.purple; 
    case 3: return Colors.red; 
    default: return Colors.grey; 
  }
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key, required String title});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _teamController = TextEditingController();
  late DatabaseReference _dbRef;
  List<Map<Object?, Object?>> _matches = [];
  List<FlSpot> _chartSpots = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _showAverages = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      developer.log('Initializing Firebase...');
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _dbRef = FirebaseDatabase.instance.ref('RCR2025/matches');
      setState(() {
        _isInitialized = true;
      });
      developer.log('Firebase initialized successfully');
    } catch (e) {
      developer.log('Firebase initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase Init Error: $e')),
        );
      }
    }
  }

  Future<void> _fetchTeamData() async {
    final teamNumber = _teamController.text.trim();
    developer.log('Fetching data for team: $teamNumber');
    
    if (!_isInitialized) {
      developer.log('Firebase not initialized');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firebase not initialized')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _showAverages = false;
    });
    
    try {
      final snapshot = await _dbRef.get();
      developer.log('Snapshot received. Exists: ${snapshot.exists}');
      
      if (snapshot.exists) {
        final allMatches = snapshot.value as Map<Object?, Object?>;
        developer.log('Total matches found: ${allMatches.length}');
        
        final teamMatches = <Map<Object?, Object?>>[];

        allMatches.forEach((matchId, matchData) {
          if (matchData is Map<Object?, Object?>) {
            matchData.forEach((key, value) {
              if (value is Map<Object?, Object?>) {
                final teamData = value;
                
                if (teamData['robotNum']?.toString() == teamNumber) {
                  developer.log('Found data for team $teamNumber in match $matchId');

                  var matchNum = 0;
                  if (teamData['matchNum'] != null) {
                    matchNum = int.tryParse(teamData['matchNum'].toString()) ?? 0;
                  }

                  teamMatches.add({
                    'match_id': matchId,
                    'match_number': matchNum,
                    'auto': teamData['auto'],
                    'teleop': teamData['teleop'],
                    'endgame': teamData['endgame'],
                  });
                }
              }
            });
          }
        });

        developer.log('Found ${teamMatches.length} matches for team $teamNumber');
        
        if (teamMatches.isNotEmpty) {
          teamMatches.sort((a, b) {
            final aNum = (a['match_number'] ?? 0) as int;
            final bNum = (b['match_number'] ?? 0) as int;
            return aNum.compareTo(bNum);
          });
          
          final chartSpots = teamMatches.map((match) {
            final score = _calculateTotalScore(match);
            return FlSpot(
              (match['match_number'] as int).toDouble(),
              score.toDouble(),
            );
          }).toList();

          setState(() {
            _matches = teamMatches;
            _chartSpots = chartSpots;
            _isLoading = false;
            _showAverages = true;
          });
        } else {
          setState(() {
            _matches = [];
            _chartSpots = [];
            _isLoading = false;
            _showAverages = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No data found for team $teamNumber')),
          );
        }
      } else {
        setState(() {
          _matches = [];
          _chartSpots = [];
          _isLoading = false;
          _showAverages = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data available in database')),
        );
      }
    } catch (e, stackTrace) {
      developer.log('Error fetching data', error: e, stackTrace: stackTrace);
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  int _calculateTotalScore(Map<Object?, Object?> match) {
  try {
    final auto = match['auto'] as Map<Object?, Object?>?;
    final teleop = match['teleop'] as Map<Object?, Object?>?;
    final endgame = match['endgame'] as Map<Object?, Object?>?;

    if (auto == null || teleop == null || endgame == null) {
      return 0;
    }

    int autoCoral = 0;
    if (auto['coral'] is Map) {
      final coralData = auto['coral'] as Map<Object?, Object?>;
      final autoCoralPoints = {
        'L4': 7,  
        'L3': 6,  
        'L2': 5,
        'L1': 4
      };
      for (var level in ['L1', 'L2', 'L3', 'L4']) {
        if (coralData[level] is Map) {
          final levelData = coralData[level] as Map<Object?, Object?>;
          final score = int.tryParse(levelData['score']?.toString() ?? '0') ?? 0;
          autoCoral += score * (autoCoralPoints[level] ?? 0);
        }
      }
    }

    int teleopCoral = 0;
    if (teleop['coral'] is Map) {
      final coralData = teleop['coral'] as Map<Object?, Object?>;
      final teleopCoralPoints = {
        'L4': 5,  
        'L3': 4,  
        'L2': 3,
        'L1': 2
      };
      for (var level in ['L1', 'L2', 'L3', 'L4']) {
        if (coralData[level] is Map) {
          final levelData = coralData[level] as Map<Object?, Object?>;
          final score = int.tryParse(levelData['score']?.toString() ?? '0') ?? 0;
          teleopCoral += score * (teleopCoralPoints[level] ?? 0);
        }
      }
    }

    int algae = 0;
    if (auto['algae'] is Map) {
      final algaeData = auto['algae'] as Map<Object?, Object?>;
      final isProcessor = algaeData['isProcessor']?.toString().toLowerCase() == 'true';
      final score = int.tryParse(algaeData['score']?.toString() ?? '0') ?? 0;
      algae += score * (isProcessor ? 6 : 4); 
    }
    if (teleop['algae'] is Map) {
      final algaeData = teleop['algae'] as Map<Object?, Object?>;
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
    if (teleop['floorStation'] is Map) {
      final fsData = teleop['floorStation'] as Map<Object?, Object?>;
      final floor = int.tryParse(fsData['floor']?.toString() ?? '0') ?? 0;
      final station = int.tryParse(fsData['station']?.toString() ?? '0') ?? 0;
      floorStation += floor;
      floorStation += station * 2;
    }

    int climbPoints = 0;
    final climbStatus = endgame['cageParkStatus']?.toString().toLowerCase() ?? '';
    if (climbStatus.contains('park')) {
      climbPoints = 2;
    } else if (climbStatus.contains('shallow')) {
      climbPoints = 6;
    } else if (climbStatus.contains('deep')) {
      climbPoints = 12;
    }

    return autoCoral + teleopCoral + algae + floorStation + climbPoints;
  } catch (e, stackTrace) {
    developer.log('Error calculating score', error: e, stackTrace: stackTrace);
    return 0;
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
      appBar: AppBar(
        title: const Text('Team Analytics',
        style: TextStyle(color: Colors.white),),
        backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _teamController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Team Number',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchTeamData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Load Data', style: TextStyle(color: Colors.white)),
              ),
              if (_chartSpots.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.black45,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Match Scores',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                getDrawingHorizontalLine: (value) => const FlLine(
                                  color: Colors.white24,
                                  strokeWidth: 1,
                                ),
                                getDrawingVerticalLine: (value) => const FlLine(
                                  color: Colors.white24,
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) => Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) => Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(color: Colors.white70),
                                    ),
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
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _chartSpots,
                                  isCurved: false,
                                  color: Colors.blue,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_showAverages) ...[
                const SizedBox(height: 16),
                _StatsCharts(matches: _matches),
              ],
              if (_matches.isEmpty && !_isLoading)
                const Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsCharts extends StatelessWidget {
  final List<Map<Object?, Object?>> matches;

  const _StatsCharts({required this.matches});

  Map<String, dynamic> calculateAverages() {
  if (matches.isEmpty) return {};
  
  Map<String, double> autoCoralSums = {'L1': 0, 'L2': 0, 'L3': 0, 'L4': 0};
  Map<String, double> teleopCoralSums = {'L1': 0, 'L2': 0, 'L3': 0, 'L4': 0};
  Map<String, double> autoCoralMisses = {'L1': 0, 'L2': 0, 'L3': 0, 'L4': 0};
  Map<String, double> teleopCoralMisses = {'L1': 0, 'L2': 0, 'L3': 0, 'L4': 0};
  double autoAlgaeScoreSum = 0;
  double autoAlgaeMissSum = 0;
  double teleopAlgaeScoreSum = 0;
  double teleopAlgaeMissSum = 0;
  Map<String, int> climbCounts = {
    'park': 0,
    'shallow': 0,
    'deep': 0,
    'failed': 0,
    'none': 0
  };

  for (var match in matches) {
    final auto = match['auto'] as Map<Object?, Object?>?;
    final teleop = match['teleop'] as Map<Object?, Object?>?;
    final endgame = match['endgame'] as Map<Object?, Object?>?;

    if (auto != null) {
      if (auto['coral'] is Map) {
        final coral = auto['coral'] as Map<Object?, Object?>;
        for (var level in ['L1', 'L2', 'L3', 'L4']) {
          if (coral[level] is Map) {
            final levelData = coral[level] as Map<Object?, Object?>;
            autoCoralSums[level] = autoCoralSums[level]! +
                (double.tryParse(levelData['score']?.toString() ?? '0') ?? 0);
            autoCoralMisses[level] = autoCoralMisses[level]! +
                (double.tryParse(levelData['miss']?.toString() ?? '0') ?? 0);
          }
        }
      }
      if (auto['algae'] is Map) {
        final algae = auto['algae'] as Map<Object?, Object?>;
        autoAlgaeScoreSum += double.tryParse(algae['score']?.toString() ?? '0') ?? 0;
        autoAlgaeMissSum += double.tryParse(algae['miss']?.toString() ?? '0') ?? 0;
      }
    }

    if (teleop != null) {
      if (teleop['coral'] is Map) {
        final coral = teleop['coral'] as Map<Object?, Object?>;
        for (var level in ['L1', 'L2', 'L3', 'L4']) {
          if (coral[level] is Map) {
            final levelData = coral[level] as Map<Object?, Object?>;
            teleopCoralSums[level] = teleopCoralSums[level]! +
                (double.tryParse(levelData['score']?.toString() ?? '0') ?? 0);
            teleopCoralMisses[level] = teleopCoralMisses[level]! +
                (double.tryParse(levelData['miss']?.toString() ?? '0') ?? 0);
          }
        }
      }
      if (teleop['algae'] is Map) {
        final algae = teleop['algae'] as Map<Object?, Object?>;
        teleopAlgaeScoreSum += double.tryParse(algae['score']?.toString() ?? '0') ?? 0;
        teleopAlgaeMissSum += double.tryParse(algae['miss']?.toString() ?? '0') ?? 0;
      }
    }

    if (endgame != null) {
      final climbStatus = endgame['cageParkStatus']?.toString().toLowerCase() ?? 'none';
      if (endgame['failed'] == true) {
        climbCounts['failed'] = climbCounts['failed']! + 1;
      } else if (climbStatus.contains('deep')) {
        climbCounts['deep'] = (climbCounts['deep'] ?? 0) + 1;
      } else if (climbStatus.contains('shallow')) {
        climbCounts['shallow'] = (climbCounts['shallow'] ?? 0) + 1;
      } else if (climbStatus.contains('park')) {
        climbCounts['park'] = (climbCounts['park'] ?? 0) + 1;
      } else {
        climbCounts['none'] = (climbCounts['none'] ?? 0) + 1;
      }
    }
  }

  final count = matches.length.toDouble();
  
  return {
    'autoCoralAvg': Map.fromEntries(
      autoCoralSums.entries.map((e) => MapEntry(e.key, e.value / count))
    ),
    'teleopCoralAvg': Map.fromEntries(
      teleopCoralSums.entries.map((e) => MapEntry(e.key, e.value / count))
    ),
    'autoCoralMissAvg': Map.fromEntries(
      autoCoralMisses.entries.map((e) => MapEntry(e.key, e.value / count))
    ),
    'teleopCoralMissAvg': Map.fromEntries(
      teleopCoralMisses.entries.map((e) => MapEntry(e.key, e.value / count))
    ),
    'autoAlgae': {
      'scoreAvg': autoAlgaeScoreSum / count,
      'missAvg': autoAlgaeMissSum / count,
    },
    'teleopAlgae': {
      'scoreAvg': teleopAlgaeScoreSum / count,
      'missAvg': teleopAlgaeMissSum / count,
    },
    'climbPercentages': Map.fromEntries(
      climbCounts.entries.map((e) => MapEntry(e.key, (e.value / count) * 100))
    ),
  };
}

  @override
  Widget build(BuildContext context) {
    final averages = calculateAverages();
    if (averages.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _buildCoralChart(
  averages['autoCoralAvg'] as Map<String, double>,
  averages['teleopCoralAvg'] as Map<String, double>,
  averages['autoCoralMissAvg'] as Map<String, double>,
  averages['teleopCoralMissAvg'] as Map<String, double>,
),
        const SizedBox(height: 16),
        _buildAlgaeChart(
          averages['autoAlgae'] as Map<String, double>,
          averages['teleopAlgae'] as Map<String, double>,
        ),
        const SizedBox(height: 16),
        _buildClimbChart(averages['climbPercentages'] as Map<String, double>),
      ],
    );
  }

  Widget _buildCoralChart(
    Map<String, double> autoAvg, 
    Map<String, double> teleopAvg,
    Map<String, double> autoMissAvg,
    Map<String, double> teleopMissAvg) {
  return Card(
    color: Colors.black45,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Average Coral Scores by Level',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                groupsSpace: 20,
                barGroups: [
                  for (var level in ['L1', 'L2', 'L3', 'L4'])
                    BarChartGroupData(
                      x: autoAvg.keys.toList().indexOf(level),
                      barRods: [
                        BarChartRodData(
                          toY: autoAvg[level] ?? 0,
                          color: Colors.blue,
                          width: 12,
                        ),
                        BarChartRodData(
                          toY: teleopAvg[level] ?? 0,
                          color: Colors.green,
                          width: 12,
                        ),
                        BarChartRodData(
                          toY: (autoMissAvg[level] ?? 0) + (teleopMissAvg[level] ?? 0),
                          color: Colors.red,
                          width: 12,
                        ),
                      ],
                    ),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        ['L1', 'L2', 'L3', 'L4'][value.toInt()],
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  const Text('Auto', style: TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  const Text('Teleop', style: TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 4),
                  const Text('Missed', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildAlgaeChart(Map<String, double> autoStats, Map<String, double> teleopStats) {
  return Card(
    color: Colors.black45,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Average Algae Performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(autoStats, teleopStats),
                groupsSpace: 12,
                barGroups: [
                  // Auto Scored
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: autoStats['scoreAvg'] ?? 0,
                        color: Colors.blue,
                        width: 12,
                      ),
                    ],
                  ),
                  // Auto Missed
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: autoStats['missAvg'] ?? 0,
                        color: Colors.red,
                        width: 12,
                      ),
                    ],
                  ),
                  // Small spacer
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: 0,
                        color: Colors.transparent,
                        width: 12,
                      ),
                    ],
                  ),
                  // Teleop Scored
                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(
                        toY: teleopStats['scoreAvg'] ?? 0,
                        color: Colors.green,
                        width: 12,
                      ),
                    ],
                  ),
                  // Teleop Missed
                  BarChartGroupData(
                    x: 4,
                    barRods: [
                      BarChartRodData(
                        toY: teleopStats['missAvg'] ?? 0,
                        color: Colors.red,
                        width: 12,
                      ),
                    ],
                  ),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 12, height: 12, color: Colors.blue),
                  const SizedBox(width: 4),
                  const Text('Auto Scored', style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 16),
                  Container(width: 12, height: 12, color: Colors.green),
                  const SizedBox(width: 4),
                  const Text('Teleop Scored', style: TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 12, height: 12, color: Colors.red),
                  const SizedBox(width: 4),
                  const Text('Missed', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}



double _calculateMaxY(Map<String, double> autoStats, Map<String, double> teleopStats) {
  final values = [
    autoStats['scoreAvg'] ?? 0,
    autoStats['missAvg'] ?? 0,
    teleopStats['scoreAvg'] ?? 0,
    teleopStats['missAvg'] ?? 0,
  ];
  return values.reduce((curr, next) => curr > next ? curr : next) * 1.2;
}

  Widget _buildClimbChart(Map<String, double> percentages) {
    final data = ['park', 'shallow', 'deep', 'failed', 'none']
        .map((status) => percentages[status] ?? 0)
        .toList();
    
    return Card(
      color: Colors.black45,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Climb Status Distribution',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100, // Set maximum Y value to 100%
                  barGroups: [
                    for (var i = 0; i < data.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[i],
                            color: _getClimbColor(i),
                            width: 16, // Slightly reduced width
                          ),
                        ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '${value.toInt()}%',
                            style: const TextStyle(color: Colors.white70, fontSize: 9),
                          ),
                        ),
                        reservedSize: 28,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Transform.rotate(
                          angle: -0.4, // Slight angle to prevent overlap
                          child: Text(
                            ['Park', 'Shallow', 'Deep', 'Failed', 'None'][value.toInt()],
                            style: const TextStyle(color: Colors.white70, fontSize: 9),
                          ),
                        ),
                        reservedSize: 24,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.white24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Changed legend to wrap
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < 5; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: _getClimbColor(i),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ['Park', 'Shallow', 'Deep', 'Failed', 'None'][i],
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}