// ignore_for_file: unused_import, avoid_print, use_build_context_synchronously

import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:scouting2024/auth_gate.dart' as auth;
import 'package:scouting2024/sp.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> deleteFirebaseAccount() async {
  try {
    // Get the currently signed-in user
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Delete the user
      await user.delete();
      print('User account deleted successfully');
    } else {
      print('No user signed in');
    }
  } catch (e) {
    print('Failed to delete user account: $e');
  }
}

Future<void> updateUsername(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('No user signed in');
    return;
  }

  final TextEditingController usernameController = TextEditingController();
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: Colors.white, // Text on buttons
            secondary: Colors.grey, // Accent color
            onPrimary: Colors.white, // Text color on primary background
            onSurface: Colors.white, // Default text color
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white), // Large body text
            bodyMedium: TextStyle(color: Colors.white), // Medium body text
            bodySmall: TextStyle(color: Colors.white), // Small body text
          ),
          dialogBackgroundColor: const Color.fromRGBO(65, 68, 73, 1), // Background color for the dialog
        ),
        child: AlertDialog(
          title: const Text('Change Username'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'New Username',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                final newUsername = usernameController.text.trim();
                if (newUsername.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
                      {
                        'username': newUsername,
                      },
                      SetOptions(merge: true),
                    );
                    print('Username updated successfully');
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
      );
    },
  );
}

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromRGBO(65, 68, 74, 1),
      child: ListView(
        // Remove padding
        padding: EdgeInsets.zero,
        children: [
          const Gap(120),
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
                builder: (BuildContext context) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.fromSwatch().copyWith(
                        primary: Colors.white, // Text on buttons
                        secondary: Colors.grey, // Accent color
                        onPrimary: Colors.white, // Text color on primary background
                        onSurface: Colors.white, // Default text color
                      ),
                      textTheme: const TextTheme(
                        bodyLarge: TextStyle(color: Colors.white), // Large body text
                        bodyMedium: TextStyle(color: Colors.white), // Medium body text
                        bodySmall: TextStyle(color: Colors.white), // Small body text
                      ),
                      dialogBackgroundColor: const Color.fromRGBO(65, 68, 73, 1), // Background color for the dialog
                    ),
                    child: AlertDialog(
                      title: const Text('Delete your Account?'),
                      content: const Text(
                        '''If you select Delete we will delete your account on our server.

Your app data will also be deleted and you won't be able to retrieve it.

Since this is a security-sensitive operation, you eventually are asked to login before your account can be deleted.''',
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Delete'),
                          onPressed: () async {
                            await deleteFirebaseAccount();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
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
              frick();
            },
          ),
        ],
      ),
    );
  }
}