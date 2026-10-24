import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/booking_model.dart';
import '../services/auth_services.dart';
import '../services/booking_service.dart';
import '../services/sitter_service.dart';
import 'accepted_booking_screen.dart';
import 'complete_stay_review_screen.dart';
import 'direct_chat_screen.dart';
import 'homeowner_detail_screen.dart';
import 'messages_screen.dart';
import 'ongoing_booking_screen.dart';
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

  // The services on the sitter's profile, to spot jobs that ask for something they don't offer.
  Set<ServiceKind> _myServices = {};
  int? _myId;

  void _loadJobs() {
    setState(() {
      _jobsFuture = () async {
        final sitterId = await AuthService().getUserId();
        _myId = sitterId;
        if (sitterId != null) await _loadMyServices(sitterId);
        return BookingService.fetchDashboardBookings(sitterId: sitterId);
      }();
    });
  }

  Future<void> _loadMyServices(int sitterId) async {
    final result = await SitterService().getSitterDetails(sitterId: sitterId);
    if (result['success'] != true) return;
    final codes = ((result['services'] as List?) ?? []).map((s) => (s['serviceType'] ?? '').toString());
    _myServices = servicesFromSitterCodes(codes);
  }

  Set<ServiceKind> _missingServices(BookingModel job) =>
      servicesForBookingType(job.rightBadgeText).difference(_myServices);

  // ---------- Helpers ----------

  // Reloads when the sitter comes back, since the screen may have changed the job.
  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _loadJobs();
  }

  bool _offerSent(BookingModel job) => job.hasOfferFrom(_myId);

  // The sitter looks over a pending booking before offering on it, and can offer or decline from there.
  Future<void> _viewJob(BookingModel job) async {
    final choice = await Navigator.of(context).push<BookingResponseChoice>(
      MaterialPageRoute(builder: (_) => AcceptedBookingScreen(booking: job, canRespond: true)),
    );
    if (!mounted) return;
    switch (choice) {
      case BookingResponseChoice.sendOffer:
        await _requestAccept(job);
      case BookingResponseChoice.decline:
        _confirmDecline(job);
      case null:
        _loadJobs();
    }
  }

  void _confirmDecline(BookingModel job) {
    _confirmAction(
      title: 'Decline this job?',
      message: "It won't show in your jobs any more.",
      confirmLabel: 'Decline',
      onConfirm: () => _declineJob(job, 'Job declined.'),
    );
  }

  Future<void> _withdrawOffer(BookingModel job) async {
    setState(() => _isLoadingAction = true);
    try {
      final sitterId = _myId ?? await AuthService().getUserId();
      if (sitterId == null) throw Exception('Sign in again.');
      await BookingService.declineOffer(_parseBookingId(job.id), sitterId);
      _showSnack('Offer withdrawn.');
      _loadJobs();
    } catch (e) {
      _showSnack('Could not withdraw: ${_errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  void _leaveReview(BookingModel job) {
    _open(CompleteStayReviewScreen(booking: job, isSitter: true, completing: false));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Parses the 'B-12' string back into an integer ID for the backend
  int _parseBookingId(String rawId) {
    return int.tryParse(rawId.replaceAll('B-', '')) ?? 0;
  }

  Future<void> _requestAccept(BookingModel job) async {
    // If the job asks for services the sitter doesn't offer, they set a price for each first.
    final missing = _missingServices(job);
    var extraPrices = <ServiceKind, double>{};
    if (missing.isNotEmpty) {
      final prices = await _askForMissingPrices(missing);
      if (prices == null) return;
      extraPrices = prices;
    }

    setState(() => _isLoadingAction = true);
    try {
      final sitterId = await AuthService().getUserId();
      await BookingService.requestAccept(_parseBookingId(job.id), sitterId: sitterId, extraPrices: extraPrices);
      _showSnack('Offer sent. The homeowner can compare it with other offers and accept it.');
      _loadJobs();
    } catch (e) {
      _showSnack('Could not send offer: ${_errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  // Pulls the backend's {"message": ...} out of "Request failed (400): {...}".
  String _errorMessage(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '');
    final match = RegExp(r'"message"\s*:\s*"([^"]*)"').firstMatch(text);
    return match?.group(1) ?? text;
  }

  /// Asks the sitter to price each service the job needs that isn't on their profile.
  /// Returns null if they cancel.
  Future<Map<ServiceKind, double>?> _askForMissingPrices(Set<ServiceKind> missing) {
    return showDialog<Map<ServiceKind, double>>(
      context: context,
      builder: (_) => _MissingPricesDialog(missing: missing),
    );
  }

  void _openChat(BookingModel job) {
    _open(DirectChatScreen(partnerId: job.homeownerId, partnerName: job.homeownerName));
  }

  void _openHomeownerProfile(BookingModel job) {
    final homeownerId = job.homeownerId;
    if (homeownerId == null) return;
    _open(HomeownerDetailScreen(
      homeownerId: homeownerId,
      homeownerName: job.homeownerName ?? 'Homeowner',
      booking: job,
    ));
  }

  Future<void> _updateJobStatus(String rawId, String newStatus, {String? doneMessage}) async {
    setState(() => _isLoadingAction = true);
    try {
      final bookingId = _parseBookingId(rawId);
      await BookingService.updateBookingStatus(bookingId: bookingId, status: newStatus);
      _showSnack(doneMessage ?? 'Job status updated to $newStatus.');
      _loadJobs(); // Refresh the list from the database
    } catch (e) {
      _showSnack('Error updating status: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  // Declined jobs are left out of the sitter's list by the backend,
  // and the homeowner sees the booking as declined.
  // An open booking (no sitter yet) is only hidden from this sitter and stays open for others.
  Future<void> _declineJob(BookingModel job, String doneMessage) async {
    if (job.sitterId != null) {
      return _updateJobStatus(job.id, 'DECLINED', doneMessage: doneMessage);
    }
    setState(() => _isLoadingAction = true);
    try {
      final sitterId = await AuthService().getUserId();
      if (sitterId == null) throw Exception('Sign in again.');
      await BookingService.dismissOpenBooking(_parseBookingId(job.id), sitterId);
      _showSnack(doneMessage);
      _loadJobs();
    } catch (e) {
      _showSnack('Could not decline: ${_errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
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
    // Accepted jobs become ongoing once the stay has started.
    if (job.isOngoing) return 'ongoing';
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

  Widget _buildStatusBadge(String status, {bool open = false, bool offerSent = false}) {
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
        label = offerSent ? 'OFFER SENT' : (open ? 'OPEN REQUEST' : 'REQUESTED');
        icon = offerSent ? Icons.send_outlined : Icons.hourglass_empty;
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
            _buildStatusBadge(status, open: job.sitterId == null, offerSent: _offerSent(job)),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: status == 'completed' ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              // The homeowner the job is for. Tap to open their profile.
              InkWell(
                onTap: () => _openHomeownerProfile(job),
                customBorder: const CircleBorder(),
                child: const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.lightRustBg,
                  child: Icon(Icons.home_outlined, color: AppColors.primaryRust),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () => _openHomeownerProfile(job),
                      child: Text(
                        '${job.homeownerName ?? 'Homeowner'} · View profile',
                        style: const TextStyle(fontSize: 12, color: AppColors.primaryRust, fontWeight: FontWeight.w600),
                      ),
                    ),
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

          // Pending: the sitter views the booking and sends an offer, then waits for the homeowner to pick one.
          if (status == 'requested') ...[
            const SizedBox(height: 16),
            if (_offerSent(job)) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(8)),
                child: const Text(
                  'Offer sent. Waiting for the homeowner to choose a sitter.',
                  style: TextStyle(color: AppColors.primaryRust, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openChat(job),
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
                      label: 'Withdraw',
                      icon: Icons.cancel_outlined,
                      onPressed: () => _confirmAction(
                        title: 'Withdraw your offer?',
                        message: 'The homeowner will no longer see your offer. You can send a new one while the booking is open.',
                        confirmLabel: 'Withdraw',
                        onConfirm: () => _withdrawOffer(job),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              if (_missingServices(job).isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade800, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This booking asks for ${_missingServices(job).map((s) => bookingServiceLabels[s]!.toLowerCase()).join(' and ')}, '
                          "which isn't in your services. You'll set a price when you request it.",
                          style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _viewJob(job),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primaryRust),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.visibility_outlined, color: AppColors.primaryRust, size: 16),
                  label: const Text('View booking', style: TextStyle(color: AppColors.primaryRust, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _requestAccept(job),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.send_outlined, color: Colors.white, size: 16),
                      label: const Text('Send offer', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRedButton(
                      label: 'Decline',
                      icon: Icons.cancel_outlined,
                      onPressed: () => _confirmDecline(job),
                    ),
                  ),
                ],
              ),
            ],
          ],

          // COMPLETED: review the homeowner if the sitter hasn't yet
          if (status == 'completed') ...[
            const SizedBox(height: 12),
            if (!job.sitterReviewed)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _leaveReview(job),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primaryRust),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.star_outline_rounded, color: AppColors.primaryRust, size: 16),
                  label: Text(
                    'Review ${job.homeownerName ?? 'the homeowner'}',
                    style: const TextStyle(color: AppColors.primaryRust, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            else
              const Text('You reviewed this stay.', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],

          // ONGOING: open the current job
          if (status == 'ongoing') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _open(OngoingBookingScreen(booking: job)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.heritageFooterBg,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.radar, color: Colors.white, size: 18),
                label: const Text('View Current Job', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],

          // ACCEPTED: Message or Cancel
          if (status == 'accepted') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openChat(job),
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
                      onConfirm: () => _declineJob(job, 'Job cancelled.'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    // Every card opens the booking. A pending one opens with Send offer / Decline.
    return GestureDetector(
      onTap: () {
        if (status == 'ongoing') {
          _open(OngoingBookingScreen(booking: job));
        } else if (status == 'requested' && !_offerSent(job)) {
          _viewJob(job);
        } else {
          _open(AcceptedBookingScreen(booking: job));
        }
      },
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
/// Asks the sitter to price each service a job needs that isn't on their profile. Owns its text
/// fields so they are only disposed once the dialog has fully closed. Pops the prices, or null on cancel.
class _MissingPricesDialog extends StatefulWidget {
  const _MissingPricesDialog({required this.missing});

  final Set<ServiceKind> missing;

  @override
  State<_MissingPricesDialog> createState() => _MissingPricesDialogState();
}

class _MissingPricesDialogState extends State<_MissingPricesDialog> {
  late final Map<ServiceKind, TextEditingController> _controllers = {
    for (final s in widget.missing) s: TextEditingController(),
  };
  final Map<ServiceKind, String?> _errors = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _priceUnit(ServiceKind service) => switch (service) {
        ServiceKind.night => '/ night',
        ServiceKind.visit => '/ visit',
        ServiceKind.walk => '/ walk',
      };

  void _submit() {
    final prices = <ServiceKind, double>{};
    for (final service in widget.missing) {
      final value = double.tryParse(_controllers[service]!.text.trim().replaceAll(',', '.'));
      _errors[service] = (value == null || value <= 0) ? 'Enter a price above R0' : null;
      if (value != null && value > 0) prices[service] = value;
    }
    if (prices.length < widget.missing.length) {
      setState(() {});
      return;
    }
    Navigator.pop(context, prices);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Set a price first', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "This booking asks for a service that isn't in your profile. "
              'Set a price for it to send your request.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            for (final service in widget.missing) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _controllers[service],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: bookingServiceLabels[service],
                  prefixText: 'R ',
                  suffixText: _priceUnit(service),
                  errorText: _errors[service],
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: _submit,
          child: const Text('Send request'),
        ),
      ],
    );
  }
}
