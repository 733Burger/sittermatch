import 'package:flutter/material.dart';

import '../../../services/places_service.dart';
import '../../../theme/app_colors.dart';
import '../../homeowner/profile/profile_styles.dart';

class SitterAreaCard extends StatelessWidget {
  const SitterAreaCard({
    super.key,
    required this.formKey,
    required this.areaController,
    required this.searching,
    required this.suggestions,
    required this.notice,
    required this.saving,
    required this.onAreaChanged,
    required this.onAreaTap,
    required this.onSelectSuggestion,
    required this.areaValidator,
    required this.onAreaSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController areaController;
  final bool searching;
  final List<PlaceSuggestion> suggestions;
  final String? notice;
  final bool saving;
  final ValueChanged<String> onAreaChanged;
  final VoidCallback onAreaTap;
  final ValueChanged<PlaceSuggestion> onSelectSuggestion;
  final FormFieldValidator<String> areaValidator;
  final VoidCallback onAreaSave;

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
              'Area of service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Search for the suburb or area you work in and choose it from the list.',
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
            ),
            const SizedBox(height: 20),
            const ProfileFieldLabel('Area'),
            TextFormField(
              controller: areaController,
              onChanged: onAreaChanged,
              onTap: onAreaTap,
              decoration: profileFieldDecoration(
                null,
                icon: Icons.location_on_outlined,
                hint: 'Start typing a suburb or area',
              ),
              validator: areaValidator,
            ),
            if (searching)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.primaryRust,
                  backgroundColor: AppColors.lightRustBg,
                ),
              ),
            if (suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < suggestions.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
                      InkWell(
                        onTap: () => onSelectSuggestion(suggestions[i]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.place_outlined,
                                size: 18,
                                color: AppColors.primaryRust,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  suggestions[i].description,
                                  style: const TextStyle(fontSize: 13, color: AppColors.darkText),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (notice != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  notice!,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            const SizedBox(height: 16),
            ProfileSaveButton(
              label: 'Save area',
              saving: saving,
              onPressed: saving ? null : onAreaSave,
            ),
          ],
        ),
      ),
    );
  }
}
