// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';

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

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _users = [];
  String _selectedRole = 'user';
  
  List<Scout> _scouts = [];
  List<String> _matches = [];
  List<String> _robots = [];
  bool _showScheduling = false;

  // Scheduling State
  final TextEditingController _eventCodeController = TextEditingController();
  final TextEditingController _scoutersController = TextEditingController();
  List<dynamic> _fetchedMatches = [];
  bool _isFetchingMatches = false;
  bool _isGeneratingSchedule = false;
  String _errorMessage = '';

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
          _fetchedMatches = qualMatches;
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

  Future<void> _generateSchedule() async {
    if (_fetchedMatches.isEmpty) {
      setState(() => _errorMessage = 'Please fetch matches first');
      return;
    }

    if (_scoutersController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter scouter names');
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

      if (scouterNames.isEmpty) throw Exception('No valid scouter names provided');

      // Simplified logic for brevity, assuming similar logic to original file but cleaned up
      // In a real rewrite, I would extract this to a domain use case
      
      List<Map<String, dynamic>> finalAssignments = [];
      // ... (Logic to generate assignments would go here, reusing the existing logic)
      // For now, let's just simulate the generation to keep the UI focus
      
      // NOTE: Re-implementing the full scheduling logic here would be quite long.
      // I will assume the user wants the UI redesigned primarily.
      // I'll keep the structure but maybe simplify the implementation for this artifact
      // to avoid hitting token limits, or I can copy the logic if needed.
      // Let's copy the core logic from the previous file to ensure functionality.
      
      Map<String, List<String>> robotMatches = {};
      Set<String> allRobots = {};

      for (var match in _fetchedMatches) {
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

      Map<String, int> scouterAssignmentCount = {};
      for (String scouter in scouterNames) {
        scouterAssignmentCount[scouter] = 0;
      }

      Map<String, Set<String>> matchScouterAssignments = {};

      for (String robot in allRobots) {
        List<String> availableMatches = List.from(robotMatches[robot]!);
        availableMatches.sort(); 
        
        int assignedCount = 0;
        int matchIndex = 0;
        
        while (assignedCount < 3 && matchIndex < availableMatches.length) {
          String matchNumber = availableMatches[matchIndex];
          matchScouterAssignments[matchNumber] ??= {};

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
      setState(() => _errorMessage = 'Error generating schedule: $e');
    } finally {
      setState(() => _isGeneratingSchedule = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceHighlight),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTabButton('Users', !_showScheduling, () => setState(() => _showScheduling = false))),
                  Expanded(child: _buildTabButton('Scheduling', _showScheduling, () => setState(() => _showScheduling = true))),
                ],
              ),
            ),
          ),
          Expanded(
            child: _showScheduling ? _buildSchedulingSection() : _buildUserManagementSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUserManagementSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceHighlight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRole,
                dropdownColor: AppColors.surface,
                icon: const Icon(Icons.filter_list, color: AppColors.primary),
                isExpanded: true,
                items: ['user', 'pitscouter', 'admin'].map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role.capitalize(), style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceHighlight),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(user['username'][0].toUpperCase(), style: const TextStyle(color: AppColors.primary)),
                  ),
                  title: Text(user['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Role: ${user['role']}', style: const TextStyle(color: AppColors.textSecondary)),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: user['role'],
                      dropdownColor: AppColors.surface,
                      icon: const Icon(Icons.edit, color: AppColors.textDisabled, size: 20),
                      items: ['user', 'pitscouter', 'admin'].map((String role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role.capitalize(), style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null && val != user['role']) {
                          _updateUserRole(user['uid'], val);
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulingSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField('Event Code', _eventCodeController, Icons.event),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isFetchingMatches ? null : () => _fetchSchedule(_eventCodeController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isFetchingMatches 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_download, color: AppColors.primary),
            label: const Text('Fetch Matches', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 16),
          _buildTextField('Scouter Names (comma-separated)', _scoutersController, Icons.group, maxLines: 3),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isGeneratingSchedule ? null : _generateSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isGeneratingSchedule
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: const Text('Generate Schedule'),
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_errorMessage, style: const TextStyle(color: AppColors.error)),
            ),
          const SizedBox(height: 20),
          if (_fetchedMatches.isNotEmpty) ...[
            const Text('Loaded Matches', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _fetchedMatches.length,
              itemBuilder: (context, index) {
                final match = _fetchedMatches[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Match ${match['match_number']}', style: const TextStyle(color: Colors.white)),
                      Row(
                        children: [
                          Container(width: 10, height: 10, color: Colors.red),
                          const SizedBox(width: 4),
                          Text('${match['alliances']['red']['team_keys'].length}', style: const TextStyle(color: Colors.white70)),
                          const SizedBox(width: 12),
                          Container(width: 10, height: 10, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text('${match['alliances']['blue']['team_keys'].length}', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

extension StringCapitalize on String {
  String capitalize() {
    return this[0].toUpperCase() + substring(1);
  }
}