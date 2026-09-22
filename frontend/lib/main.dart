import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const SitterMatchApp());
}

class SitterMatchApp extends StatelessWidget {
  const SitterMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SitterMatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E50)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}