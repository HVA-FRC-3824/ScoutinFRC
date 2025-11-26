// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_colors.dart';
import '../../home/presentation/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> createUserDocument(String uid, {String? role, String? username}) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': role ?? 'user', 
        'username': username ?? 'default_username',
      }, SetOptions(merge: true)); 
      print('User document created/updated successfully');
    } catch (e) {
      print("Error creating/updating user document: $e");
    }
  }

  Future<Map<String, String?>> _getUserDetails(String uid) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;

        if (data != null) {
          return {
            'role': data['role'] as String? ?? 'user',  
            'username': data['username'] as String? ?? 'default_username',
          };
        } else {
          print("Document data is null");
        }
      } else {
        print("Document does not exist");
        await createUserDocument(uid);
        return {'role': 'user', 'username': 'default_username'};
      }
    } catch (e) {
      print("Error getting user details: $e");
    }
    return {'role': null, 'username': null};
  }

  Future<void> _updateUsername(String uid, String username) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username,
      }, SetOptions(merge: true)); 
    } catch (e) {
      print("Error updating username: $e");
    }
  }

  Future<void> _assignRolesIfNeeded(User user) async {
    final details = await _getUserDetails(user.uid);
    final username = details['username'];

    if (username == null || username.isEmpty) {
      await createUserDocument(user.uid, role: 'user', username: 'default_username');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.fromSwatch().copyWith(
                primary: AppColors.primary,
                secondary: AppColors.accent,
                onPrimary: Colors.white,
                onSurface: Colors.white,
              ),
              inputDecorationTheme: InputDecorationTheme(
                labelStyle: const TextStyle(color: Colors.white),
                hintStyle: const TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white),
                bodySmall: TextStyle(color: Colors.white),
              ),
              scaffoldBackgroundColor: AppColors.background,
            ),
            child: SignInScreen(
              providers: [
                EmailAuthProvider(),
                GoogleProvider(clientId: "246498824596-93ae95j4i3lr4rmeq0mfu455jcdsjs6v.apps.googleusercontent.com"),
                AppleProvider(),
              ],
              headerBuilder: (context, constraints, shrinkOffset) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: AspectRatio(
                    aspectRatio: 1,
                  ),
                );
              },
              subtitleBuilder: (context, action) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: action == AuthAction.signIn
                      ? const Text(
                          'Welcome to the RoHAWKtics Scouting App, please sign in!',
                          style: TextStyle(color: Colors.white),
                        )
                      : const Text(
                          'Welcome to the RoHAWKtics Scouting App, please sign up!',
                          style: TextStyle(color: Colors.white),
                        ),
                );
              },
              footerBuilder: (context, action) {
                return const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'By signing in, you agree to our terms and conditions.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              },
            ),
          );
        }

    
        final user = snapshot.data!;
        _assignRolesIfNeeded(user);

        return FutureBuilder<Map<String, String?>>(
          future: _getUserDetails(user.uid),
          builder: (context, detailsSnapshot) {
            if (detailsSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final details = detailsSnapshot.data!;
            final username = details['username'];

            if (username == null || username.isEmpty) {
              return Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                body: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Welcome! Before you get started, please choose a username.',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person, color: Colors.white70),
                          ),
                          onSubmitted: (value) async {
                            if (value.isNotEmpty) {
                              await _updateUsername(user.uid, value);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(),
                                ),
                              );
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
                ),
              );
            }

            return const HomePage();
          },
        );
      },
    );
  }
}
