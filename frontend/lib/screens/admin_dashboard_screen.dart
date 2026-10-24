import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/auth_services.dart';
import '../theme/app_colors.dart';
import 'admin_checks_screen.dart';
import 'admin_reviews_screen.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<AdminStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = AdminService.fetchStats();
  }

  void _refresh() {
    setState(() => _statsFuture = AdminService.fetchStats());
  }

  /// Opens an admin tool and refreshes the counts when the admin comes back.
  Future<void> _openTool(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    _refresh();
  }

  Future<void> _signOut() async {
    await AuthService().clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
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
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.pets, color: AppColors.primaryRust),
            SizedBox(width: 8),
            Text(
              'Sit & Stay Admin',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refresh,
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _signOut,
          ),
        ],
      ),
      body: FutureBuilder<AdminStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryRust));
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load dashboard data.', style: TextStyle(color: Colors.red)),
            );
          }

          final stats = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Overview',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.1),
              ),
              const SizedBox(height: 4),
              const Text(
                'Everything happening on Sit & Stay.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              _buildTotalUsersCard(stats),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      icon: Icons.work_outline,
                      label: 'SITTERS',
                      count: stats.sitters,
                      total: stats.totalUsers,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleCard(
                      icon: Icons.home_outlined,
                      label: 'HOMEOWNERS',
                      count: stats.homeowners,
                      total: stats.totalUsers,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBookingsCard(stats),
              const SizedBox(height: 24),
              _sectionTitle('Admin tools'),
              const SizedBox(height: 12),
              _buildToolCard(
                icon: Icons.verified_user_outlined,
                title: 'User checks verifier',
                subtitle: 'Approve ID, SAPS, address and contact checks',
                count: stats.pendingChecks,
                onTap: () => _openTool(const AdminChecksScreen()),
              ),
              _buildToolCard(
                icon: Icons.rate_review_outlined,
                title: 'Review verifier',
                subtitle: 'Approve or remove reviews before they show',
                count: stats.pendingReviews,
                onTap: () => _openTool(const AdminReviewsScreen()),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.lightRustBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primaryRust, size: 24),
    );
  }

  Widget _buildTotalUsersCard(AdminStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _buildIconBox(Icons.people_alt_outlined),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL USERS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.black54,
                ),
              ),
              Text(
                '${stats.totalUsers}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String label,
    required int count,
    required int total,
  }) {
    final percent = total == 0 ? 0 : (count / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconBox(icon),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.black54,
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '$percent% of users',
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsCard(AdminStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Bookings'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMiniStat('Ongoing', stats.ongoingBookings)),
              const SizedBox(width: 10),
              Expanded(child: _buildMiniStat('Accepted', stats.acceptedBookings)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMiniStat('Searching', stats.searchingBookings)),
              const SizedBox(width: 10),
              Expanded(child: _buildMiniStat('Completed', stats.completedBookings)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryRust,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              _buildIconBox(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (count > 0)
                Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRust,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const Icon(Icons.check_circle_outline, color: Colors.black38, size: 22),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}