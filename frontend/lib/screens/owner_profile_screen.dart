import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../theme/app_colors.dart';
import 'bookings_dashboard_screen.dart';
import 'messages_screen.dart';
import 'owner_home_screen.dart';
import '../services/home_services.dart';

class PetModel {
  final int? id;
  String name;
  String breed;
  String species;
  int age;
  String careNotes;
  double? behaviorScore; // set by sitters after a stay
  String? review; // set by sitters after a stay
  String? photoUrl;

  PetModel({
    this.id,
    required this.name,
    required this.breed,
    required this.species,
    required this.age,
    required this.careNotes,
    this.behaviorScore,
    this.review,
    this.photoUrl,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    final reviews = (json['totalReviews'] as num?)?.toInt() ?? 0;
    final score = (json['behaviourScore'] as num?)?.toDouble();
    return PetModel(
      id: (json['id'] as num?)?.toInt(),
      name: (json['name'] ?? '').toString(),
      breed: (json['breed'] ?? '').toString(),
      species: (json['species'] ?? 'Dog').toString(),
      age: (json['age'] as num?)?.toInt() ?? 0,
      careNotes: (json['careNotes'] ?? '').toString(),
      behaviorScore: reviews > 0 ? score : null,
      photoUrl: json['imageUrl']?.toString(),
    );
  }
}

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  static const List<String> _petTypes = [
    'LARGE DOG',
    'SMALL DOG',
    'CAT',
    'BIRD',
    'REPTILE',
    'FISH',
    'EXOTIC',
  ];

  static String _petTypeLabel(String value) {
    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  final _formKey = GlobalKey<FormState>();

  final HomeService _homeService = HomeService();
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';

  // Editable controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();

  final List<PetModel> _pets = [];

  final List<Map<String, dynamic>> _ownerReviews = [];

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
    _loadProfile();
    _loadPets();
  }

  Future<void> _loadProfile() async {
    final userId = await AuthService().getUserId();
    if (!mounted) return;
    if (userId == null) {
      _showSnack('User session expired. Please log in again.', error: true);
      return;
    }

    final result = await _homeService.fetchProfile(userId: userId);
    if (!mounted) return;
    if (result['success'] != true) {
      _showSnack(result['message']?.toString() ?? 'Could not load profile', error: true);
      return;
    }

    setState(() {
      _userName = (result['name'] ?? '').toString();
      _userEmail = (result['email'] ?? '').toString();
      _userPhone = (result['phone'] ?? '').toString();
      _nameController.text = _userName;
      _emailController.text = _userEmail;
      _phoneController.text = _userPhone;
      _addressController.text = (result['address'] ?? '').toString();
      _requirementsController.text = (result['requirements'] ?? '').toString();
    });
  }

