import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'profile_styles.dart';

class ProfileUserDetailsCard extends StatelessWidget {
  const ProfileUserDetailsCard({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.saving,
    required this.onChangePassword,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final bool saving;
  final VoidCallback onChangePassword;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: profileCardDecoration(),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Update your name, email and phone number. Your password is changed separately',
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
            ),
            const SizedBox(height: 20),
            const ProfileFieldLabel('Full name'),
            TextFormField(
              controller: nameController,
              maxLength: 100,
              decoration: profileFieldDecoration(null, icon: Icons.person_outline)
                  .copyWith(counterText: ''),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),
            const ProfileFieldLabel('Email'),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: profileFieldDecoration(null, icon: Icons.mail_outline),
              validator: (val) {
                final value = val?.trim() ?? '';
                if (value.isEmpty) return 'Email is required';
                if (!value.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const ProfileFieldLabel('Phone number'),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 20,
              decoration: profileFieldDecoration(null, icon: Icons.phone_outlined)
                  .copyWith(counterText: ''),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Phone number is required' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onChangePassword,
                icon: const Icon(Icons.lock_outline, color: AppColors.primaryRust, size: 18),
                label: const Text(
                  'Change password',
                  style: TextStyle(color: AppColors.darkText, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ProfileSaveButton(
              label: 'Save user details',
              saving: saving,
              onPressed: saving ? null : onSave,
            ),
          ],
        ),
      ),
    );
  }
}
