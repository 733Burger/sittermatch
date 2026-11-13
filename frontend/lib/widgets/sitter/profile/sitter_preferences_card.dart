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
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final tileWidth = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final pet in petTypes)
                    SizedBox(
                      width: tileWidth,
                      child: _PetTypeTile(
                        label: petTypeLabel(pet),
                        selected: selectedPets.contains(pet),
                        onTap: () => onToggle(pet),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            '${selectedPets.length} of ${petTypes.length} selected',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
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

/// One equal-width option in the pet type grid: outlined when off, tinted with a tick when on.
class _PetTypeTile extends StatelessWidget {
  const _PetTypeTile({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.lightRustBg : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? AppColors.primaryRust : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    selected ? Icons.check_circle : Icons.radio_button_unchecked,
                    key: ValueKey(selected),
                    size: 20,
                    color: selected ? AppColors.primaryRust : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
