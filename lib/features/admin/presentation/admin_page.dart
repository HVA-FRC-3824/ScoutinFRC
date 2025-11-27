// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';

class AdminPage extends StatefulWidget {
  final VoidCallback? onMenuPressed;

  const AdminPage({super.key, this.onMenuPressed});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _users = [];
  
  // Scheduling State
  final TextEditingController _eventCodeController = TextEditingController();
  final TextEditingController _scoutersController = TextEditingController();
  List<dynamic> _fetchedMatches = [];
  bool _isFetchingMatches = false;
  bool _isGeneratingSchedule = false;
  bool _showScheduling = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fetched ${qualMatches.length} qualification matches')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load schedule')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isFetchingMatches = false;
      });
    }
  }

  Future<void> _generateSchedule() async {
    if (_fetchedMatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fetch matches first')),
      );
      return;
    }
    
    setState(() => _isGeneratingSchedule = true);
    await Future.delayed(const Duration(seconds: 2)); // Simulate work
    setState(() => _isGeneratingSchedule = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule generated successfully (Simulation)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildToggle(),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _showScheduling ? _buildSchedulingSection() : _buildUserManagementSection(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(widget.onMenuPressed != null ? Icons.menu : Icons.arrow_back, color: Colors.white),
            onPressed: widget.onMenuPressed ?? () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Dashboard',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'System Control Center',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleButton('Users', !_showScheduling, () => setState(() => _showScheduling = false))),
          Expanded(child: _buildToggleButton('Scheduling', _showScheduling, () => setState(() => _showScheduling = true))),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.black : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUserManagementSection() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceHighlight),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(user['role']).withOpacity(0.2),
              child: Icon(
                _getRoleIcon(user['role']),
                color: _getRoleColor(user['role']),
                size: 20,
              ),
            ),
            title: Text(
              user['username'],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              user['role'].toString().toUpperCase(),
              style: TextStyle(color: _getRoleColor(user['role']), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              color: AppColors.surface,
              onSelected: (String role) {
                if (role != user['role']) {
                  _updateUserRole(user['uid'], role);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'user', child: Text('User', style: TextStyle(color: Colors.white))),
                const PopupMenuItem<String>(value: 'pitscouter', child: Text('Pit Scouter', style: TextStyle(color: Colors.white))),
                const PopupMenuItem<String>(value: 'admin', child: Text('Admin', style: TextStyle(color: Colors.white))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSchedulingSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EVENT CONFIGURATION', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildTextField('Event Code', _eventCodeController, Icons.event),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isFetchingMatches ? null : () => _fetchSchedule(_eventCodeController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.background,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: AppColors.surfaceHighlight),
              ),
              icon: _isFetchingMatches 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_download, color: AppColors.primary),
              label: const Text('Fetch Matches from TBA', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('SCOUTER ASSIGNMENT', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildTextField('Scouter Names (comma-separated)', _scoutersController, Icons.group, maxLines: 3),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingSchedule ? null : _generateSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              icon: _isGeneratingSchedule
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: const Text('Generate & Publish Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
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
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.purple;
      case 'pitscouter': return AppColors.primary;
      default: return Colors.blue;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin': return Icons.security;
      case 'pitscouter': return Icons.assignment;
      default: return Icons.person;
    }
  }
}