import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'profile_styles.dart';

class ProfilePetsHeader extends StatelessWidget {
  const ProfilePetsHeader({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'My pets',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryRust, size: 18),
          label: const Text(
            'Add pet',
            style: TextStyle(color: AppColors.primaryRust, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class ProfileEmptyPets extends StatelessWidget {
  const ProfileEmptyPets({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: profileCardDecoration(),
      child: const Text(
        'No pets added yet. Add your pets so sitters know who they will be looking after.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }
}
