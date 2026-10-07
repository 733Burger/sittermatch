import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../theme/app_colors.dart';
import 'bookings_dashboard_screen.dart';
import 'messages_screen.dart';
import 'owner_home_screen.dart';

class PetModel {
  String name;
  String breed;
  String size; // Small, Medium, Large
  int age;
  String careNotes;
  double? behaviorScore; // set by sitters after a stay
  String? review; // set by sitters after a stay
  String? photoUrl;

  PetModel({
    required this.name,
    required this.breed,
    required this.size,
    required this.age,
    required this.careNotes,
    this.behaviorScore,
    this.review,
    this.photoUrl,
  });
}

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Read-only user details
  final String _userName = 'Joshua Stevens'; // TODO: load from the backend
  String _userEmail = '';
  final String _userPhone = '+27 82 123 4567'; // TODO: load from the backend

  // Editable controllers
  final TextEditingController _addressController = TextEditingController(
    text: '123 Beach Road, Sea Point, Cape Town',
  );
  final TextEditingController _requirementsController = TextEditingController(
    text: 'Please water the plants daily and ensure the main gate is locked at 8 PM.',
  );

  final List<PetModel> _pets = [
    PetModel(
      name: 'Buster',
      breed: 'Golden Retriever',
      size: 'Large',
      age: 3,
      careNotes: 'Needs 2 walks a day. Hypoallergenic food only.',
      behaviorScore: 4.8,
      review: 'Very friendly and loves playing fetch!',
    ),
  ];

  final List<Map<String, dynamic>> _ownerReviews = [
    {
      'sitterName': 'Sarah Jenkins',
      'rating': 5.0,
      'comment': 'Joshua was an amazing host! Great instructions and lovely home.',
      'date': 'Sep 2026',
    },
    {
      'sitterName': 'Michael Coetzee',
      'rating': 4.9,
      'comment': 'Super clear house rules and communication was seamless.',
      'date': 'Aug 2026',
    },
  ];

  bool get _isFormValid =>
      _addressController.text.trim().isNotEmpty &&
      _requirementsController.text.trim().isNotEmpty;

  double get _averageRating => _ownerReviews.isEmpty
      ? 0
      : _ownerReviews.fold<double>(0, (sum, r) => sum + (r['rating'] as double)) /
          _ownerReviews.length;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final email = await AuthService().getUserEmail();
    if (!mounted) return;
    setState(() => _userEmail = email ?? '');
  }

  @override
  void dispose() {
    _addressController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  // ---------- Helpers ----------

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: error ? Colors.red : null),
      );
  }

  void _showGateMessage() {
    _showSnack('Please add your address and house sitting requirements first.', error: true);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // TODO: send the address and requirements to the backend.
    _showSnack('Profile saved.');
  }

  void _handleBottomNavTap(int index) {
    if (index == 3) return; // already on Profile
    if (!_isFormValid) {
      _showGateMessage();
      return;
    }
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const OwnerHomeScreen()),
              );
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BookingsDashboardScreen()),
        );
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MessagesScreen()),
        );
        break;
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    );
  }

  /// Label shown above a field (bigger and never overlaps the text box).
  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
          children: const [
            TextSpan(text: ' *', style: TextStyle(color: AppColors.primaryRust)),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String? label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.primaryRust),
      filled: true,
      fillColor: AppColors.expandButtonBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryRust, width: 1.5),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightRustBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryRust,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _stars(double score, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final remaining = score - i;
        IconData icon;
        if (remaining >= 1) {
          icon = Icons.star_rounded;
        } else if (remaining >= 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, color: AppColors.primaryRust, size: size);
      }),
    );
  }

  // ---------- Add pet dialog ----------

  void _showAddPetDialog() {
    final nameCtrl = TextEditingController();
    final breedCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final careCtrl = TextEditingController();
    String selectedSize = 'Medium';
    String? nameError;
    String? breedError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add a pet', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () => _showSnack('Pet photo upload is coming soon.'),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.lightRustBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: AppColors.primaryRust),
                          SizedBox(height: 4),
                          Text(
                            'Add photo',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primaryRust,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: _fieldDecoration('Pet name *').copyWith(errorText: nameError),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: breedCtrl,
                  decoration: _fieldDecoration('Breed *').copyWith(errorText: breedError),
                ),
                const SizedBox(height: 16),
                const Text('Dog size', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['Small', 'Medium', 'Large'].map((s) {
                    final selected = selectedSize == s;
                    return ChoiceChip(
                      label: Text(s),
                      selected: selected,
                      showCheckmark: false,
                      selectedColor: AppColors.primaryRust,
                      backgroundColor: AppColors.expandButtonBg,
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.darkText,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setDialogState(() => selectedSize = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration('Age (years)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: careCtrl,
                  maxLines: 2,
                  decoration: _fieldDecoration('Care notes'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Behaviour scores and reviews are added by sitters after a stay.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final breed = breedCtrl.text.trim();
                if (name.isEmpty || breed.isEmpty) {
                  setDialogState(() {
                    nameError = name.isEmpty ? 'Required' : null;
                    breedError = breed.isEmpty ? 'Required' : null;
                  });
                  return;
                }
                setState(() {
                  _pets.add(
                    PetModel(
                      name: name,
                      breed: breed,
                      size: selectedSize,
                      age: int.tryParse(ageCtrl.text.trim()) ?? 1,
                      careNotes: careCtrl.text.trim(),
                    ),
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add pet'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isFormValid,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showGateMessage();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: const Icon(Icons.pets, color: AppColors.primaryRust),
          title: const Text(
            'Homeowner Profile',
            style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
          ),
        ),
        body: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!_isFormValid) ...[
                _buildGateBanner(),
                const SizedBox(height: 16),
              ],
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildPropertyCard(),
              const SizedBox(height: 24),
              _buildPetsHeader(),
              const SizedBox(height: 12),
              if (_pets.isEmpty)
                _buildNoPets()
              else
                ..._pets.map(_buildPetCard),
              const SizedBox(height: 12),
              _buildReviewsCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: 3,
          selectedItemColor: AppColors.primaryRust,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: _handleBottomNavTap,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'HOME'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'BOOKINGS'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'MESSAGES'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PROFILE'),
          ],
        ),
      ),
    );
  }

  Widget _buildGateBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightRustBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, color: AppColors.primaryRust, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add your address and house sitting requirements to unlock the rest of the app.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, size: 52, color: Colors.grey),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showSnack('Photo upload is coming soon.'),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRust,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _userName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 6),
          _tag('HOMEOWNER'),
          const SizedBox(height: 10),
          if (_ownerReviews.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: AppColors.primaryRust, size: 18),
                const SizedBox(width: 4),
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  ' (${_ownerReviews.length} reviews)',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.mail_outline, _userEmail.isEmpty ? 'No email on file' : _userEmail),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.phone_outlined, _userPhone),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryRust, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.darkText)),
        ),
      ],
    );
  }

  Widget _buildPropertyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          const SizedBox(height: 2),
          const Text(
            'Both fields are required.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          _fieldLabel('Address'),
          TextFormField(
            controller: _addressController,
            decoration: _fieldDecoration(
              null,
              icon: Icons.location_on_outlined,
              hint: 'e.g. 123 Beach Road, Sea Point',
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Address is required' : null,
          ),
          const SizedBox(height: 20),
          _fieldLabel('House sitting requirements / notes'),
          TextFormField(
            controller: _requirementsController,
            maxLines: 4,
            decoration: _fieldDecoration(
              null,
              icon: Icons.note_alt_outlined,
              hint: 'e.g. Feed the dogs twice a day and lock the gate at 8 PM.',
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Requirements are required' : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _save,
              child: const Text(
                'Save details',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'My pets',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
        ),
        TextButton.icon(
          onPressed: _showAddPetDialog,
          icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryRust, size: 18),
          label: const Text(
            'Add pet',
            style: TextStyle(color: AppColors.primaryRust, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildNoPets() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: const Text(
        'No pets added yet. Add your pets so sitters know who they will be looking after.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  Widget _buildPetCard(PetModel pet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.lightRustBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pets, color: AppColors.primaryRust, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pet.breed,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tag('${pet.size.toUpperCase()} DOG'),
                        _tag('${pet.age} ${pet.age == 1 ? 'YR' : 'YRS'}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.emoji_emotions_outlined, color: AppColors.primaryRust, size: 18),
              const SizedBox(width: 6),
              const Text(
                'behaviour score: 4',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkText),
              ),
            ],
          ),
          if (pet.behaviorScore != null || (pet.review != null && pet.review!.trim().isNotEmpty)) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (pet.behaviorScore != null) ...[
                  _stars(pet.behaviorScore!, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    pet.behaviorScore!.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                ],
                if (pet.review != null && pet.review!.trim().isNotEmpty)
                  Expanded(
                    child: Text(
                      '"${pet.review!}"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (pet.careNotes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Care notes: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: pet.careNotes),
                  ],
                ),
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ratings & sitter reviews',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          const SizedBox(height: 12),
          if (_ownerReviews.isEmpty)
            const Text(
              'No reviews yet. Sitters can review you after a stay.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            )
          else ...[
            Row(
              children: [
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _stars(_averageRating, size: 18),
                    const SizedBox(height: 2),
                    Text(
                      '${_ownerReviews.length} reviews',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            ..._ownerReviews.map(_buildReviewTile),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewTile(Map<String, dynamic> review) {
    final String name = review['sitterName'] as String;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.lightRustBg,
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryRust,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.primaryRust, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${review['rating']}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  review['comment'] as String,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  review['date'] as String,
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}