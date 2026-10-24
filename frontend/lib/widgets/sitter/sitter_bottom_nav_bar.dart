import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

enum SitterNavTab { home, jobs, messages, profile }

class SitterBottomNavBar extends StatelessWidget {
  const SitterBottomNavBar({
    super.key,
    required this.onTap,
    this.selected = SitterNavTab.home,
  });

  final ValueChanged<SitterNavTab> onTap;
  final SitterNavTab? selected;

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
      onTap: (index) => onTap(SitterNavTab.values[index]),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'HOME',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.work_outline),
          label: 'JOBS',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
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
