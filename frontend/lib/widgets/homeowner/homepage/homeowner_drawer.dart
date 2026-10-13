import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class OwnerHomeDrawer extends StatelessWidget {
  const OwnerHomeDrawer({
    super.key,
    required this.email,
    required this.savedSittersCount,
    required this.onProfileTap,
    required this.onBookingsTap,
    required this.onSavedSittersTap,
    required this.onSettingsTap,
    required this.onLogOut,
  });

  final String email;
  final int savedSittersCount;
  final VoidCallback onProfileTap;
  final VoidCallback onBookingsTap;
  final VoidCallback onSavedSittersTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryRust),
            accountName: const Text('Homeowner'),
            accountEmail: Text(email),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppColors.primaryRust),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: onProfileTap,
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('My Bookings'),
            onTap: onBookingsTap,
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_border_outlined),
            title: const Text('Saved Sitters'),
            trailing: Badge(
              label: Text('$savedSittersCount'),
              backgroundColor: AppColors.primaryRust,
            ),
            onTap: onSavedSittersTap,
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: onSettingsTap,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: onLogOut,
          ),
        ],
      ),
    );
  }
}