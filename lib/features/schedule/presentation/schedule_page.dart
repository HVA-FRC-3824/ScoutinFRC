import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';

class SchedulePage extends StatefulWidget {
  final VoidCallback? onMenuPressed;

  const SchedulePage({super.key, this.onMenuPressed});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  
  String? _selectedScouter;
  List<Map<String, dynamic>> _assignments = [];
  List<String> _scouterNames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchScouterNames();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: widget.onMenuPressed != null 
            ? IconButton(icon: const Icon(Icons.menu, color: AppColors.primary), onPressed: widget.onMenuPressed)
            : null,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'My Schedule'),
            Tab(text: 'All Matches'),
          ],
        ),
        actions: [
          if (_selectedScouter != null && _assignments.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share, color: AppColors.primary),
              onPressed: _shareSchedule,
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyScheduleTab(),
          _buildAllMatchesTab(), // Placeholder for now
        ],
      ),
    );
  }

  Widget _buildMyScheduleTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScouterDropdown(),
          const SizedBox(height: 20),
          Expanded(
            child: _buildAssignmentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAllMatchesTab() {
    return const Center(
      child: Text(
        'Full Schedule View\n(Coming Soon)',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
      ),
    );
  }

  Widget _buildScouterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceHighlight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedScouter,
          hint: const Text('Select Scouter', style: TextStyle(color: AppColors.textSecondary)),
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.person_search, color: AppColors.primary),
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
    );
  }

  Widget _buildAssignmentsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    
    if (_selectedScouter != null && _assignments.isEmpty) {
      return _buildEmptyState(Icons.event_busy, 'No assignments found');
    }
    
    if (_selectedScouter == null) {
      return _buildEmptyState(Icons.touch_app, 'Select a scouter above');
    }

    return ListView.builder(
      itemCount: _assignments.length,
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
        return _buildAssignmentCard(assignment, index);
      },
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment, int index) {
    // Alternate colors for visual interest
    bool isEven = index % 2 == 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.surface.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEven ? AppColors.primary.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // Future: Navigate to match details
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isEven ? AppColors.primary.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isEven ? AppColors.primary.withOpacity(0.5) : Colors.blue.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'MATCH',
                        style: TextStyle(
                          color: isEven ? AppColors.primary : Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        assignment['matchNumber'],
                        style: TextStyle(
                          color: isEven ? AppColors.primary : Colors.blue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Team',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.7),
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assignment['robotNumber'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 18),
          ),
        ],
      ),
    );
  }
}