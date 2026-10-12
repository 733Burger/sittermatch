import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

enum OwnerNavTab { home, bookings, messages, profile }

class OwnerBottomNavBar extends StatelessWidget {
  const OwnerBottomNavBar({super.key, required this.onTap});

  final ValueChanged<OwnerNavTab> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 0,
      currentIndex: OwnerNavTab.home.index,
      selectedItemColor: AppColors.primaryRust,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (index) => onTap(OwnerNavTab.values[index]),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'HOME',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'BOOKINGS',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text('3'),
            backgroundColor: AppColors.primaryRust,
            child: Icon(Icons.chat_bubble_outline),
          ),
          label: 'MESSAGES',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'PROFILE',
        ),
      ],
    );
  }
}