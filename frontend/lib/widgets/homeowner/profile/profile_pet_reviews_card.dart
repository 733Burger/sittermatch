import 'package:flutter/material.dart';

import '../../../models/review_model.dart';
import '../../../theme/app_colors.dart';
import 'profile_styles.dart';

/// What sitters said about each pet after a stay. Only shows reviews an admin has approved.
class ProfilePetReviewsCard extends StatelessWidget {
  const ProfilePetReviewsCard({super.key, required this.reviews, this.title = 'Pet reviews'});

  final List<PetReview> reviews;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: profileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pets, size: 18, color: AppColors.primaryRust),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            const Text(
              'No pet reviews yet. Sitters can rate each pet after a stay.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            )
          else
            ...reviews.map((r) => _PetReviewTile(review: r)),
        ],
      ),
    );
  }
}

class _PetReviewTile extends StatelessWidget {
  const _PetReviewTile({required this.review});

  final PetReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.petName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkText),
                ),
              ),
              ...List.generate(
                5,
                (i) => Icon(
                  i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 14,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            review.notes.isEmpty ? 'No comment.' : review.notes,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            [
              'By ${review.sitterName}',
              if (review.dateLabel.isNotEmpty) review.dateLabel,
            ].join(' · '),
            style: const TextStyle(fontSize: 10, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
