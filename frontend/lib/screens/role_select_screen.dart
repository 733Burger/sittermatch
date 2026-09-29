import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'login_screen.dart';


class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  void _navigateToSignup(BuildContext context, String role) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignupScreen(selectedRole: role),
      ),
    );
  }

  void _navigateToLogin(BuildContext context, {String role = 'HOMEOWNER'}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(selectedRole: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF8FAFC);
    const primaryDark = Color(0xFF0F172A);
    const cardBorderColor = Color(0xFFE2E8F0);
    const subtextColor = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.pets,
                  size: 48,
                  color: primaryDark,
                ),
                const SizedBox(height: 12),
                const Text(
                  'SIT & STAY',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please select how you want to use the\nplatform today.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: subtextColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),

                _RoleCard(
                  borderColor: cardBorderColor,
                  icon: Icons.roofing_rounded,
                  title: 'I need a\nSitter',
                  description: 'Find verified help for\nyour home and pets.',
                  onTap: () => _navigateToSignup(context, 'HOMEOWNER'),
                ),
                const SizedBox(height: 20),

                _RoleCard(
                  borderColor: cardBorderColor,
                  icon: Icons.accessibility_new_rounded,
                  title: 'I want to Sit',
                  description: 'Join our community of\ntrusted sitters.',
                  onTap: () => _navigateToSignup(context, 'SITTER'),
                ),
                const SizedBox(height: 32),

                TextButton(
                  onPressed: () => _navigateToLogin(context),
                  child: const Text(
                    'Already have an account? Sign in',
                    style: TextStyle(
                      color: primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final Color borderColor;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.borderColor,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: const Color(0xFF0F172A)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}