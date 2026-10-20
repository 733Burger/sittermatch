import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'profile_styles.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.reviewCount,
    required this.averageRating,
    required this.onPhotoTap,
  });

  final String name;
  final String email;
  final String phone;
  final int reviewCount;
  final double averageRating;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    final displayName = name.isEmpty ? 'Your name' : name;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: profileCardDecoration(),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, size: 52, color: Colors.grey),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onPhotoTap,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRust,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: name.isEmpty ? Colors.black38 : AppColors.darkText,
            ),
          ),
          const SizedBox(height: 6),
          const ProfileTag('HOMEOWNER'),
          const SizedBox(height: 10),
          if (reviewCount > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: AppColors.primaryRust, size: 18),
                const SizedBox(width: 4),
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  ' ($reviewCount reviews)',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _InfoRow(
            Icons.mail_outline,
            email.isEmpty ? 'No email on file' : email,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            Icons.phone_outlined,
            phone.isEmpty ? 'No phone number on file' : phone,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryRust, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.darkText),
          ),
        ),
      ],
    );
  }
}
