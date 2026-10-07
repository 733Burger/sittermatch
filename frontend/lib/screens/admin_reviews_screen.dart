import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme/app_colors.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  late Future<List<ReviewItem>> _future;
  bool _flaggedOnly = false;

  @override
  void initState() {
    super.initState();
    _future = AdminService.fetchPendingReviews();
  }

  void _reload() {
    setState(() => _future = AdminService.fetchPendingReviews());
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _approve(ReviewItem review) async {
    await AdminService.resolveReview(review.id, approved: true);
    if (!mounted) return;
    _reload();
    _showSnack('Review approved and now visible on ${review.revieweeName}\'s profile.');
  }

  void _confirmRemove(ReviewItem review) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this review?'),
        content: Text(
          'The review from ${review.reviewerName} will not be shown on '
          '${review.revieweeName}\'s profile.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Go back')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminService.resolveReview(review.id, approved: false);
              if (!mounted) return;
              _reload();
              _showSnack('Review removed.');
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Review Verifier',
          style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<ReviewItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryRust));
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load reviews.', style: TextStyle(color: Colors.red)),
            );
          }

          final all = snapshot.data!;
          final flaggedCount = all.where((r) => r.flagReason != null).length;
          final visible = _flaggedOnly ? all.where((r) => r.flagReason != null).toList() : all;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${all.length} waiting for approval',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPill('ALL (${all.length})', !_flaggedOnly, () {
                    setState(() => _flaggedOnly = false);
                  }),
                  const SizedBox(width: 8),
                  _buildPill('FLAGGED ($flaggedCount)', _flaggedOnly, () {
                    setState(() => _flaggedOnly = !_flaggedOnly);
                  }),
                ],
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                _buildEmptyState()
              else
                ...visible.map(_buildReviewCard),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRust : AppColors.expandButtonBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.darkText.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: const Column(
        children: [
          Icon(Icons.rate_review_outlined, color: AppColors.primaryRust, size: 40),
          SizedBox(height: 12),
          Text(
            'All caught up',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          SizedBox(height: 4),
          Text(
            'There are no reviews waiting for approval.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildStars(double score) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final remaining = score - i;
        IconData icon;
        if (remaining >= 1) {
          icon = Icons.star_rounded;
        } else if (remaining >= 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, color: AppColors.primaryRust, size: 16);
      }),
    );
  }

  Widget _buildReviewCard(ReviewItem review) {
    final reviewerRole = review.reviewerRole == 'SITTER' ? 'Sitter' : 'Homeowner';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (review.flagReason != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.lightRustBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag_outlined, color: AppColors.primaryRust, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      review.flagReason!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRust,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: review.reviewerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' ($reviewerRole) reviewed '),
                      TextSpan(
                        text: review.revieweeName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 13, color: AppColors.darkText),
                ),
              ),
              const SizedBox(width: 8),
              Text(review.date, style: const TextStyle(fontSize: 11, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStars(review.rating),
              const SizedBox(width: 6),
              Text(
                review.rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"${review.comment}"',
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmRemove(review),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                  label: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approve(review),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRust,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white, size: 16),
                  label: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}