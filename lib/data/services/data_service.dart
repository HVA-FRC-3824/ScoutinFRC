import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataService {
  static final DataService _instance = DataService._internal();

  factory DataService() {
    return _instance;
  }

  DataService._internal();

  Future<void> submitMatchData(Map<String, dynamic> data) async {
    developer.log('DataService: Submitting match data: $data');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to submit data');
    }

    final dataToSubmit = {
      ...data,
      'scouterName': data['matchInfo']['scouterName'] ?? 'Unknown',
      'scouterId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'submittedAt': DateTime.now().toIso8601String(),
    };

    await FirebaseFirestore.instance.collection('match_scouting').add(dataToSubmit);
    developer.log('DataService: Match data submitted successfully');
  }

  Future<void> submitPitScoutingData(Map<String, dynamic> data) async {
    developer.log('DataService: Submitting pit scouting data: $data');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to submit data');
    }

    final dataToSubmit = {
      ...data,
      'scouterId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'submittedAt': DateTime.now().toIso8601String(),
    };

    await FirebaseFirestore.instance.collection('pit_scouting').add(dataToSubmit);
    developer.log('DataService: Pit data submitted successfully');
  }

  Future<List<Map<String, dynamic>>> getMatchesForEvent(String eventKey) async {
    developer.log('DataService: Fetching matches for event $eventKey');
    return [];
  }

  Future<List<Map<String, dynamic>>> getTeamData(String eventKey, String teamNumber) async {
    developer.log('DataService: Fetching data for team $teamNumber at event $eventKey');
    return [];
  }
  Future<Map<String, double>> getAverageStats(String teamNumber) async {
    developer.log('DataService: Fetching average stats for team $teamNumber');
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('match_scouting')
          .where('matchInfo.teamNumber', isEqualTo: teamNumber)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'auto': 0.0,
          'teleop': 0.0,
          'endgame': 0.0,
          'defense': 0.0,
        };
      }

      double totalAuto = 0;
      double totalTeleop = 0;
      double totalEndgame = 0;
      double totalDefense = 0;
      int count = querySnapshot.docs.length;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        totalAuto += (data['auto']['fuel'] ?? 0) * 1.0; 
        // Auto LEAVE points could be added here (e.g. +3), assuming fuel is just count
        if (data['auto']['moved'] == true) totalAuto += 3;
        if (data['auto']['l1Climb'] == true) totalAuto += 6; // Example point value

        totalTeleop += (data['teleop']['fuel'] ?? 0) * 1.0;
        totalDefense += (data['teleop']['defense'] ?? 0) * 1.0;

        // Endgame scoring
        String hang = data['endgame']['hang'] ?? 'None';
        if (hang == 'L1') totalEndgame += 6;
        else if (hang == 'L2') totalEndgame += 10;
        else if (hang == 'L3') totalEndgame += 15;
      }

      return {
        'auto': totalAuto / count,
        'teleop': totalTeleop / count,
        'endgame': totalEndgame / count,
        'defense': totalDefense / count,
      };
    } catch (e) {
      developer.log('Error fetching stats: $e');
      return {
        'auto': 0.0,
        'teleop': 0.0,
        'endgame': 0.0,
        'defense': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> getMatchPredictions(List<String> redTeams, List<String> blueTeams) async {
    developer.log('DataService: Predicting match outcome');

    double redScore = 0;
    double blueScore = 0;

    for (var team in redTeams) {
      if (team.isNotEmpty) {
        var stats = await getAverageStats(team);
        redScore += stats['auto']! + stats['teleop']! + stats['endgame']!;
      }
    }

    for (var team in blueTeams) {
      if (team.isNotEmpty) {
        var stats = await getAverageStats(team);
        blueScore += stats['auto']! + stats['teleop']! + stats['endgame']!;
      }
    }

    // Simple win probability based on score ratio
    double totalScore = redScore + blueScore;
    String winProbability = '50.0';
    if (totalScore > 0) {
      winProbability = (redScore / totalScore * 100).toStringAsFixed(1);
    }

    return {
      'redScore': redScore.round(),
      'blueScore': blueScore.round(),
      'winProbability': winProbability,
    };
  }
}
