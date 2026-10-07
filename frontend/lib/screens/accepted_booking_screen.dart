import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../theme/app_colors.dart';
import 'direct_chat_screen.dart';

/// A pet that is part of the booking.
class _BookedPet {
  final String name;
  final String details; // e.g. 'Golden Retriever · Large dog'
  final String? careNotes;

  const _BookedPet({
    required this.name,
    required this.details,
    this.careNotes,
  });
}

class AcceptedBookingScreen extends StatefulWidget {
  const AcceptedBookingScreen({super.key});

  @override
  State<AcceptedBookingScreen> createState() => _AcceptedBookingScreenState();
}

class _AcceptedBookingScreenState extends State<AcceptedBookingScreen> {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Sample booking details. TODO: load the real booking from the backend.
  final String _stayTitle = 'Camps Bay Stay';
  final String _location = 'Camps Bay, Cape Town';
  final String _sitterName = 'Lerato Khumalo';
  final String _homeownerName = 'Joshua Stevens';
  static const int _nightlyRate = 320;
  static const String _homeownerNotes =
      'Please water the plants daily and make sure the main gate is locked at 8 PM.';
  static const List<_BookedPet> _pets = [
    _BookedPet(
      name: 'Bella',
      details: 'Golden Retriever · Large dog',
      careNotes: 'Two walks a day. No table scraps.',
    ),
    _BookedPet(
      name: 'Milo',
      details: 'Pug · Small dog',
      careNotes: 'Keep on the lead near the road.',
    ),
    _BookedPet(
      name: 'Cleo',
      details: 'Domestic shorthair · Cat',
    ),
  ];

  // Sample dates are set relative to today so the countdown always shows.
  // Replace with the booking's real start and end dates.
  late final DateTime _start;
  late final DateTime _end;

  bool _loading = true;
  bool _isSitter = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _start = today.add(const Duration(days: 5));
    _end = _start.add(const Duration(days: 3));
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await AuthService().getUserRole();
    if (!mounted) return;
    setState(() {
      _isSitter = (role ?? '').toUpperCase() == 'SITTER';
      _loading = false;
    });
  }

  // ---------- Helpers ----------

  int get _nights => _end.difference(_start).inDays;

  int get _daysToGo {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _start.difference(today).inDays;
  }

  String get _countdownValue {
    final days = _daysToGo;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return 'In $days days';
  }

  String _formatDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirmCancel() {
    final noun = _isSitter ? 'job' : 'booking';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel this $noun?'),
        content: Text('Are you sure you want to cancel "$_stayTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep $noun'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: send the cancellation to the backend.
              _showSnack('Cancellation request sent.');
            },
            child: Text('Cancel $noun', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Accepted Booking',
          style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRust))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildServicesCard(),
                const SizedBox(height: 16),
                _buildPetsCard(),
                const SizedBox(height: 16),
                _buildNotesCard(),
                const SizedBox(height: 16),
              ],
            ),
      bottomNavigationBar: _loading ? null : _buildActionBar(),
    );
  }

  Widget _buildSummaryCard() {
    final otherLabel = _isSitter ? 'Homeowner' : 'Sitter';
    final otherName = _isSitter ? _homeownerName : _sitterName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.lightRustBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_available, color: AppColors.primaryRust, size: 12),
                SizedBox(width: 4),
                Text(
                  'ACCEPTED',
                  style: TextStyle(
                    color: AppColors.primaryRust,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _stayTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.login, 'Check-in: ${_formatDate(_start)}'),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.logout, 'Check-out: ${_formatDate(_end)}'),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.nights_stay_outlined, '$_nights ${_nights == 1 ? 'night' : 'nights'}'),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.location_on_outlined, _location),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.person_outline, '$otherLabel: $otherName'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lightRustBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppColors.primaryRust, size: 26),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STARTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: AppColors.primaryRust,
                      ),
                    ),
                    Text(
                      _countdownValue,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRust,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryRust, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesCard() {
    const labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      color: Colors.black54,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Agreed services'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Expanded(child: Text('SERVICE', style: labelStyle)),
                    Text('PRICE', style: labelStyle),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.primaryRust, size: 14),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Stay over night',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      'R$_nightlyRate / night',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRust,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total · $_nights ${_nights == 1 ? 'night' : 'nights'}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      'R${_nights * _nightlyRate}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRust,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Pets'),
          ..._pets.map(_buildPetTile),
        ],
      ),
    );
  }

  Widget _buildPetTile(_BookedPet pet) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.pets, color: AppColors.primaryRust, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  pet.details,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                if (pet.careNotes != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    pet.careNotes!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(_isSitter ? "Homeowner's notes" : 'Your notes for the sitter'),
          const SizedBox(height: 10),
          const Text(
            _homeownerNotes,
            style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _confirmCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                label: Text(
                  _isSitter ? 'Cancel Job' : 'Cancel Booking',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DirectChatScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRust,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                label: Text(
                  _isSitter ? 'Message Homeowner' : 'Message Sitter',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}