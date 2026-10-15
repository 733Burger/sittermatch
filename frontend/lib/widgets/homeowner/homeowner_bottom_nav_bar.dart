import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

enum OwnerNavTab { home, bookings, messages, profile }

class OwnerBottomNavBar extends StatelessWidget {
  const OwnerBottomNavBar({
    super.key,
    required this.onTap,
    this.selected = OwnerNavTab.home,
  });

  final ValueChanged<OwnerNavTab> onTap;
  final OwnerNavTab? selected;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected != null;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 0,
      currentIndex: selected?.index ?? 0,
      selectedItemColor: hasSelection ? AppColors.primaryRust : Colors.grey,
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