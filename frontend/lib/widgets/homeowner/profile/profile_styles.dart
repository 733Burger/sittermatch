import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

const Widget profileButtonSpinner = SizedBox(
  width: 16,
  height: 16,
  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
);

BoxDecoration profileCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.shade200),
  );
}

InputDecoration profileFieldDecoration(String? label, {IconData? icon, String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
    prefixIcon: icon == null ? null : Icon(icon, color: AppColors.primaryRust),
    filled: true,
    fillColor: AppColors.expandButtonBg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primaryRust, width: 1.5),
    ),
  );
}

class ProfileFieldLabel extends StatelessWidget {
  const ProfileFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
          children: const [
            TextSpan(text: ' *', style: TextStyle(color: AppColors.primaryRust)),
          ],
        ),
      ),
    );
  }
}

class ProfileSaveButton extends StatelessWidget {
  const ProfileSaveButton({
    super.key,
    required this.label,
    required this.saving,
    required this.onPressed,
  });

  final String label;
  final bool saving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: saving
            ? profileButtonSpinner
            : Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

class ProfileTag extends StatelessWidget {
  const ProfileTag(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightRustBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryRust,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ProfileStars extends StatelessWidget {
  const ProfileStars({super.key, required this.score, this.size = 16});

  final double score;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final remaining = score - i;
        final IconData icon;
        if (remaining >= 1) {
          icon = Icons.star_rounded;
        } else if (remaining >= 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, color: AppColors.primaryRust, size: size);
      }),
    );
  }
}
