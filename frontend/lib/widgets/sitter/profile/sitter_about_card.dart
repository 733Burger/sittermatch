import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../homeowner/profile/profile_styles.dart';

class SitterAboutCard extends StatelessWidget {
  const SitterAboutCard({
    super.key,
    required this.formKey,
    required this.aboutController,
    required this.saving,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController aboutController;
  final bool saving;
  final VoidCallback onSave;

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
              'About & experience',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Optional. Share your background, skills and pet experience.',
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: aboutController,
              minLines: 3,
              maxLines: 8,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              decoration: profileFieldDecoration(
                null,
                hint: 'Share your background, skills and pet experience...',
              ).copyWith(counterText: ''),
            ),
            const SizedBox(height: 16),
            ProfileSaveButton(
              label: 'Save about',
              saving: saving,
              onPressed: saving ? null : onSave,
            ),
          ],
        ),
      ),
    );
  }
}
