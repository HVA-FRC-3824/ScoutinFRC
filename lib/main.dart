// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, unused_import, prefer_const_constructors

// Imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'navbar.dart';
import 'variables.dart' as v;
import 'firebase_options.dart';
import 'auth_gate.dart' as auth;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scouting.dart' as scouting;
import 'pitscout.dart' as pitscout;
import 'admin.dart' as admin;
import 'analytics.dart' as analytics;
import 'schedule.dart' as schedule;
import 'package:shared_preferences/shared_preferences.dart';

// Firebase Initialization
Future<void> firebaseInit() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

// App Entry Point
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await firebaseInit();
  if (const bool.fromEnvironment('USE_EMULATOR', defaultValue: false)) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  runApp(const ScoutingApp());
}

// Main App Widget
class ScoutingApp extends StatelessWidget {
  const ScoutingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const auth.AuthGate(actions: []),
      debugShowCheckedModeBanner: false,
      title: 'Scouting',
      routes: <String, WidgetBuilder>{
        '/home': (context) => const HomePage(title: ''),
        '/admin': (context) => const admin.AdminPage(title: ''),
        '/scouting': (context) => const scouting.ScoutingPage(title: '',),
        '/auto': (context) => const scouting.AutoPage(title: ''),
        '/teleop': (context) => const scouting.TeleopPage(title: ''),
        '/endgame': (context) => const scouting.EndgamePage(title: ''),
        '/analytics': (context) => const analytics.AnalyticsPage(title: ''),
        '/autostart': (context) => const scouting.AutoStartPage(title: ''),
        '/pitscouting': (context) => const pitscout.PitScoutingPage(title: ''),
        '/schedule': (context) => const schedule.SchedulePage(title: ''),
      },
      theme: ThemeData(
        primaryColor: Colors.white,
        primaryTextTheme: const TextTheme(),
        colorScheme: Theme.of(context).colorScheme.copyWith(),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(),
          bodyMedium: TextStyle(),
          bodySmall: TextStyle(),
          displayLarge: TextStyle(),
          displayMedium: TextStyle(),
          displaySmall: TextStyle(),
          headlineLarge: TextStyle(),
          headlineMedium: TextStyle(),
          headlineSmall: TextStyle(),
          titleLarge: TextStyle(),
          titleMedium: TextStyle(),
          titleSmall: TextStyle(),
          labelLarge: TextStyle(),
          labelMedium: TextStyle(),
          labelSmall: TextStyle(),
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color.fromRGBO(65, 68, 73, 1),
        useMaterial3: true,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _scale = 1.0;
  final String _correctPassword = "itsnotpassword";
  List<dynamic> rankings = [];
  String _username = "Loading...";
  String _role = "";
  String _currentEventKey = "2025alhu"; // Default event key

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadEventKey();
  }

  // Load saved event key from SharedPreferences
  Future<void> _loadEventKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEventKey = prefs.getString('eventKey');
      if (savedEventKey != null && savedEventKey.isNotEmpty) {
        setState(() {
          _currentEventKey = savedEventKey;
        });
      }
      // After loading the event key, fetch data
      fetchRankings();
      fetchUserDetails();
    } catch (e) {
      print('Error loading event key: $e');
      // If there's an error, still try to fetch data with default key
      fetchRankings();
      fetchUserDetails();
    }
  }

  // Refresh data when event key is updated
  void _refreshData() {
    _loadEventKey();
  }

  Future<void> fetchRankings() async {
    final eventCode = _currentEventKey;
    const String apiKey = 'XKgCGALe7EzYqZUeKKONsQ45iGHVUZYlN0F6qQzchKQrLxED5DFWrYi9pcjxIzGY';

    try {
      final response = await http.get(
        Uri.parse('https://www.thebluealliance.com/api/v3/event/$eventCode/rankings'),
        headers: {
          'X-TBA-Auth-Key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            rankings = data['rankings'] ?? [];
          });
        }
      } else {
        throw Exception('Failed to load rankings: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching rankings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load rankings for event $eventCode. Error: $e"),
          ),
        );
        // Reset rankings to empty if there was an error
        setState(() {
          rankings = [];
        });
      }
    }
  }

  Future<void> fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _username = doc['username'] ?? "Unknown User";
            _role = doc['role'] ?? "";
          });
        }
      } catch (e) {
        print("Error getting user details: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to update user details."),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavBar(onEventKeyUpdated: _refreshData),
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
        backgroundColor: const Color.fromRGBO(65, 68, 73, 1),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/images/rohawktics.png',
              width: 75,
              height: 75,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _username,
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Event: $_currentEventKey',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Container(
        color: const Color.fromRGBO(65, 68, 73, 1),
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              fetchRankings(),
              fetchUserDetails(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: <Widget>[
              const Gap(20),
              Center(child: _buildButton("Scouting", "/scouting", Icons.search, const Color.fromARGB(255, 190, 63, 63), const Color.fromARGB(255, 181, 8, 8))),
              Center(child: _buildButton("Analytics", "/analytics", Icons.analytics, const Color.fromARGB(255, 0, 72, 255), const Color.fromARGB(255, 8, 11, 181))),
              Center(child: _buildButton("Schedule", "/schedule", Icons.schedule, const Color.fromARGB(255, 156, 33, 217), const Color.fromARGB(255, 123, 8, 181))),
              if (_role == 'pitscouter' || _role == 'admin')
                Center(child: _buildButton("Pit Scouting", "/pitscouting", Icons.checklist, const Color.fromARGB(255, 85, 152, 56), const Color.fromARGB(255, 39, 87, 38))),
              if (_role == 'admin')
                Center(child: _buildButton("Admin", "/admin", Icons.admin_panel_settings, const Color.fromARGB(255, 255, 193, 7), const Color.fromARGB(255, 255, 160, 0))),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 350,
                  height: 500,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(75, 79, 85, 1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 5,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          'Rankings for Event: $_currentEventKey',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: rankings.isNotEmpty
                            ? ListView.builder(
                                shrinkWrap: true,
                                itemCount: rankings.length,
                                itemBuilder: (context, index) {
                                  final ranking = rankings[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.grey,
                                      child: Text('${ranking['rank']}'),
                                    ),
                                    title: Text(
                                      'Team ${ranking['team_key'].substring(3)}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      'W: ${ranking['record']['wins']} | L: ${ranking['record']['losses']} | T: ${ranking['record']['ties']}',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      'Loading rankings for $_currentEventKey...',
                                      style: TextStyle(color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String label, String route, IconData icon, Color backgroundColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (_) => setState(() => _scale = 1.05),
        onExit: (_) => setState(() => _scale = 1.0),
        child: GestureDetector(
          onTap: () {
            if (label == "Pit Scouting") {
              _showPasswordDialog(context, route);
            } else {
              Navigator.pushNamed(context, route);
            }
          },
          child: Transform.scale(
            scale: _scale,
            child: SizedBox(
              width: 300,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 70,
                    width: 300,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 4,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 5,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 45),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: borderColor,
                          width: 4,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 15,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPasswordDialog(BuildContext context, String route) {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text(
            "Enter Password",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Password",
              hintStyle: TextStyle(color: Colors.white70),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("OK", style: TextStyle(color: Colors.white)),
              onPressed: () {
                if (passwordController.text == _correctPassword) {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, route);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Incorrect Password"),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}