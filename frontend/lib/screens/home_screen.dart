// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/services/user_services.dart';
import 'login_screen.dart';
import '../services/auth_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _userService = UserServices();
  final _authService = AuthService();

  bool _loading = true;
  bool _actionInProgress = false;
  String? _activeRole;
  String? _email;
  bool _hasSitterProfile = false;
  bool _hasHomeownerProfile = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = await _authService.getUserEmail();
    final currentRole = await _authService.getUserRole();

    if (email == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final associatedRoles = await _userService.getUserRoles(email);
    
    if (!mounted) return;
    setState(() {
      _loading = false;
      _email = email;
      _activeRole = currentRole;
      _hasSitterProfile = associatedRoles?['hasSitterProfile'] ?? false;
      _hasHomeownerProfile = associatedRoles?['hasHomeownerProfile'] ?? false;
    });
  }

  Future<void> _handleSwitchRole(String targetRole) async {
    if (_email == null) return;
    setState(() => _actionInProgress = true);

    final result = await _userService.switchActiveRole(_email!, targetRole);

    if (!mounted) return;

    if (result['success'] == true) {
      await _authService.setUserRole(result['activeRole']);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );

    setState(() => _actionInProgress = false);
    if (result['success'] == true) {
      await _loadUserData();
    }
  }

  Future<void> _addRole(String targetRole) async {
    if (_email == null) return;
    setState(() => _actionInProgress = true);

    final result = await _userService.addRole(_email!, targetRole);

    if (!mounted) return;

    if (result['success'] == true) {
      await _authService.setUserRole(result['activeRole']);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );

    setState(() => _actionInProgress = false);
    if (result['success'] == true) {
      await _loadUserData();
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().clearSession();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SitterMatch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Welcome! Active role: $_activeRole'),
                const SizedBox(height: 16),
                if (_actionInProgress)
                  const CircularProgressIndicator()
                else if (_hasSitterProfile && _hasHomeownerProfile)
                  FilledButton(
                    onPressed: () => _handleSwitchRole(
                      _activeRole == 'SITTER' ? 'HOMEOWNER' : 'SITTER',
                    ),
                    child: Text(
                      'Switch to ${_activeRole == 'SITTER' ? 'Homeowner' : 'Sitter'}'
                    ),
                  )
                else if (_activeRole == 'HOMEOWNER' && !_hasSitterProfile)
                  FilledButton(
                    onPressed: () => _addRole('SITTER'), 
                    child: const Text('Set up Sitter account'),
                  )
                else if (_activeRole == 'SITTER' && !_hasHomeownerProfile)
                  FilledButton(
                    onPressed: () => _addRole('HOMEOWNER'), 
                    child: const Text('Set up Homeowner account')
                  ),
              ],
            ),)
    );
  }
}