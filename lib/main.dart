// ignore_for_file: avoid_unnecessary_containers, avoid_print, unused_import, unnecessary_import, prefer_const_constructors
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sp.dart';
import 'package:gap/gap.dart';
import 'variables.dart' as v;
import 'package:flutter/animation.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';

void main() {
  print(v.reorganizePD(v.pageData));
  runApp(const ScoutingApp());
}

class ScoutingApp extends StatelessWidget {
  const ScoutingApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scouting',
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (context) => const HomePage(
              title: '',
            ),
        '/scouting': (context) => const MatchNumPage(
              title: '',
            ),
        '/auto': (context) => const AutoPage(
              title: ''
            ),
        '/teleop': (context) => const TeleopPage(
              title: ''
            ),
        '/endgame': (context) => const EndgamePage(
              title: ''
            ),
        '/schedule': (context) => const SchedulePage(
              title: '',
            ),
        '/analytics': (context) => const AnalyticsPage(
              title: '',
            ),
        '/pitscouting': (context) => const PitScoutingPage(
              title: '',
            ),
        '/sscouting': (context) => const SScoutingPage(
              title: '',
            ),
      },
      theme: ThemeData(
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
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavBar(),
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
        backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
        title: Image.asset(
          'assets/images/rohawktics.png',
          width: 75,
          height: 75,
          alignment: Alignment.center,
        ),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 20,
            ),
        Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            style: BorderStyle.solid,
            color: Color.fromRGBO(1, 1, 1, 0.4),
            width: 5
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(30, 30, 30, 1),
              offset: Offset(6, 6),
              blurRadius: 15,
              spreadRadius: 1,
            )
          ],
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: const [
              Color.fromARGB(255, 190, 63, 63),
              Color.fromARGB(255, 181, 8, 8),
            ],
          ),
        ),
            child: ElevatedButton(
              onPressed: () {
                setPref('qpint', 'oqeihtqoiw', v.pageData);
                Navigator.pushNamed(context, '/scouting');
              },
              style: TextButton.styleFrom(
                elevation: 0,
                shadowColor: const Color.fromRGBO(198, 65, 65, 1),
                textStyle: const TextStyle(fontSize: 40),
                padding: const EdgeInsets.only(
                    left: 14, top: 12, right: 14, bottom: 12),
                backgroundColor: Colors.transparent,
                side: const BorderSide(
                    width: 3, color: Color.fromRGBO(198, 65, 65, 0)),
              ),
              child: const Text(
                "Scouting",
                style: TextStyle(color: Colors.white),
              ).animate().fade(delay: 500.ms),
            ),
        ),
            const SizedBox(
              height: 20,
            ),
        Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            style: BorderStyle.solid,
            color: Color.fromRGBO(1, 1, 1, 0.4),
            width: 5
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(30, 30, 30, 1),
              offset: Offset(6, 6),
              blurRadius: 15,
              spreadRadius: 1,
            )
          ],
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: const [
              Color.fromARGB(255, 0, 72, 255),
              Color.fromARGB(255, 8, 11, 181),
            ],
          ),
        ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/schedule');
              },
              style: TextButton.styleFrom(
                elevation: 00,
                shadowColor: const Color.fromRGBO(65, 104, 196, 1),
                textStyle: const TextStyle(fontSize: 40),
                padding: const EdgeInsets.only(
                    left: 14, top: 12, right: 14, bottom: 12),
                backgroundColor: Colors.transparent,
                side: const BorderSide(
                    width: 3, color: Color.fromRGBO(65, 104, 196, 0)),
              ),
              child: const Text(
                "Schedule",
                style: TextStyle(color: Colors.white),
              ).animate().fade(delay: 700.ms),
            ),
        ),
            const SizedBox(
              height: 20,
            ),
        Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            style: BorderStyle.solid,
            color: Color.fromRGBO(1, 1, 1, 0.4),
            width: 5
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(30, 30, 30, 1),
              offset: Offset(6, 6),
              blurRadius: 15,
              spreadRadius: 1,
            )
          ],
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: const [
              Color.fromARGB(255, 53, 129, 75),
              Color.fromARGB(255, 8, 94, 29),
            ],
          ),
        ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/analytics');
              },
              style: TextButton.styleFrom(
                elevation: 00,
                shadowColor: const Color.fromRGBO(196, 188, 65, 1),
                textStyle: const TextStyle(fontSize: 40),
                padding: const EdgeInsets.only(
                    left: 14, top: 12, right: 14, bottom: 12),
                backgroundColor: Colors.transparent,
                side: const BorderSide(
                    width: 3, color: Color.fromRGBO(196, 188, 65, 0)),
              ),
              child: const Text(
                "Analytics",
                style: TextStyle(color: Colors.white),
              ).animate().fade(delay: 900.ms),
            ),
        ),
            const SizedBox(
              height: 20,
            ),
        Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            style: BorderStyle.solid,
            color: Color.fromRGBO(1, 1, 1, 0.4),
            width: 5
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(30, 30, 30, 1),
              offset: Offset(6, 6),
              blurRadius: 15,
              spreadRadius: 1,
            )
          ],
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: const [
              Color.fromARGB(255, 240, 141, 61),
              Color.fromARGB(255, 255, 115, 0),
            ],
          ),
        ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/pitscouting');
              },
              style: TextButton.styleFrom(
                elevation: 0,
                shadowColor: const Color.fromRGBO(50, 87, 39, 1),
                textStyle: const TextStyle(fontSize: 40),
                padding: const EdgeInsets.only(
                    left: 14, top: 12, right: 14, bottom: 12),
                backgroundColor: Colors.transparent,
                side: const BorderSide(
                    width: 3, color: Color.fromRGBO(50, 87, 39, 0)),
              ),
              child: const Text(
                "Pit Scouting",
                style: TextStyle(color: Colors.white),
              ).animate().fade(delay: 1100.ms),
            ),
        ),
            const SizedBox(
              height: 20,
            ),
        Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            style: BorderStyle.solid,
            color: Color.fromRGBO(1, 1, 1, 0.4),
            width: 5
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(30, 30, 30, 1),
              offset: Offset(6, 6),
              blurRadius: 15,
              spreadRadius: 1,
            )
          ],
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: const [
              Colors.purple,
              Color.fromARGB(255, 87, 0, 154),
            ],
          ),
        ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/sscouting');
              },
              style: TextButton.styleFrom(
                elevation: 0,
                shadowColor: const Color.fromRGBO(157, 90, 38, 1),
                textStyle: const TextStyle(
                  fontSize: 40,
                ),
                padding: const EdgeInsets.only(
                    left: 14, top: 12, right: 14, bottom: 12),
                backgroundColor: Colors.transparent,
                side: const BorderSide(
                    width: 3, color: Color.fromRGBO(157, 90, 38, 0)),
              ),
              child: const Text(
                "Super Scouting",
                style: TextStyle(color: Colors.white),
              ).animate().fade(delay: 1350.ms),
            ),
        ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class MatchNumPage extends StatefulWidget {
  const MatchNumPage({super.key, required this.title});
  final String title;
  @override
  State<MatchNumPage> createState() => _MatchNumPageState();
}

