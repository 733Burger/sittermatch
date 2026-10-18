import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'accepted_booking_screen.dart';
import 'direct_chat_screen.dart';
import 'messages_screen.dart';
import 'ongoing_booking_screen.dart';
import 'previous_booking_screen.dart';
import 'sitter_profile_screen.dart';

class JobsDashboardScreen extends StatefulWidget {
  const JobsDashboardScreen({super.key});

  @override
  State<JobsDashboardScreen> createState() => _JobsDashboardScreenState();
}

class _JobsDashboardScreenState extends State<JobsDashboardScreen> {
  late Future<List<BookingModel>> _jobsFuture;
  String? _selectedFilter;
  bool _isLoadingAction = false;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() {
    // Fetching all bookings for testing. In production, pass sitterId: user.id
    setState(() {
      _jobsFuture = BookingService.fetchDashboardBookings();
    });
  }

  // ---------- Helpers ----------

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Parses the 'B-12' string back into an integer ID for the backend
  int _parseBookingId(String rawId) {
    return int.tryParse(rawId.replaceAll('B-', '')) ?? 0;
  }

  Future<void> _updateJobStatus(String rawId, String newStatus) async {
    setState(() => _isLoadingAction = true);
    try {
      final bookingId = _parseBookingId(rawId);
      await BookingService.updateBookingStatus(bookingId: bookingId, status: newStatus);
      _showSnack('Job status updated to $newStatus.');
      _loadJobs(); // Refresh the list from the database
    } catch (e) {
      _showSnack('Error updating status: $e');
    } finally {
      setState(() => _isLoadingAction = false);
    }
  }

  void _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Go back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(confirmLabel, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleBottomNavTap(int index) {
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
          MaterialPageRoute(builder: (_) => const SitterProfileScreen()),
        );
        break;
    }
  }

  // Maps backend BookingType to local UI filter tabs
  String _getUiStatus(BookingModel job) {
    if (job.type == BookingType.active) return 'accepted';
    if (job.type == BookingType.completed) return 'completed';
    return 'requested'; 
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
        leading: const Icon(Icons.pets, color: AppColors.primaryRust),
        title: const Text('Jobs', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
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
      body: _isLoadingAction 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRust))
        : FutureBuilder<List<BookingModel>>(
            future: _jobsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primaryRust));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Failed to load jobs: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }

              final jobs = snapshot.data ?? [];
              
              // Filter logic based on tab selection
              final ongoing = jobs.where((j) => _getUiStatus(j) == 'ongoing').toList();
              final others = jobs.where((j) => _getUiStatus(j) != 'ongoing').toList();
              final visible = _selectedFilter == null
                  ? others
                  : others.where((j) => _getUiStatus(j) == _selectedFilter).toList();

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 10),
                  ...ongoing.map(_buildJobCard),
                  _buildFilterPills(others),
                  const SizedBox(height: 16),
                  if (visible.isEmpty)
                    _buildEmptyState(jobs.isEmpty)
                  else
                    ...visible.map(_buildJobCard),
                  const SizedBox(height: 24),
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
        onTap: _handleBottomNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'JOBS'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'MESSAGES'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PROFILE'),
        ],
      ),
    );
  }

  //Filter pills 

  Widget _buildFilterPills(List<BookingModel> others) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPill('ACCEPTED', 'accepted', others),
          const SizedBox(width: 8),
          _buildPill('REQUESTED', 'requested', others),
          const SizedBox(width: 8),
          _buildPill('COMPLETED', 'completed', others),
        ],
      ),
    );
  }

  Widget _buildPill(String label, String status, List<BookingModel> others) {
    final isSelected = _selectedFilter == status;
    final count = others.where((j) => _getUiStatus(j) == status).length;

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

  Widget _buildEmptyState(bool noJobsAtAll) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      alignment: Alignment.center,
      child: Text(
        noJobsAtAll
            ? 'No jobs yet. Requests and bookings from homeowners will show up here.'
            : 'No jobs to show under this filter.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.darkText.withValues(alpha: 0.6), fontSize: 13),
      ),
    );
  }

  // Job card

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
        label = 'REQUESTED';
        icon = Icons.hourglass_empty;
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
          Text(label, style: const TextStyle(color: AppColors.primaryRust, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildJobCard(BookingModel job) {
    final status = _getUiStatus(job);

    final card = Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status != 'completed') ...[
            _buildStatusBadge(status),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: status == 'completed' ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: job.avatarUrl != null ? NetworkImage(job.avatarUrl!) : null,
                child: job.avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                    const SizedBox(height: 4),
                    Text(job.subtitle, style: TextStyle(fontSize: 12, color: AppColors.darkText.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.home_outlined, size: 14, color: AppColors.primaryRust),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Request: ${job.detailText1 ?? "No notes"}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (status == 'completed') ...[
                const SizedBox(width: 8),
                _buildStatusBadge(status),
              ],
            ],
          ),

          // Show Accept and Decline buttons
          if (status == 'requested') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateJobStatus(job.id, 'ACCEPTED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                    label: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRedButton(
                    label: 'Decline',
                    icon: Icons.cancel_outlined,
                    onPressed: () => _confirmAction(
                      title: 'Decline this job?',
                      message: 'Are you sure you want to decline this booking request?',
                      confirmLabel: 'Decline',
                      onConfirm: () => _updateJobStatus(job.id, 'CANCELLED'),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ACCEPTED: Message or Cancel
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
                    label: const Text('Message', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRedButton(
                    label: 'Cancel Job',
                    icon: Icons.cancel_outlined,
                    onPressed: () => _confirmAction(
                      title: 'Cancel this accepted job?',
                      message: 'Are you sure you want to cancel? This may affect your rating.',
                      confirmLabel: 'Cancel job',
                      onConfirm: () => _updateJobStatus(job.id, 'CANCELLED'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    // Clickable cards routing
    Widget? detail;
    if (status == 'accepted') detail = const AcceptedBookingScreen();
    if (status == 'completed') detail = const PreviousBookingsScreen();
    
    if (detail == null) return card;
    return GestureDetector(
      onTap: () => _open(detail!),
      child: card,
    );
  }

  Widget _buildRedButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: Colors.red),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, color: Colors.red, size: 16),
      label: Text(label, style: const TextStyle(color: Colors.red, fontSize: 12)),
    );
  }
}