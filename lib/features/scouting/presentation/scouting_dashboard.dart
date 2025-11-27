import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'match_scouting_form.dart';

class ScoutingDashboard extends StatelessWidget {
  final VoidCallback? onMenuPressed;

  const ScoutingDashboard({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scouting Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: onMenuPressed != null 
            ? IconButton(icon: const Icon(Icons.menu, color: AppColors.primary), onPressed: onMenuPressed)
            : null, // Default back button if null, or nothing
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildOptionCard(
              context,
              'Match Scouting',
              Icons.sports_esports,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MatchScoutingForm()),
                );
              },
            ),
            _buildOptionCard(
              context,
              'Pit Scouting',
              Icons.assignment,
              Colors.orange,
              () {
                // Navigate to Pit Scouting Form
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
