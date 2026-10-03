import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'screens/splash_screen.dart';

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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryRust,
          primary: AppColors.primaryRust,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const SplashScreen(),
    );
  }
}