import 'package:flutter/material.dart';

import '../../models/sitter_listing.dart';
import '../../theme/app_colors.dart';

class SitterCard extends StatelessWidget {
  const SitterCard({
    super.key,
    required this.sitter,
    required this.isSaved,
    required this.onTap,
    required this.onMessage,
    required this.onBook,
    required this.onToggleSave,
  });

  final SitterListing sitter;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onMessage;
  final VoidCallback onBook;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SitterAvatar(imageUrl: sitter.imageUrl),
                  const SizedBox(width: 16),
                  Expanded(child: _SitterDetails(sitter: sitter)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CardActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: 'Message',
                      backgroundColor: Colors.black87,
                      onPressed: onMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CardActionButton(
                      icon: Icons.calendar_month,
                      label: 'Book',
                      backgroundColor: AppColors.primaryRust,
                      onPressed: onBook,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? AppColors.primaryRust : Colors.grey,
                      ),
                      onPressed: onToggleSave,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SitterAvatar extends StatelessWidget {
  const _SitterAvatar({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 60,
            height: 60,
            child: url != null
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _AvatarPlaceholder(),
                  )
                : const _AvatarPlaceholder(),
          ),
        ),
        const Positioned(
          bottom: -4,
          right: -4,
          child: CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.primaryRust,
            child: Icon(Icons.check, color: Colors.white, size: 12),
          ),
        ),
      ],
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.person, color: Colors.grey, size: 36),
    );
  }
}

class _SitterDetails extends StatelessWidget {
  const _SitterDetails({required this.sitter});

  final SitterListing sitter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                sitter.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'R${sitter.nightRate.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text: ' / nt',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppColors.primaryRust,
              size: 14,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                sitter.suburb,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.star_rounded,
              color: AppColors.primaryRust,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '${sitter.rating} (${sitter.totalReviews})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 16),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}