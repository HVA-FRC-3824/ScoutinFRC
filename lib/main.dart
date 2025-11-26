import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoHAWKtics Scouting',
      theme: ThemeData.light(), 
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, 
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}