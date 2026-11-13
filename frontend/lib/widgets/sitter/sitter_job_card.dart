import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/booking_model.dart';
import '../../screens/accepted_booking_screen.dart';
import '../../screens/complete_stay_review_screen.dart';
import '../../screens/direct_chat_screen.dart';
import '../../screens/homeowner_detail_screen.dart';
import '../../screens/ongoing_booking_screen.dart';
import '../../services/auth_services.dart';
import '../../services/booking_service.dart';
import '../../services/sitter_service.dart';
import '../../theme/app_colors.dart';
import '../homeowner/profile/profile_styles.dart';

/// The sitter's job card and everything its buttons do (send offer, decline, withdraw,
/// message, cancel, review). Shared by the sitter Home page, which lists open requests,
/// and the Jobs screen, which lists the sitter's own jobs and the offers they've sent.
mixin SitterJobActions<T extends StatefulWidget> on State<T> {
  // The services on the sitter's profile, to spot jobs that ask for something they don't offer.
  Set<ServiceKind> _myServices = {};
  int? myId;
  bool jobActionBusy = false;

  /// Reloads the list after a job has changed.
  void reloadJobs();

  /// Everything the backend has for this sitter: their own jobs plus open requests they
  /// haven't declined. Also loads their id and services for the card.
  Future<List<BookingModel>> fetchSitterBookings() async {
    final sitterId = await AuthService().getUserId();
    myId = sitterId;
    if (sitterId == null) return [];
    await _loadMyServices(sitterId);
    return BookingService.fetchDashboardBookings(sitterId: sitterId);
  }

  /// An open booking (no sitter chosen yet) this sitter hasn't offered on. Shown on Home.
  /// Once they send an offer it moves to Jobs.
  bool isOpenRequest(BookingModel job) => job.sitterId == null && !offerSent(job);

  Future<void> _loadMyServices(int sitterId) async {
    final result = await SitterService().getSitterDetails(sitterId: sitterId);
    if (result['success'] != true) return;
    final codes = ((result['services'] as List?) ?? []).map((s) => (s['serviceType'] ?? '').toString());
    _myServices = servicesFromSitterCodes(codes);
  }

  Set<ServiceKind> _missingServices(BookingModel job) =>
      servicesForBookingType(job.rightBadgeText).difference(_myServices);

  bool offerSent(BookingModel job) => job.hasOfferFrom(myId);

  /// Maps the backend booking type to the card's status.
  String jobUiStatus(BookingModel job) {
    // Accepted jobs become ongoing once the stay has started.
    if (job.isOngoing) return 'ongoing';
    if (job.type == BookingType.active) return 'accepted';
    if (job.type == BookingType.completed) return 'completed';
    return 'requested';
  }

  // ---------- Actions ----------

  void _setBusy(bool busy) {
    if (mounted) setState(() => jobActionBusy = busy);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Reloads when the sitter comes back, since the screen may have changed the job.
  Future<void> openAndReload(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) reloadJobs();
  }

  // Parses the 'B-12' string back into an integer ID for the backend
  int _parseBookingId(String rawId) => int.tryParse(rawId.replaceAll('B-', '')) ?? 0;

  // Pulls the backend's {"message": ...} out of "Request failed (400): {...}".
  String _errorMessage(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '');
    final match = RegExp(r'"message"\s*:\s*"([^"]*)"').firstMatch(text);
    return match?.group(1) ?? text;
  }

  // The sitter looks over a pending booking before offering on it, and can offer or decline from there.
  // The booking screen runs Send offer / Decline itself, so the price dialog and confirmation show
  // over the booking, not the Home page. It only closes once the offer or decline has gone through.
  Future<void> _viewJob(BookingModel job) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AcceptedBookingScreen(
          booking: job,
          canRespond: true,
          onSendOffer: () => _requestAccept(job),
          onDecline: () => _confirmDecline(job),
        ),
      ),
    );
    if (mounted) reloadJobs();
  }

  /// True once the sitter confirmed and the job was declined.
  Future<bool> _confirmDecline(BookingModel job) async {
    final open = job.sitterId == null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ProfileConfirmDialog(
        title: open ? 'Decline this request?' : 'Decline this job?',
        message: open ? "You won't see this request again." : "It won't show in your jobs any more.",
        cancelLabel: 'Go back',
        cancelColor: Colors.grey.shade600,
        confirmLabel: 'Decline',
        confirmColor: Colors.red,
      ),
    );
    if (confirmed != true) return false;
    return _declineJob(job, open ? 'Request declined.' : 'Job declined.');
  }

  /// True once the offer was sent. False if the sitter cancelled the price dialog or it failed.
  Future<bool> _requestAccept(BookingModel job) async {
    // If the job asks for services the sitter doesn't offer, they set a price for each first.
    final missing = _missingServices(job);
    var extraPrices = <ServiceKind, double>{};
    if (missing.isNotEmpty) {
      final prices = await showDialog<Map<ServiceKind, double>>(
        context: context,
        builder: (_) => _MissingPricesDialog(missing: missing),
      );
      if (prices == null) return false;
      extraPrices = prices;
    }

    _setBusy(true);
    try {
      final sitterId = await AuthService().getUserId();
      await BookingService.requestAccept(_parseBookingId(job.id), sitterId: sitterId, extraPrices: extraPrices);
      _showSnack('Offer sent. You can follow it under Jobs.');
      reloadJobs();
      return true;
    } catch (e) {
      _showSnack('Could not send offer: ${_errorMessage(e)}');
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _withdrawOffer(BookingModel job) async {
    _setBusy(true);
    try {
      final sitterId = myId ?? await AuthService().getUserId();
      if (sitterId == null) throw Exception('Sign in again.');
      await BookingService.declineOffer(_parseBookingId(job.id), sitterId);
      _showSnack('Offer withdrawn.');
      reloadJobs();
    } catch (e) {
      _showSnack('Could not withdraw: ${_errorMessage(e)}');
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> _updateJobStatus(String rawId, String newStatus, {String? doneMessage}) async {
    _setBusy(true);
    try {
      await BookingService.updateBookingStatus(bookingId: _parseBookingId(rawId), status: newStatus);
      _showSnack(doneMessage ?? 'Job status updated to $newStatus.');
      reloadJobs();
      return true;
    } catch (e) {
      _showSnack('Error updating status: $e');
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // Declined jobs are left out of the sitter's list by the backend,
  // and the homeowner sees the booking as declined.
  // An open booking (no sitter yet) is only hidden from this sitter and stays open for others.
  Future<bool> _declineJob(BookingModel job, String doneMessage) async {
    if (job.sitterId != null) {
      return _updateJobStatus(job.id, 'DECLINED', doneMessage: doneMessage);
    }
    _setBusy(true);
    try {
      final sitterId = await AuthService().getUserId();
      if (sitterId == null) throw Exception('Sign in again.');
      await BookingService.dismissOpenBooking(_parseBookingId(job.id), sitterId);
      _showSnack(doneMessage);
      reloadJobs();
      return true;
    } catch (e) {
      _showSnack('Could not decline: ${_errorMessage(e)}');
      return false;
    } finally {
      _setBusy(false);
    }
  }

  void _openChat(BookingModel job) {
    openAndReload(DirectChatScreen(partnerId: job.homeownerId, partnerName: job.homeownerName));
  }

  void _openHomeownerProfile(BookingModel job) {
    final homeownerId = job.homeownerId;
    if (homeownerId == null) return;
    openAndReload(HomeownerDetailScreen(
      homeownerId: homeownerId,
      homeownerName: job.homeownerName ?? 'Homeowner',
      booking: job,
    ));
  }

  void _leaveReview(BookingModel job) {
    openAndReload(CompleteStayReviewScreen(booking: job, isSitter: true, completing: false));
  }

  // Withdraw / Decline / Cancel Job: same dialog as the app's other confirmations.
  Future<void> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ProfileConfirmDialog(
        title: title,
        message: message,
        cancelLabel: 'Go back',
        cancelColor: Colors.grey.shade600,
        confirmLabel: confirmLabel,
        confirmColor: Colors.red,
      ),
    );
    if (confirmed == true) onConfirm();
  }

  // ---------- Card ----------

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

  // "Fri 13 Nov – Sat 14 Nov · 1 night". The badge already shows the status.
  String _dateLine(BookingModel job) {
    final start = job.startDate;
    final end = job.endDate;
    if (start == null || end == null) return 'To be confirmed';
    final format = DateFormat('EEE d MMM');
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final nights = endDay.difference(startDay).inDays;
    final length = nights <= 0 ? '' : ' · $nights ${nights == 1 ? 'night' : 'nights'}';
    return '${format.format(start)} – ${format.format(end)}$length';
  }

  // The booking notes end with a "Pets: ..." line added when the booking was made.
  List<String> _noteLines(BookingModel job) => (job.homeownerNotes ?? '')
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  String? _petsLine(BookingModel job) {
    for (final line in _noteLines(job)) {
      if (line.startsWith('Pets:')) return line.substring('Pets:'.length).trim();
    }
    return null;
  }

  String? _notesLine(BookingModel job) {
    final notes = _noteLines(job).where((line) => !line.startsWith('Pets:')).join(' ');
    return notes.isEmpty ? null : notes;
  }

  // Who the job is for, labelled, with a button to their profile.
  Widget _buildHomeownerRow(BookingModel job) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.lightRustBg,
          child: Icon(Icons.person_outline, color: AppColors.primaryRust, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HOMEOWNER',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                job.homeownerName ?? 'Homeowner',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
              ),
              // Where the homeowner lives (suburb and city), under their name.
              if (job.area != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.primaryRust),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        job.area!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _openHomeownerProfile(job),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRust,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('View profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // "2 pets". Open requests show how many pets, not their names.
  String? _petCount(BookingModel job) {
    final names = _petsLine(job);
    if (names == null) return null;
    final count = names.split(',').where((name) => name.trim().isNotEmpty).length;
    return count == 0 ? null : '$count ${count == 1 ? 'pet' : 'pets'}';
  }

  // Dates, pets and notes in a soft panel, each with a small label above the value.
  Widget _buildDetailsPanel(BookingModel job) {
    final pets = isOpenRequest(job) ? _petCount(job) : _petsLine(job);
    final notes = _notesLine(job);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildDetailRow(Icons.calendar_today_outlined, 'DATES', _dateLine(job)),
          if (pets != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(Icons.pets, 'PETS', pets),
          ],
          if (notes != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(Icons.sticky_note_2_outlined, 'NOTES', notes, maxLines: 2),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppColors.primaryRust),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Every card button: solid fill, same height, 12px text. Only the colour changes.
  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, color: Colors.white, size: 16),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _buildRedButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return _buildButton(label: label, icon: icon, color: Colors.red, onPressed: onPressed);
  }

  Widget buildJobCard(BookingModel job) {
    final status = jobUiStatus(job);

    final card = Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status != 'completed') ...[
            _buildStatusBadge(status, open: job.sitterId == null, offerSent: offerSent(job)),
            const SizedBox(height: 16),
          ],
          // Title, with the badge on the right once the job is completed.
          Row(
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText),
                ),
              ),
              if (status == 'completed') ...[
                const SizedBox(width: 8),
                _buildStatusBadge(status),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _buildHomeownerRow(job),
          const SizedBox(height: 14),
          _buildDetailsPanel(job),

          // Pending: the sitter views the booking and sends an offer, then waits for the homeowner to pick one.
          if (status == 'requested') ...[
            const SizedBox(height: 16),
            if (offerSent(job)) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(8)),
                child: const Text(
                  'Offer sent. Waiting for the homeowner to choose a sitter.',
                  style: TextStyle(color: AppColors.primaryRust, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      label: 'Message',
                      icon: Icons.chat_bubble_outline,
                      color: AppColors.primaryRust,
                      onPressed: () => _openChat(job),
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
                          "which isn't in your services. You'll set a price when you send your offer.",
                          style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: _buildButton(
                  label: 'View booking',
                  icon: Icons.visibility_outlined,
                  color: AppColors.primaryRust,
                  onPressed: () => _viewJob(job),
                ),
              ),
              // On Home, open requests only have View booking. The sitter sends an offer or
              // declines from the booking screen. Direct requests on Jobs keep both buttons.
              if (!isOpenRequest(job)) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildButton(
                        label: 'Send offer',
                        icon: Icons.send_outlined,
                        color: Colors.green,
                        onPressed: () => _requestAccept(job),
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
          ],

          // COMPLETED: review the homeowner if the sitter hasn't yet
          if (status == 'completed') ...[
            const SizedBox(height: 12),
            if (!job.sitterReviewed)
              SizedBox(
                width: double.infinity,
                child: _buildButton(
                  label: 'Review ${job.homeownerName ?? 'the homeowner'}',
                  icon: Icons.star_outline_rounded,
                  color: AppColors.primaryRust,
                  onPressed: () => _leaveReview(job),
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
              child: _buildButton(
                label: 'View Current Job',
                icon: Icons.radar,
                color: AppColors.heritageFooterBg,
                onPressed: () => openAndReload(OngoingBookingScreen(booking: job)),
              ),
            ),
          ],

          // ACCEPTED: Message or Cancel
          if (status == 'accepted') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    label: 'Message',
                    icon: Icons.chat_bubble_outline,
                    color: AppColors.primaryRust,
                    onPressed: () => _openChat(job),
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
          openAndReload(OngoingBookingScreen(booking: job));
        } else if (status == 'requested' && !offerSent(job)) {
          _viewJob(job);
        } else {
          openAndReload(AcceptedBookingScreen(booking: job));
        }
      },
      child: card,
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

  // Same layout as the app's other dialogs: icon header, labelled fields, full-width button, Cancel.
  @override
  Widget build(BuildContext context) {
    final several = widget.missing.length > 1;
    return ProfileDialogShell(
      children: [
        ProfileDialogHeader(
          icon: Icons.sell_outlined,
          title: 'Set your price',
          subtitle: several
              ? "This booking asks for services that aren't on your profile. Set a price for each to send your offer."
              : "This booking asks for a service that isn't on your profile. Set a price for it to send your offer.",
        ),
        for (final service in widget.missing) ...[
          const SizedBox(height: 18),
          ProfileFieldLabel(bookingServiceLabels[service]!),
          TextField(
            controller: _controllers[service],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: profileFieldDecoration(null, hint: '0').copyWith(
              prefixText: 'R ',
              suffixText: _priceUnit(service),
              errorText: _errors[service],
            ),
          ),
        ],
        const SizedBox(height: 20),
        ProfileSaveButton(label: 'Send offer', saving: false, onPressed: _submit),
        const ProfileDialogCancelButton(enabled: true),
      ],
    );
  }
}
