import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'owner_home_screen.dart';
import 'sitter_home_screen.dart';
import 'role_select_screen.dart';
import '../services/auth_services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _startRoute();
  }

  Future<void> _startRoute() async {
    Widget onLoadDestination;

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      final savedRole = await _authService.getUserRole();

      if (isLoggedIn) {
        if (savedRole?.toUpperCase() == 'SITTER') {
          onLoadDestination = const SitterHomeScreen();
        } else {
          onLoadDestination = const OwnerHomeScreen();
        }
      } else {
        final hasAccount = await _authService.hasActiveAccount();

        if (hasAccount) {
          onLoadDestination = LoginScreen(
            selectedRole: savedRole ?? 'HOMEOWNER',
          );
        } else {
          onLoadDestination = const RoleSelectScreen();
        }
      }
    } catch (e) {
      onLoadDestination = const RoleSelectScreen();
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => onLoadDestination),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryDark = Color(0xFF0F172A);
    const backgroundColor = Color(0xFFF8FAFC);

    return const Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 56, color: primaryDark),
            SizedBox(height: 16),
            CircularProgressIndicator(color: primaryDark),
          ],
        ),
      ),
    );
  }
}