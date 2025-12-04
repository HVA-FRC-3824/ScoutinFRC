
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../scouting/presentation/scouting_dashboard.dart';
import '../../analytics/presentation/analytics_dashboard.dart';
import '../../schedule/presentation/schedule_page.dart';
import '../../admin/presentation/admin_page.dart' as admin_page;
import '../../auth/presentation/account_settings_page.dart';
import '../../scouting/presentation/match_selection_page.dart';
import 'widgets/side_menu.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onDestinationSelected(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AccountSettingsPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: SideMenu(
        selectedIndex: -1, 
        onDestinationSelected: _onDestinationSelected,
      ),
      body: HomeDashboardView(
        onTabChange: (index) {
          Widget page;
          switch (index) {
            case 1:
              page = const ScoutingDashboard();
              break;
            case 2:
              page = const AnalyticsDashboard();
              break;
            case 3:
              page = const SchedulePage();
              break;
            case 4:
              page = const admin_page.AdminPage();
              break;
            case 5:
              page = const MatchSelectionPage();
              break;
            default:
              return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
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

  Future<Map<String, dynamic>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data() ?? {};
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          final userData = snapshot.data ?? {};
          final role = userData['role'] ?? 'user';
          final username = userData['username'] ?? 'Scouter';
          final photoURL = userData['photoURL'];

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, username, photoURL),
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
                        _buildActionLayout(context, role),
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
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String username, String? photoURL) {
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: photoURL != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: photoURL,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                            errorWidget: (context, url, error) => const Icon(Icons.person, color: AppColors.primary),
                          ),
                        )
                      : const Icon(Icons.person, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionLayout(BuildContext context, String role) {
    final bool isAdmin = role == 'admin';
    final bool canPitScout = role == 'admin' || role == 'pitscouter';

    // Scouting Button Logic
    final VoidCallback onScoutingTap = canPitScout
        ? () => onTabChange(1) // Go to Dashboard
        : () => onTabChange(5); // Go directly to Match Selection

    final scoutingCard = _buildActionCard(
      context,
      'Scouting',
      'Collect match data',
      Icons.sports_esports,
      AppColors.primary,
      onScoutingTap,
    );

    final analyticsCard = _buildActionCard(
      context,
      'Analytics',
      'View team stats',
      Icons.analytics,
      AppColors.tertiary,
      () => onTabChange(2),
    );

    final scheduleCard = _buildActionCard(
      context,
      'Schedule',
      'Upcoming matches',
      Icons.calendar_today,
      AppColors.secondary,
      () => onTabChange(3),
    );

    if (isAdmin) {
      final adminCard = _buildActionCard(
        context,
        'Admin',
        'Manage app settings',
        Icons.admin_panel_settings,
        Colors.purple,
        () => onTabChange(4),
      );

      return Column(
        children: [
          Row(
            children: [
              Expanded(child: scoutingCard),
              const SizedBox(width: 15),
              Expanded(child: analyticsCard),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: scheduleCard),
              const SizedBox(width: 15),
              Expanded(child: adminCard),
            ],
          ),
        ],
      );
    } else {
      // Non-admin layout: Scouting & Analytics on top, Schedule centered below
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: scoutingCard),
              const SizedBox(width: 15),
              Expanded(child: analyticsCard),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Spacer(), // Push to center
              Expanded(flex: 2, child: scheduleCard), // Make it wider or standard size? 
              // If we want it same size as others but centered, we need constraints.
              // Let's try making it span full width or just centered with same width.
              // User asked for "centered". 
              // A full width button might look nice. Let's try keeping aspect ratio similar.
              // Actually, Expanded flex 2 with spacers might work, or just a Center widget with fixed width?
              // Responsive is better. Let's use a Row with Spacers to center a fixed-ish width or percentage.
              // Or simply:
              // Expanded(child: scheduleCard) would make it full width.
              // Let's make it full width? "Centered" usually implies position. 
              // If I make it full width, it is technically centered.
              // But maybe they want it to look like a grid item but in the middle.
              // Let's try 50% width centered.
              const Spacer(),
            ],
          ),
        ],
      );
    }
  }
  
  // Helper to build the card (same as before, just ensuring it fits)
  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 140, // Fixed height to ensure uniformity in Rows
      child: Material(
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
