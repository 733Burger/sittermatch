import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'sitter_detail_screen.dart';
import 'booking_flow_screen.dart';
import 'direct_chat_screen.dart';
import 'messages_screen.dart';
import 'accepted_booking_screen.dart';
import 'ongoing_booking_screen.dart';
import 'owner_profile_screen.dart';
import 'previous_booking_screen.dart';

/// Plain data the booking cards draw from.
/// status: 'ongoing' | 'accepted' | 'completed' | 'searching'
class _BookingView {
  final String status;
  final String title;
  final String subtitle;
  final String? sitterName;
  final bool showAvatar;

  const _BookingView({
    required this.status,
    required this.title,
    required this.subtitle,
    this.sitterName,
    this.showAvatar = false,
  });
}

class BookingsDashboardScreen extends StatefulWidget {
  const BookingsDashboardScreen({super.key});

  @override
  State<BookingsDashboardScreen> createState() => _BookingsDashboardScreenState();
}

class _BookingsDashboardScreenState extends State<BookingsDashboardScreen> {
  late Future<List<BookingModel>> _bookingsFuture;

  // 'accepted', 'searching', 'completed', or null to show everything.
  String? _selectedFilter;

  // Placeholder completed booking, shown only when the backend returns none.
  // Set to false (or delete) once real completed bookings come through.
  static const bool _showSampleCompleted = true;
  static const _BookingView _sampleCompleted = _BookingView(
    status: 'completed',
    title: 'Sea Point Apartment',
    subtitle: 'Sep 5 – 9',
    sitterName: 'Sarah Jenkins',
    showAvatar: true,
  );

  @override
  void initState() {
    super.initState();
    _bookingsFuture = BookingService.fetchDashboardBookings();
  }

  // ---------- Helpers ----------

  _BookingView _toView(BookingModel booking) {
    String status;
    if (booking.type == BookingType.active) {
      status = 'ongoing';
    } else if (booking.type == BookingType.upcoming) {
      status = 'accepted';
    } else if (booking.type == BookingType.completed) {
      status = 'completed';
    } else {
      status = 'searching'; // any other booking type
    }

    return _BookingView(
      status: status,
      title: booking.title,
      subtitle: booking.subtitle,
      sitterName: booking.sitterName,
      showAvatar: booking.avatarUrl != null,
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirmCancel(String bookingTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text('Are you sure you want to cancel "$bookingTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep booking'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: send the cancellation to the backend.
              _showSnack('Cancellation request sent.');
            },
            child: const Text('Cancel booking', style: TextStyle(color: Colors.red)),
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

          final views = snapshot.data!.map(_toView).toList();
          if (_showSampleCompleted && !views.any((v) => v.status == 'completed')) {
            views.add(_sampleCompleted);
          }

          final ongoing = views.where((v) => v.status == 'ongoing').toList();
          final others = views.where((v) => v.status != 'ongoing').toList();
          final visible = _selectedFilter == null
              ? others
              : others.where((v) => v.status == _selectedFilter).toList();

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
              // Home is the first screen in the stack after login.
              Navigator.of(context).popUntil((route) => route.isFirst);
              break;
            case 1:
              break; // already on Bookings
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

  // ---------- Filter pills ----------

  Widget _buildFilterPills(List<_BookingView> others) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPill('ACCEPTED', 'accepted', others),
          const SizedBox(width: 8),
          _buildPill('SEARCHING', 'searching', others),
          const SizedBox(width: 8),
          _buildPill('COMPLETED', 'completed', others),
        ],
      ),
    );
  }

  Widget _buildPill(String label, String status, List<_BookingView> others) {
    final isSelected = _selectedFilter == status;
    final count = others.where((v) => v.status == status).length;

    return GestureDetector(
      // Tapping the selected pill again clears the filter.
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

  // ---------- Booking card ----------

  Widget _buildStatusBadge(String status) {
    late final String label;
    late final IconData icon;
    switch (status) {
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

  Widget _buildCancelButton(_BookingView booking) {
    return OutlinedButton.icon(
      onPressed: () => _confirmCancel(booking.title),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: Colors.red),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
      label: const Text('Cancel Booking', style: TextStyle(color: Colors.red, fontSize: 12)),
    );
  }

  Widget _buildBookingCard(_BookingView booking) {
    final status = booking.status;

    return GestureDetector(
      onTap: () {
        Widget screen;
        if (status == 'completed') {
          screen = const PreviousBookingsScreen();
        } else if (status == 'accepted') {
          screen = const AcceptedBookingScreen();
        } else {
          screen = const SitterDetailScreen();
        }
        _open(screen);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completed cards show the badge beside the info instead of above it.
            if (status != 'completed') ...[
              _buildStatusBadge(status),
              const SizedBox(height: 16),
            ],
            Row(
              crossAxisAlignment:
                  status == 'completed' ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                if (booking.showAvatar) ...[
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
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
                  _buildStatusBadge(status),
                ],
              ],
            ),

            // Ongoing: a single button to view the booking.
            if (status == 'ongoing') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _open(const OngoingBookingScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.heritageFooterBg,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.radar, color: Colors.white, size: 18),
                  label: const Text(
                    'View In-Progress Booking',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],

            // Accepted: message the sitter or cancel.
            if (status == 'accepted') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _open(const DirectChatScreen()),
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
              ),
            ],

            // Searching: no sitter yet, so only cancel.
            if (status == 'searching') ...[
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: _buildCancelButton(booking)),
            ],
          ],
        ),
      ),
    );
  }
}