import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../models/pet_model.dart';
import '../models/review_model.dart';
import '../services/auth_services.dart';
import '../services/booking_service.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';
import 'complete_stay_review_screen.dart';
import 'direct_chat_screen.dart';
import 'homeowner_detail_screen.dart';
import 'sitter_detail_screen.dart';

/// What a sitter chose on a booking they opened before offering on it.
enum BookingResponseChoice { sendOffer, decline }

/// One booking in full: dates, services, notes, pets and the reviews for the stay. Used for every
/// booking, whatever its status.
///
/// With [canRespond] a sitter is looking at a pending booking before offering on it, and the
/// screen pops a [BookingResponseChoice]. Otherwise it pops true if the booking changed.
class AcceptedBookingScreen extends StatefulWidget {
  final BookingModel? booking;
  final bool canRespond;

  const AcceptedBookingScreen({super.key, this.booking, this.canRespond = false});

  @override
  State<AcceptedBookingScreen> createState() => _AcceptedBookingScreenState();
}

class _AcceptedBookingScreenState extends State<AcceptedBookingScreen> {
  bool _loading = true;
  bool _isSitter = false;
  int? _myId;
  bool _busy = false;
  List<PetModel> _pets = [];
  List<StayReview> _reviews = [];
  bool _reviewedNow = false;

  BookingModel? get _job => widget.booking;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final role = await AuthService().getUserRole();
    final id = await AuthService().getUserId();
    final job = _job;

    if (job?.homeownerId != null) {
      try {
        _pets = await BookingService.fetchHomeownerPets(job!.homeownerId!);
      } catch (e) {
        debugPrint('Error loading pets: $e');
      }
    }
    await _loadReviews();

