import 'dart:async';

import 'package:flutter/material.dart';

import '../models/pet_model.dart';
import '../services/auth_services.dart';
import '../services/places_service.dart';
import '../services/profile_service.dart';
import '../theme/app_colors.dart';
import '../widgets/homeowner/dialogs/change_password_dialog.dart';
import '../widgets/homeowner/profile/profile_gate_banner.dart';
import '../widgets/homeowner/profile/profile_header_card.dart';
import '../widgets/homeowner/profile/profile_user_details_card.dart';
import '../widgets/sitter/profile/sitter_about_card.dart';
import '../widgets/sitter/profile/sitter_area_card.dart';
import '../widgets/sitter/profile/sitter_preferences_card.dart';
import '../widgets/sitter/profile/sitter_reviews_card.dart';
import '../widgets/sitter/profile/sitter_services_card.dart';
import '../widgets/sitter/sitter_bottom_nav_bar.dart';
import 'jobs_dashboard_screen.dart';
import 'messages_screen.dart';

class SitterProfileScreen extends StatefulWidget {
  const SitterProfileScreen({super.key});

  @override
  State<SitterProfileScreen> createState() => _SitterProfileScreenState();
}

class _SitterProfileScreenState extends State<SitterProfileScreen> {
  final _userFormKey = GlobalKey<FormState>();
  final _areaFormKey = GlobalKey<FormState>();
  final _aboutFormKey = GlobalKey<FormState>();
  final _servicesFormKey = GlobalKey<FormState>();

  final ProfileService _profileService = ProfileService();
  final PlacesApi _placesApi = PlacesApi();

  String _sitterName = '';
  String _sitterEmail = '';
  String _sitterPhone = '';
  String _savedArea = '';
  double? _savedLatitude;
  double? _savedLongitude;
  bool _hasSavedPets = false;
  bool _hasSavedServices = false;
  double _rating = 0;
  int _totalReviews = 0;

  bool _savingUser = false;
  bool _savingArea = false;
  bool _savingAbout = false;
  bool _savingPets = false;
  bool _savingServices = false;

  Timer? _areaDebounce;
  String _placesSessionToken = PlacesApi.newSessionToken();
  String? _selectedPlaceId;
  String? _selectedDescription;
  List<PlaceSuggestion> _areaSuggestions = [];
  bool _searchingArea = false;
  String? _areaLookupMessage;
  int _areaSearchGeneration = 0;
  String? _petsError;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  final Set<String> _selectedPets = {};

  static const Map<String, String> _serviceCodes = {
    'Stay Over Night': 'STAY_OVER_NIGHT',
    'Walk Pet': 'WALK_PET',
    'Feed Pet': 'FEED_PET',
  };

  final Map<String, bool> _selectedServices = {
    'Stay Over Night': true,
    'Walk Pet': false,
    'Feed Pet': false,
  };

  final TextEditingController _overnightRateCtrl = TextEditingController();
  final TextEditingController _walkRateCtrl = TextEditingController();
  final TextEditingController _walkDurationCtrl = TextEditingController();
  final TextEditingController _feedRateCtrl = TextEditingController();

  // The rest of the app unlocks once the sitter has a saved area, pet types and services.
  bool getValidForm() {
    final areaSaved = _savedArea.isNotEmpty && _savedLatitude != null && _savedLongitude != null;
    return areaSaved && _hasSavedPets && _hasSavedServices;
  }

  bool get _isAreaPinned {
    final text = _areaController.text.trim();
    if (text.isEmpty) {
      return false;
    }

    if (_selectedPlaceId != null && text == _selectedDescription) {
      return true;
    }

    return (text == _savedArea) && (_savedLatitude != null) && (_savedLongitude != null);
  }

