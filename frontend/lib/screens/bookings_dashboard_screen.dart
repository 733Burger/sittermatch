import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/auth_services.dart';
import '../services/booking_service.dart';
import '../theme/app_colors.dart';
import 'accepted_booking_screen.dart';
import 'booking_flow_screen.dart';
import 'booking_offers_screen.dart';
import 'complete_stay_review_screen.dart';
import 'direct_chat_screen.dart';
import 'messages_screen.dart';
import 'ongoing_booking_screen.dart';
import 'owner_profile_screen.dart';

class BookingsDashboardScreen extends StatefulWidget {
  const BookingsDashboardScreen({super.key});

  @override
  State<BookingsDashboardScreen> createState() => _BookingsDashboardScreenState();
}

class _BookingsDashboardScreenState extends State<BookingsDashboardScreen> {
  late Future<List<BookingModel>> _bookingsFuture;
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final userId = await AuthService().getUserId();
    if (!mounted) return;
    setState(() {
      _bookingsFuture = BookingService.fetchDashboardBookings(homeownerId: userId);
    });
  }

  // Reloads when the user comes back, since the screen may have changed the booking.
  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _loadBookings();
  }

  // The sitters offering on a booking. REQUESTED is how a sitter's request was stored before offers.
  int _offerCount(BookingModel booking) =>
      booking.offers.isNotEmpty ? booking.offers.length : (booking.rawStatus == 'REQUESTED' ? 1 : 0);

  void _openOffers(BookingModel booking) {
    if (booking.offers.isEmpty) {
      // An older request only lives in the chat with that sitter.
      _open(DirectChatScreen(partnerId: booking.sitterId, partnerName: booking.sitterName ?? 'Sitter'));
      return;
    }
    _open(BookingOffersScreen(booking: booking));
  }

  void _leaveReview(BookingModel booking) {
    _open(CompleteStayReviewScreen(booking: booking, isSitter: false, completing: false));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Cancelling deletes the booking. A declined booking is removed the same way.
  void _confirmCancel(BookingModel booking) {
    final declined = _getUiStatus(booking) == 'declined';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(declined ? 'Remove this booking?' : 'Cancel this booking?'),
        content: Text(declined
            ? 'This removes "${booking.title}" from your bookings.'
            : 'This cancels and deletes "${booking.title}". It cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep booking'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteBooking(booking, declined ? 'Booking removed.' : 'Booking cancelled and deleted.');
            },
            child: Text(declined ? 'Remove' : 'Cancel booking', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBooking(BookingModel booking, String doneMessage) async {
    final bookingId = booking.bookingId;
    if (bookingId == null) {
      _showSnack('Could not find this booking.');
      return;
    }
    try {
      await BookingService.deleteBooking(bookingId);
      if (!mounted) return;
      _showSnack(doneMessage);
      _loadBookings();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not cancel the booking: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  String _getUiStatus(BookingModel booking) {
    if (booking.rawStatus == 'DECLINED') return 'declined';
    // Accepted bookings only count as ongoing once the stay has started.
    if (booking.isOngoing) return 'ongoing';
    if (booking.type == BookingType.active) return 'accepted';
    if (booking.type == BookingType.completed) return 'completed';
    // One or more sitters have offered to take it.
    if (booking.type == BookingType.upcoming && _offerCount(booking) > 0) return 'offers';
    // No sitter has offered yet.
    if (booking.type == BookingType.upcoming && booking.sitterId == null) return 'searching';
    // Sent to one sitter, waiting for them to offer.
    if (booking.type == BookingType.upcoming) return 'pending';
    return 'searching';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const Icon(Icons.pets, color: AppColors.primaryRust),
        title: const Text('Bookings', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: AppColors.darkText), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF2C2C2C),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(const BookingFlowScreen()),
        backgroundColor: AppColors.primaryRust,
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text('New Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryRust));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load dashboard data.', style: TextStyle(color: Colors.red)));
          }

          final bookings = snapshot.data ?? [];
          final ongoing = bookings.where((b) => _getUiStatus(b) == 'ongoing').toList();
          final others = bookings.where((b) => _getUiStatus(b) != 'ongoing').toList();
          final visible = _selectedFilter == null
              ? others
              : others.where((b) => _getUiStatus(b) == _selectedFilter).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              const SizedBox(height: 10),
              ...ongoing.map(_buildBookingCard),
              _buildFilterPills(others),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                _buildEmptyState()
              else
                ...visible.map(_buildBookingCard),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        currentIndex: 1,
        selectedItemColor: AppColors.primaryRust,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).popUntil((route) => route.isFirst);
              break;
            case 1:
              break;
            case 2:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MessagesScreen()),
              );
              break;
            case 3:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const OwnerProfileScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'BOOKINGS'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'MESSAGES'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PROFILE'),
        ],
      ),
    );
  }

  Widget _buildFilterPills(List<BookingModel> others) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPill('ACCEPTED', 'accepted', others),
          const SizedBox(width: 8),
          _buildPill('OFFERS SENT', 'offers', others),
          const SizedBox(width: 8),
          _buildPill('SEARCHING', 'searching', others),
          const SizedBox(width: 8),
          _buildPill('PENDING', 'pending', others),
          const SizedBox(width: 8),
          _buildPill('COMPLETED', 'completed', others),
          const SizedBox(width: 8),
          _buildPill('DECLINED', 'declined', others),
        ],
      ),
    );
  }

  Widget _buildPill(String label, String status, List<BookingModel> others) {
    final isSelected = _selectedFilter == status;
    final count = others.where((b) => _getUiStatus(b) == status).length;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = isSelected ? null : status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRust : AppColors.expandButtonBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label ($count)',
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
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        'No bookings to show.',
        style: TextStyle(color: AppColors.darkText.withValues(alpha: 0.6), fontSize: 13),
      ),
    );
  }

  Widget _buildStatusBadge(String status, {int offerCount = 0}) {
    late final String label;
    late final IconData icon;
    switch (status) {
      case 'offers':
        label = 'OFFERS SENT ($offerCount)';
        icon = Icons.mark_chat_unread_outlined;
        break;
      case 'pending':
        label = 'PENDING';
        icon = Icons.hourglass_empty;
        break;
      case 'ongoing':
        label = 'ONGOING';
        icon = Icons.circle;
        break;
      case 'accepted':
        label = 'ACCEPTED';
        icon = Icons.event_available;
        break;
      case 'completed':
        label = 'COMPLETED';
        icon = Icons.check_circle_outline;
        break;
      case 'declined':
        label = 'DECLINED';
        icon = Icons.block;
        break;
      default:
        label = 'SEARCHING';
        icon = Icons.search;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightRustBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryRust, size: status == 'ongoing' ? 8 : 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryRust,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.primaryRust, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMessageAndCancelRow(BookingModel booking) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _open(
              DirectChatScreen(partnerId: booking.sitterId, partnerName: booking.sitterName ?? 'Sitter'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRust,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
            label: const Text('Message Sitter', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildCancelButton(booking)),
      ],
    );
  }

  Widget _buildCancelButton(BookingModel booking, {String label = 'Cancel Booking'}) {
    return OutlinedButton.icon(
      onPressed: () => _confirmCancel(booking),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: Colors.red),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
      label: Text(label, style: const TextStyle(color: Colors.red, fontSize: 12)),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final status = _getUiStatus(booking);

    return GestureDetector(
      onTap: () => _open(
        status == 'ongoing' ? OngoingBookingScreen(booking: booking) : AcceptedBookingScreen(booking: booking),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (status != 'completed') ...[
              _buildStatusBadge(status, offerCount: _offerCount(booking)),
              const SizedBox(height: 16),
            ],
            Row(
              crossAxisAlignment: status == 'completed' ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: booking.avatarUrl != null ? NetworkImage(booking.avatarUrl!) : null,
                  child: booking.avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkText.withValues(alpha: 0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (booking.sitterName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: AppColors.primaryRust),
                            const SizedBox(width: 4),
                            Text(
                              'Sitter: ${booking.sitterName}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (status == 'completed') ...[
                  const SizedBox(width: 8),
                  _buildStatusBadge(status, offerCount: _offerCount(booking)),
                ],
              ],
            ),
            if (status == 'ongoing') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _open(OngoingBookingScreen(booking: booking)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.heritageFooterBg,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.radar, color: Colors.white, size: 18),
                  label: const Text('View In-Progress Booking', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
            if (status == 'accepted') ...[
              const SizedBox(height: 16),
              _buildMessageAndCancelRow(booking),
            ],
            if (status == 'offers') ...[
              const SizedBox(height: 16),
              _buildInfo(_offerCount(booking) == 1
                  ? '${booking.offers.isEmpty ? booking.sitterName ?? 'A sitter' : booking.offers.first.sitterName} '
                      'sent an offer. Check their prices and profile, then accept it.'
                  : '${_offerCount(booking)} sitters sent offers. Compare them and accept the one you want.'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openOffers(booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRust,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.people_outline, color: Colors.white, size: 16),
                      label: Text(
                        _offerCount(booking) == 1 ? 'View offer' : 'View offers',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _buildCancelButton(booking)),
                ],
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              _buildInfo('Waiting for ${booking.sitterName ?? 'the sitter'} to respond.'),
              const SizedBox(height: 8),
              _buildMessageAndCancelRow(booking),
            ],
            if (status == 'completed') ...[
              const SizedBox(height: 12),
              if (!booking.homeownerReviewed && booking.sitterId != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _leaveReview(booking),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primaryRust),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.star_outline_rounded, color: AppColors.primaryRust, size: 16),
                    label: Text(
                      'Review ${booking.sitterName ?? 'your sitter'}',
                      style: const TextStyle(color: AppColors.primaryRust, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else if (booking.homeownerReviewed)
                const Text('You reviewed this stay.', style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
            if (status == 'searching') ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(8)),
                child: const Text(
                  "Looking for a sitter. Sitters can see your booking and send you an offer. You'll get a message when one does.",
                  style: TextStyle(color: AppColors.primaryRust, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: _buildCancelButton(booking)),
            ],
            if (status == 'declined') ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${booking.sitterName ?? 'The sitter'} declined this booking. Make a new booking to find another sitter.',
                  style: const TextStyle(color: AppColors.primaryRust, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: _buildCancelButton(booking, label: 'Remove')),
            ],
          ],
        ),
      ),
    );
  }
}