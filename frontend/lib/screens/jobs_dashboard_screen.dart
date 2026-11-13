import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/booking_model.dart';
import '../widgets/sitter/sitter_job_card.dart';
import 'messages_screen.dart';
import 'sitter_profile_screen.dart';

/// The sitter's own jobs: bookings made directly with them, and open requests they've sent
/// an offer on. Open requests they haven't offered on yet are on the Home page instead.
class JobsDashboardScreen extends StatefulWidget {
  const JobsDashboardScreen({super.key});

  @override
  State<JobsDashboardScreen> createState() => _JobsDashboardScreenState();
}

class _JobsDashboardScreenState extends State<JobsDashboardScreen> with SitterJobActions {
  late Future<List<BookingModel>> _jobsFuture;
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    reloadJobs();
  }

  @override
  void reloadJobs() {
    setState(() {
      _jobsFuture = fetchSitterBookings().then((all) => all.where((job) => !isOpenRequest(job)).toList());
    });
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
      body: jobActionBusy
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
              final ongoing = jobs.where((j) => jobUiStatus(j) == 'ongoing').toList();
              final others = jobs.where((j) => jobUiStatus(j) != 'ongoing').toList();
              final visible = _selectedFilter == null
                  ? others
                  : others.where((j) => jobUiStatus(j) == _selectedFilter).toList();

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 10),
                  ...ongoing.map(buildJobCard),
                  _buildFilterPills(others),
                  const SizedBox(height: 16),
                  if (visible.isEmpty)
                    _buildEmptyState(jobs.isEmpty)
                  else
                    ...visible.map(buildJobCard),
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
    final count = others.where((j) => jobUiStatus(j) == status).length;

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
            ? 'No jobs yet. Bookings made with you and offers you send will show up here. '
                'Find open requests on the Home page.'
            : 'No jobs to show under this filter.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.darkText.withValues(alpha: 0.6), fontSize: 13),
      ),
    );
  }
}
