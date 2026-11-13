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
        TextButton.icon(
          onPressed: onAction,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryRust, size: 18),
          label: Text(
            actionLabel,
            style: const TextStyle(color: AppColors.primaryRust, fontWeight: FontWeight.bold),
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
