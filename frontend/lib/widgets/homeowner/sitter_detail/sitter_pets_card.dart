import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'sitter_detail_card.dart';

class SitterPetsCard extends StatelessWidget {
  const SitterPetsCard({super.key, required this.petPreferences});

  final List<String> petPreferences;

  @override
  Widget build(BuildContext context) {
    return SitterDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SitterSectionTitle('Accepted pets'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pet in petPreferences)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.expandButtonBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pets, color: AppColors.primaryRust, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        pet,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}