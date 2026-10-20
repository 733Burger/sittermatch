import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class ProfileGateBanner extends StatelessWidget {
  const ProfileGateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightRustBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, color: AppColors.primaryRust, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select your home address and add house sitting notes to unlock the rest of the app.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
