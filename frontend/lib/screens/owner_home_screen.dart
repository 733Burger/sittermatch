import 'package:flutter/material.dart';

import '../models/homeowner_checks_model.dart';
import '../models/sitter_listing.dart';
import '../screens/login_screen.dart';
import '../services/auth_services.dart';
import '../services/home_services.dart';
import '../theme/app_colors.dart';
import '../widgets/homeowner/dialogs/address_check_dialog.dart';
import '../widgets/homeowner/dialogs/emergency_contact_dialog.dart';
import '../widgets/homeowner/dialogs/identity_check_dialog.dart';
import '../widgets/homeowner/homeowner_bottom_nav_bar.dart';
import '../widgets/homeowner/homepage/homeowner_drawer.dart';
import '../widgets/homeowner/homepage/sitter_card.dart';
import '../widgets/homeowner/homepage/sitter_filter_chips.dart';
import '../widgets/homeowner/homepage/sitter_search_field.dart';
import '../widgets/homeowner/homepage/verification_checks_card.dart';
import '../services/saved_sitter_service.dart';

import 'bookings_dashboard_screen.dart';
import 'saved_sitters_screen.dart';
import 'direct_chat_screen.dart';
import 'sitter_detail_screen.dart';
import 'booking_flow_screen.dart';
import 'messages_screen.dart';
import 'owner_profile_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  static const List<String> _filterTags = [
    'All',
    'ID Verified',
    'Pet Type',
    'Date Available',
    'Medication Admin',
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final HomeService _homeService = HomeService();
  final AuthService _authService = AuthService();
  final SavedSitterService _savedSitterService = SavedSitterService();
  final TextEditingController _searchController = TextEditingController();

  String _email = '';
  OwnerChecks _checks = const OwnerChecks();
  List<SitterListing> _sitters = [];
  final Set<int> _savedSitterIds = {};

  String? _idPhotoPath;
  String _selectedFilter = _filterTags.first;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Methods
  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    try {
      final email = await _homeService.getUserEmail();
      if (!mounted) return;

      if (email == null || email.isEmpty) {
        setState(() => _email = '');
        return;
      }

      final verificationCheck = await _homeService.fetchChecks();
      final nearbySitters = await _homeService.fetchSitters();

      if (!mounted) return;

      if (verificationCheck['success'] == false) {
        setState(() => _email = email);
        _showSnack(verificationCheck['message']?.toString() ?? 'Could not load checks');
        return;
      }

      final sitters = SitterListing.listFromJson(nearbySitters['sitters']);

      setState(() {
        _email = email;
        _checks = OwnerChecks.fromJson(verificationCheck);
        _sitters = sitters;
        _savedSitterIds
          ..clear()                          
          ..addAll(sitters.where((sitter) => sitter.isSaved).map((sitter) => sitter.id));
        _isLoading = false;        
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not load home data');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSaved(SitterListing sitter) async {
    final bool wasSaved = _savedSitterIds.contains(sitter.id);

    setState(() {
      if (wasSaved) {
        _savedSitterIds.remove(sitter.id);
      } else {
        _savedSitterIds.add(sitter.id);
      }
    });

    try {
      final homeownerId = await _authService.getUserId();
      if (!mounted) return;

      if (homeownerId == null) {
        _rollbackState(sitter.id, wasSaved);
        _showSnack('User session expired. Please log in again.');
        return;
      }

      final saveSitter = await _savedSitterService.toggleSavedSitter(
        homeownerId: homeownerId,
        sitterId: sitter.id,
        isCurrentlySaved: wasSaved,
      );

      if (!mounted) return;

      if (saveSitter['success']) {
        _showSnack(wasSaved
            ? '${sitter.name} removed from Saved Sitters.'
            : '${sitter.name} added to Saved Sitters!');
      } else {
        _rollbackState(sitter.id, wasSaved);
        _showSnack(wasSaved
            ? 'Failed to remove sitter. Please try again.'
            : 'Failed to save sitter. Please try again.');
      }
    } catch (e) {
      debugPrint('Error toggling sitter: $e');
      if (!mounted) return;
      _rollbackState(sitter.id, wasSaved);
      _showSnack('Network error occurred.');
    }
  }

  void _rollbackState(int sitterId, bool wasSavedBefore) {
    if (!mounted) return;
    setState(() {
      if (wasSavedBefore) {
        _savedSitterIds.add(sitterId);
      } else {
        _savedSitterIds.remove(sitterId);
      }
    });
  }

  void _closeDrawerIfOpen() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  Future<void> _open(Widget screen, {bool refreshOnReturn = false}) async {
    _closeDrawerIfOpen();
    final result = await Navigator.of(context).push<Object?>(MaterialPageRoute(builder: (_) => screen));

    if (!mounted) return;
    
    if (result is Set<int> && result.isNotEmpty) {
      setState(() => _savedSitterIds.removeAll(result));
    }

    if (refreshOnReturn) _loadData(silent: true);
  }

  void _comingSoon(String title) {
    _closeDrawerIfOpen();
    _showSnack('$title is coming soon');
  }

  Future<void> _logout() async {
    await AuthService().clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showMessageIfMounted(String message) {
    if (mounted) _showSnack(message);
  }

  void _handleBottomNavTap(OwnerNavTab tab) {
    switch (tab) {
      case OwnerNavTab.home:
        break;
      case OwnerNavTab.bookings:
        _open(const BookingsDashboardScreen());
        break;
      case OwnerNavTab.messages:
        _open(const MessagesScreen());
        break;
      case OwnerNavTab.profile:
        _open(const OwnerProfileScreen());
        break;
    }
  }

  // Dialogs
  void _openIdentityCheckDialog() {
    showDialog(
      context: context,
      builder: (_) => IdentityCheckDialog(
        email: _email,
        homeService: _homeService,
        hasSelectedPhoto: _idPhotoPath != null,
        onUploaded: (photoPath) {
          if (!mounted) return;
          setState(() => _idPhotoPath = photoPath);
          _showSnack('ID Photo uploaded successfully! Status set to Pending.');
          _loadData();
        },
        onMessage: _showMessageIfMounted,
      ),
    );
  }

  void _openAddressCheckDialog() {
    showDialog(
      context: context,
      builder: (_) => AddressCheckDialog(
        initialAddress: _checks.addressCheck.subtitle,
        email: _email,
        homeService: _homeService,
        onSaved: () {
          if (!mounted) return;
          _showSnack('Home address saved! Status set to Pending.');
          _loadData();
        },
        onMessage: _showMessageIfMounted,
      ),
    );
  }

  void _openEmergencyContactDialog() {
    showDialog(
      context: context,
      builder: (_) => EmergencyContactDialog(
        initialName: _checks.emergencyContactName,
        initialPhone: _checks.emergencyContactNumber,
        email: _email,
        homeService: _homeService,
        onSaved: () {
          if (!mounted) return;
          _showSnack('Emergency contact saved! Status set to Pending.');
          _loadData();
        },
        onMessage: _showMessageIfMounted,
      ),
    );
  }

  // Main Widget for the Home Screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Row(
          children: [
            Icon(Icons.pets, color: AppColors.primaryRust),
            SizedBox(width: 8),
            Text(
              'Sit & Stay',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Colors.black),
            tooltip: 'Security & Trust',
            onPressed: () => _comingSoon('Security & Trust'),
          ),
        ],
      ),
      drawer: OwnerHomeDrawer(
        email: _email,
        savedSittersCount: _savedSitterIds.length,
        onSavedSittersTap: () => _open(const SavedSittersScreen(), refreshOnReturn: true),
        onSettingsTap: () => _comingSoon('Settings'),
        onLogOut: _logout,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRust),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VerificationChecksCard(
                    checks: _checks,
                    onIdentityTap: _openIdentityCheckDialog,
                    onAddressTap: _openAddressCheckDialog,
                    onEmergencyContactTap: _openEmergencyContactDialog,
                  ),
                  const SizedBox(height: 24),
                  SitterSearchField(controller: _searchController),
                  const SizedBox(height: 12),
                  SitterFilterChips(
                    tags: _filterTags,
                    selected: _selectedFilter,
                    onSelected: (tag) => setState(() => _selectedFilter = tag),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Available Sitters Nearby',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  for (final sitter in _sitters)
                    SitterCard(
                      sitter: sitter,
                      isSaved: _savedSitterIds.contains(sitter.id),
                      onTap: () => _open(SitterDetailScreen(sitterId: sitter.id)),
                      onMessage: () => _open(DirectChatScreen(
                        partnerId: sitter.id,
                        partnerName: sitter.name,
                      )),
                      onBook: () => _open(const BookingFlowScreen()),
                      onToggleSave: () => _toggleSaved(sitter),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: OwnerBottomNavBar(onTap: _handleBottomNavTap),
    );
  }
}