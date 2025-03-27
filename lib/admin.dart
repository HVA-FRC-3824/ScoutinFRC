// ignore_for_file: use_build_context_synchronously, duplicate_ignore, library_private_types_in_public_api, avoid_types_as_parameter_names

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class Scout {
  final String uid;
  final String username;
  int assignedMatches;

  Scout({
    required this.uid,
    required this.username,
    this.assignedMatches = 0,
  });
}

class MatchAssignment {
  final String matchNumber;
  final String scoutUid;
  final String robotNumber;
  final DateTime timestamp;

  MatchAssignment({
    required this.matchNumber,
    required this.scoutUid,
    required this.robotNumber,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'matchNumber': matchNumber,
      'scoutUid': scoutUid,
      'robotNumber': robotNumber,
      'timestamp': timestamp,
    };
  }
}

class ScoutingScheduler {
  final FirebaseFirestore _firestore;
  
  ScoutingScheduler(this._firestore);

  Future<List<MatchAssignment>> generateSchedule({
    required List<Scout> availableScouts,
    required List<String> matches,
    required List<String> robotNumbers,
    required int matchesPerRobot,
  }) async {
    List<MatchAssignment> assignments = [];
    Map<String, int> robotMatchCounts = {};
    
    for (String robot in robotNumbers) {
      robotMatchCounts[robot] = 0;
    }

    matches.sort();

    for (String match in matches) {
      List<Scout> availableForMatch = [...availableScouts]
        ..sort((a, b) => a.assignedMatches.compareTo(b.assignedMatches));

      for (String robot in robotNumbers) {
        if (robotMatchCounts[robot]! < matchesPerRobot) {
          if (availableForMatch.isNotEmpty) {
            Scout selectedScout = availableForMatch.removeAt(0);
            
            assignments.add(MatchAssignment(
              matchNumber: match,
              scoutUid: selectedScout.uid,
              robotNumber: robot,
              timestamp: DateTime.now(),
            ));

            robotMatchCounts[robot] = robotMatchCounts[robot]! + 1;
            selectedScout.assignedMatches++;
          }
        }
      }
    }

    return assignments;
  }

  Future<void> saveSchedule(List<MatchAssignment> assignments) async {
    WriteBatch batch = _firestore.batch();
    
    for (var assignment in assignments) {
      DocumentReference ref = _firestore.collection('scouting_assignments').doc();
      batch.set(ref, assignment.toMap());
    }

    await batch.commit();
  }
}

class ScheduleDisplay extends StatefulWidget {
  final List<Scout> scouts;
  final List<String> matches;
  final List<String> robots;

  const ScheduleDisplay({
    Key? key,
    required this.scouts,
    required this.matches,
    required this.robots,
  }) : super(key: key);

  @override
  _ScheduleDisplayState createState() => _ScheduleDisplayState();
}

