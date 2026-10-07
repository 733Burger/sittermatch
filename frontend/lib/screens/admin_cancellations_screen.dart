import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme/app_colors.dart';

class AdminCancellationsScreen extends StatefulWidget {
  const AdminCancellationsScreen({super.key});

  @override
  State<AdminCancellationsScreen> createState() => _AdminCancellationsScreenState();
}

class _AdminCancellationsScreenState extends State<AdminCancellationsScreen> {
  late Future<List<CancellationRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.fetchCancellationRequests();
  }

  void _reload() {
    setState(() => _future = AdminService.fetchCancellationRequests());
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _decline(CancellationRequest request) async {
    await AdminService.resolveCancellation(request.id, approved: false);
    if (!mounted) return;
    _reload();
    _showSnack('Request declined. "${request.bookingTitle}" stays booked.');
  }

  void _confirmCancelBooking(CancellationRequest request) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(
          '"${request.bookingTitle}" (${request.dates}) will be cancelled for both '
          '${request.homeownerName} and ${request.sitterName}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Go back')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminService.resolveCancellation(request.id, approved: true);
              if (!mounted) return;
              _reload();
              _showSnack('Booking cancelled.');
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Cancellations',
          style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<CancellationRequest>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryRust));
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load requests.', style: TextStyle(color: Colors.red)),
            );
          }

          final requests = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${requests.length} cancellation ${requests.length == 1 ? 'request' : 'requests'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              if (requests.isEmpty)
                _buildEmptyState()
              else
                ...requests.map(_buildRequestCard),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: const Column(
        children: [
          Icon(Icons.event_available, color: AppColors.primaryRust, size: 40),
          SizedBox(height: 12),
          Text(
            'All caught up',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          SizedBox(height: 4),
          Text(
            'There are no cancellation requests right now.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(CancellationRequest request) {
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
              Expanded(
                child: Text(
                  request.bookingTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightRustBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ASKED BY ${request.requestedBy.toUpperCase()}',
                  style: const TextStyle(
                    color: AppColors.primaryRust,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${request.dates} · requested ${request.requestedOn}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPersonRow(Icons.home_outlined, 'Homeowner', request.homeownerName),
                const SizedBox(height: 6),
                _buildPersonRow(Icons.work_outline, 'Sitter', request.sitterName),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                const Text(
                  'REASON',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"${request.reason}"',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _decline(request),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.black87),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.close, color: Colors.black87, size: 16),
                  label: const Text('Decline', style: TextStyle(color: Colors.black87, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmCancelBooking(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.event_busy, color: Colors.white, size: 16),
                  label: const Text('Cancel booking', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonRow(IconData icon, String label, String name) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryRust, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: name),
              ],
            ),
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}