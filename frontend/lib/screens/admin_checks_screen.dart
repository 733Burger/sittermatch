import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme/app_colors.dart';

class AdminChecksScreen extends StatefulWidget {
  const AdminChecksScreen({super.key});

  @override
  State<AdminChecksScreen> createState() => _AdminChecksScreenState();
}

class _AdminChecksScreenState extends State<AdminChecksScreen> {
  late Future<List<UserCheck>> _future;

  // 'SITTER', 'HOMEOWNER', or null to show everything.
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    _future = AdminService.fetchPendingChecks();
  }

  void _reload() {
    setState(() => _future = AdminService.fetchPendingChecks());
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _approve(UserCheck check) async {
    await AdminService.resolveCheck(check.id, approved: true);
    if (!mounted) return;
    _reload();
    _showSnack('${check.checkType} approved for ${check.userName}.');
  }

  void _askToReject(UserCheck check) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject this check?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${check.userName} will be asked to submit "${check.checkType}" again.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Go back')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminService.resolveCheck(
                check.id,
                approved: false,
                reason: reasonCtrl.text.trim(),
              );
              if (!mounted) return;
              _reload();
              _showSnack('Check rejected.');
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
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
          'User Checks',
          style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<UserCheck>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryRust));
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load checks.', style: TextStyle(color: Colors.red)),
            );
          }

          final all = snapshot.data!;
          final visible = _roleFilter == null
              ? all
              : all.where((c) => c.role == _roleFilter).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${all.length} waiting for verification',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              _buildFilterPills(all),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                _buildEmptyState()
              else
                ...visible.map(_buildCheckCard),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterPills(List<UserCheck> all) {
    int count(String role) => all.where((c) => c.role == role).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPill('ALL (${all.length})', _roleFilter == null, () {
            setState(() => _roleFilter = null);
          }),
          const SizedBox(width: 8),
          _buildPill('SITTERS (${count('SITTER')})', _roleFilter == 'SITTER', () {
            setState(() => _roleFilter = _roleFilter == 'SITTER' ? null : 'SITTER');
          }),
          const SizedBox(width: 8),
          _buildPill('HOMEOWNERS (${count('HOMEOWNER')})', _roleFilter == 'HOMEOWNER', () {
            setState(() => _roleFilter = _roleFilter == 'HOMEOWNER' ? null : 'HOMEOWNER');
          }),
        ],
      ),
    );
  }

  Widget _buildPill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRust : AppColors.expandButtonBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: const Column(
        children: [
          Icon(Icons.verified_outlined, color: AppColors.primaryRust, size: 40),
          SizedBox(height: 12),
          Text(
            'All caught up',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          SizedBox(height: 4),
          Text(
            'There are no checks waiting to be verified.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckCard(UserCheck check) {
    final isSitter = check.role == 'SITTER';

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
                radius: 22,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      check.userName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Submitted ${check.submittedOn}',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightRustBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSitter ? 'SITTER' : 'HOMEOWNER',
                  style: const TextStyle(
                    color: AppColors.primaryRust,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, color: AppColors.primaryRust, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        check.checkType,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  check.detail,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _askToReject(check),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.close, color: Colors.red, size: 16),
                  label: const Text('Reject', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approve(check),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRust,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white, size: 16),
                  label: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}