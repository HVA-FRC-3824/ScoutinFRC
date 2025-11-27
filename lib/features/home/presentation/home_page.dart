// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../scouting/presentation/scouting_dashboard.dart';
import '../../analytics/presentation/analytics_dashboard.dart';
import '../../schedule/presentation/schedule_page.dart';
import '../../admin/presentation/admin_page.dart';
import '../../auth/presentation/account_settings_page.dart';
import 'widgets/side_menu.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      HomeDashboardView(
        onTabChange: (index) => _onTabChange(index),
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      ScoutingDashboard(onMenuPressed: () => _scaffoldKey.currentState?.openDrawer()),
      AnalyticsDashboard(onMenuPressed: () => _scaffoldKey.currentState?.openDrawer()),
      SchedulePage(onMenuPressed: () => _scaffoldKey.currentState?.openDrawer()),
      AdminPage(onMenuPressed: () => _scaffoldKey.currentState?.openDrawer()),
      AccountSettingsPage(onMenuPressed: () => _scaffoldKey.currentState?.openDrawer()),
    ]);
  }

  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: SideMenu(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabChange,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
    );
  }
}

class HomeDashboardView extends StatelessWidget {
  final Function(int) onTabChange;
  final VoidCallback onMenuPressed;
  
  const HomeDashboardView({
    super.key, 
    required this.onTabChange,
    required this.onMenuPressed,
  });

  Future<String> _getUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data()?['username'] ?? 'Scouter';
    }
    return 'Scouter';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QUICK ACTIONS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildActionGrid(context),
                    const SizedBox(height: 30),
                    const Text(
                      'RECENT ACTIVITY',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildRecentActivityList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceHighlight)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.primary),
            onPressed: onMenuPressed,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                FutureBuilder<String>(
                  future: _getUsername(),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Loading...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.1,
      children: [
        _buildActionCard(
          context,
          'Scouting',
          'Collect match data',
          Icons.sports_esports,
          AppColors.primary,
          () => onTabChange(1), // Switch to Scouting Tab
        ),
        _buildActionCard(
          context,
          'Analytics',
          'View team stats',
          Icons.analytics,
          AppColors.tertiary,
          () => onTabChange(2), // Switch to Analytics Tab
        ),
        _buildActionCard(
          context,
          'Schedule',
          'Upcoming matches',
          Icons.calendar_today,
          AppColors.secondary,
          () => onTabChange(3), // Switch to Schedule Tab
        ),
        _buildActionCard(
          context,
          'Admin',
          'Manage app settings',
          Icons.admin_panel_settings,
          Colors.purple,
          () => onTabChange(4), // Switch to Admin Tab
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        children: [
          _buildActivityItem('Match 42 - Team 254', 'Submitted 5 mins ago', Icons.check_circle, AppColors.success),
          const Divider(color: AppColors.surfaceHighlight, height: 1),
          _buildActivityItem('Match 41 - Team 118', 'Submitted 15 mins ago', Icons.check_circle, AppColors.success),
          const Divider(color: AppColors.surfaceHighlight, height: 1),
          _buildActivityItem('Pit Scout - Team 1678', 'Draft saved', Icons.save, AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color iconColor) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
