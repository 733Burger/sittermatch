import 'package:flutter/material.dart';

import '../../../models/pet_model.dart';
import '../../../theme/app_colors.dart';
import '../../homeowner/profile/profile_styles.dart';

class SitterPreferencesCard extends StatelessWidget {
  const SitterPreferencesCard({
    super.key,
    required this.selectedPets,
    required this.errorText,
    required this.saving,
    required this.onToggle,
    required this.onSave,
  });

  final Set<String> selectedPets;
  final String? errorText;
  final bool saving;
  final ValueChanged<String> onToggle;
  final VoidCallback onSave;

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
            'Pet preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Select the animals you are happy to look after. At least one is required.',
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pet in petTypes)
                ChoiceChip(
                  label: Text(petTypeLabel(pet)),
                  selected: selectedPets.contains(pet),
                  showCheckmark: false,
                  selectedColor: AppColors.primaryRust,
                  backgroundColor: AppColors.expandButtonBg,
                  side: BorderSide.none,
                  labelStyle: TextStyle(
                    color: selectedPets.contains(pet) ? Colors.white : AppColors.darkText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (_) => onToggle(pet),
                ),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              errorText!,
              style: const TextStyle(color: Color(0xFFB42318), fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          ProfileSaveButton(
            label: 'Save pet preferences',
            saving: saving,
            onPressed: saving ? null : onSave,
          ),
        ],
      ),
    );
  }
}
