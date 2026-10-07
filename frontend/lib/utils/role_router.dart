import 'package:flutter/material.dart';
import '../screens/owner_home_screen.dart';
import '../screens/sitter_home_screen.dart';
import '../screens/admin_dashboard_screen.dart';

/// Returns the home screen for a role, or null if the role is missing or unknown.
Widget? homeForRole(String? role) {
  switch ((role ?? '').trim().toUpperCase()) {
    case 'SITTER':
      return const SitterHomeScreen();
    case 'HOMEOWNER':
      return const OwnerHomeScreen();
    case 'ADMIN':
      return const AdminDashboardScreen();
    default:
      return null;
  }
}