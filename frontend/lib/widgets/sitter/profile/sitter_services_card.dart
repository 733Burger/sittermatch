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

  // Sentence-case display names for the service keys.
  static const Map<String, String> _serviceLabels = {
    'Stay Over Night': 'Stay over night',
    'Walk Pet': 'Walk pet',
    'Feed Pet': 'Feed pet',
  };

  @override
  Widget build(BuildContext context) {
    final selected = selectedServices.keys.where((service) => selectedServices[service]!).toList();

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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText),
            ),
            const SizedBox(height: 2),
            const Text(
              "Select one or more and set your price. Stay over night and Feed pet can't be combined.",
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
            ),
            const SizedBox(height: 20),
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
                  label: Text(_serviceLabels[service] ?? service),
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
            const SizedBox(height: 8),
            for (final service in selected)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Icon(_serviceIcons[service], color: AppColors.primaryRust, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _serviceLabels[service] ?? service,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText),
                        ),
                      ),
                    ),
                    Expanded(flex: 6, child: _fieldsFor(service)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ProfileSaveButton(label: 'Save services', saving: saving, onPressed: saving ? null : onSave),
          ],
        ),
      ),
    );
  }

  Widget _fieldsFor(String service) {
    switch (service) {
      case 'Walk Pet':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _priceField(walkRateController, '/ walk')),
            const SizedBox(width: 8),
            SizedBox(
              width: 76,
              child: TextFormField(
                controller: walkDurationController,
                keyboardType: TextInputType.number,
                decoration: _compactDecoration(hint: '0', suffix: 'min'),
                validator: validateMinutes,
              ),
            ),
          ],
        );
      case 'Feed Pet':
        return _priceField(feedRateController, '/ visit');
      default:
        return _priceField(overnightRateController, '/ night');
    }
  }

  Widget _priceField(TextEditingController controller, String unit) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: _compactDecoration(hint: '0', prefix: 'R ', suffix: unit),
      validator: validatePrice,
    );
  }

  InputDecoration _compactDecoration({required String hint, String? prefix, String? suffix}) {
    return profileFieldDecoration(null, hint: hint).copyWith(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      prefixText: prefix,
      suffixText: suffix,
      suffixStyle: const TextStyle(fontSize: 12, color: Colors.black54),
    );
  }
}
