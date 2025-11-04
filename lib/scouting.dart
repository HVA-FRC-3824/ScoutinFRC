// ignore_for_file: non_constant_identifier_names, avoid_unnecessary_containers, unused_import, unused_field, deprecated_member_use, use_build_context_synchronously, prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:firebase_database/firebase_database.dart';
import 'navbar.dart';
import 'variables.dart' as v;
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScoutingPage extends StatefulWidget {
  const ScoutingPage({super.key, required this.title});
  final String title;

  @override
  State<ScoutingPage> createState() => _ScoutingPageState();
}

class _ScoutingPageState extends State<ScoutingPage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _matches = [];

  Future<void> _fetchSchedule(String eventCode) async {
  final response = await http.get(
    Uri.parse('https://www.thebluealliance.com/api/v3/event/$eventCode/matches/simple'),
    headers: {'X-TBA-Auth-Key': 'XKgCGALe7EzYqZUeKKONsQ45iGHVUZYlN0F6qQzchKQrLxED5DFWrYi9pcjxIzGY'},
  );

  if (response.statusCode == 200) {
    List<dynamic> allMatches = jsonDecode(response.body);
    List<dynamic> qualMatches = allMatches
        .where((match) => match['comp_level'] == 'qm')
        .toList()
        ..sort((a, b) => a['match_number'].compareTo(b['match_number']));

    // Store the event code in pageData
    v.pageData['eventKey'] = eventCode;
    // Also store it in pitScoutingData
    v.pitScoutingData['eventKey'] = eventCode;

    setState(() {
      _matches = qualMatches;
    });
  } else {
    print('Failed to load schedule');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavBar(),
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.white,  
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
              color: Colors.white,  
              size: 50,
            ),
          ),
        ],
        backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
        title: Image.asset(
          'assets/images/rohawktics.png',
          width: 75,
          height: 75,
          alignment: Alignment.center,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),  
              decoration: const InputDecoration(
                labelText: 'Enter Event Code',
                labelStyle: TextStyle(color: Colors.white),  
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: const TextStyle(color: Color.fromARGB(255, 246, 246, 246)),  
                side: const BorderSide(width: 3, color: Color.fromRGBO(90, 93, 102, 1)),
              ),
              onPressed: () {
                _fetchSchedule(_controller.text);
              },
              child: const Text('Fetch Schedule'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  final match = _matches[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchNumPage(
                            title: 'Match Scouting',
                            matchData: match,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      color: const Color.fromRGBO(90, 93, 102, 1),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Match ${match['match_number']}',
                              style: const TextStyle(
                                color: Colors.white,  
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                border: Border.all(color: Colors.red.shade900),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Red Alliance: ${match['alliances']['red']['team_keys'].join(', ')}',
                                style: const TextStyle(
                                  color: Colors.white,  
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                border: Border.all(color: Colors.blue.shade900),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Blue Alliance: ${match['alliances']['blue']['team_keys'].join(', ')}',
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MatchNumPage extends StatefulWidget {
  const MatchNumPage({super.key, required this.title, required this.matchData});

  final String title;
  final dynamic matchData;

  @override
  State<MatchNumPage> createState() => _MatchNumPageState();
}

class _MatchNumPageState extends State<MatchNumPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> _scouterAssignments = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    try {
      final String matchNumber = widget.matchData['match_number'].toString();
      
      QuerySnapshot snapshot = await _firestore
          .collection('scouting_assignments')
          .where('matchNumber', isEqualTo: matchNumber)
          .get();

      Map<String, String> assignments = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        assignments[data['robotNumber']] = data['scouterName'];
      }

      setState(() {
        _scouterAssignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching assignments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchData = widget.matchData;
    final List<String> redAlliance = (matchData['alliances']['red']['team_keys'] as List<dynamic>)
        .map((e) => e.toString().replaceAll('frc', ''))
        .toList();
    final List<String> blueAlliance = (matchData['alliances']['blue']['team_keys'] as List<dynamic>)
        .map((e) => e.toString().replaceAll('frc', ''))
        .toList();

    return Scaffold(
      drawer: NavBar(),
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
        title: Image.asset(
          'assets/images/rohawktics.png',
          width: 75,
          height: 75,
          alignment: Alignment.center,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 20),
                  const Text(
                    'Select Team to Scout',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildTeamSelection('Red Alliance', redAlliance),
                  const SizedBox(height: 20),
                  _buildTeamSelection('Blue Alliance', blueAlliance),
                  const SizedBox(height: 25),
                ],
              ),
            ),
    );
  }

  Widget _buildTeamSelection(String alliance, List<String> teamNumbers) {
    return Column(
      children: teamNumbers.map((teamNumber) {
        final assignedScouter = _scouterAssignments[teamNumber] ?? 'Unassigned';
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: alliance == 'Red Alliance' ? Colors.red.shade900 : Colors.blue.shade900,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            onPressed: () {
              v.pageData['robotNum'] = teamNumber;
              v.pageData['matchNum'] = widget.matchData['match_number'].toString();
              Navigator.pushNamed(context, '/autostart');
            },
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              backgroundColor: alliance == 'Red Alliance' ? Colors.red.shade700 : Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Team $teamNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scouter: $assignedScouter',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}


class AutoStartPage extends StatefulWidget {
  const AutoStartPage({super.key, required this.title});
  final String title;

  @override
  State<AutoStartPage> createState() => _AutoStartPageState();
}

class _AutoStartPageState extends State<AutoStartPage> {
  String? _selectedStartPosition;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.white, 
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
              color: Colors.white,  
              size: 50,
            ),
          ),
        ],
        backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
        title: Image.asset(
          'assets/images/rohawktics.png',
          width: 75,
          height: 75,
          alignment: Alignment.center,
        ),
      ),
      body: Container(
        color:   const Color.fromRGBO(65, 68, 74, 1),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: GestureDetector(
                  onTapDown: (details) {
                    setState(() {
                      double relativeY = details.localPosition.dy / 300; 

                      if (relativeY < 0.125) {
                        _selectedStartPosition = 'Top';
                      } else if (relativeY < 0.25) {
                        _selectedStartPosition = 'TopMiddle1';
                      } else if (relativeY < 0.375) {
                        _selectedStartPosition = 'TopMiddle2';
                      } else if (relativeY < 0.5) {
                        _selectedStartPosition = 'Middle';
                      } else if (relativeY < 0.625) {
                        _selectedStartPosition = 'BottomMiddle1';
                      } else if (relativeY < 0.75) {
                        _selectedStartPosition = 'BottomMiddle2';
                      } else if (relativeY < 0.875) {
                        _selectedStartPosition = 'Bottom';
                      } else {
                        _selectedStartPosition = 'BottomExtreme';
                      }
                      v.pageData['startPosition'] = _selectedStartPosition;
                    });
                  },
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/field.png',
                        fit: BoxFit.contain,
                      ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                          ),
                          child: Center(
                            child: _selectedStartPosition == 'Top'
                                ? const Icon(Icons.check, color: Colors.white, size: 15)
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 40,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                          ),
                          child: Center(
                            child: _selectedStartPosition == 'TopMiddle1'
                                ? const Icon(Icons.check, color: Colors.white, size: 15)
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 70,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                          ),
                          child: Center(
                            child: _selectedStartPosition == 'TopMiddle2'
                                ? const Icon(Icons.check, color: Colors.white, size: 15)
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 110,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                          ),
                          child: Center(
                            child: _selectedStartPosition == 'Middle'
                                ? const Icon(Icons.check, color: Colors.white, size: 15)
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 150,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                          ),
                          child: Center(
                            child: _selectedStartPosition == 'BottomMiddle1'
                                ? const Icon(Icons.check, color: Colors.white, size: 15)
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 190,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                          ),
                          child: Center(
                            child: _selectedStartPosition == 'BottomMiddle2'
                                ? const Icon(Icons.check, color: Colors.white, size: 15)
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 230,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                          ),
                          child: Center(
                            child: _selectedStartPosition == 'Bottom'
                                ? const Icon(Icons.check, color: Colors.white, size: 15)
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 270,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                          ),
                          child: Center(
                            child: _selectedStartPosition == 'BottomExtreme'
                                ? const Icon(Icons.check, color: Colors.white, size: 15)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Auto Start',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedStartPosition != null) {
                        Navigator.pushNamed(
                          context,
                          '/auto',
                          arguments: _selectedStartPosition,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select a starting position.',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                    ),
                    child: const Text(
                      'Proceed',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AutoPage extends StatefulWidget {
  const AutoPage({super.key, required this.title});
  final String title;

  @override
  State<AutoPage> createState() => _AutoPageState();
}

class _AutoPageState extends State<AutoPage> {
  final List<Map<String, dynamic>> _coralCounters = [
    {'label': 'L4', 'score': 0, 'miss': 0},
    {'label': 'L3', 'score': 0, 'miss': 0},
    {'label': 'L2', 'score': 0, 'miss': 0},
    {'label': 'L1', 'score': 0, 'miss': 0},
  ];

  int _algaeScore = 0;
  int _algaeMiss = 0;
  int _floorCount = 0;
  int _stationCount = 0;
  int _floorStationMiss = 0;

  Timer? _decrementDelayTimer;
  Timer? _decrementRepeatTimer;
  bool _isDecrementing = false;

@override
void initState() {
  super.initState();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Load existing data if available
  if (v.pageData['auto']['coral'] != null) {
    _coralCounters[0]['score'] = v.pageData['auto']['coral']['L4']['score'] ?? 0;
    _coralCounters[0]['miss'] = v.pageData['auto']['coral']['L4']['miss'] ?? 0;
    _coralCounters[1]['score'] = v.pageData['auto']['coral']['L3']['score'] ?? 0;
    _coralCounters[1]['miss'] = v.pageData['auto']['coral']['L3']['miss'] ?? 0;
    _coralCounters[2]['score'] = v.pageData['auto']['coral']['L2']['score'] ?? 0;
    _coralCounters[2]['miss'] = v.pageData['auto']['coral']['L2']['miss'] ?? 0;
    _coralCounters[3]['score'] = v.pageData['auto']['coral']['L1']['score'] ?? 0;
    _coralCounters[3]['miss'] = v.pageData['auto']['coral']['L1']['miss'] ?? 0;
  }

  _algaeScore = v.pageData['auto']['algae']['score'] ?? 0;
  _algaeMiss = v.pageData['auto']['algae']['miss'] ?? 0;

  _floorCount = v.pageData['auto']['floorStation']['floor'] ?? 0;
  _stationCount = v.pageData['auto']['floorStation']['station'] ?? 0;
  _floorStationMiss = v.pageData['auto']['floorStation']['miss'] ?? 0;

  WidgetsBinding.instance.addPostFrameCallback((_) => _updatePageData());
}

void _updatePageData() {
  v.pageData['auto']['coral'] = {
    'L4': {
      'score': _coralCounters[0]['score'],
      'miss': _coralCounters[0]['miss'],
    },
    'L3': {
      'score': _coralCounters[1]['score'],
      'miss': _coralCounters[1]['miss'],
    },
    'L2': {
      'score': _coralCounters[2]['score'],
      'miss': _coralCounters[2]['miss'],
    },
    'L1': {
      'score': _coralCounters[3]['score'],
      'miss': _coralCounters[3]['miss'],
    },
  };
  
  v.pageData['auto']['algae'] = {
    'score': _algaeScore,
    'miss': _algaeMiss,
  };

  v.pageData['auto']['floorStation'] = {
    'floor': _floorCount,
    'station': _stationCount,
    'miss': _floorStationMiss,
  };
}

  @override
  void dispose() {
    _decrementDelayTimer?.cancel();
    _decrementRepeatTimer?.cancel();
    super.dispose();
  }

  void _handleTapDown(VoidCallback decrementCallback) {
    _isDecrementing = false;
    _decrementDelayTimer = Timer(const Duration(milliseconds: 250), () {
      _isDecrementing = true;
      _decrementRepeatTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
        decrementCallback();
      });
    });
  }

  void _handleTapUpOrCancel(VoidCallback incrementCallback) {
    _decrementDelayTimer?.cancel();
    _decrementRepeatTimer?.cancel();
    if (!_isDecrementing) {
      incrementCallback();
    }
    _isDecrementing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
      ),
      body: Container(
        color: const Color.fromRGBO(65, 68, 74, 1),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/r.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _coralCounters.length,
                          itemBuilder: (context, index) => _buildCounterRow(_coralCounters[index]),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                        child: Column(
                          children: [
                            const Text(
                              'Auto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(child: _buildFloorStationSection()),
                            Expanded(child: _buildAlgaeSection()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorStationSection() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlacementButton(
  icon: Icons.view_comfy_outlined,
  label: 'Floor',
  onIncrement: () => setState(() {
    _floorCount++;
    _updatePageData();
  }),
  onDecrement: () => setState(() {
    _floorCount = _floorCount > 0 ? _floorCount - 1 : 0;
    _updatePageData();
  }),
),
// Repeat for Station and Miss buttons
              _buildPlacementButton(
  icon: Icons.currency_exchange,
  label: 'Station',
  onIncrement: () => setState(() {
    _stationCount++;
    _updatePageData();
  }),
  onDecrement: () => setState(() {
    _stationCount = _stationCount > 0 ? _stationCount - 1 : 0;
    _updatePageData();
  }),
),
// Repeat for Station and Miss buttons
              _buildPlacementButton(
  icon: Icons.close,
  label: 'Miss',
  onIncrement: () => setState(() {
    _floorStationMiss++;
    _updatePageData();
  }),
  onDecrement: () => setState(() {
    _floorStationMiss = _floorStationMiss > 0 ? _floorStationMiss - 1 : 0;
    _updatePageData();
  }),
),
// Repeat for Station and Miss buttons
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Floor: $_floorCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                'Station: $_stationCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                'Miss: $_floorStationMiss',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildPlacementButton({
  required IconData icon,
  required String label,
  required VoidCallback onIncrement,
  required VoidCallback onDecrement,
}) {
  return GestureDetector(
    onTapDown: (details) => _handleTapDown(onDecrement),
    onTapUp: (details) => _handleTapUpOrCancel(onIncrement),
    onTapCancel: () => _handleTapUpOrCancel(onIncrement),
    child: Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.white),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildAlgaeSection() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAlgaeButton(
  icon: Icons.sports_basketball,
  label: 'Net',
  onIncrement: () => setState(() {
    _algaeScore++;
    _updatePageData();
  }),
  onDecrement: () => setState(() {
    _algaeScore = _algaeScore > 0 ? _algaeScore - 1 : 0;
    _updatePageData();
  }),
),
// Repeat for other algae buttons
              _buildAlgaeButton(
  icon: Icons.memory,
  label: 'Processor',
  onIncrement: () => setState(() {
    _algaeScore++;
    _updatePageData();
  }),
  onDecrement: () => setState(() {
    _algaeScore = _algaeScore > 0 ? _algaeScore - 1 : 0;
    _updatePageData();
  }),
),
// Repeat for other algae buttons
              _buildAlgaeButton(
  icon: Icons.close,
  label: 'Miss',
  onIncrement: () => setState(() {
    _algaeMiss++;
    _updatePageData();
  }),
  onDecrement: () => setState(() {
    _algaeMiss = _algaeMiss > 0 ? _algaeMiss - 1 : 0;
    _updatePageData();
  }),
),
// Repeat for other algae buttons
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Scored: $_algaeScore',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              const SizedBox(width: 8),
              Text(
                'Missed: $_algaeMiss',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildAlgaeButton({
  required IconData icon,
  required String label,
  required VoidCallback onIncrement,
  required VoidCallback onDecrement,
}) {
  return GestureDetector(
    onTapDown: (details) => _handleTapDown(onDecrement),
    onTapUp: (details) => _handleTapUpOrCancel(onIncrement),
    onTapCancel: () => _handleTapUpOrCancel(onIncrement),
    child: Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.white),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCounterRow(Map<String, dynamic> counter) {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        children: [
          Text(
            counter['label'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _buildSmallButton(
                '+',
                () => setState(() => counter['score']++),
              ),
              const SizedBox(width: 4),
              Text(
                'Score: ${counter['score']}',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(width: 4),
              _buildSmallButton(
                '-',
                () => setState(() => counter['score'] = counter['score'] > 0 ? counter['score'] - 1 : 0),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              _buildSmallButton(
                '+',
                () => setState(() => counter['miss']++),
              ),
              const SizedBox(width: 4),
              Text(
                'Miss: ${counter['miss']}',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(width: 4),
              _buildSmallButton(
                '-',
                () => setState(() => counter['miss'] = counter['miss'] > 0 ? counter['miss'] - 1 : 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildSmallButton(String text, VoidCallback onPressed) {
  return SizedBox(
    width: 30,
    height: 30,
    child: ElevatedButton(
      onPressed: () {
        onPressed();
        _updatePageData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.withOpacity(0.7),
        padding: EdgeInsets.zero,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
    ),
  );
}

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavButton('Back', () => Navigator.pop(context)),
        _buildNavButton('Proceed', () => Navigator.pushNamed(context, '/teleop')),
      ],
    );
  }

  Widget _buildNavButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[700],
        minimumSize: const Size(80, 30),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}


class TeleopPage extends StatefulWidget {
  const TeleopPage({super.key, required this.title});
  final String title;

  @override
  State<TeleopPage> createState() => _TeleopPageState();
}

class _TeleopPageState extends State<TeleopPage> {
  final List<Map<String, dynamic>> _coralCounters = [
    {'label': 'L4', 'score': 0, 'miss': 0},
    {'label': 'L3', 'score': 0, 'miss': 0},
    {'label': 'L2', 'score': 0, 'miss': 0},
    {'label': 'L1', 'score': 0, 'miss': 0},
  ];

  int _algaeScore = 0;
  int _algaeMiss = 0;
  int _floorCount = 0;
  int _stationCount = 0;
  int _floorStationMiss = 0;

  Timer? _decrementDelayTimer;
  Timer? _decrementRepeatTimer;
  bool _isDecrementing = false;

@override
void initState() {
  super.initState();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Load existing data if available
  if (v.pageData['teleop']['coral'] != null) {
    _coralCounters[0]['score'] = v.pageData['teleop']['coral']['L4']['score'] ?? 0;
    _coralCounters[0]['miss'] = v.pageData['teleop']['coral']['L4']['miss'] ?? 0;
    _coralCounters[1]['score'] = v.pageData['teleop']['coral']['L3']['score'] ?? 0;
    _coralCounters[1]['miss'] = v.pageData['teleop']['coral']['L3']['miss'] ?? 0;
    _coralCounters[2]['score'] = v.pageData['teleop']['coral']['L2']['score'] ?? 0;
    _coralCounters[2]['miss'] = v.pageData['teleop']['coral']['L2']['miss'] ?? 0;
    _coralCounters[3]['score'] = v.pageData['teleop']['coral']['L1']['score'] ?? 0;
    _coralCounters[3]['miss'] = v.pageData['teleop']['coral']['L1']['miss'] ?? 0;
  }

  _algaeScore = v.pageData['teleop']['algae']['score'] ?? 0;
  _algaeMiss = v.pageData['teleop']['algae']['miss'] ?? 0;

  _floorCount = v.pageData['teleop']['floorStation']['floor'] ?? 0;
  _stationCount = v.pageData['teleop']['floorStation']['station'] ?? 0;
  _floorStationMiss = v.pageData['teleop']['floorStation']['miss'] ?? 0;

  WidgetsBinding.instance.addPostFrameCallback((_) => _updatePageData());
}

void _updatePageData() {
  v.pageData['teleop']['coral'] = {
    'L4': {
      'score': _coralCounters[0]['score'],
      'miss': _coralCounters[0]['miss'],
    },
    'L3': {
      'score': _coralCounters[1]['score'],
      'miss': _coralCounters[1]['miss'],
    },
    'L2': {
      'score': _coralCounters[2]['score'],
      'miss': _coralCounters[2]['miss'],
    },
    'L1': {
      'score': _coralCounters[3]['score'],
      'miss': _coralCounters[3]['miss'],
    },
  };
  
  v.pageData['teleop']['algae'] = {
    'score': _algaeScore,
    'miss': _algaeMiss,
  };

  v.pageData['teleop']['floorStation'] = {
    'floor': _floorCount,
    'station': _stationCount,
    'miss': _floorStationMiss,
  };
}

  @override
  void dispose() {
    _decrementDelayTimer?.cancel();
    _decrementRepeatTimer?.cancel();
    super.dispose();
  }

  void _handleTapDown(VoidCallback decrementCallback) {
    _isDecrementing = false;
    _decrementDelayTimer = Timer(const Duration(milliseconds: 250), () {
      _isDecrementing = true;
      _decrementRepeatTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
        decrementCallback();
      });
    });
  }

  void _handleTapUpOrCancel(VoidCallback incrementCallback) {
    _decrementDelayTimer?.cancel();
    _decrementRepeatTimer?.cancel();
    if (!_isDecrementing) {
      incrementCallback();
    }
    _isDecrementing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
      ),
      body: Container(
        color: const Color.fromRGBO(65, 68, 74, 1),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/r.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _coralCounters.length,
                          itemBuilder: (context, index) => _buildCounterRow(_coralCounters[index]),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                        child: Column(
                          children: [
                            const Text(
                              'Teleop',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(child: _buildFloorStationSection()),
                            Expanded(child: _buildAlgaeSection()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorStationSection() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlacementButton(
  icon: Icons.view_comfy_outlined,
  label: 'Floor',
  onIncrement: () => setState(() {
    _floorCount++;
    _updatePageData();
  }),
  onDecrement: () => setState(() {
    _floorCount = _floorCount > 0 ? _floorCount - 1 : 0;
    _updatePageData();
  }),
),
// Repeat for Station and Miss buttons
              _buildPlacementButton(
  icon: Icons.currency_exchange,
  label: 'Station',
  onIncrement: () => setState(() {
    _stationCount++;
    _updatePageData();
  }),
  onDecrement: () => setState(() {
    _stationCount = _stationCount > 0 ? _stationCount - 1 : 0;
    _updatePageData();
  }),
),
// Repeat for Station and Miss buttons
              _buildPlacementButton(
  icon: Icons.close,
  label: 'Miss',
  onIncrement: () => setState(() {
    _floorStationMiss++;
    _updatePageData();
  }),
  onDecrement: () => setState(() {
    _floorStationMiss = _floorStationMiss > 0 ? _floorStationMiss - 1 : 0;
    _updatePageData();
  }),
),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Floor: $_floorCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                'Station: $_stationCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                'Miss: $_floorStationMiss',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildPlacementButton({
  required IconData icon,
  required String label,
  required VoidCallback onIncrement,
  required VoidCallback onDecrement,
}) {
  return GestureDetector(
    onTapDown: (details) => _handleTapDown(onDecrement),
    onTapUp: (details) => _handleTapUpOrCancel(onIncrement),
    onTapCancel: () => _handleTapUpOrCancel(onIncrement),
    child: Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.white),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildAlgaeSection() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAlgaeButton(
  icon: Icons.sports_basketball,
  label: 'Net',
  onIncrement: () => setState(() {
    _algaeScore++;
    _updatePageData();
  }),
  onDecrement: () => setState(() {
    _algaeScore = _algaeScore > 0 ? _algaeScore - 1 : 0;
    _updatePageData();
  }),
),
// Repeat for other algae buttons
              _buildAlgaeButton(
  icon: Icons.memory,
  label: 'Processor',
  onIncrement: () => setState(() {
    _algaeScore++;
    _updatePageData();
  }),
  onDecrement: () => setState(() {
    _algaeScore = _algaeScore > 0 ? _algaeScore - 1 : 0;
    _updatePageData();
  }),
),
// Repeat for other algae buttons
              _buildAlgaeButton(
  icon: Icons.close,
  label: 'Miss',
  onIncrement: () => setState(() {
    _algaeMiss++;
    _updatePageData();
  }),
  onDecrement: () => setState(() {
    _algaeMiss = _algaeMiss > 0 ? _algaeMiss - 1 : 0;
    _updatePageData();
  }),
),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Scored: $_algaeScore',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              const SizedBox(width: 8),
              Text(
                'Missed: $_algaeMiss',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildAlgaeButton({
  required IconData icon,
  required String label,
  required VoidCallback onIncrement,
  required VoidCallback onDecrement,
}) {
  return GestureDetector(
    onTapDown: (details) => _handleTapDown(onDecrement),
    onTapUp: (details) => _handleTapUpOrCancel(onIncrement),
    onTapCancel: () => _handleTapUpOrCancel(onIncrement),
    child: Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.white),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCounterRow(Map<String, dynamic> counter) {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        children: [
          Text(
            counter['label'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _buildSmallButton(
                '+',
                () => setState(() => counter['score']++),
              ),
              const SizedBox(width: 4),
              Text(
                'Score: ${counter['score']}',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(width: 4),
              _buildSmallButton(
                '-',
                () => setState(() => counter['score'] = counter['score'] > 0 ? counter['score'] - 1 : 0),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              _buildSmallButton(
                '+',
                () => setState(() => counter['miss']++),
              ),
              const SizedBox(width: 4),
              Text(
                'Miss: ${counter['miss']}',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(width: 4),
              _buildSmallButton(
                '-',
                () => setState(() => counter['miss'] = counter['miss'] > 0 ? counter['miss'] - 1 : 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildSmallButton(String text, VoidCallback onPressed) {
  return SizedBox(
    width: 30,
    height: 30,
    child: ElevatedButton(
      onPressed: () {
        onPressed();
        _updatePageData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.withOpacity(0.7),
        padding: EdgeInsets.zero,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
    ),
  );
}

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavButton('Back', () => Navigator.pop(context)),
        _buildNavButton('Proceed', () => Navigator.pushNamed(context, '/endgame')),
      ],
    );
  }

  Widget _buildNavButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[700],
        minimumSize: const Size(80, 30),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
class EndgamePage extends StatefulWidget {
  const EndgamePage({super.key, required this.title});
  final String title;

  @override
  State<EndgamePage> createState() => _EndgamePageState();
}

class _EndgamePageState extends State<EndgamePage> {
  String _cageParkStatus = 'None';
  bool _isFailed = false;
  String _comments = '';
  final List<bool> _toggleStates = [false, false]; // [Disabled, Playing Defense]

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white),
                      value: _cageParkStatus,
                      onChanged: (String? newValue) {
                        setState(() {
                          _cageParkStatus = newValue!;
                        });
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      items: <String>['None', 'Park', 'Shallow Cage', 'Deep Cage']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    Checkbox(
                      value: _isFailed,
                      checkColor: Colors.white,
                      activeColor: Colors.blue,
                      onChanged: (bool? value) {
                        setState(() {
                          _isFailed = value!;
                        });
                      },
                    ),
                    const Text('Failed?', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ToggleButtons(
            color: Colors.white, // Unselected text color
          selectedColor: Colors.white, // Selected text color
  renderBorder: false,
  onPressed: (int index) {
    setState(() {
      _toggleStates[index] = !_toggleStates[index];
    });
  },
  isSelected: _toggleStates,
  children: [
    Container(
      decoration: BoxDecoration(
        color: _toggleStates[0] ? Colors.red : Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Text('Disabled', style: TextStyle(color: Colors.white)),
    ),
    Container(
      decoration: BoxDecoration(
        color: _toggleStates[1] ? Colors.green : Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Text('Playing Defense', style: TextStyle(color: Colors.white)),
    ),
  ],
),
            const SizedBox(height: 20),
            TextField(
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              onChanged: (value) {
                setState(() {
                  _comments = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Comments',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.grey[800],
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Back'),
                ),
                ElevatedButton(
  style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: Colors.blue,
  ),
  onPressed: () async {
    
    v.pageData['endgame'] = {
      'cageParkStatus': _cageParkStatus,
      'failed': _isFailed,
      'disabled': _toggleStates[0],
      'playingDefense': _toggleStates[1],
      'comments': _comments,
    };
print("Updated data: ${v.pageData}");

    try {
      await v.submitMatchData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match data submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  child: const Text('Submit'),
),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