    if (!mounted) return;
    setState(() {
      _isSitter = (role ?? '').toUpperCase() == 'SITTER';
      _myId = id;
      _loading = false;
    });
  }

  Future<void> _loadReviews() async {
    final bookingId = _job?.bookingId;
    if (bookingId == null || _job?.isCompleted != true) return;
    try {
      _reviews = await ReviewService.fetchBookingReviews(bookingId);
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String get _partnerName => _isSitter
      ? (_job?.homeownerName ?? 'Homeowner')
      : (_job?.sitterName ?? 'Sitter');

  int? get _partnerId => _isSitter ? _job?.homeownerId : _job?.sitterId;

  bool get _isPending => _job?.type == BookingType.upcoming;
  bool get _isAccepted => _job?.type == BookingType.active;
  bool get _isCompleted => _job?.isCompleted == true;
  bool get _myOfferSent => _isSitter && _job?.hasOfferFrom(_myId) == true;

  bool get _iReviewed =>
      _reviewedNow || (_isSitter ? _job?.sitterReviewed == true : _job?.homeownerReviewed == true);
  bool get _canReview => _isCompleted && !_iReviewed && _job?.sitterId != null;

  void _openChat() {
    final partnerId = _partnerId;
    if (partnerId == null) {
      _showSnack('There is no sitter on this booking yet.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(partnerId: partnerId, partnerName: _partnerName),
      ),
    );
  }

  // Sitters open the homeowner's profile; homeowners open the sitter's.
  void _openPartnerProfile() {
    final partnerId = _partnerId;
    if (partnerId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _isSitter
            ? HomeownerDetailScreen(homeownerId: partnerId, homeownerName: _partnerName, booking: _job)
            : SitterDetailScreen(sitterId: partnerId),
      ),
    );
  }

  Future<void> _leaveReview() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CompleteStayReviewScreen(
          booking: _job,
          pets: _pets,
          isSitter: _isSitter,
          completing: false,
        ),
      ),
    );
    if (saved != true || !mounted) return;
    _reviewedNow = true;
    await _loadReviews();
    if (mounted) setState(() {});
  }

  // A homeowner cancelling deletes the booking; a sitter cancelling hands it back as declined.
  void _confirmCancel() {
    final noun = _isSitter ? 'job' : 'booking';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel this $noun?'),
        content: Text(_isSitter
            ? 'The homeowner will see that you cancelled "${_job?.title ?? "this stay"}".'
            : 'This cancels and deletes "${_job?.title ?? "this stay"}". It cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Stay', style: TextStyle(color: AppColors.darkText)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancel();
            },
            child: Text('Cancel $noun', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel() async {
    final bookingId = _job?.bookingId;
    if (bookingId == null) return;
    setState(() => _busy = true);
    try {
      if (_isSitter) {
        await BookingService.updateBookingStatus(bookingId: bookingId, status: 'DECLINED');
      } else {
        await BookingService.deleteBooking(bookingId);
      }
      if (!mounted) return;
      _showSnack(_isSitter ? 'Job cancelled.' : 'Booking cancelled and deleted.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showSnack('Could not cancel: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryRust),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
        ),
      ],
    );
  }

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
          _isSitter ? 'Job Details' : 'Booking Details',
          style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading || _busy
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRust))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildPartnerCard(),
                const SizedBox(height: 16),
                _buildPetsCard(),
                const SizedBox(height: 16),
                _buildNotesCard(),
                if (_isCompleted) ...[
                  const SizedBox(height: 16),
                  _buildReviewsSection(),
                ],
                const SizedBox(height: 24),
              ],
            ),
      bottomNavigationBar: _loading || _busy ? null : _buildActionBar(),
    );
  }

  ({String label, IconData icon, Color color}) get _statusStyle {
    const rust = AppColors.primaryRust;
    final job = _job;
    if (job == null) return (label: 'BOOKING', icon: Icons.event_note, color: rust);
    if (job.isCompleted) return (label: 'COMPLETED', icon: Icons.check_circle, color: Colors.green.shade700);
    if (job.rawStatus == 'DECLINED' || job.rawStatus == 'CANCELLED') {
      return (label: job.rawStatus, icon: Icons.cancel, color: Colors.red.shade700);
    }
    if (job.isOngoing) return (label: 'ONGOING', icon: Icons.circle, color: rust);
    if (_isAccepted) return (label: 'ACCEPTED', icon: Icons.event_available, color: rust);
    if (_myOfferSent) return (label: 'OFFER SENT', icon: Icons.send, color: rust);
    if (!_isSitter && job.offers.isNotEmpty) {
      return (label: 'OFFERS SENT (${job.offers.length})', icon: Icons.mark_chat_unread, color: rust);
    }
    if (job.sitterId == null) {
      return (label: _isSitter ? 'OPEN REQUEST' : 'SEARCHING', icon: Icons.search, color: rust);
    }
    return (label: 'PENDING', icon: Icons.hourglass_empty, color: rust);
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String get _dateRange {
    final start = _job?.startDate, end = _job?.endDate;
    if (start == null || end == null) return 'Dates unconfirmed';
    return '${_months[start.month - 1]} ${start.day} – ${_months[end.month - 1]} ${end.day}';
  }

  int? get _totalDays {
    final start = _job?.startDate, end = _job?.endDate;
    if (start == null || end == null) return null;
    final diff = DateTime(end.year, end.month, end.day).difference(DateTime(start.year, start.month, start.day)).inDays;
    return diff <= 0 ? 1 : diff + 1;
  }

  // How far off the stay is, e.g. "Starts in 3 days".
  String get _timingLabel {
    final start = _job?.startDate;
    if (start == null) return '';
    if (_isCompleted) return 'Finished';
    final now = DateTime.now();
    final days = DateTime(start.year, start.month, start.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days > 1) return 'Starts in $days days';
    if (days == 1) return 'Starts tomorrow';
    if (days == 0) return 'Starts today';
    return '';
  }

  Widget _buildSummaryCard() {
    final job = _job;
    final style = _statusStyle;
    final days = _totalDays;
    final services = servicesForBookingType(job?.rightBadgeText ?? '');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(style.icon, color: style.color, size: style.icon == Icons.circle ? 8 : 12),
                    const SizedBox(width: 6),
                    Text(style.label,
                        style: TextStyle(color: style.color, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (job?.bookingId != null)
                Text('ID #${job!.bookingId}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 14),
          Text(job?.title ?? 'Pet Sitting',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: AppColors.primaryRust, size: 16),
              const SizedBox(width: 8),
              Text(_dateRange, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(days == null ? '–' : '$days', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text(days == 1 ? 'day' : 'days', style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const Spacer(),
              if (_timingLabel.isNotEmpty)
                Text(
                  _timingLabel,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryRust),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (services.isEmpty
                    ? [job?.rightBadgeText ?? 'Pet sitting']
                    : services.map((s) => bookingServiceLabels[s]!))
                .map((label) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.lightRustBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(label,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryRust)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // Who the stay is with. Tap to open their profile.
  Widget _buildPartnerCard() {
    final hasPartner = _partnerId != null;
    // The booking's avatar is the sitter's photo, so only show it to the homeowner.
    final avatarUrl = _isSitter ? null : _job?.avatarUrl;
    final subtitle = !hasPartner
        ? 'No sitter yet. Sitters can send you offers.'
        : _isSitter
            ? 'Homeowner · View profile'
            : 'Your sitter · View profile';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasPartner ? _openPartnerProfile : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.lightRustBg,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(!hasPartner ? Icons.search : _isSitter ? Icons.home_outlined : Icons.person,
                        color: AppColors.primaryRust)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hasPartner ? _partnerName : 'Looking for a sitter',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (hasPartner)
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.lightRustBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  tooltip: 'Message',
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryRust, size: 20),
                  onPressed: _openChat,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.pets, _isSitter ? 'Pets to Care For' : 'Your Pets'),
          const SizedBox(height: 12),
          if (_pets.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.pets_outlined, size: 16, color: AppColors.primaryRust),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('No registered pets found for this homeowner.',
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _pets.map(_buildPetChip).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPetChip(PetModel pet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pets_outlined, size: 14, color: AppColors.primaryRust),
          const SizedBox(width: 6),
          Text(
            '${pet.name} (${petTypeLabel(pet.species)}${pet.breed.isNotEmpty ? ' - ${pet.breed}' : ''})',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    final notes = _job?.homeownerNotes ?? 'No special requirements specified.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.notes_outlined, _isSitter ? "Homeowner's Requirements" : 'Your Requirements'),
          const SizedBox(height: 10),
          Text(notes, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    // The other side's review only shows once an admin approves it; your own shows straight away.
    final mine = _isSitter ? 'SITTER' : 'HOMEOWNER';
    final visible = _reviews.where((r) => r.reviewedBy == mine || r.isPublished).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader(Icons.star_outline_rounded, 'Reviews'),
              if (_canReview)
                TextButton(
                  onPressed: _leaveReview,
                  child: const Text(
                    'Leave Review',
                    style: TextStyle(color: AppColors.primaryRust, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            Text(
              _canReview
                  ? 'How did it go? Leave a review for $_partnerName.'
                  : 'No reviews for this stay yet.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            )
          else
            ...visible.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildSingleReviewTile(r, isMine: r.reviewedBy == mine),
                )),
        ],
      ),
    );
  }

  Widget _buildSingleReviewTile(StayReview review, {required bool isMine}) {
    final author = isMine ? 'You' : review.reviewerName;
    final role = review.isBySitter ? 'Sitter' : 'Homeowner';
    final date = [
      review.dateLabel,
      if (!review.isPublished) 'Waiting for admin approval',
    ].where((s) => s.isNotEmpty).join(' · ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$author ($role)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkText),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.comment.isEmpty ? 'No comment.' : review.comment,
            style: const TextStyle(fontSize: 12, color: Colors.black87, fontStyle: FontStyle.italic),
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    final Widget content;

    if (widget.canRespond && _isPending && !_myOfferSent) {
      content = Row(
        children: [
          Expanded(
            child: _outlinedButton(
              label: 'Decline',
              icon: Icons.cancel_outlined,
              onPressed: () => Navigator.pop(context, BookingResponseChoice.decline),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _filledButton(
              label: 'Send offer',
              icon: Icons.send_outlined,
              color: Colors.green,
              onPressed: () => Navigator.pop(context, BookingResponseChoice.sendOffer),
            ),
          ),
        ],
      );
    } else if (_isCompleted) {
      content = Row(
        children: [
          if (_partnerId != null)
            Expanded(
              child: _outlinedButton(
                label: 'Message',
                icon: Icons.chat_bubble_outline,
                color: AppColors.primaryRust,
                onPressed: _openChat,
              ),
            ),
          if (_partnerId != null && _canReview) const SizedBox(width: 12),
          if (_canReview)
            Expanded(
              child: _filledButton(label: 'Leave Review', icon: Icons.star_outline_rounded, onPressed: _leaveReview),
            ),
        ],
      );
    } else if (_isAccepted || (_isPending && !_isSitter)) {
      content = Row(
        children: [
          Expanded(
            child: _outlinedButton(
              label: _isSitter ? 'Cancel Job' : 'Cancel Booking',
              icon: Icons.cancel_outlined,
              onPressed: _confirmCancel,
            ),
          ),
          if (_partnerId != null) ...[
            const SizedBox(width: 12),
            Expanded(child: _filledButton(label: 'Message', icon: Icons.chat_bubble_outline, onPressed: _openChat)),
          ],
        ],
      );
    } else if (_partnerId != null) {
      content = _filledButton(label: 'Message', icon: Icons.chat_bubble_outline, onPressed: _openChat);
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(child: content),
    );
  }

  Widget _outlinedButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.red,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, color: color, size: 18),
      label: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _filledButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = AppColors.primaryRust,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }
}
