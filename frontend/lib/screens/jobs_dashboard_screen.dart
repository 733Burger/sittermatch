import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'direct_chat_screen.dart';
import 'messages_screen.dart';
import 'ongoing_booking_screen.dart';
import 'previous_booking_screen.dart';
import 'sitter_profile_screen.dart';

/// One job on the sitter's dashboard.
/// status: 'ongoing' | 'accepted' | 'requested' | 'completed'
class _Job {
  final String status;
  final String title;
  final String dates;
  final String homeownerName;

  const _Job({
    required this.status,
    required this.title,
    required this.dates,
    required this.homeownerName,
  });
}

class JobsDashboardScreen extends StatefulWidget {
  const JobsDashboardScreen({super.key});

  @override
  State<JobsDashboardScreen> createState() => _JobsDashboardScreenState();
}

class _JobsDashboardScreenState extends State<JobsDashboardScreen> {
  // Sample jobs so the layout can be seen.
  // Set to false once real jobs come from the backend.
  static const bool _useSampleData = true;

  static const List<_Job> _sampleJobs = [
    _Job(
      status: 'ongoing',
      title: 'Camps Bay Stay',
      dates: 'Oct 12 – 18',
      homeownerName: 'Joshua Stevens',
    ),
    _Job(
      status: 'accepted',
      title: 'Claremont Cottage',
      dates: 'Nov 24 – 27',
      homeownerName: 'Claire Vance',
    ),
    _Job(
      status: 'requested',
      title: 'Constantia Villa',
      dates: 'Dec 15 – 20',
      homeownerName: 'Thandi Mokoena',
    ),
    _Job(
      status: 'completed',
      title: 'Sea Point Apartment',
      dates: 'Sep 5 – 9',
      homeownerName: 'Joshua Stevens',
    ),
  ];

  // 'accepted', 'requested', 'completed', or null to show everything.
  String? _selectedFilter;

  // TODO: replace with jobs loaded from the backend.
  List<_Job> get _jobs => _useSampleData ? _sampleJobs : const <_Job>[];

  // ---------- Helpers ----------

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required String doneMessage,
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
              // TODO: send this to the backend.
              _showSnack(doneMessage);
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
        // Home is the first screen in the stack after login.
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 1:
        break; // already on Jobs
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

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final jobs = _jobs;
    final ongoing = jobs.where((j) => j.status == 'ongoing').toList();
    final others = jobs.where((j) => j.status != 'ongoing').toList();
    final visible = _selectedFilter == null
        ? others
        : others.where((j) => j.status == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.pets, color: AppColors.primaryRust),
        title: const Text(
          'Jobs',
          style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.darkText),
            onPressed: () {},
          ),
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
      body: ListView(
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

  // ---------- Filter pills ----------

  Widget _buildFilterPills(List<_Job> others) {
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

  Widget _buildPill(String label, String status, List<_Job> others) {
    final isSelected = _selectedFilter == status;
    final count = others.where((j) => j.status == status).length;

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

  Widget _buildEmptyState(bool noJobsAtAll) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      alignment: Alignment.center,
      child: Text(
        noJobsAtAll
            ? 'No jobs yet. Requests and bookings from homeowners will show up here.'
            : 'No jobs to show.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.darkText.withValues(alpha: 0.6), fontSize: 13),
      ),
    );
  }

  // ---------- Job card ----------

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

  Widget _buildJobCard(_Job job) {
    final status = job.status;

    final card = Container(
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
                      job.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.dates,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkText.withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.home_outlined, size: 14, color: AppColors.primaryRust),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Homeowner: ${job.homeownerName}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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

          // Ongoing: a single button to view the job.
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
                  'View In-Progress Job',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],

          // Accepted: message the homeowner or cancel the job.
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
                    label: const Text(
                      'Message Homeowner',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRedButton(
                    label: 'Cancel Job',
                    icon: Icons.cancel_outlined,
                    onPressed: () => _confirmAction(
                      title: 'Cancel this job?',
                      message:
                          'Are you sure you want to cancel "${job.title}" for ${job.homeownerName}?',
                      confirmLabel: 'Cancel job',
                      doneMessage: 'Cancellation request sent.',
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Requested: waiting on the homeowner, so only withdraw.
          if (status == 'requested') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _buildRedButton(
                label: 'Withdraw Request',
                icon: Icons.undo,
                onPressed: () => _confirmAction(
                  title: 'Withdraw your request?',
                  message: 'Withdraw your request for "${job.title}"?',
                  confirmLabel: 'Withdraw',
                  doneMessage: 'Request withdrawn.',
                ),
              ),
            ),
          ],
        ],
      ),
    );

    // Completed jobs open the previous jobs screen (details and your review).
    if (status != 'completed') return card;
    return GestureDetector(
      onTap: () => _open(const PreviousBookingsScreen()),
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