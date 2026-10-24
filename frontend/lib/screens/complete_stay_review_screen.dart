import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/pet_model.dart';
import '../services/booking_service.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';

/// Reviews the other side of a stay. A sitter rates the homeowner and each pet; a homeowner rates
/// the sitter. Reviews are hidden until an admin approves them.
///
/// With [completing] the stay is being ended here, so the user can also end it without a review.
/// Pops true once the booking is completed or the review is saved.
class CompleteStayReviewScreen extends StatefulWidget {
  final BookingModel? booking;
  final List<PetModel> pets;
  final bool isSitter;
  final bool completing;

  const CompleteStayReviewScreen({
    super.key,
    this.booking,
    this.pets = const [],
    required this.isSitter,
    this.completing = true,
  });

  @override
  State<CompleteStayReviewScreen> createState() => _CompleteStayReviewScreenState();
}

class _CompleteStayReviewScreenState extends State<CompleteStayReviewScreen> {
  int _rating = 5;
  final TextEditingController _commentCtrl = TextEditingController();
  final Map<int, int> _petRatings = {};
  final Map<int, TextEditingController> _petReviewCtrls = {};
  bool _isSubmitting = false;

  // Only sitters rate pets.
  List<PetModel> get _pets => widget.isSitter ? widget.pets.where((p) => p.id != null).toList() : const [];

  String get _otherName => widget.isSitter
      ? (widget.booking?.homeownerName ?? 'the homeowner')
      : (widget.booking?.sitterName ?? 'your sitter');

  @override
  void initState() {
    super.initState();
    for (final pet in _pets) {
      _petRatings[pet.id!] = 5;
      _petReviewCtrls[pet.id!] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    for (final c in _petReviewCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitReview() async {
    final bookingId = widget.booking?.bookingId;
    if (bookingId == null) {
      _showSnack('Could not find this booking.');
      return;
    }
    if (_commentCtrl.text.trim().isEmpty) {
      _showSnack('Write a few words about $_otherName.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Saving the review also marks the booking completed.
      await ReviewService.submitStayReview(
        bookingId: bookingId,
        sitterId: widget.booking?.sitterId,
        homeownerId: widget.booking?.homeownerId,
        reviewedBy: widget.isSitter ? 'SITTER' : 'HOMEOWNER',
        rating: _rating,
        comments: _commentCtrl.text.trim(),
        petReviews: [
          for (final pet in _pets)
            {
              'petId': pet.id,
              'rating': _petRatings[pet.id] ?? 5,
              'notes': _petReviewCtrls[pet.id]!.text.trim(),
            },
        ],
      );
      if (!mounted) return;
      _showSnack('Thank you! Your review will show once an admin has approved it.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _completeWithoutReview() async {
    final bookingId = widget.booking?.bookingId;
    if (bookingId == null) return;
    setState(() => _isSubmitting = true);
    try {
      await BookingService.updateBookingStatus(bookingId: bookingId, status: 'COMPLETED');
      if (!mounted) return;
      _showSnack('Stay completed. You can still leave a review from your bookings.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnack('Could not complete the stay: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      );

  Widget _stars(int value, ValueChanged<int> onChanged) {
    return Row(
      children: List.generate(
        5,
        (i) => IconButton(
          icon: Icon(i < value ? Icons.star : Icons.star_border, color: Colors.amber, size: 28),
          onPressed: () => onChanged(i + 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.completing ? 'Complete Stay & Review' : 'Leave a Review';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRust))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration,
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.lightRustBg,
                        child: Icon(Icons.check_circle_outline, color: AppColors.primaryRust, size: 36),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.isSitter ? 'Thanks for looking after them!' : 'How was your stay?',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tell others what $_otherName was like. An admin checks every review before it '
                        'shows on their profile.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isSitter ? 'Rate the homeowner ($_otherName)' : 'Rate your sitter ($_otherName)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkText),
                      ),
                      const SizedBox(height: 8),
                      _stars(_rating, (v) => setState(() => _rating = v)),
                      TextField(
                        controller: _commentCtrl,
                        maxLines: 3,
                        maxLength: 255,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: widget.isSitter
                              ? 'Communication, the state of the house, instructions...'
                              : 'Care for your pets, communication, how the home was left...',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._pets.map((pet) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rate ${pet.name} (${petTypeLabel(pet.species)})',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                          const SizedBox(height: 8),
                          _stars(_petRatings[pet.id] ?? 5, (v) => setState(() => _petRatings[pet.id!] = v)),
                          TextField(
                            controller: _petReviewCtrls[pet.id],
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: "How was ${pet.name}'s behaviour?",
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    )),
                ElevatedButton(
                  onPressed: _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRust,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    widget.completing ? 'Submit Review & Complete Stay' : 'Submit Review',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.completing) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _completeWithoutReview,
                    child: const Text('Complete without a review',
                        style: TextStyle(color: AppColors.primaryRust, fontWeight: FontWeight.bold)),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}
