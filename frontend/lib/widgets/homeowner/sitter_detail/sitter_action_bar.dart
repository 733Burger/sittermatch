import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class SitterActionBar extends StatelessWidget {
  const SitterActionBar({
    super.key,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onMessage,
  });

  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Tooltip(
            message: isFavorite ? 'Remove from saved' : 'Save sitter',
            child: InkWell(
              onTap: onToggleFavorite,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  color: isFavorite ? AppColors.primaryRust : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRust,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
              label: const Text(
                'Message Sitter',
                style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}