// ignore_for_file: unused_import, depend_on_referenced_packages, library_private_types_in_public_api

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class TeamComparisonScreen extends StatefulWidget {
  const TeamComparisonScreen({super.key});

  @override
  _TeamComparisonScreenState createState() => _TeamComparisonScreenState();
}

class _TeamComparisonScreenState extends State<TeamComparisonScreen> {
  final String _baseUrl = 'https://www.thebluealliance.com/api/v3';
  final String _authKey = 'XKgCGALe7EzYqZUeKKONsQ45iGHVUZYlN0F6qQzchKQrLxED5DFWrYi9pcjxIzGY'; 
  final TextEditingController _team1Controller = TextEditingController();
  final TextEditingController _team2Controller = TextEditingController();

  Map<String, dynamic>? _team1Data;
  Map<String, dynamic>? _team2Data;
  List<dynamic>? _team1Events;
  List<dynamic>? _team2Events;
  List<dynamic>? _team1Media;
  List<dynamic>? _team2Media;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(
                Icons.menu,
                color: Color.fromRGBO(165, 176, 168, 1),
                size: 50,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Color.fromRGBO(165, 176, 168, 1),
              size: 50,
            ),
          )
        ],
        backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
        title: Image.asset(
          'assets/images/rohawktics.png',
          width: 75,
          height: 75,
          alignment: Alignment.center,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
  controller: _team1Controller,
  style: const TextStyle(color: Colors.white), 
  decoration: const InputDecoration(
    labelText: 'Enter Team 1 Number (e.g. 3824)',
    labelStyle: TextStyle(color: Colors.white), 
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white), 
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white, width: 2), 
    ),
    border: OutlineInputBorder(), 
  ),
),
const SizedBox(height: 10),


TextField(
  controller: _team2Controller,
  style: const TextStyle(color: Colors.white), 
  decoration: const InputDecoration(
    labelText: 'Enter Team 2 Number (e.g. 3140)',
    labelStyle: TextStyle(color: Colors.white), 
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white), 
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white, width: 2), 
    ),
    border: OutlineInputBorder(), 
  ),
),

            const SizedBox(height: 20),
            
            
            Center(child: ElevatedButton(
  onPressed: _compareTeams,
  style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white, backgroundColor: Colors.grey[800], 
    side: BorderSide(
      color: Colors.grey[900]!, 
      width: 2, 
      
    ),
  ),
  child: const Text('Compare Teams'),

),
            ),

            const SizedBox(height: 20),
            
           
            Expanded(
              child: _team1Data == null || _team2Data == null
                  ? const Center(child: Text('Enter team numbers and press "Compare Teams"'))
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          
                          _buildTeamSection(_team1Data, _team1Media, _team1Events, 'Team 1'),

                          const SizedBox(height: 30),

                          
                          _buildTeamSection(_team2Data, _team2Media, _team2Events, 'Team 2'),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

void _compareTeams() async {
  final team1Key = 'frc${_team1Controller.text.trim()}';
  final team2Key = 'frc${_team2Controller.text.trim()}';

  if (team1Key.isNotEmpty && team2Key.isNotEmpty) {
    try {
      var team1Data = await _getTeamData(team1Key);
      var team2Data = await _getTeamData(team2Key);

      var team1Events = await _getTeamEvents(team1Key, 2024);
      var team2Events = await _getTeamEvents(team2Key, 2024);

      var team1Media = await _getTeamMedia(team1Key, 2024);  
      var team2Media = await _getTeamMedia(team2Key, 2024);  

      
      setState(() {
        _team1Data = team1Data;
        _team2Data = team2Data;
        _team1Events = team1Events;
        _team2Events = team2Events;
        _team1Media = team1Media;  
        _team2Media = team2Media;  
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }
}

Future<Map<String, dynamic>> _getTeamData(String teamKey) async {
  final response = await http.get(
    Uri.parse('$_baseUrl/team/$teamKey'),
    headers: {'X-TBA-Auth-Key': _authKey},
  );


  print('Team data response status: ${response.statusCode}');
  print('Team data response body: ${response.body}');

  if (response.statusCode == 200) {
    var data = json.decode(response.body);

    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is List) {
  
      print('Error: Received a List instead of a Map.');
      throw Exception('Expected Map but received List for team data.');
    } else {

      print('Error: Received an unexpected type: ${data.runtimeType}');
      throw Exception('Unexpected response type.');
    }
  } else {
    print('Failed to load team data with status code ${response.statusCode}');
    throw Exception('Failed to load team data for $teamKey');
  }
}



  Future<List<dynamic>> _getTeamEvents(String teamKey, int year) async {
  final response = await http.get(
    Uri.parse('$_baseUrl/team/$teamKey/events/$year'),
    headers: {'X-TBA-Auth-Key': _authKey},
  );


  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');

  if (response.statusCode == 200) {
    var data = json.decode(response.body);

  
    if (data is List) {
      return data;
    } else {
      return [];
    }
  } else {
    print('Failed to load events: ${response.body}');
    throw Exception('Failed to load events for team $teamKey');
  }
}


Future<List<dynamic>> _getTeamMedia(String teamKey, int year) async {
  final response = await http.get(
    Uri.parse('$_baseUrl/team/$teamKey/media/$year'),
    headers: {'X-TBA-Auth-Key': _authKey},
  );


  print('Media data response status: ${response.statusCode}');
  print('Media data response body: ${response.body}');

  if (response.statusCode == 200) {
    var data = json.decode(response.body);


    if (data is List) {
      return data;
    } else {

      print('Unexpected media data type: ${data.runtimeType}');
      throw Exception('Expected a List but received something else.');
    }
  } else {
    print('Failed to load media for team $teamKey');
    throw Exception('Failed to load media for team $teamKey');
  }
}

Widget _buildTeamSection(
    Map<String, dynamic>? teamData, List<dynamic>? teamMedia, List<dynamic>? events, String label) {
  if (teamData == null) {
    return Text(
      'No data available for $label',
      style: const TextStyle(color: Colors.white), 
    );
  }

  events?.sort((a, b) {
    DateTime dateA = DateTime.parse(a['start_date']);
    DateTime dateB = DateTime.parse(b['start_date']);
    return dateA.compareTo(dateB);
  });

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$label: ${teamData['team_number']} - ${teamData['nickname']}',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      Text(
        'Rookie Year: ${teamData['rookie_year']}',
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
      const SizedBox(height: 10),

      if (teamMedia != null && teamMedia.isNotEmpty)
        CachedNetworkImage(
          imageUrl: '${teamMedia.firstWhere(
            (media) => media['type'] == 'imgur', 
            orElse: () => null
          )?['direct_url'] ?? ''}.png',
          height: 200,
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        )
      else
        const Text(
          'No robot image available.',
          style: TextStyle(color: Colors.white), 
        ),
      const SizedBox(height: 10),

      // Events
      const Text(
        'Events:',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      Column(
        children: events!.map((event) {
          return ListTile(
            title: Text(
              event['name'],
              style: const TextStyle(color: Colors.white), 
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location: ${event['city']}, ${event['country']}',
                  style: const TextStyle(color: Colors.white), 
                ),
                Text(
                  'Start Date: ${event['start_date']}',
                  style: const TextStyle(color: Colors.white), 
                ),
                 Text(
                  'Wins: ${event['wins']}',
                  style: const TextStyle(color: Colors.white), 
                ),
                Text(
                  'Losses: ${event['losses']}',
                  style: const TextStyle(color: Colors.white), 
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ],
  );
}
}