  Future<void> _loadPets() async {
    final userId = await AuthService().getUserId();
    if (!mounted || userId == null) return;

    final result = await _homeService.fetchPets(homeownerId: userId);
    if (!mounted) return;
    if (result['success'] != true) {
      _showSnack(result['message']?.toString() ?? 'Could not load pets', error: true);
      return;
    }

    final pets = (result['pets'] as List)
        .map((e) => PetModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    setState(() {
      _pets
        ..clear()
        ..addAll(pets);
    });
  }

  Future<void> _confirmDeletePet(PetModel pet) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Delete ${pet.name}?'),
      content: const Text(
        'This removes the pet and any reviews linked to it. This can\'t be undone.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  if (confirmed != true || pet.id == null) return;

  final homeownerId = await AuthService().getUserId();
  if (!mounted || homeownerId == null) return;

  final result = await _homeService.deletePet(homeownerId: homeownerId, petId: pet.id!);
  if (!mounted) return;

  if (result['success'] == true) {
    await _loadPets();
    if (!mounted) return;
    _showSnack('Pet entry deleted.');
  } else {
    _showSnack(result['message']?.toString() ?? 'Could not delete pet.', error: true);
  }
}

  @override
  void dispose() {
    _addressController.dispose();
    _requirementsController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final userId = await AuthService().getUserId();
    if (!mounted) return;
    if (userId == null) {
      _showSnack('User session expired. Please log in again.', error: true);
      return;
    }

    final result = await _homeService.updateProfile(
      userId: userId,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      requirements: _requirementsController.text.trim(),
    );
    if (!mounted) return;

    if (result['success'] != true) {
      _showSnack(result['message']?.toString() ?? 'Save failed.', error: true);
      return;
    }

    // The app uses the email as its session key, so keep it in sync.
    final newEmail = (result['email'] ?? '').toString();
    if (newEmail.isNotEmpty && newEmail != _userEmail) {
      final auth = AuthService();
      final role = await auth.getUserRole();
      await auth.saveSession(newEmail, role ?? '');
      if (!mounted) return;
    }

    setState(() {
      _userName = (result['name'] ?? '').toString();
      _userEmail = newEmail;
      _userPhone = (result['phone'] ?? '').toString();
    });
    _showSnack('Profile details saved.');
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

  void _showPetDialog({PetModel? pet}) {
  final isEdit = pet != null;
  final nameCtrl = TextEditingController(text: pet?.name ?? '');
  final breedCtrl = TextEditingController(text: pet?.breed ?? '');
  String? selectedSpecies = _petTypes.contains(pet?.species.toUpperCase())
      ? pet!.species.toUpperCase()
      : null;
  final ageCtrl = TextEditingController(text: pet == null ? '' : '${pet.age}');
  final careCtrl = TextEditingController(text: pet?.careNotes ?? '');
  String? speciesError;
  String? nameError;
  String? breedError;
  String? ageError;
  String? saveError;
  bool saving = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? 'Edit pet' : 'Add a pet',
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
                maxLength: 255,
                decoration: _fieldDecoration('Pet name *')
                    .copyWith(errorText: nameError, counterText: ''),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: breedCtrl,
                maxLength: 255,
                decoration: _fieldDecoration('Breed *')
                    .copyWith(errorText: breedError, counterText: ''),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 12),
             DropdownButtonFormField<String>(
                value: selectedSpecies,
                isExpanded: true,
                dropdownColor: Colors.white,
                decoration: _fieldDecoration('Type of pet *')
                    .copyWith(errorText: speciesError),
                items: _petTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(_petTypeLabel(t))))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedSpecies = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ageCtrl,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration('Age (years) *').copyWith(errorText: ageError),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: careCtrl,
                maxLines: 2,
                maxLength: 255,
                decoration: _fieldDecoration('Care notes').copyWith(counterText: ''),
              ),
              const SizedBox(height: 12),
              const Text(
                'Behaviour scores and reviews are added by sitters after a stay.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              if (saveError != null) ...[
                const SizedBox(height: 12),
                Text(saveError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            onPressed: saving
                ? null
                : () async {
                    final name = nameCtrl.text.trim();
                    final breed = breedCtrl.text.trim();
                    final species = selectedSpecies ?? '';      
                    final age = int.tryParse(ageCtrl.text.trim());
                    final ageOk = age != null && age >= 0 && age <= 40;

                    if (name.isEmpty || breed.isEmpty || species.isEmpty || !ageOk) {   
                      setDialogState(() {
                        nameError = name.isEmpty ? 'Required' : null;
                        breedError = breed.isEmpty ? 'Required' : null;
                        speciesError = species.isEmpty ? 'Required' : null;             
                        ageError = ageOk ? null : 'Enter an age from 0 to 40';
                      });
                      return;
                    }

                    final homeownerId = await AuthService().getUserId();
                    if (homeownerId == null) {
                      setDialogState(() => saveError = 'Session expired. Please log in again.');
                      return;
                    }

                    setDialogState(() {
                      saving = true;
                      saveError = null;
                      nameError = null;
                      breedError = null;
                      speciesError = null;                                               
                      ageError = null;
                    });

                    final result = isEdit
                        ? await _homeService.updatePet(
                            homeownerId: homeownerId,
                            petId: pet.id!,
                            name: name,
                            species: species,
                            breed: breed,
                            age: age,
                            careNotes: careCtrl.text.trim(),
                          )
                        : await _homeService.addPet(
                            homeownerId: homeownerId,
                            name: name,
                            species: species,
                            breed: breed,
                            age: age,
                            careNotes: careCtrl.text.trim(),
                          );
                    if (!mounted) return;

                    if (result['success'] == true) {
                      Navigator.pop(ctx);
                      await _loadPets();
                      _showSnack(isEdit ? 'Pet details updated.' : '$name added as a pet.');
                    } else {
                      setDialogState(() {
                        saving = false;
                        saveError = result['message']?.toString() ?? 'Could not add pet.';
                      });
                    }
                  },
            child: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(isEdit ? 'Save changes' : 'Add pet'),
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
              _buildPersonalCard(),      
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

  
  void _showChangePasswordDialog() {
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool hideCurrent = true;
  bool hideNew = true;
  bool saving = false;
  String? errorText;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change password', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: hideCurrent,
                decoration: _fieldDecoration('Current password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(hideCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setDialogState(() => hideCurrent = !hideCurrent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: hideNew,
                decoration: _fieldDecoration('New password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(hideNew ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setDialogState(() => hideNew = !hideNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: hideNew,
                decoration: _fieldDecoration('Confirm new password'),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 12),
                Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            onPressed: saving
                ? null
                : () async {
                    final current = currentCtrl.text;
                    final next = newCtrl.text;

                    if (current.isEmpty || next.isEmpty || confirmCtrl.text.isEmpty) {
                      setDialogState(() => errorText = 'Fill in all three fields.');
                      return;
                    }
                    if (next.length < 8) {
                      setDialogState(() => errorText = 'New password must be at least 8 characters.');
                      return;
                    }
                    if (next != confirmCtrl.text) {
                      setDialogState(() => errorText = 'New passwords do not match.');
                      return;
                    }

                    final userId = await AuthService().getUserId();
                    if (userId == null) {
                      setDialogState(() => errorText = 'Session expired. Please log in again.');
                      return;
                    }

                    setDialogState(() {
                      saving = true;
                      errorText = null;
                    });

                    final result = await AuthService().changePassword(
                      userId: userId,
                      currentPassword: current,
                      newPassword: next,
                    );
                    if (!mounted) return;

                    if (result['success'] == true) {
                      Navigator.pop(ctx);
                      _showSnack('Password updated.');
                    } else {
                      setDialogState(() {
                        saving = false;
                        errorText = result['message']?.toString() ?? 'Could not update password.';
                      });
                    }
                  },
            child: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Update password'),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPersonalCard() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
        ),
        const SizedBox(height: 2),
        const Text(
          'Saved with the "Save details" button below.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        _fieldLabel('Full name'),
        TextFormField(
          controller: _nameController,
          maxLength: 100,
          decoration: _fieldDecoration(null, icon: Icons.person_outline).copyWith(counterText: ''),
          validator: (val) =>
              val == null || val.trim().isEmpty ? 'Name is required' : null,
        ),
        const SizedBox(height: 20),
        _fieldLabel('Email'),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _fieldDecoration(null, icon: Icons.mail_outline),
          validator: (val) {
            final v = val?.trim() ?? '';
            if (v.isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 20),
        _fieldLabel('Phone number'),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 20,
          decoration: _fieldDecoration(null, icon: Icons.phone_outlined).copyWith(counterText: ''),
          validator: (val) =>
              val == null || val.trim().isEmpty ? 'Phone number is required' : null,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showChangePasswordDialog,
            icon: const Icon(Icons.lock_outline, color: AppColors.primaryRust, size: 18),
            label: const Text(
              'Change password',
              style: TextStyle(color: AppColors.darkText, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    ),
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
          onPressed: () => _showPetDialog(),
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
                        _tag(_petTypeLabel(pet.species)),
                        _tag('${pet.age} ${pet.age == 1 ? 'YR' : 'YRS'}'),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black54),
                color: Colors.white,
                onSelected: (value) {
                  if (value == 'edit') _showPetDialog(pet: pet);
                  if (value == 'delete') _confirmDeletePet(pet);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.emoji_emotions_outlined, color: AppColors.primaryRust, size: 18),
              const SizedBox(width: 6),
              Text(
              pet.behaviorScore == null ? 'No behaviour score yet' : 'Behaviour score',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkText),
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