class _MatchNumPageState extends State<MatchNumPage> {
  @override
  Widget build(BuildContext context) {
    TextEditingController matchNum = TextEditingController();
    TextEditingController robotNum = TextEditingController();
    return Scaffold(
        drawer: const NavBar(),
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
            Container(
                child: IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/'),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color.fromRGBO(165, 176, 168, 1),
                      size: 50,
                    )))
          ],
          backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
          title: Image.asset(
            'assets/images/rohawktics.png',
            width: 75,
            height: 75,
            alignment: Alignment.center,
          ),
        ),
        body: Center(
        child: Column(children: <Widget>[
          const Gap(20),
          const Text(
            "Team Number",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          TextField(
            controller: robotNum,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color.fromRGBO(255, 255, 255, 1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0)
                ),
                hintText: 'ex: 3824',
              )
              ),
            const Gap(80),
            const Text(
            "Match Number",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          TextField(
            controller: matchNum,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color.fromRGBO(255, 255, 255, 1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0)
                ),
                hintText: 'ex: 1',
              )
              ),
              const Gap(25),
              ElevatedButton(
              onPressed: () {
                print(robotNum.text);
                print(matchNum.text);
                Navigator.pushNamed(context, '/auto');
              },
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 40,
                ),
                padding: const EdgeInsets.only(
                    left: 14, top: 12, right: 14, bottom: 12),
                backgroundColor: Colors.blue,
                side: const BorderSide(
                    width: 3, color: Color.fromRGBO(65, 104, 196, 1)),
              ), child: const Text("Confirm",
              style: TextStyle(color: Colors.white, fontSize: 25),
              ),
              )
        ]
        )
      )
    );
  }
}

const List<Widget> autoPosition = <Widget>[
  Text('Left'),
  Text('Middle'),
  Text('Right')
];

const List<Widget> autoScoring = <Widget>[
  Text('None'),
  Text('Cargo'),
  Text('Scored')
];

const List<Widget> communityLeave = <Widget>[
  Text('None'),
  Text('Inside'),
  Text('Left')
];



