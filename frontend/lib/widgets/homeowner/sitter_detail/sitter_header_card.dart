import 'package:flutter/material.dart';

import '../../../../models/sitter_details_model.dart';
import '../../../../theme/app_colors.dart';
import 'sitter_detail_card.dart';

class SitterHeaderCard extends StatelessWidget {
  const SitterHeaderCard({super.key, required this.details});

  final SitterDetails details;

  String get _initial {
    final name = details.name.trim();
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SitterDetailCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.lightRustBg,
                child: Text(
                  _initial,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRust,
                  ),
                ),
              ),
              if (details.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRust,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            details.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          if (details.email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              details.email,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
          if (details.phoneNumber.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              details.phoneNumber,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.primaryRust, size: 18),
              const SizedBox(width: 4),
              Text(
                details.rating.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                ' (${details.totalReviews} reviews)',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}