class _ScheduleDisplayState extends State<ScheduleDisplay> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _eventCodeController = TextEditingController();
  final TextEditingController _scoutersController = TextEditingController();
  List<dynamic> _matches = [];
  bool _isFetchingMatches = false;
  bool _isGeneratingSchedule = false;
  String _errorMessage = '';

  Future<void> _generateSchedule() async {
  if (_matches.isEmpty) {
    setState(() {
      _errorMessage = 'Please fetch matches first';
    });
    return;
  }

  if (_scoutersController.text.isEmpty) {
    setState(() {
      _errorMessage = 'Please enter scouter names';
    });
    return;
  }

  setState(() {
    _isGeneratingSchedule = true;
    _errorMessage = '';
  });

  try {
    List<String> scouterNames = _scoutersController.text
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (scouterNames.isEmpty) {
      throw Exception('No valid scouter names provided');
    }

    Map<String, List<String>> robotMatches = {};
    Set<String> allRobots = {};

    for (var match in _matches) {
      String matchNumber = match['match_number'].toString();
      List<String> redTeams = (match['alliances']['red']['team_keys'] as List).cast<String>();
      List<String> blueTeams = (match['alliances']['blue']['team_keys'] as List).cast<String>();
      List<String> allTeams = [...redTeams, ...blueTeams];

      for (String team in allTeams) {
        allRobots.add(team);
        robotMatches[team] ??= [];
        robotMatches[team]!.add(matchNumber);
      }
    }

    // Track assignments for each scouter to ensure balanced workload
    Map<String, int> scouterAssignmentCount = {};
    for (String scouter in scouterNames) {
      scouterAssignmentCount[scouter] = 0;
    }

    Map<String, Set<String>> matchScouterAssignments = {};
    List<Map<String, dynamic>> finalAssignments = [];

    for (String robot in allRobots) {
      List<String> availableMatches = List.from(robotMatches[robot]!);
      availableMatches.sort(); // Sort by match number instead of shuffling
      
      int assignedCount = 0;
      int matchIndex = 0;
      
      while (assignedCount < 3 && matchIndex < availableMatches.length) {
        String matchNumber = availableMatches[matchIndex];
        matchScouterAssignments[matchNumber] ??= {};

        // Find the scouter with the lowest assignment count who isn't already assigned to this match
        String? selectedScouter;
        int lowestCount = double.maxFinite.toInt();
        
        for (String scouter in scouterNames) {
          if (!matchScouterAssignments[matchNumber]!.contains(scouter) && 
              (scouterAssignmentCount[scouter] ?? 0) < lowestCount) {
            selectedScouter = scouter;
            lowestCount = scouterAssignmentCount[scouter]!;
          }
        }

        if (selectedScouter != null) {
          matchScouterAssignments[matchNumber]!.add(selectedScouter);
          scouterAssignmentCount[selectedScouter] = (scouterAssignmentCount[selectedScouter] ?? 0) + 1;
          
          finalAssignments.add({
            'matchNumber': matchNumber,
            'robotNumber': robot.replaceAll('frc', ''),
            'scouterName': selectedScouter,
            'timestamp': DateTime.now(),
          });
          assignedCount++;
        }
        matchIndex++;
      }
    }

    // Print workload distribution for debugging
    print('Scouter assignment distribution:');
    scouterAssignmentCount.forEach((scouter, count) {
      print('$scouter: $count assignments');
    });

    WriteBatch batch = _firestore.batch();
    
    final existingAssignments = await _firestore.collection('scouting_assignments').get();
    for (var doc in existingAssignments.docs) {
      batch.delete(doc.reference);
    }

    for (var assignment in finalAssignments) {
      DocumentReference ref = _firestore.collection('scouting_assignments').doc();
      batch.set(ref, assignment);
    }

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule generated successfully')),
    );

  } catch (e) {
    setState(() {
      _errorMessage = 'Error generating schedule: $e';
    });
  } finally {
    setState(() {
      _isGeneratingSchedule = false;
    });
  }
}

  Future<void> _fetchSchedule(String eventCode) async {
    setState(() {
      _isFetchingMatches = true;
      _errorMessage = '';
    });

    try {
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

        setState(() {
          _matches = qualMatches;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load schedule';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isFetchingMatches = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _eventCodeController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Event Code',
              labelStyle: TextStyle(color: Colors.white),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isFetchingMatches ? null : () => _fetchSchedule(_eventCodeController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(75, 79, 85, 1),
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isFetchingMatches
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Fetch Matches',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _scoutersController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Scouter Names (comma-separated)',
              labelStyle: TextStyle(color: Colors.white),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              hintText: 'John, Jane, Bob',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isGeneratingSchedule ? null : _generateSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(75, 79, 85, 1),
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isGeneratingSchedule
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Generate Schedule',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: _matches.isEmpty
                ? const Center(
                    child: Text(
                      'No matches loaded',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView.builder(
                    itemCount: _matches.length,
                    itemBuilder: (context, index) {
                      final match = _matches[index];
                      return Card(
                        color: const Color.fromRGBO(75, 79, 85, 1),
                        child: ListTile(
                          title: Text(
                            'Match ${match['match_number']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Red: ${match['alliances']['red']['team_keys'].join(', ')}',
                                style: const TextStyle(color: Colors.red),
                              ),
                              Text(
                                'Blue: ${match['alliances']['blue']['team_keys'].join(', ')}',
                                style: const TextStyle(color: Colors.blue),
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
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key, required String title}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _users = [];
  String _selectedRole = 'user';
  
  List<Scout> _scouts = [];
  List<String> _matches = [];
  List<String> _robots = [];
  bool _showScheduling = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchSchedulingData();
  }

  Future<void> _fetchSchedulingData() async {
    try {
      final matchesSnapshot = await _firestore.collection('matches').orderBy('number').get();
      final List<String> matches = matchesSnapshot.docs.map((doc) => doc.get('number').toString()).toList();

      final robotsSnapshot = await _firestore.collection('robots').get();
      final List<String> robots = robotsSnapshot.docs.map((doc) => doc.get('number').toString()).toList();

      final List<Scout> scouts = _users
          .where((user) => user['role'] == 'pitscouter')
          .map((user) => Scout(
                uid: user['uid'],
                username: user['username'],
              ))
          .toList();

      setState(() {
        _matches = matches;
        _robots = robots;
        _scouts = scouts;
      });
    } catch (e) {
      print("Error fetching scheduling data: $e");
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('users').get();
      final List<Map<String, dynamic>> users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final role = data['role'] ?? 'user';
        final validRoles = ['user', 'pitscouter', 'admin'];
        return {
          'uid': doc.id,
          'username': data['username'] ?? 'Unknown User',
          'role': validRoles.contains(role) ? role : 'user',
        };
      }).toList();
      setState(() {
        _users = users;
      });
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  Future<void> _updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': role});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User role updated successfully.")),
      );
      _fetchUsers();
      _fetchSchedulingData();
    } catch (e) {
      print("Error updating user role: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update user role.")),
      );
    }
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
      body: Container(
        color: const Color.fromRGBO(65, 68, 73, 1),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => _showScheduling = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_showScheduling 
                        ? const Color.fromRGBO(75, 79, 85, 1)
                        : const Color.fromRGBO(65, 68, 74, 1),
                  ),
                  child: const Text('User Management',
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => setState(() => _showScheduling = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showScheduling 
                        ? const Color.fromRGBO(75, 79, 85, 1)
                        : const Color.fromRGBO(65, 68, 74, 1),
                  ),
                  child: const Text('Scheduling',
                  style: TextStyle(color: Colors.white),),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _showScheduling
                  ? _buildSchedulingSection()
                  : _buildUserManagementSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagementSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DropdownButton<String>(
            value: _selectedRole,
            items: <String>['user', 'pitscouter', 'admin']
                .map((String role) {
              return DropdownMenuItem<String>(
                value: role,
                child: Text(role.capitalize()),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedRole = newValue!;
              });
            },
            isExpanded: true,
            dropdownColor: const Color.fromRGBO(75, 79, 85, 1),
            style: const TextStyle(color: Colors.white),
            underline: Container(
              height: 2,
              color: Colors.grey.shade300,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return ListTile(
                tileColor: const Color.fromRGBO(75, 79, 85, 1),
                leading: CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Text(user['username'][0]),
                ),
                title: Text(
                  user['username'],
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Role: ${user['role']}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: DropdownButton<String>(
                  value: user['role'],
                  items: <String>['user', 'pitscouter', 'admin']
                      .map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role.capitalize()),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null && newValue != user['role']) {
                      _updateUserRole(user['uid'], newValue);
                    }
                  },
                  dropdownColor: const Color.fromRGBO(75, 79, 85, 1),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulingSection() {
    if (_scouts.isEmpty) {
      return const Center(
        child: Text(
          'No pit scouters available. Assign users as pit scouters first.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ScheduleDisplay(
      scouts: _scouts,
      matches: _matches,
      robots: _robots,
    );
  }
}

extension StringCapitalize on String {
  String capitalize() {
    return this[0].toUpperCase() + substring(1);
  }
}