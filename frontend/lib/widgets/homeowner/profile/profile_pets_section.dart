import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'profile_styles.dart';

/// Section title with an "Add …" action on the right, e.g. "My pets" / "Stay checklist".
class ProfileSectionHeader extends StatelessWidget {
  const ProfileSectionHeader({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        // Solid pill button, e.g. "Add pet" / "Add task".
        ElevatedButton.icon(
          onPressed: onAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRust,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            actionLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Centred placeholder card shown when a profile list has nothing in it yet.
class ProfileEmptyCard extends StatelessWidget {
  const ProfileEmptyCard(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(20),
      decoration: profileCardDecoration(),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }
}
