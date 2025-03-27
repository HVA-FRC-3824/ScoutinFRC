// ignore_for_file: use_build_context_synchronously, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'navbar.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.title});
  final String title;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedScouter;
  List<Map<String, dynamic>> _assignments = [];
  List<String> _scouterNames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchScouterNames();
  }

  void _shareSchedule() {
    if (_selectedScouter == null || _assignments.isEmpty) return;

    // Create a formatted message
    String message = 'Scouting Schedule for $_selectedScouter:\n\n';
    
    for (var assignment in _assignments) {
      message += '• Match ${assignment['matchNumber']}: Robot ${assignment['robotNumber']}\n';
    }

    Share.share(message);
  }

  Future<void> _fetchScouterNames() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('scouting_assignments')
          .get();

      Set<String> names = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['scouterName'] != null) {
          names.add(data['scouterName']);
        }
      }

      setState(() {
        _scouterNames = names.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching scouter names: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAssignments(String scouterName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('scouting_assignments')
          .where('scouterName', isEqualTo: scouterName)
          .get();

      List<Map<String, dynamic>> assignments = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        assignments.add({
          'matchNumber': data['matchNumber'],
          'robotNumber': data['robotNumber'],
        });
      }

      // Sort assignments by match number
      assignments.sort((a, b) => int.parse(a['matchNumber'])
          .compareTo(int.parse(b['matchNumber'])));

      setState(() {
        _assignments = assignments;
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
          if (_selectedScouter != null && _assignments.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.share,
                color: Color.fromRGBO(165, 176, 168, 1),
                size: 30,
              ),
              onPressed: _shareSchedule,
            ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Color.fromRGBO(165, 176, 168, 1),
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
        color: const Color.fromRGBO(65, 68, 74, 1),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(75, 79, 85, 1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedScouter,
                  hint: const Text(
                    'Select Scouter',
                    style: TextStyle(color: Colors.white),
                  ),
                  items: _scouterNames.map((String name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(
                        name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedScouter = newValue;
                    });
                    if (newValue != null) {
                      _fetchAssignments(newValue);
                    }
                  },
                  dropdownColor: const Color.fromRGBO(75, 79, 85, 1),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  isExpanded: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else if (_selectedScouter != null && _assignments.isEmpty)
              const Center(
                child: Text(
                  'No assignments found',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            else if (_selectedScouter != null)
              Expanded(
                child: ListView.builder(
                  itemCount: _assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = _assignments[index];
                    return Card(
                      color: const Color.fromRGBO(75, 79, 85, 1),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Text(
                            assignment['matchNumber'],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          'Match ${assignment['matchNumber']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Robot: ${assignment['robotNumber']}',
                          style: const TextStyle(
                            color: Colors.white70,
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