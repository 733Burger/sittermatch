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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pet.breed,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ProfileTag(petTypeLabel(pet.species)),
                        ProfileTag(
                          '${pet.age} ${pet.age == 1 ? 'year' : 'years'}',
                        ),
                      ],
                    ),
                  ],
                ),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PetActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  foreground: AppColors.primaryRust,
                  iconColor: AppColors.primaryRust,
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PetActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  foreground: const Color(0xFFD32F2F),
                  iconColor: const Color(0xFFD32F2F),
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PetActionButton extends StatelessWidget {
  const _PetActionButton({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.iconColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 17,
          color: Colors.white,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: iconColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
            color: iconColor,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
