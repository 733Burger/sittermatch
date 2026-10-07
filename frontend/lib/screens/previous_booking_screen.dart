import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../theme/app_colors.dart';
import 'direct_chat_screen.dart';

/// A completed booking and (if the user left one) the review they gave.
class _PastBooking {
  final String title;
  final String dates;
  final int nights;
  final String otherName; // the sitter (for owners) or homeowner (for sitters)
  final String service;
  final String? notes;
  double? rating;
  String? comment;
  String? reviewedOn;

  _PastBooking({
    required this.title,
    required this.dates,
    required this.nights,
    required this.otherName,
    required this.service,
    this.notes,
    this.rating,
    this.comment,
    this.reviewedOn,
  });

  bool get hasReview => rating != null;
}

class PreviousBookingsScreen extends StatefulWidget {
  const PreviousBookingsScreen({super.key});

  @override
  State<PreviousBookingsScreen> createState() => _PreviousBookingsScreenState();
}

class _PreviousBookingsScreenState extends State<PreviousBookingsScreen> {
  // Sample bookings so the layout can be seen.
  // Set to false once real completed bookings come from the backend.
  static const bool _useSampleData = true;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  bool _loading = true;
  bool _isSitter = false;
  List<_PastBooking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final role = await AuthService().getUserRole();
    if (!mounted) return;
    final isSitter = (role ?? '').toUpperCase() == 'SITTER';
    setState(() {
      _isSitter = isSitter;
      // TODO: load the real completed bookings from the backend.
      _bookings = _useSampleData ? _sampleFor(isSitter) : <_PastBooking>[];
      _loading = false;
    });
  }

  // Homeowners see the sitters they booked; sitters see the homeowners they sat for.
  List<_PastBooking> _sampleFor(bool isSitter) {
    if (isSitter) {
      return [
        _PastBooking(
          title: 'Sea Point Apartment',
          dates: 'Sep 5 – 9',
          nights: 4,
          otherName: 'Joshua Stevens',
          service: 'Stay over night',
          rating: 5.0,
          comment: 'Joshua was a great host. Clear instructions and a lovely home.',
          reviewedOn: 'Sep 10',
        ),
        _PastBooking(
          title: 'Claremont Cottage',
          dates: 'Aug 14 – 16',
          nights: 2,
          otherName: 'Claire Vance',
          service: 'Stay over night, Feed dog',
          notes: 'Gate code changes daily. Claire texts it each morning.',
          rating: 4.5,
          comment: 'Easy to deal with and very organised.',
          reviewedOn: 'Aug 17',
        ),
        _PastBooking(
          title: 'Constantia Villa',
          dates: 'Jul 3 – 6',
          nights: 3,
          otherName: 'Thandi Mokoena',
          service: 'Stay over night',
        ),
      ];
    }
    return [
      _PastBooking(
        title: 'Sea Point Apartment',
        dates: 'Sep 5 – 9',
        nights: 4,
        otherName: 'Sarah Jenkins',
        service: 'Stay over night',
        rating: 5.0,
        comment: 'Sarah was brilliant with Buster! Daily updates and everything spotless.',
        reviewedOn: 'Sep 10',
      ),
      _PastBooking(
        title: 'Claremont Cottage',
        dates: 'Aug 14 – 16',
        nights: 2,
        otherName: 'Michael Tau',
        service: 'Stay over night, Feed dog',
        notes: 'Two walks a day for Buster.',
        rating: 4.5,
        comment: 'Reliable and friendly. Would book again.',
        reviewedOn: 'Aug 17',
      ),
      _PastBooking(
        title: 'Constantia Villa',
        dates: 'Jul 3 – 6',
        nights: 3,
        otherName: 'Jessica Daniels',
        service: 'Stay over night',
      ),
    ];
  }

  // ---------- Helpers ----------

  String get _otherLabel => _isSitter ? 'Homeowner' : 'Sitter';

  String _todayLabel() {
    final now = DateTime.now();
    return '${_months[now.month - 1]} ${now.day}';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openChat() {
    // TODO: pass the selected person once DirectChatScreen accepts one.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DirectChatScreen()),
    );
  }

  void _showReviewDialog(_PastBooking booking) {
    double rating = 0;
    final commentCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Review ${booking.otherName}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    onPressed: () => setDialogState(() {
                      rating = i + 1.0;
                      error = null;
                    }),
                    icon: Icon(
                      rating >= i + 1 ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.primaryRust,
                      size: 34,
                    ),
                  );
                }),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (rating == 0) {
                  setDialogState(() => error = 'Please choose a star rating');
                  return;
                }
                final comment = commentCtrl.text.trim();
                setState(() {
                  booking.rating = rating;
                  booking.comment = comment.isEmpty ? null : comment;
                  booking.reviewedOn = _todayLabel();
                });
                // TODO: save the review to the backend.
                Navigator.pop(ctx);
                _showSnack('Review saved.');
              },
              child: const Text('Save review'),
            ),
          ],
        ),
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
        title: Text(
          _isSitter ? 'Previous Jobs' : 'Previous Bookings',
          style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRust))
          : _bookings.isEmpty
              ? _buildEmptyState()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        '${_bookings.length} completed ${_isSitter ? (_bookings.length == 1 ? 'job' : 'jobs') : (_bookings.length == 1 ? 'booking' : 'bookings')}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    ..._bookings.map(_buildBookingCard),
                    const SizedBox(height: 8),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.lightRustBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, color: AppColors.primaryRust, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              _isSitter ? 'No previous jobs yet' : 'No previous bookings yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Completed stays and your reviews will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(_PastBooking booking) {
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
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppColors.primaryRust),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$_otherLabel: ${booking.otherName}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildCompletedBadge(),
            ],
          ),
          const SizedBox(height: 14),
          _buildDetailsBlock(booking),
          const SizedBox(height: 14),
          _buildReviewBlock(booking),
          const SizedBox(height: 14),
          _buildActions(booking),
        ],
      ),
    );
  }

  Widget _buildCompletedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightRustBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.primaryRust, size: 12),
          SizedBox(width: 4),
          Text(
            'COMPLETED',
            style: TextStyle(
              color: AppColors.primaryRust,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsBlock(_PastBooking booking) {
    final nightsText = '${booking.nights} ${booking.nights == 1 ? 'night' : 'nights'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.calendar_today_outlined, 'Dates', '${booking.dates} · $nightsText'),
          const SizedBox(height: 8),
          _buildDetailRow(Icons.work_outline, 'Service', booking.service),
          if (booking.notes != null && booking.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildDetailRow(Icons.note_alt_outlined, 'Notes', booking.notes!),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryRust, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildStars(double score, {double size = 16}) {
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
        return Icon(icon, color: AppColors.primaryRust, size: size);
      }),
    );
  }

  Widget _buildReviewBlock(_PastBooking booking) {
    if (!booking.hasReview) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "You haven't reviewed ${booking.otherName} yet.",
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      );
    }

    final comment = booking.comment;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightRustBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'YOUR REVIEW',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.primaryRust,
                  ),
                ),
              ),
              if (booking.reviewedOn != null)
                Text(
                  booking.reviewedOn!,
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildStars(booking.rating!),
              const SizedBox(width: 6),
              Text(
                booking.rating!.toStringAsFixed(1),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (comment != null && comment.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"$comment"',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(_PastBooking booking) {
    return Row(
      children: [
        if (!booking.hasReview) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showReviewDialog(booking),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.primaryRust),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.star_outline_rounded, color: AppColors.primaryRust, size: 16),
              label: const Text(
                'Leave a review',
                style: TextStyle(color: AppColors.primaryRust, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _openChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRust,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
            label: Text(
              'Message $_otherLabel',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}