class AutoPage extends StatefulWidget {
  const AutoPage({super.key, required this.title});
  final String title;
  @override
  State<AutoPage> createState() => _AutoPageState();
}
class _AutoPageState extends State<AutoPage> {
  bool toggleButton1 = false;
    final List<bool> selectedStart = <bool>[false, false, false];
    final List<bool> selectedAuto = <bool>[false, false, false];
    final List<bool> selectedEnd = <bool>[false, false, false];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const NavBar(),
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
            Container(
                child: IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/scouting'),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color.fromRGBO(165, 176, 168, 1),
                      size: 50,
                    )))
          ],
          backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
          title: Image.asset(
            'assets/images/rohawktics.png',
            width: 75,
            height: 75,
            alignment: Alignment.center,
          ),
        ),
        body: Center(
        child: Column(children: <Widget>[
          const Gap(20),
          const Text("Starting Position", style: TextStyle(color: Colors.white, fontSize: 25),
          ),
          ToggleButtons(
            onPressed: (int index) {
              setState(() {
                for (int i = 0; i < selectedStart.length; i++) {
                  selectedStart[i] = i == index; //CHECK AND MAKE SURE IT DOES WHAT IT SHOULD
                }
              }
              );
            },
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          selectedBorderColor: const Color.fromRGBO(198, 65, 65, 1), borderWidth: 2.5,
          selectedColor: Colors.black,
          fillColor: Colors.red,
          color: Colors.white,
          constraints: const BoxConstraints(
          minHeight: 40.0,
          minWidth: 80.0,
          ),
          isSelected: selectedStart, // MAKE A NEW ONE OF THESE
           children: autoPosition, //MAKE A NEW ONE OF THESE
         ),
          const Gap(20),
          const Text("Auto Scoring", style: TextStyle(color: Colors.white, fontSize: 25),
          ),
          ToggleButtons(
            onPressed: (int index) {
              setState(() {
                for (int i = 0; i < selectedAuto.length; i++) {
                  selectedAuto[i] = i == index; //CHECK AND MAKE SURE IT DOES WHAT IT SHOULD
                }
              }
              );
            },
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          selectedBorderColor: const Color.fromRGBO(50, 87, 39, 1), borderWidth: 2.5,
          selectedColor: Colors.black,
          fillColor: Colors.green,
          color: Colors.white,
          constraints: const BoxConstraints(
          minHeight: 40.0,
          minWidth: 80.0,
          ),
          isSelected: selectedAuto, // MAKE A NEW ONE OF THESE
           children: autoScoring, //MAKE A NEW ONE OF THESE
         ),
         const Gap(20),
          const Text("Did they leave wing?", style: TextStyle(color: Colors.white, fontSize: 25),
          ),
          ToggleButtons(
            onPressed: (int index) {
              setState(() {
                for (int i = 0; i < selectedEnd.length; i++) {
                  selectedEnd[i] = i == index; //CHECK AND MAKE SURE IT DOES WHAT IT SHOULD
                }
              }
              );
            },
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          selectedBorderColor: const Color.fromRGBO(196, 188, 65, 1), borderWidth: 2.5,
          selectedColor: Colors.black,
          fillColor: Colors.yellow,
          color: Colors.white,
          constraints: const BoxConstraints(
          minHeight: 40.0,
          minWidth: 80.0,
          ),
          isSelected: selectedEnd, // MAKE A NEW ONE OF THESE
           children: communityLeave, //MAKE A NEW ONE OF THESE
         ),
         const Gap(50),
         ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/teleop');
              },
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 40,
                ),
                padding: const EdgeInsets.only(
                    left: 14, top: 12, right: 14, bottom: 12),
                backgroundColor: Colors.blue,
                side: const BorderSide(
                    width: 3, color: Color.fromRGBO(65, 104, 196, 1)),
              ), child: const Text("Confirm",
              style: TextStyle(color: Colors.white, fontSize: 25),
              ),
              )
        ]
        )
      )
    );
  }
}

class TeleopPage extends StatefulWidget {
  const TeleopPage({super.key, required this.title});
  final String title;
  @override
  State<TeleopPage> createState() => _TeleopPageState();
}
class _TeleopPageState extends State<TeleopPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const NavBar(),
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
            Container(
                child: IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/auto'),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color.fromRGBO(165, 176, 168, 1),
                      size: 50,
                    )))
          ],
          backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
          title: Image.asset(
            'assets/images/rohawktics.png',
            width: 75,
            height: 75,
            alignment: Alignment.center,
          ),
        ),
        body: const Center(
        child: Column(children: <Widget>[
          
        ]
      )
    )
   );
  }
}

