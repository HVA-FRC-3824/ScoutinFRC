import 'dart:developer' as developer;

class DataService {
  static final DataService _instance = DataService._internal();

  factory DataService() {
    return _instance;
  }

  DataService._internal();

  Future<void> submitMatchData(Map<String, dynamic> data) async {
    developer.log('DataService: Submitting match data: $data');
    await Future.delayed(const Duration(milliseconds: 500)); 
  }

  Future<void> submitPitScoutingData(Map<String, dynamic> data) async {
    developer.log('DataService: Submitting pit scouting data: $data');
    await Future.delayed(const Duration(milliseconds: 500)); 
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
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
    
    // Generate deterministic "random" stats based on team number
    int seed = int.tryParse(teamNumber) ?? 0;
    double auto = (seed % 20) + 10.0; // 10-30
    double teleop = (seed % 40) + 20.0; // 20-60
    double endgame = (seed % 15) + 5.0; // 5-20
    double defense = (seed % 10) / 2.0; // 0-5 rating
    
    return {
      'auto': auto,
      'teleop': teleop,
      'endgame': endgame,
      'defense': defense,
    };
  }

  Future<Map<String, dynamic>> getMatchPredictions(List<String> redTeams, List<String> blueTeams) async {
    developer.log('DataService: Predicting match outcome');
    await Future.delayed(const Duration(milliseconds: 1000));

    double redScore = 0;
    double blueScore = 0;

    for (var team in redTeams) {
      var stats = await getAverageStats(team);
      redScore += stats['auto']! + stats['teleop']! + stats['endgame']!;
    }

    for (var team in blueTeams) {
      var stats = await getAverageStats(team);
      blueScore += stats['auto']! + stats['teleop']! + stats['endgame']!;
    }

    // Add some variance
    redScore *= 1.1; 
    blueScore *= 0.95;

    return {
      'redScore': redScore.round(),
      'blueScore': blueScore.round(),
      'winProbability': (redScore / (redScore + blueScore) * 100).toStringAsFixed(1),
    };
  }
}
