import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/profile_completion.dart';

/// Shown on a profile that isn't finished yet. The rest of the app stays locked until it is.
class ProfileGateBanner extends StatelessWidget {
  const ProfileGateBanner({super.key, required this.missing});

  /// What still needs filling in, from [missingProfileItems].
  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightRustBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.primaryRust, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Finish your profile to unlock the rest of the app. Still needed: ${describeMissing(missing)}.',
              style: const TextStyle(
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
