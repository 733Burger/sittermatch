import 'package:flutter/material.dart';

import '../../../models/pet_model.dart';
import '../../../theme/app_colors.dart';
import 'profile_styles.dart';

class ProfilePetCard extends StatelessWidget {
  const ProfilePetCard({
    super.key,
    required this.pet,
    required this.onEdit,
    required this.onDelete,
  });

  final PetModel pet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasReview = pet.review != null && pet.review!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: profileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.lightRustBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pets, color: AppColors.primaryRust, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pet.breed,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ProfileTag(petTypeLabel(pet.species)),
                        ProfileTag('${pet.age} ${pet.age == 1 ? 'YR' : 'YRS'}'),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black54),
                color: Colors.white,
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.emoji_emotions_outlined,
                color: AppColors.primaryRust,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                pet.behaviorScore == null ? 'No behaviour score yet' : 'Behaviour score',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          if (pet.behaviorScore != null || hasReview) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (pet.behaviorScore != null) ...[
                  ProfileStars(score: pet.behaviorScore!, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    pet.behaviorScore!.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                ],
                if (hasReview)
                  Expanded(
                    child: Text(
                      '"${pet.review!}"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (pet.careNotes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Care notes: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: pet.careNotes),
                  ],
                ),
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
