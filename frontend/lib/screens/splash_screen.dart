import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'role_select_screen.dart';
import '../services/auth_services.dart';

class SplashScreen extends StatefulWidget{
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
      final hasAccount = await _authService.hasActiveAccount();

      if (isLoggedIn) {
        onLoadDestination = const HomeScreen();
      } else if (hasAccount) {
        onLoadDestination = const LoginScreen();
      } else {
        onLoadDestination = const RoleSelectScreen();
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
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}