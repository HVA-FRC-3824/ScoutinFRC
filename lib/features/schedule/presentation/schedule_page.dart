import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

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

    String message = 'Scouting Schedule for $_selectedScouter:\n\n';
    for (var assignment in _assignments) {
      message += '• Match ${assignment['matchNumber']}: Robot ${assignment['robotNumber']}\n';
    }

    Share.share(message);
  }

  Future<void> _fetchScouterNames() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('scouting_assignments').get();
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAssignments(String scouterName) async {
    setState(() => _isLoading = true);
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

      assignments.sort((a, b) => int.parse(a['matchNumber']).compareTo(int.parse(b['matchNumber'])));

      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching assignments: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Match Schedule'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_selectedScouter != null && _assignments.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share, color: AppColors.primary),
              onPressed: _shareSchedule,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceHighlight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedScouter,
                  hint: const Text('Select Scouter', style: TextStyle(color: AppColors.textSecondary)),
                  dropdownColor: AppColors.surface,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  isExpanded: true,
                  items: _scouterNames.map((String name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() => _selectedScouter = newValue);
                    if (newValue != null) _fetchAssignments(newValue);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    
    if (_selectedScouter != null && _assignments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppColors.textDisabled),
            SizedBox(height: 16),
            Text('No assignments found', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
          ],
        ),
      );
    }
    
    if (_selectedScouter == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: AppColors.textDisabled),
            SizedBox(height: 16),
            Text('Select a scouter to view schedule', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _assignments.length,
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.surface, AppColors.surface.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceHighlight),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                assignment['matchNumber'],
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              'Match ${assignment['matchNumber']}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'Target Robot: ${assignment['robotNumber']}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textDisabled),
          ),
        );
      },
    );
  }
}