import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/pet_model.dart';
import '../models/review_model.dart';
import '../services/booking_service.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';
import '../widgets/homeowner/profile/profile_pet_reviews_card.dart';
import 'direct_chat_screen.dart';

/// What a sitter sees about a homeowner: who they are, their pets,
/// their home requirements and the stay they have booked.
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
  bool _loadingPets = true;
  List<PetModel> _pets = [];
  // Reviews sitters wrote about this homeowner, once an admin has approved them.
  List<StayReview> _reviews = [];
  List<PetReview> _petReviews = [];

  String get _name => widget.homeownerName ?? widget.booking?.homeownerName ?? 'Homeowner';

  String get _notes =>
      widget.homeownerNotes ??
      widget.booking?.homeownerNotes ??
      widget.booking?.detailText1 ??
      'No special requirements specified.';

  @override
  void initState() {
    super.initState();
    _loadPets();
    _loadReviews();
  }

  Future<void> _loadPets() async {
    List<PetModel> pets = [];
    try {
      pets = await BookingService.fetchHomeownerPets(widget.homeownerId);
    } catch (e) {
      debugPrint('Error loading homeowner pets: $e');
    }
    if (!mounted) return;
    setState(() {
      _pets = pets;
      _loadingPets = false;
    });
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await ReviewService.fetchHomeownerReviews(widget.homeownerId);
      if (mounted) setState(() => _reviews = reviews);
    } catch (e) {
      debugPrint('Error loading homeowner reviews: $e');
    }
    try {
      final petReviews = await ReviewService.fetchHomeownerPetReviews(widget.homeownerId);
      if (mounted) setState(() => _petReviews = petReviews);
    } catch (e) {
      debugPrint('Error loading pet reviews: $e');
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(partnerId: widget.homeownerId, partnerName: _name),
      ),
    );
  }

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
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkText)),
      ],
    );
  }

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(),
          if (widget.booking != null) ...[
            const SizedBox(height: 16),
            _buildBookingCard(widget.booking!),
          ],
          const SizedBox(height: 16),
          _buildPetsCard(),
          const SizedBox(height: 16),
          _buildRequirementsCard(),
          const SizedBox(height: 16),
          _buildReviewsCard(),
          const SizedBox(height: 16),
          ProfilePetReviewsCard(reviews: _petReviews),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primaryRust,
            child: Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            _name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_outlined, size: 12, color: AppColors.primaryRust),
                SizedBox(width: 4),
                Text('HOMEOWNER',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryRust)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildStat('${_loadingPets ? '–' : _pets.length}', _pets.length == 1 ? 'Pet' : 'Pets')),
              Container(width: 1, height: 32, color: Colors.grey.shade200),
              Expanded(child: _buildStat('${_reviews.length}', _reviews.length == 1 ? 'Review' : 'Reviews')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // The stay this sitter has with the homeowner, when opened from a booking.
  Widget _buildBookingCard(BookingModel booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.event_note_outlined, 'Your Stay'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primaryRust),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(booking.subtitle,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
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
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.pets, 'Pets'),
          const SizedBox(height: 12),
          if (_loadingPets)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryRust),
                ),
              ),
            )
          else if (_pets.isEmpty)
            const Text('No pets registered yet.', style: TextStyle(fontSize: 12, color: Colors.black54))
          else
            ..._pets.map(_buildPetTile),
        ],
      ),
    );
  }

  Widget _buildPetTile(PetModel pet) {
    final type = petTypeLabel(pet.species);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.pets, color: AppColors.primaryRust, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                  const SizedBox(height: 2),
                  Text(pet.breed.isNotEmpty ? '$type · ${pet.breed}' : type,
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.home_outlined, 'Home Requirements'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Text(_notes, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.star_outline_rounded, 'Sitter Reviews'),
          const SizedBox(height: 10),
          if (_reviews.isEmpty)
            const Text('No reviews submitted yet for this homeowner.',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))
          else
            ..._reviews.map((r) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(r.reviewerName,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                          ),
                          ...List.generate(
                            5,
                            (i) => Icon(i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 14, color: Colors.amber),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(r.comment, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      if (r.dateLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(r.dateLabel, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ],
                  ),
                )),
        ],
      ),
    );
  }

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
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
