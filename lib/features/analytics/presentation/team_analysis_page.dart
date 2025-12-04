import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/data_service.dart';

class TeamAnalysisPage extends StatefulWidget {
  const TeamAnalysisPage({super.key});

  @override
  State<TeamAnalysisPage> createState() => _TeamAnalysisPageState();
}

class _TeamAnalysisPageState extends State<TeamAnalysisPage> {
  final TextEditingController _searchController = TextEditingController();
  final DataService _dataService = DataService();
  
  String? _currentTeam;
  Map<String, double>? _stats;
  bool _isLoading = false;

  Future<void> _fetchStats() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _currentTeam = _searchController.text;
    });

    try {
      final stats = await _dataService.getAverageStats(_currentTeam!);
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Team Analysis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (_stats != null)
              _buildAnalysisContent()
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Enter Team Number (e.g. 254)',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
            onPressed: _fetchStats,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: (_) => _fetchStats(),
      ),
    );
  }

  Widget _buildAnalysisContent() {
    return Column(
      children: [
        Text(
          'Team $_currentTeam',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Performance Profile',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 300,
          child: RadarChart(
            RadarChartData(
              dataSets: [
                RadarDataSet(
                  fillColor: AppColors.primary.withOpacity(0.2),
                  borderColor: AppColors.primary,
                  entryRadius: 3,
                  dataEntries: [
                    RadarEntry(value: _stats!['auto']!),
                    RadarEntry(value: _stats!['teleop']!),
                    RadarEntry(value: _stats!['endgame']!),
                    RadarEntry(value: _stats!['defense']! * 10), // Scale defense to match others
                  ],
                  borderWidth: 3,
                ),
              ],
              radarBackgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              radarBorderData: const BorderSide(color: AppColors.surfaceHighlight),
              titlePositionPercentageOffset: 0.2,
              titleTextStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              getTitle: (index, angle) {
                switch (index) {
                  case 0: return RadarChartTitle(text: 'Auto');
                  case 1: return RadarChartTitle(text: 'Teleop');
                  case 2: return RadarChartTitle(text: 'Endgame');
                  case 3: return RadarChartTitle(text: 'Defense');
                  default: return const RadarChartTitle(text: '');
                }
              },
              tickCount: 1,
              ticksTextStyle: const TextStyle(color: Colors.transparent),
              gridBorderData: const BorderSide(color: AppColors.surfaceHighlight, width: 1),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildStatGrid(),
      ],
    );
  }

  Widget _buildStatGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Auto Avg', _stats!['auto']!.toStringAsFixed(1), Icons.flash_on, Colors.yellow),
        _buildStatCard('Teleop Avg', _stats!['teleop']!.toStringAsFixed(1), Icons.videogame_asset, Colors.blue),
        _buildStatCard('Endgame Avg', _stats!['endgame']!.toStringAsFixed(1), Icons.flag, Colors.green),
        _buildStatCard('Defense Rating', _stats!['defense']!.toStringAsFixed(1), Icons.shield, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: AppColors.textDisabled),
          SizedBox(height: 16),
          Text(
            'Search for a team to see their stats',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
