import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../homeowner/profile/profile_styles.dart';

class SitterReviewsCard extends StatelessWidget {
  const SitterReviewsCard({
    super.key,
    required this.reviewCount,
    required this.averageRating,
  });

  final int reviewCount;
  final double averageRating;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: profileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ratings & client reviews',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          if (reviewCount == 0)
            const Text(
              'No reviews yet. Homeowners can review you after a stay.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            )
          else
            Row(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileStars(score: averageRating, size: 18),
                    const SizedBox(height: 2),
                    Text(
                      '$reviewCount reviews',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