class EndgamePage extends StatefulWidget {
  const EndgamePage({super.key, required this.title});
  final String title;
  @override
  State<EndgamePage> createState() => _EndgamePageState();
}
class _EndgamePageState extends State<EndgamePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const NavBar(),
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
            Container(
                child: IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/'),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color.fromRGBO(165, 176, 168, 1),
                      size: 50,
                    )))
          ],
          backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
          title: Image.asset(
            'assets/images/rohawktics.png',
            width: 75,
            height: 75,
            alignment: Alignment.center,
          ),
        )
      );
  }
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.title});
  final String title;
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const NavBar(),
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
            Container(
                child: IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/'),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color.fromRGBO(165, 176, 168, 1),
                      size: 50,
                    )))
          ],
          backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
          title: Image.asset(
            'assets/images/rohawktics.png',
            width: 75,
            height: 75,
            alignment: Alignment.center,
          ),
        ),
        body: Center(
            child: Column(children: <Widget>[
          const SizedBox(
            height: 20,
          ),
          Container(
            width: 350,
            height: 125,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(82, 79, 79, 1),
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Container(
            width: 350,
            height: 125,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(82, 79, 79, 1),
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Container(
            width: 350,
            height: 125,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(82, 79, 79, 1),
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Container(
            width: 350,
            height: 125,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(82, 79, 79, 1),
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ]
        )
        )
        );
  }
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key, required this.title});
  final String title;
  @override
  State<AnalyticsPage> createState() => _AnalyticsHomePageState();
}

class _AnalyticsHomePageState extends State<AnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const NavBar(),
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
            Container(
                child: IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/'),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color.fromRGBO(165, 176, 168, 1),
                      size: 50,
                    )))
          ],
          backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
          title: Image.asset(
            'assets/images/rohawktics.png',
            width: 75,
            height: 75,
            alignment: Alignment.center,
          ),
        ),
        body: const Center(child: Column(children: <Widget>[])));
  }
}


class PitScoutingPage extends StatefulWidget {
  const PitScoutingPage({super.key, required this.title});
  final String title;
  @override
  State<PitScoutingPage> createState() => _PitScoutingPageState();
}

class _PitScoutingPageState extends State<PitScoutingPage> {
  @override
  Widget build(BuildContext context) {
    TextEditingController drivetrainText = TextEditingController();
    TextEditingController dimensionText = TextEditingController();
    TextEditingController weightText = TextEditingController();
    TextEditingController mechanismText = TextEditingController();
    return Scaffold(
        drawer: const NavBar(),
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
            Container(
                child: IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/'),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color.fromRGBO(165, 176, 168, 1),
                      size: 50,
                    )))
          ],
          backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
          title: Image.asset(
            'assets/images/rohawktics.png',
            width: 75,
            height: 75,
            alignment: Alignment.center,
          ),
        ),
        body: Center(
        child: Column(children: <Widget>[
          const Gap(20),
          const Text(
            "What is the drive train?",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          TextField(
            controller: drivetrainText,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color.fromRGBO(255, 255, 255, 1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Input answer here',
              )),
          const Gap(20),
          const Text(
            "What is the dimensions of your Robot",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          TextField(
            controller: dimensionText,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color.fromRGBO(255, 255, 255, 1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Input answer here',
              )),
          const Gap(20),
          const Text(
            "What is the weight of your Robot?",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          TextField(
            controller: weightText,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color.fromRGBO(255, 255, 255, 1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Input answer here',
              )),
          const Gap(20),
          const Text(
            "How did you create your grabber/shooter",
            style: TextStyle(color: Colors.white, fontSize: 19),
          ),
          TextField(
            controller: mechanismText,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color.fromRGBO(255, 255, 255, 1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Input answer here',
              )
              ),
              const Gap(20),
              ElevatedButton(
              onPressed: () {
                print(drivetrainText.text);
                print(dimensionText.text);
                print(weightText.text);
                print(mechanismText.text);
                Navigator.pushNamed(context, '/');
              },
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 40,
                ),
                padding: const EdgeInsets.only(
                    left: 14, top: 12, right: 14, bottom: 12),
                backgroundColor: Colors.blue,
                side: const BorderSide(
                    width: 3, color: Color.fromRGBO(65, 104, 196, 1)),
              ), child: const Text("Confirm",
              style: TextStyle(color: Colors.white, fontSize: 25),
              ),
              )
        ]
        )
      )
    );
  }
}

class SScoutingPage extends StatefulWidget {
  const SScoutingPage({super.key, required this.title});
  final String title;
  @override
  State<SScoutingPage> createState() => _SScoutingPageState();
}

class _SScoutingPageState extends State<SScoutingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const NavBar(),
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
            Container(
                child: IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/'),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color.fromRGBO(165, 176, 168, 1),
                      size: 50,
                    )))
          ],
          backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
          title: Image.asset(
            'assets/images/rohawktics.png',
            width: 75,
            height: 75,
            alignment: Alignment.center,
          ),
        )
      );
  }
}