  String? get _areaNotice {
    final text = _areaController.text.trim();
    if (_selectedPlaceId != null && text == _selectedDescription) {
      return 'Area selected. Save to store its location.';
    }
    if (text == _savedArea && _savedLatitude != null && _savedLongitude != null) {
      return 'Location saved.';
    }
    if (text.isNotEmpty &&
        text == _savedArea &&
        !_searchingArea &&
        _areaSuggestions.isEmpty &&
        _areaLookupMessage == null) {
      return 'Type to search, then select your area so its location can be saved.';
    }
    return _areaLookupMessage;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _areaDebounce?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    _areaController.dispose();
    _overnightRateCtrl.dispose();
    _walkRateCtrl.dispose();
    _walkDurationCtrl.dispose();
    _feedRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = await AuthService().getUserId();
    if (!mounted) return;

    if (userId == null) {
      _showSnack('User session expired. Please log in again.', error: true);
      return;
    }

    final result = await _profileService.fetchSitterProfile(userId: userId);
    if (!mounted) return;

    if (result['success'] != true) {
      _showSnack(result['message']?.toString() ?? 'Could not load profile', error: true);
      return;
    }

    setState(() {
      _sitterName = (result['name'] ?? '').toString();
      _sitterEmail = (result['email'] ?? '').toString();
      _sitterPhone = (result['phone'] ?? '').toString();
      _rating = (result['rating'] as num?)?.toDouble() ?? 0;
      _totalReviews = (result['totalReviews'] as num?)?.toInt() ?? 0;
      _savedArea = (result['serviceArea'] ?? '').toString().trim();
      _savedLatitude = (result['latitude'] as num?)?.toDouble();
      _savedLongitude = (result['longitude'] as num?)?.toDouble();

      _nameController.text = _sitterName;
      _emailController.text = _sitterEmail;
      _phoneController.text = _sitterPhone;
      _aboutController.text = (result['experience'] ?? '').toString();
      _areaController.text = _savedArea;

      _selectedPets
        ..clear()
        ..addAll(
          ((result['petPreferences'] as List?) ?? [])
              .map((pet) => pet.toString().toUpperCase())
              .where(petTypes.contains),
        );
      _hasSavedPets = _selectedPets.isNotEmpty;

      final services = (result['services'] as List?) ?? [];
      _hasSavedServices = services.isNotEmpty;
      if (services.isNotEmpty) {
        for (final key in _selectedServices.keys) {
          _selectedServices[key] = false;
        }
        for (final service in services) {
          final code = service['serviceType']?.toString();
          final price = _formatNumber(service['price'] as num?);
          if (code == 'STAY_OVER_NIGHT') {
            _selectedServices['Stay Over Night'] = true;
            _overnightRateCtrl.text = price;
          } else if (code == 'WALK_PET') {
            _selectedServices['Walk Pet'] = true;
            _walkRateCtrl.text = price;
            _walkDurationCtrl.text = _formatNumber(service['durationMinutes'] as num?);
          } else if (code == 'FEED_PET') {
            _selectedServices['Feed Pet'] = true;
            _feedRateCtrl.text = price;
          }
        }
      }
    });
  }

