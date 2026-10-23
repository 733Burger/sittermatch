import 'dart:async';

import 'package:flutter/material.dart';

import '../models/owner_review.dart';
import '../models/pet_model.dart';
import '../services/auth_services.dart';
import '../services/places_service.dart';
import '../services/profile_service.dart';
import '../theme/app_colors.dart';
import '../widgets/homeowner/dialogs/change_password_dialog.dart';
import '../widgets/homeowner/dialogs/pet_form_dialog.dart';
import '../widgets/homeowner/homeowner_bottom_nav_bar.dart';
import '../widgets/homeowner/profile/profile_address_card.dart';
import '../widgets/homeowner/profile/profile_gate_banner.dart';
import '../widgets/homeowner/profile/profile_header_card.dart';
import '../widgets/homeowner/profile/profile_pet_card.dart';
import '../widgets/homeowner/profile/profile_pets_section.dart';
import '../widgets/homeowner/profile/profile_reviews_card.dart';
import '../widgets/homeowner/profile/profile_user_details_card.dart';
import 'bookings_dashboard_screen.dart';
import 'messages_screen.dart';
import 'owner_home_screen.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _userFormKey = GlobalKey<FormState>();
  final _homeFormKey = GlobalKey<FormState>();

  final ProfileService _profileService = ProfileService();
  final PlacesApi _placesApi = PlacesApi();

  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _savedAddress = '';
  String _savedRequirements = '';
  double? _savedLatitude;
  double? _savedLongitude;

  bool _savingUser = false;
  bool _savingHome = false;

  Timer? _addressDebounce;
  String _placesSessionToken = PlacesApi.newSessionToken();
  String? _selectedPlaceId;
  String? _selectedDescription;
  List<PlaceSuggestion> _addressSuggestions = [];
  bool _searchingAddress = false;
  String? _addressLookupMessage;
  int _addressSearchGeneration = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();

  final List<PetModel> _pets = [];
  final List<OwnerReview> _ownerReviews = [];

  bool getValidForm() {
    return _isAddressPinned && _requirementsController.text.trim().isNotEmpty;
  }

  bool get _isAddressPinned {
    final text = _addressController.text.trim();
    if (text.isEmpty) { 
      return false;
    }
    
    if (_selectedPlaceId != null && text == _selectedDescription) { 
      return true;
    }

    return (text == _savedAddress) && (_savedLatitude != null) && (_savedLongitude != null);
  }

  String? get _addressNotice {
    final text = _addressController.text.trim();
    if (_selectedPlaceId != null && text == _selectedDescription) {
      return 'Address selected. Save to store its location.';
    }
    if (text == _savedAddress && _savedLatitude != null && _savedLongitude != null) {
      return 'Location saved.';
    }
    if (text.isNotEmpty &&
        text == _savedAddress &&
        !_searchingAddress &&
        _addressSuggestions.isEmpty &&
        _addressLookupMessage == null) {
      return 'Type to search, then select your address so its location can be saved.';
    }
    return _addressLookupMessage;
  }

  double get _averageRating {
    if (_ownerReviews.isEmpty) return 0;
    final total = _ownerReviews.fold<double>(0, (sum, review) => sum + review.rating);
    return total / _ownerReviews.length;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPets();
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    _addressController.dispose();
    _requirementsController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProfile() async {
    final userId = await AuthService().getUserId();
    if (!mounted) return;

    if (userId == null) {
      _showSnack('User session expired. Please log in again.', error: true);
      return;
    }

    final profileDetails = await _profileService.fetchProfile(userId: userId);
    if (!mounted) return;

    if (profileDetails['success'] != true) {
      _showSnack(profileDetails['message']?.toString() ?? 'Could not load profile', error: true);
      return;
    }

    setState(() {
      _userName = (profileDetails['name'] ?? '').toString();
      _userEmail = (profileDetails['email'] ?? '').toString();
      _userPhone = (profileDetails['phone'] ?? '').toString();
      _savedAddress = (profileDetails['address'] ?? '').toString();
      _savedRequirements = (profileDetails['requirements'] ?? '').toString();
      _savedLatitude = (profileDetails['latitude'] as num?)?.toDouble();
      _savedLongitude = (profileDetails['longitude'] as num?)?.toDouble();

      _nameController.text = _userName;
      _emailController.text = _userEmail;
      _phoneController.text = _userPhone;
      _addressController.text = _savedAddress;
      _requirementsController.text = _savedRequirements;
    });
  }

  Future<void> _loadPets() async {
    final userId = await AuthService().getUserId();
    if (!mounted || userId == null) return;

    final homeownerPets = await _profileService.fetchPets(homeownerId: userId);
    if (!mounted) return;

    if (homeownerPets['success'] != true) {
      _showSnack(homeownerPets['message']?.toString() ?? 'Could not load pets', error: true);
      return;
    }

    final pets = (homeownerPets['pets'] as List)
        .map((pet) => PetModel.fromJson(Map<String, dynamic>.from(pet as Map)))
        .toList();

    setState(() {
      _pets
        ..clear()
        ..addAll(pets);
    });
  }

  Future<void> _saveUserDetails() async {
    if (_savingUser || !_userFormKey.currentState!.validate()) return;

    setState(() => _savingUser = true);
    final saved = await _submitProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _savedAddress,
      requirements: _savedRequirements,
    );
    if (!mounted) return;

    setState(() => _savingUser = false);
    if (saved) _showSnack('User details saved.');
  }

  Future<void> _saveAddressDetails() async {
    if (_savingHome || !_homeFormKey.currentState!.validate()) return;

    setState(() => _savingHome = true);
    final placeId = _selectedPlaceId;
    final saved = await _submitProfile(
      name: _userName,
      email: _userEmail,
      phone: _userPhone,
      address: _addressController.text.trim(),
      requirements: _requirementsController.text.trim(),
      placeId: placeId,
      sessionToken: _placesSessionToken,
    );
    if (!mounted) return;

    setState(() {
      _savingHome = false;
      if (saved && placeId != null) {
        _selectedPlaceId = null;
        _selectedDescription = null;
        _addressSuggestions = [];
        _addressLookupMessage = null;
        _placesSessionToken = PlacesApi.newSessionToken();
      }
    });
    if (saved) _showSnack('Address details saved.');
  }

  Future<bool> _submitProfile({required String name, required String email, required String phone, required String address, required String requirements, String? placeId, String? sessionToken}) async {
    FocusScope.of(context).unfocus();

    final userId = await AuthService().getUserId();
    if (!mounted) return false;

    if (userId == null) {
      _showSnack('User session expired. Please log in again.', error: true);
      return false;
    }

    final result = await _profileService.updateProfile(
      userId: userId,
      name: name,
      email: email,
      phone: phone,
      address: address,
      requirements: requirements,
      placeId: placeId,
      sessionToken: sessionToken,
    );
    if (!mounted) return false;

    if (result['success'] != true) {
      _showSnack(result['message']?.toString() ?? 'Save failed.', error: true);
      return false;
    }

    final newEmail = (result['email'] ?? email).toString();
    if (newEmail.isNotEmpty && newEmail != _userEmail) {
      final auth = AuthService();
      final role = await auth.getUserRole();
      await auth.saveSession(newEmail, role ?? '');
      if (!mounted) return false;
    }

    setState(() {
      _userName = (result['name'] ?? name).toString();
      _userEmail = newEmail;
      _userPhone = (result['phone'] ?? phone).toString();
      _savedAddress = (result['address'] ?? address).toString();
      _savedRequirements = (result['requirements'] ?? requirements).toString();
      _savedLatitude = (result['latitude'] as num?)?.toDouble();
      _savedLongitude = (result['longitude'] as num?)?.toDouble();
      if (placeId != null) {
        _addressController.text = _savedAddress;
      }
    });
    return true;
  }

  void _onAddressChanged(String value) {
    final text = value.trim();
    if (_selectedPlaceId != null && text != _selectedDescription) {
      _selectedPlaceId = null;
      _selectedDescription = null;
    }

    _addressDebounce?.cancel();
    if (_selectedPlaceId != null || text.length < 3) {
      _addressSearchGeneration++;
      setState(() {
        _addressSuggestions = [];
        _searchingAddress = false;
        _addressLookupMessage = null;
      });
      return;
    }

    setState(() {
      _searchingAddress = true;
      _addressLookupMessage = null;
    });
    _addressDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchAddresses(text);
    });
  }

  Future<void> _searchAddresses(String text) async {
    final generation = ++_addressSearchGeneration;
    try {
      final suggestions = await _placesApi.autocomplete(
        input: text,
        sessionToken: _placesSessionToken,
      );
      if (!mounted || generation != _addressSearchGeneration) return;
      if (_addressController.text.trim() != text) return;
      setState(() {
        _searchingAddress = false;
        _addressSuggestions = suggestions;
        _addressLookupMessage =
            suggestions.isEmpty ? 'No matching addresses. Try a more specific search.' : null;
      });
    } catch (_) {
      if (!mounted || generation != _addressSearchGeneration) return;
      setState(() {
        _searchingAddress = false;
        _addressSuggestions = [];
        _addressLookupMessage = 'Address search is unavailable right now.';
      });
    }
  }

  void _selectAddress(PlaceSuggestion suggestion) {
    _addressDebounce?.cancel();
    _addressSearchGeneration++;
    _addressController.text = suggestion.description;
    _addressController.selection = TextSelection.collapsed(
      offset: _addressController.text.length,
    );
    setState(() {
      _selectedPlaceId = suggestion.placeId;
      _selectedDescription = suggestion.description;
      _addressSuggestions = [];
      _searchingAddress = false;
      _addressLookupMessage = null;
    });
  }

  String? _validateAddress(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Address is required';
    if (!_isAddressPinned) return 'Select an address from the suggestions';
    return null;
  }

  void _onHouseNotesPresenceChanged() {
    setState(() {});
  }

  void _onAddressTap() {
    final text = _addressController.text.trim();
    if (!_isAddressPinned && text.length >= 3 && !_searchingAddress) {
      _onAddressChanged(text);
    }
  }

  void _showPetDialog({PetModel? pet}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PetFormDialog(
        pet: pet,
        profileService: _profileService,
        onSaved: _loadPets,
        onMessage: _showMessageIfMounted,
      ),
    );
  }

  Future<void> _confirmDeletePet(PetModel pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${pet.name}?'),
        content: const Text(
          "This removes the pet and any reviews linked to it. This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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

    final result = await _profileService.deletePet(
      homeownerId: homeownerId,
      petId: pet.id!,
    );
    if (!mounted) return;

    if (result['success'] == true) {
      await _loadPets();
      if (!mounted) return;
      _showSnack('Pet entry deleted.');
    } else {
      _showSnack(result['message']?.toString() ?? 'Could not delete pet.', error: true);
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangePasswordDialog(onMessage: _showMessageIfMounted),
    );
  }

  void _showPhotoComingSoon() {
    _showSnack('Photo upload is coming soon.');
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red : null,
        ),
      );
  }

  void _showMessageIfMounted(String message) {
    if (mounted) _showSnack(message);
  }

  void _showGateMessage() {
    _showSnack(
      'Select your home address from the suggestions and add house sitting notes first.',
      error: true,
    );
  }

  void _handleBottomNavTap(OwnerNavTab tab) {
    if (tab == OwnerNavTab.profile) return;

    if (!getValidForm()) {
      _showGateMessage();
      return;
    }

    final Widget destination = switch (tab) {
      OwnerNavTab.home => const OwnerHomeScreen(),
      OwnerNavTab.bookings => const BookingsDashboardScreen(),
      OwnerNavTab.messages => const MessagesScreen(),
      OwnerNavTab.profile => const OwnerProfileScreen(),
    };

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: getValidForm(),
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
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!getValidForm()) ...[
              const ProfileGateBanner(),
              const SizedBox(height: 16),
            ],
            ProfileHeaderCard(
              name: _userName,
              email: _userEmail,
              phone: _userPhone,
              reviewCount: _ownerReviews.length,
              averageRating: _averageRating,
              onPhotoTap: _showPhotoComingSoon,
            ),
            const SizedBox(height: 16),
            ProfileUserDetailsCard(
              formKey: _userFormKey,
              nameController: _nameController,
              emailController: _emailController,
              phoneController: _phoneController,
              saving: _savingUser,
              onChangePassword: _showChangePasswordDialog,
              onSave: _saveUserDetails,
            ),
            const SizedBox(height: 16),
            ProfileAddressCard(
              formKey: _homeFormKey,
              addressController: _addressController,
              requirementsController: _requirementsController,
              searching: _searchingAddress,
              suggestions: _addressSuggestions,
              notice: _addressNotice,
              saving: _savingHome,
              onChanged: _onHouseNotesPresenceChanged,
              onAddressChanged: _onAddressChanged,
              onAddressTap: _onAddressTap,
              onSelectSuggestion: _selectAddress,
              addressValidator: _validateAddress,
              onAddressSave: _saveAddressDetails,
            ),
            const SizedBox(height: 24),
            ProfilePetsHeader(onAdd: () => _showPetDialog()),
            const SizedBox(height: 12),
            if (_pets.isEmpty)
              const ProfileEmptyPets()
            else
              ..._pets.map(
                (pet) => ProfilePetCard(
                  pet: pet,
                  onEdit: () => _showPetDialog(pet: pet),
                  onDelete: () => _confirmDeletePet(pet),
                ),
              ),
            const SizedBox(height: 12),
            ProfileReviewsCard(
              reviews: _ownerReviews,
              averageRating: _averageRating,
            ),
            const SizedBox(height: 24),
          ],
        ),
        bottomNavigationBar: OwnerBottomNavBar(
          selected: OwnerNavTab.profile,
          onTap: _handleBottomNavTap,
        ),
      ),
    );
  }
}
