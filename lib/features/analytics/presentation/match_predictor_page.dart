import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/data_service.dart';

class MatchPredictorPage extends StatefulWidget {
  const MatchPredictorPage({super.key});

  @override
  State<MatchPredictorPage> createState() => _MatchPredictorPageState();
}

class _MatchPredictorPageState extends State<MatchPredictorPage> {
  final List<TextEditingController> _redControllers = List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> _blueControllers = List.generate(3, (_) => TextEditingController());
  final DataService _dataService = DataService();

  bool _isLoading = false;
  Map<String, dynamic>? _prediction;

  @override
  void dispose() {
    for (var c in _redControllers) {
      c.dispose();
    }
    for (var c in _blueControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _predictMatch() async {
    // Validate inputs
    final redTeams = _redControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();
    final blueTeams = _blueControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();

    if (redTeams.length != 3 || blueTeams.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 6 team numbers')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _prediction = null;
    });

    try {
      final result = await _dataService.getMatchPredictions(redTeams, blueTeams);
      setState(() {
        _prediction = result;
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
        title: const Text('Match Predictor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildAllianceInput('Red Alliance', Colors.red, _redControllers)),
                const SizedBox(width: 16),
                Expanded(child: _buildAllianceInput('Blue Alliance', Colors.blue, _blueControllers)),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _predictMatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('PREDICT OUTCOME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 32),
            if (_prediction != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllianceInput(String title, Color color, List<TextEditingController> controllers) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: controllers[index],
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Team ${index + 1}',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final redScore = _prediction!['redScore'];
    final blueScore = _prediction!['blueScore'];
    final winProb = double.parse(_prediction!['winProbability']);
    final winner = redScore > blueScore ? 'Red' : 'Blue';
    final winnerColor = redScore > blueScore ? Colors.red : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [winnerColor.withOpacity(0.2), AppColors.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: winnerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: winnerColor.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$winner Wins!',
            style: TextStyle(color: winnerColor, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Win Probability: ${winner == 'Red' ? winProb : (100 - winProb).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreColumn('Red', redScore.toString(), Colors.red),
              const Text('vs', style: TextStyle(color: Colors.white38, fontSize: 20)),
              _buildScoreColumn('Blue', blueScore.toString(), Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(String label, String score, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          score,
          style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
