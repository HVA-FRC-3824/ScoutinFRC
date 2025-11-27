import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import 'match_scouting_form.dart';

class MatchSelectionPage extends StatefulWidget {
  const MatchSelectionPage({super.key});

  @override
  State<MatchSelectionPage> createState() => _MatchSelectionPageState();
}

class _MatchSelectionPageState extends State<MatchSelectionPage> {
  final TextEditingController _eventCodeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<dynamic> _matches = [];
  Map<String, String> _assignments = {}; 
  bool _isLoading = false;
  bool _hasSearched = false;

  Future<void> _fetchMatchesAndAssignments() async {
    if (_eventCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Event Code')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _matches = [];
      _assignments = {};
    });

    try {
      final response = await http.get(
        Uri.parse('https://www.thebluealliance.com/api/v3/event/${_eventCodeController.text}/matches/simple'),
        headers: {'X-TBA-Auth-Key': 'XKgCGALe7EzYqZUeKKONsQ45iGHVUZYlN0F6qQzchKQrLxED5DFWrYi9pcjxIzGY'},
      );

      if (response.statusCode == 200) {
        List<dynamic> allMatches = jsonDecode(response.body);
        _matches = allMatches
            .where((match) => match['comp_level'] == 'qm')
            .toList()
          ..sort((a, b) => (a['match_number'] as int).compareTo(b['match_number'] as int));
      } else {
        throw Exception('Failed to load matches from TBA');
      }

      final snapshot = await _firestore
          .collection('scouting_assignments')
          .where('eventCode', isEqualTo: _eventCodeController.text)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final key = '${data['matchNumber']}_${data['teamNumber']}';
        _assignments[key] = data['scouterName'] ?? 'Unknown';
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToScoutingForm(int matchNumber, String teamNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchScoutingForm(
          eventKey: _eventCodeController.text,
          matchNumber: matchNumber,
          teamNumber: teamNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Select Match', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _matches.isEmpty && _hasSearched
                    ? const Center(child: Text('No matches found.', style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _matches.length,
                        itemBuilder: (context, index) => _buildMatchCard(_matches[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _eventCodeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Event Code (e.g. 2024txwac)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _fetchMatchesAndAssignments,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(dynamic match) {
    final matchNumber = match['match_number'];
    final redTeams = List<String>.from(match['alliances']['red']['team_keys']);
    final blueTeams = List<String>.from(match['alliances']['blue']['team_keys']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text(
              'Qual Match $matchNumber',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: _buildAllianceColumn('Red', redTeams, Colors.redAccent, matchNumber)),
                const SizedBox(width: 12),
                Expanded(child: _buildAllianceColumn('Blue', blueTeams, Colors.blueAccent, matchNumber)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllianceColumn(String allianceName, List<String> teamKeys, Color color, int matchNumber) {
    return Column(
      children: teamKeys.map((teamKey) {
        final teamNumber = teamKey.replaceAll('frc', '');
        final assignmentKey = '${matchNumber}_$teamNumber';
        final scouterName = _assignments[assignmentKey];

        return GestureDetector(
          onTap: () => _navigateToScoutingForm(matchNumber, teamNumber),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  teamNumber,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (scouterName != null)
                  Text(
                    scouterName,
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
