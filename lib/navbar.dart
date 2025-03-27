// ignore_for_file: unused_import, depend_on_referenced_packages, use_build_context_synchronously, use_key_in_widget_constructors, library_private_types_in_public_api, prefer_const_constructors, deprecated_member_use

import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:scouting2024/auth_gate.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:scouting2024/team_comparison.dart' as team;
import 'package:scouting2024/credits.dart' as credits;
import 'package:shared_preferences/shared_preferences.dart';

// Function to get dark dialog theme
ThemeData getDarkDialogTheme(BuildContext context) {
  final darkGray = Color.fromRGBO(65, 68, 73, 1);
  return ThemeData.dark().copyWith(
    useMaterial3: true,
    // Set base colors
    scaffoldBackgroundColor: darkGray,
    dialogBackgroundColor: darkGray,
    
    // Configure color scheme
    colorScheme: ColorScheme.dark(
      surface: darkGray,
      background: darkGray,
      primary: Colors.white,
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    
    // Configure dialog specific theme
    dialogTheme: DialogTheme(
      backgroundColor: darkGray,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    
    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
      ),
    ),
    
    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color.fromRGBO(75, 78, 83, 1),
      labelStyle: TextStyle(color: Colors.white),
      hintStyle: TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white54),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    ),
  );
}

// Function to delete Firebase account
Future<void> deleteFirebaseAccount() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.delete();
      print('User account deleted successfully');
    } else {
      print('No user signed in');
    }
  } catch (e) {
    print('Failed to delete user account: $e');
  }
}

// Function to update username in Firestore
Future<void> updateUsername(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('No user signed in');
    return;
  }

  final TextEditingController usernameController = TextEditingController();
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Material(
        type: MaterialType.transparency,
        child: Theme(
          data: getDarkDialogTheme(context),
          child: AlertDialog(
            elevation: 0,
            backgroundColor: Color.fromRGBO(65, 68, 73, 1),
            title: Text('Change Username', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'New Username',
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text('Save'),
                onPressed: () async {
                  final newUsername = usernameController.text.trim();
                  if (newUsername.isNotEmpty) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .set({
                        'username': newUsername,
                      }, SetOptions(merge: true));
                      Navigator.of(context).pop();
                    } catch (e) {
                      print('Failed to update username: $e');
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Username cannot be empty')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Function to update event key
Future<bool> updateEventKey(BuildContext context) async {
  // Get current event key from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final currentEventKey = prefs.getString('eventKey') ?? '2025alhu';

  final TextEditingController eventKeyController = TextEditingController(text: currentEventKey);
  bool updated = false;
  
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Material(
        type: MaterialType.transparency,
        child: Theme(
          data: getDarkDialogTheme(context),
          child: AlertDialog(
            elevation: 0,
            backgroundColor: Color.fromRGBO(65, 68, 73, 1),
            title: Text('Set Event Key', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: eventKeyController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Event Key',
                    hintText: 'e.g., 2025alhu',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  autofocus: true,
                ),
                SizedBox(height: 10),
                Text(
                  'This will be used for both rankings display and analytics.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text('Save'),
                onPressed: () async {
                  final newEventKey = eventKeyController.text.trim();
                  if (newEventKey.isNotEmpty) {
                    try {
                      // Save to SharedPreferences
                      await prefs.setString('eventKey', newEventKey);
                      // Also save as lastEventKey for analytics
                      await prefs.setString('lastEventKey', newEventKey);
                      updated = true;
                      Navigator.of(context).pop();
                      
                      // Show confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Event key updated to $newEventKey')),
                      );
                    } catch (e) {
                      print('Failed to update event key: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update event key')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event key cannot be empty')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
  
  return updated;
}

class NavBar extends StatelessWidget {
  final Function? onEventKeyUpdated;
  
  const NavBar({Key? key, this.onEventKeyUpdated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const Gap(120),
          ListTile(
            leading: const Icon(Icons.event),
            iconColor: Colors.white,
            title: const Text('Set Event Key'),
            textColor: Colors.white,
            onTap: () async {
              bool updated = await updateEventKey(context);
              if (updated && onEventKeyUpdated != null) {
                onEventKeyUpdated!();
                Navigator.pop(context); // Close the drawer
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            iconColor: Colors.white,
            title: const Text('Sign Out'),
            textColor: Colors.white,
            onTap: () {
              FirebaseAuth.instance.signOut();
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            iconColor: Colors.white,
            title: const Text('Change Username'),
            textColor: Colors.white,
            onTap: () {
              updateUsername(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_remove),
            iconColor: Colors.white,
            title: const Text('Delete Account'),
            textColor: Colors.white,
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return Material(
                    type: MaterialType.transparency,
                    child: Theme(
                      data: getDarkDialogTheme(context),
                      child: AlertDialog(
                        elevation: 0,
                        backgroundColor: Color.fromRGBO(65, 68, 73, 1),
                        title: Text('Delete your Account?', 
                          style: TextStyle(color: Colors.white)),
                        content: Text(
                          '''If you select Delete we will delete your account on our server.

Your app data will also be deleted and you won't be able to retrieve it.

Since this is a security-sensitive operation, you eventually are asked to login before your account can be deleted.''',
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: Text('Delete'),
                            onPressed: () async {
                              await deleteFirebaseAccount();
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud),
            iconColor: Colors.white,
            title: const Text('Clear Data'),
            textColor: Colors.white,
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return Material(
                    type: MaterialType.transparency,
                    child: Theme(
                      data: getDarkDialogTheme(context),
                      child: AlertDialog(
                        elevation: 0,
                        backgroundColor: Color.fromRGBO(65, 68, 73, 1),
                        title: Text('Clear Data?', 
                          style: TextStyle(color: Colors.white)),
                        content: Text(
                          'Are you sure you want to clear all local data? This action cannot be undone.',
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: Text('Clear'),
                            onPressed: () {
                              // Add your clear data logic here
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.compare_arrows),
            iconColor: Colors.white,
            title: const Text('Team Comparison'),
            textColor: Colors.white,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => team.TeamComparisonScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            iconColor: Colors.white,
            title: const Text("Credits"),
            textColor: Colors.white,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => credits.SponsorshipPage()
                ),
              );
            },
          )
        ],
      ),
    );
  }
}