import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/booking_model.dart';
import '../models/pet_model.dart';
import '../services/profile_service.dart';
import '../theme/app_colors.dart';
import 'direct_chat_screen.dart';

/// What a sitter sees about a homeowner: who they are and roughly where, the stay they've
/// booked, their pets and their house sitting notes. Laid out like the Job Details screen.
class HomeownerDetailScreen extends StatefulWidget {
  final int homeownerId;
  final String? homeownerName;
  final String? homeownerNotes;
  final BookingModel? booking;

  const HomeownerDetailScreen({
    super.key,
    required this.homeownerId,
    this.homeownerName,
    this.homeownerNotes,
    this.booking,
  });

  @override
  State<HomeownerDetailScreen> createState() => _HomeownerDetailScreenState();
}

class _HomeownerDetailScreenState extends State<HomeownerDetailScreen> {
  bool _loading = true;
  List<PetModel> _pets = [];
  // The "House sitting notes" from the homeowner's profile.
  String? _requirements;
  // Suburb and city only, never the street address.
  String? _area;

  String get _name => widget.homeownerName ?? widget.booking?.homeownerName ?? 'Homeowner';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // One call that returns only what this screen shows: no street address, email or phone.
  Future<void> _load() async {
    final profile = await ProfileService().fetchPublicHomeownerProfile(homeownerId: widget.homeownerId);
    List<PetModel> pets = [];
    String? requirements;
    String? area = widget.booking?.area;
    if (profile['success'] == true) {
      final text = (profile['requirements'] ?? '').toString().trim();
      requirements = text.isEmpty ? null : text;
      area ??= _areaFrom(profile['suburb']?.toString(), profile['city']?.toString());
      pets = (profile['pets'] as List).map((p) {
        final pet = p as Map<String, dynamic>;
        return PetModel(
          name: (pet['name'] ?? '').toString(),
          breed: (pet['breed'] ?? '').toString(),
          species: (pet['species'] ?? '').toString(),
          age: (pet['age'] as num?)?.toInt() ?? 0,
          careNotes: '',
        );
      }).toList();
    }

    if (!mounted) return;
    setState(() {
      _pets = pets;
      _requirements = requirements;
      _area = area;
      _loading = false;
    });
  }

  static String? _areaFrom(String? suburb, String? city) {
    final parts = [suburb?.trim() ?? '', city?.trim() ?? ''].where((p) => p.isNotEmpty).toSet().toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(partnerId: widget.homeownerId, partnerName: _name),
      ),
    );
  }

  // "Fri 13 Nov – Sat 14 Nov".
  String _dateRange(BookingModel booking) {
    final start = booking.startDate, end = booking.endDate;
    if (start == null || end == null) return 'Dates unconfirmed';
    final format = DateFormat('EEE d MMM');
    return '${format.format(start)} – ${format.format(end)}';
  }

  // ---------- Shared pieces (same as Job Details) ----------

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryRust),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText)),
      ],
    );
  }

  static const _labelStyle =
      TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5);

  Widget _buildDetailRow(IconData icon, String label, String value) {
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
              Text(label, style: _labelStyle),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkText)),
            ],
          ),
        ),
      ],
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
        title: const Text('Homeowner Profile',
            style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRust))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _buildHeaderCard(),
                if (widget.booking != null) ...[
                  const SizedBox(height: 12),
                  _buildBookingCard(widget.booking!),
                ],
                const SizedBox(height: 12),
                _buildPetsCard(),
                const SizedBox(height: 12),
                _buildRequirementsCard(),
              ],
            ),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  // Avatar, name and area side by side.
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.lightRustBg,
            child: Icon(Icons.person_outline, color: AppColors.primaryRust, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HOMEOWNER', style: _labelStyle),
                const SizedBox(height: 2),
                Text(
                  _name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText),
                ),
                if (_area != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primaryRust),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(_area!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // The stay this sitter is looking at, when opened from a booking.
  Widget _buildBookingCard(BookingModel booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.event_note_outlined, 'This Booking'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildDetailRow(Icons.home_work_outlined, 'STAY', booking.title),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.calendar_today_outlined, 'DATES', _dateRange(booking)),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.pets, 'Pets'),
          const SizedBox(height: 4),
          if (_pets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No pets registered yet.', style: TextStyle(fontSize: 13, color: Colors.black54)),
            )
          else
            for (var i = 0; i < _pets.length; i++) ...[
              if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
              _buildPetRow(_pets[i]),
            ],
        ],
      ),
    );
  }

  // One pet as a list row: avatar, name, then type, breed and age underneath.
  Widget _buildPetRow(PetModel pet) {
    final details = [
      petTypeLabel(pet.species),
      if (pet.breed.isNotEmpty) pet.breed,
      if (pet.age > 0) 'Age ${pet.age}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.lightRustBg,
            child: Icon(Icons.pets, size: 16, color: AppColors.primaryRust),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
                const SizedBox(height: 2),
                Text(details, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsCard() {
    final notes = _requirements;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.home_outlined, 'Home Requirements'),
          const SizedBox(height: 8),
          Text(
            notes ?? 'No house sitting notes.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: notes == null ? Colors.black45 : Colors.black87,
              fontStyle: notes == null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Same bottom bar and button as Job Details.
  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRust,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
            label: Text('Message ${_name.split(' ').first}',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
