// ignore_for_file: use_build_context_synchronously, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter/services.dart';
import 'navbar.dart';
import 'variables.dart';

class PitScoutingPage extends StatefulWidget {
  const PitScoutingPage({super.key, required this.title});
  final String title;
  @override
  State<PitScoutingPage> createState() => _PitScoutingPageState();
}

class _PitScoutingPageState extends State<PitScoutingPage> {
  // Controllers for text inputs
  final TextEditingController _robotNumController = TextEditingController();
  final TextEditingController _robotWeightController = TextEditingController();
  final TextEditingController _robotSizeController = TextEditingController();
  final TextEditingController _additionalNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data if any
    _robotNumController.text = pitScoutingData['robotNum'];
    _robotWeightController.text = pitScoutingData['weight'];
    _robotSizeController.text = pitScoutingData['size'];
    _additionalNotesController.text = pitScoutingData['additionalNotes'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavBar(),
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
            )
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
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // Robot Number
              const Text(
                "Robot Number",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              SizedBox(
                width: 350,
                child: TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]{0,4}')),
                  ],
                  textAlign: TextAlign.center,
                  controller: _robotNumController,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color.fromRGBO(255, 255, 255, 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(width: 1, color: Colors.white),
                    ),
                    hintText: 'Team Number', 
                    hintStyle: const TextStyle(color: Colors.white),
                  )
                ),
              ),
              
              const Gap(20),
              
              // Robot Weight
              const Text(
                "What is the weight of your robot?",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              SizedBox(
                width: 350,
                child: TextField(
                  textAlign: TextAlign.center,
                  controller: _robotWeightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color.fromRGBO(255, 255, 255, 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(width: 1, color: Colors.white),
                    ),
                    hintText: 'Weight (lbs)', 
                    hintStyle: const TextStyle(color: Colors.white),
                  )
                ),
              ),
              
              const Gap(20),
              
              // Robot Size
              const Text(
                "What is the size of your robot?",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              SizedBox(
                width: 350,
                child: TextField(
                  textAlign: TextAlign.center,
                  controller: _robotSizeController,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color.fromRGBO(255, 255, 255, 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(width: 1, color: Colors.white),
                    ),
                    hintText: 'L x W x H (inches)', 
                    hintStyle: const TextStyle(color: Colors.white),
                  )
                ),
              ),
              
              const Gap(20),
              
              // Coral Scoring Levels
              const Text(
                "What levels can your robot score coral on?",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              Center(
                child: SizedBox(
                  width: 350,
                  child: Column(
                    children: ['L4', 'L3', 'L2', 'L1'].map((level) => 
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: CheckboxListTile(
                          title: Text(
                            level, 
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 18
                            )
                          ),
                          value: pitScoutingData['scoringLevels'][level],
                          onChanged: (bool? value) {
                            setState(() {
                              pitScoutingData['scoringLevels'][level] = value ?? false;
                            });
                          },
                          activeColor: Colors.blue,
                          checkColor: Colors.white,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      )
                    ).toList(),
                  ),
                ),
              ),
              
              const Gap(20),
              
              // Barge Scoring
              const Text(
                "Can your robot score in the barge?",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio<bool>(
                    value: true, 
                    groupValue: pitScoutingData['bargeScoring'], 
                    onChanged: (bool? value) {
                      setState(() {
                        pitScoutingData['bargeScoring'] = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  const Text('Yes', style: TextStyle(color: Colors.white)),
                  Radio<bool>(
                    value: false, 
                    groupValue: pitScoutingData['bargeScoring'], 
                    onChanged: (bool? value) {
                      setState(() {
                        pitScoutingData['bargeScoring'] = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  const Text('No', style: TextStyle(color: Colors.white)),
                ],
              ),
              
              const Gap(20),
              const Text(
                "Can your team climb?",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio<String>(
                    value: 'yes', 
                    groupValue: pitScoutingData['climbing']['ability'], 
                    onChanged: (String? value) {
                      setState(() {
                        pitScoutingData['climbing']['ability'] = value!;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  const Text('Yes', style: TextStyle(color: Colors.white)),
                  Radio<String>(
                    value: 'no', 
                    groupValue: pitScoutingData['climbing']['ability'], 
                    onChanged: (String? value) {
                      setState(() {
                        pitScoutingData['climbing']['ability'] = value!;
                        pitScoutingData['climbing']['cageType'] = null;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  const Text('No', style: TextStyle(color: Colors.white)),
                ],
              ),
              if (pitScoutingData['climbing']['ability'] == 'yes') ...[
                const Gap(10),
                const Text(
                  "Climbing Cage Type",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Radio<String>(
                      value: 'Shallow', 
                      groupValue: pitScoutingData['climbing']['cageType'], 
                      onChanged: (String? value) {
                        setState(() {
                          pitScoutingData['climbing']['cageType'] = value!;
                        });
                      },
                      activeColor: Colors.blue,
                    ),
                    const Text('Shallow', style: TextStyle(color: Colors.white)),
                    Radio<String>(
                      value: 'Deep', 
                      groupValue: pitScoutingData['climbing']['cageType'], 
                      onChanged: (String? value) {
                        setState(() {
                          pitScoutingData['climbing']['cageType'] = value!;
                        });
                      },
                      activeColor: Colors.blue,
                    ),
                    const Text('Deep', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
              
              const Gap(20),
              const Text(
                "Additional Notes",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              SizedBox(
                width: 350,
                child: TextField(
                  controller: _additionalNotesController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color.fromRGBO(255, 255, 255, 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(width: 1, color: Colors.white),
                    ),
                    hintText: 'Optional additional information', 
                    hintStyle: const TextStyle(color: Colors.white),
                  ),
                  onChanged: (value) {
                    pitScoutingData['additionalNotes'] = value;
                  },
                ),
              ),
              
              const Gap(20),
              ElevatedButton(
                onPressed: _submitPitScoutingData,
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 40),
                  padding: const EdgeInsets.only(
                    left: 14, top: 12, right: 14, bottom: 12
                  ),
                  backgroundColor: Colors.blue,
                  side: const BorderSide(
                    width: 3, color: Color.fromRGBO(65, 104, 196, 1)
                  ),
                ),
                child: const Text(
                  "Confirm",
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _submitPitScoutingData() async {
    pitScoutingData['robotNum'] = _robotNumController.text;
    pitScoutingData['weight'] = _robotWeightController.text;
    pitScoutingData['size'] = _robotSizeController.text;
    pitScoutingData['additionalNotes'] = _additionalNotesController.text;

    try {
      await submitPitScoutingData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pit Scouting Data Submitted Successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}