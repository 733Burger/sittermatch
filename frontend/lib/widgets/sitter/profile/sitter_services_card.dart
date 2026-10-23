import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../homeowner/profile/profile_styles.dart';

class SitterServicesCard extends StatelessWidget {
  const SitterServicesCard({
    super.key,
    required this.formKey,
    required this.selectedServices,
    required this.overnightRateController,
    required this.walkRateController,
    required this.walkDurationController,
    required this.feedRateController,
    required this.saving,
    required this.onToggle,
    required this.onSave,
    required this.validatePrice,
    required this.validateMinutes,
  });

  final GlobalKey<FormState> formKey;
  final Map<String, bool> selectedServices;
  final TextEditingController overnightRateController;
  final TextEditingController walkRateController;
  final TextEditingController walkDurationController;
  final TextEditingController feedRateController;
  final bool saving;
  final ValueChanged<String> onToggle;
  final VoidCallback onSave;
  final FormFieldValidator<String> validatePrice;
  final FormFieldValidator<String> validateMinutes;

  static const Map<String, IconData> _serviceIcons = {
    'Stay Over Night': Icons.nights_stay_outlined,
    'Walk Pet': Icons.directions_walk,
    'Feed Pet': Icons.restaurant_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: profileCardDecoration(),
      child: Form(
        key: formKey,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services offered & pricing',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Select one or more. At least one is required.',
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedServices.keys.map((service) {
              final isSelected = selectedServices[service]!;
              return ChoiceChip(
                avatar: Icon(
                  _serviceIcons[service],
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.primaryRust,
                ),
                label: Text(service),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: AppColors.primaryRust,
                backgroundColor: AppColors.expandButtonBg,
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.darkText,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (_) => onToggle(service),
              );
            }).toList(),
          ),
          if (selectedServices['Stay Over Night']!)
            _ServiceBlock(
              icon: Icons.nights_stay_outlined,
              title: 'Stay over night',
              children: [
                const ProfileFieldLabel('Price per night'),
                TextFormField(
                  controller: overnightRateController,
                  keyboardType: TextInputType.number,
                  decoration: _priceDecoration(),
                  validator: validatePrice,
                ),
              ],
            ),
          if (selectedServices['Walk Pet']!)
            _ServiceBlock(
              icon: Icons.directions_walk,
              title: 'Walk pet',
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ProfileFieldLabel('Price per walk'),
                          TextFormField(
                            controller: walkRateController,
                            keyboardType: TextInputType.number,
                            decoration: _priceDecoration(),
                            validator: validatePrice,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ProfileFieldLabel('Walk length'),
                          TextFormField(
                            controller: walkDurationController,
                            keyboardType: TextInputType.number,
                            decoration: profileFieldDecoration(null, hint: '0', icon: null)
                                .copyWith(suffixText: 'min'),
                            validator: validateMinutes,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          if (selectedServices['Feed Pet']!)
            _ServiceBlock(
              icon: Icons.restaurant_outlined,
              title: 'Feed pet',
              children: [
                const ProfileFieldLabel('Price per feeding visit'),
                TextFormField(
                  controller: feedRateController,
                  keyboardType: TextInputType.number,
                  decoration: _priceDecoration(),
                  validator: validatePrice,
                ),
              ],
            ),
          const SizedBox(height: 16),
          ProfileSaveButton(
            label: 'Save services',
            saving: saving,
            onPressed: saving ? null : onSave,
          ),
        ],
        ),
      ),
    );
  }

  InputDecoration _priceDecoration() {
    return profileFieldDecoration(null, hint: '0').copyWith(prefixText: 'R ');
  }
}

class _ServiceBlock extends StatelessWidget {
  const _ServiceBlock({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryRust, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