  String _formatNumber(num? value) {
    if (value == null) return '';
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  Future<void> _saveUserDetails() async {
    if (_savingUser || !_userFormKey.currentState!.validate()) return;

    setState(() => _savingUser = true);
    final saved = await _submitProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (!mounted) return;

    setState(() => _savingUser = false);
    if (saved) _showSnack('User details saved.');
  }

  Future<void> _saveAreaDetails() async {
    if (_savingArea || !_areaFormKey.currentState!.validate()) return;

    setState(() => _savingArea = true);
    final placeId = _selectedPlaceId;
    final saved = await _submitProfile(
      serviceArea: _areaController.text.trim(),
      placeId: placeId,
      sessionToken: placeId == null ? null : _placesSessionToken,
    );
    if (!mounted) return;

    setState(() {
      _savingArea = false;
      if (saved && placeId != null) {
        _selectedPlaceId = null;
        _selectedDescription = null;
        _areaSuggestions = [];
        _areaLookupMessage = null;
        _placesSessionToken = PlacesApi.newSessionToken();
      }
    });
    if (saved) _showSnack('Area of service saved.');
  }

  Future<void> _saveAbout() async {
    if (_savingAbout || !_aboutFormKey.currentState!.validate()) return;

    setState(() => _savingAbout = true);
    final saved = await _submitProfile(experience: _aboutController.text.trim());
    if (!mounted) return;

    setState(() => _savingAbout = false);
    if (saved) _showSnack('About & experience saved.');
  }

  Future<void> _savePetPreferences() async {
    if (_savingPets) return;
    if (_selectedPets.isEmpty) {
      setState(() => _petsError = 'Select at least one pet type.');
      return;
    }

    setState(() => _savingPets = true);
    final saved = await _submitProfile(petPreferences: _selectedPets.toList());
    if (!mounted) return;

    setState(() {
      _savingPets = false;
      if (saved) _hasSavedPets = true;
    });
    if (saved) _showSnack('Pet preferences saved.');
  }

  Future<void> _saveServices() async {
    if (_savingServices || !_servicesFormKey.currentState!.validate()) return;

    setState(() => _savingServices = true);
    final saved = await _submitProfile(services: _servicePayload());
    if (!mounted) return;

    setState(() {
      _savingServices = false;
      if (saved) _hasSavedServices = true;
    });
    if (saved) _showSnack('Services & pricing saved.');
  }

  Future<bool> _submitProfile({String? name, String? email, String? phone, String? experience, List<Map<String, dynamic>>? services, List<String>? petPreferences, String? serviceArea, String? placeId, String? sessionToken}) async {
    FocusScope.of(context).unfocus();

    final userId = await AuthService().getUserId();
    if (!mounted) return false;

    if (userId == null) {
      _showSnack('User session expired. Please log in again.', error: true);
      return false;
    }

    final result = await _profileService.updateSitterProfile(
      userId: userId,
      name: name,
      email: email,
      phone: phone,
      experience: experience,
      services: services,
      petPreferences: petPreferences,
      serviceArea: serviceArea,
      placeId: placeId,
      sessionToken: sessionToken,
    );
    if (!mounted) return false;

    if (result['success'] != true) {
      _showSnack(result['message']?.toString() ?? 'Save failed.', error: true);
      return false;
    }

    final newEmail = (result['email'] ?? _sitterEmail).toString();
    if (newEmail.isNotEmpty && newEmail != _sitterEmail) {
      final auth = AuthService();
      final role = await auth.getUserRole();
      await auth.saveSession(newEmail, role ?? '');
      if (!mounted) return false;
    }

    setState(() {
      _sitterName = (result['name'] ?? _sitterName).toString();
      _sitterEmail = newEmail;
      _sitterPhone = (result['phone'] ?? _sitterPhone).toString();
      _savedArea = (result['serviceArea'] ?? _savedArea).toString();
      _savedLatitude = (result['latitude'] as num?)?.toDouble();
      _savedLongitude = (result['longitude'] as num?)?.toDouble();
      if (placeId != null) {
        _areaController.text = _savedArea;
      }
    });
    return true;
  }

  List<Map<String, dynamic>> _servicePayload() {
    return [
      if (_selectedServices['Stay Over Night']!)
        {
          'serviceType': _serviceCodes['Stay Over Night'],
          'price': double.parse(_overnightRateCtrl.text.trim()),
        },
      if (_selectedServices['Walk Pet']!)
        {
          'serviceType': _serviceCodes['Walk Pet'],
          'price': double.parse(_walkRateCtrl.text.trim()),
          'durationMinutes': int.parse(_walkDurationCtrl.text.trim()),
        },
      if (_selectedServices['Feed Pet']!)
        {
          'serviceType': _serviceCodes['Feed Pet'],
          'price': double.parse(_feedRateCtrl.text.trim()),
        },
    ];
  }

  void _onAreaChanged(String value) {
    final text = value.trim();
    if (_selectedPlaceId != null && text != _selectedDescription) {
      _selectedPlaceId = null;
      _selectedDescription = null;
    }

    _areaDebounce?.cancel();
    if (_selectedPlaceId != null || text.length < 3) {
      _areaSearchGeneration++;
      setState(() {
        _areaSuggestions = [];
        _searchingArea = false;
        _areaLookupMessage = null;
      });
      return;
    }

    setState(() {
      _searchingArea = true;
      _areaLookupMessage = null;
    });
    _areaDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchAreas(text);
    });
  }

  Future<void> _searchAreas(String text) async {
    final generation = ++_areaSearchGeneration;
    try {
      final suggestions = await _placesApi.autocomplete(
        input: text,
        sessionToken: _placesSessionToken,
      );
      if (!mounted || generation != _areaSearchGeneration) return;
      if (_areaController.text.trim() != text) return;
      setState(() {
        _searchingArea = false;
        _areaSuggestions = suggestions;
        _areaLookupMessage =
            suggestions.isEmpty ? 'No matching areas. Try a more specific search.' : null;
      });
    } catch (_) {
      if (!mounted || generation != _areaSearchGeneration) return;
      setState(() {
        _searchingArea = false;
        _areaSuggestions = [];
        _areaLookupMessage = 'Area search is unavailable right now.';
      });
    }
  }

  void _selectArea(PlaceSuggestion suggestion) {
    _areaDebounce?.cancel();
    _areaSearchGeneration++;
    _areaController.text = suggestion.description;
    _areaController.selection = TextSelection.collapsed(
      offset: _areaController.text.length,
    );
    setState(() {
      _selectedPlaceId = suggestion.placeId;
      _selectedDescription = suggestion.description;
      _areaSuggestions = [];
      _searchingArea = false;
      _areaLookupMessage = null;
    });
  }

  String? _validateArea(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Area of service is required';
    if (!_isAreaPinned) return 'Select an area from the suggestions';
    return null;
  }

  void _onAreaTap() {
    final text = _areaController.text.trim();
    if (!_isAreaPinned && text.length >= 3 && !_searchingArea) {
      _onAreaChanged(text);
    }
  }

  void _togglePet(String pet) {
    setState(() {
      if (_selectedPets.contains(pet)) {
        _selectedPets.remove(pet);
      } else {
        _selectedPets.add(pet);
      }
      if (_selectedPets.isNotEmpty) _petsError = null;
    });
  }

  void _toggleService(String key) {
    final count = _selectedServices.values.where((selected) => selected).length;
    if (_selectedServices[key]! && count == 1) {
      _showSnack('At least one service type must be selected.');
      return;
    }
    setState(() => _selectedServices[key] = !_selectedServices[key]!);
  }

  String? _validatePrice(String? value) {
    final price = double.tryParse((value ?? '').trim());
    if (price == null || price <= 0) return 'Enter a price';
    return null;
  }

  String? _validateMinutes(String? value) {
    final minutes = int.tryParse((value ?? '').trim());
    if (minutes == null || minutes <= 0) return 'Enter minutes';
    return null;
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
      'Save your area of service, pet preferences and services & pricing first.',
      error: true,
    );
  }

  void _handleBottomNavTap(SitterNavTab tab) {
    if (tab == SitterNavTab.profile) return;

    if (!getValidForm()) {
      _showGateMessage();
      return;
    }

    if (tab == SitterNavTab.home) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final Widget destination = switch (tab) {
      SitterNavTab.jobs => const JobsDashboardScreen(),
      SitterNavTab.messages => const MessagesScreen(),
      SitterNavTab.home || SitterNavTab.profile => const SitterProfileScreen(),
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
            'Sitter Profile',
            style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!getValidForm()) ...[
              const ProfileGateBanner(
                message:
                    'Save your area of service, pet preferences and services & pricing to unlock the rest of the app.',
              ),
              const SizedBox(height: 16),
            ],
            ProfileHeaderCard(
              name: _sitterName,
              email: _sitterEmail,
              phone: _sitterPhone,
              reviewCount: _totalReviews,
              averageRating: _rating,
              onPhotoTap: _showPhotoComingSoon,
              tag: 'SITTER',
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
            SitterAreaCard(
              formKey: _areaFormKey,
              areaController: _areaController,
              searching: _searchingArea,
              suggestions: _areaSuggestions,
              notice: _areaNotice,
              saving: _savingArea,
              onAreaChanged: _onAreaChanged,
              onAreaTap: _onAreaTap,
              onSelectSuggestion: _selectArea,
              areaValidator: _validateArea,
              onAreaSave: _saveAreaDetails,
            ),
            const SizedBox(height: 16),
            SitterAboutCard(
              formKey: _aboutFormKey,
              aboutController: _aboutController,
              saving: _savingAbout,
              onSave: _saveAbout,
            ),
            const SizedBox(height: 16),
            SitterPreferencesCard(
              selectedPets: _selectedPets,
              errorText: _petsError,
              saving: _savingPets,
              onToggle: _togglePet,
              onSave: _savePetPreferences,
            ),
            const SizedBox(height: 16),
            SitterServicesCard(
              formKey: _servicesFormKey,
              selectedServices: _selectedServices,
              overnightRateController: _overnightRateCtrl,
              walkRateController: _walkRateCtrl,
              walkDurationController: _walkDurationCtrl,
              feedRateController: _feedRateCtrl,
              saving: _savingServices,
              onToggle: _toggleService,
              onSave: _saveServices,
              validatePrice: _validatePrice,
              validateMinutes: _validateMinutes,
            ),
            const SizedBox(height: 16),
            SitterReviewsCard(
              reviewCount: _totalReviews,
              averageRating: _rating,
            ),
            const SizedBox(height: 24),
          ],
        ),
        bottomNavigationBar: SitterBottomNavBar(
          selected: SitterNavTab.profile,
          onTap: _handleBottomNavTap,
        ),
      ),
    );
  }
}
