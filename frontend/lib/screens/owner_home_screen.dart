import 'package:flutter/material.dart';

import '../models/owner_checks_model.dart';
import '../models/sitter_listing.dart';
import '../screens/login_screen.dart';
import '../services/auth_services.dart';
import '../services/home_services.dart';
import '../theme/app_colors.dart';
import '../widgets/owner_home/dialogs/address_check_dialog.dart';
import '../widgets/owner_home/dialogs/emergency_contact_dialog.dart';
import '../widgets/owner_home/dialogs/identity_check_dialog.dart';
import '../widgets/owner_home/owner_bottom_nav_bar.dart';
import '../widgets/owner_home/owner_home_drawer.dart';
import '../widgets/owner_home/sitter_card.dart';
import '../widgets/owner_home/sitter_filter_chips.dart';
import '../widgets/owner_home/sitter_search_field.dart';
import '../widgets/owner_home/verification_checks_card.dart';

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
  final TextEditingController _searchController = TextEditingController();

  String _email = '';
  OwnerChecks _checks = const OwnerChecks();
  String? _idPhotoPath;
  String _selectedFilter = _filterTags.first;

  final Set<int> _favoriteSitterIds = {101};

  final List<SitterListing> _sitters = const [
    SitterListing(
      id: 101,
      name: 'Sarah Jenkins',
      suburb: 'Sea Point, Cape Town',
      rating: 4.9,
      totalReviews: 28,
      nightRate: 250.0,
      imageUrl: 'https://i.pravatar.cc/150?img=5',
      completedChecks: ['SA ID Verified', 'SAPS Clearance'],
    ),
    SitterListing(
      id: 102,
      name: 'Michael Tau',
      suburb: 'Sandton, Johannesburg',
      rating: 5.0,
      totalReviews: 14,
      nightRate: 300.0,
      imageUrl: 'https://i.pravatar.cc/150?img=12',
      completedChecks: [
        'SA ID Verified',
        'Proof of Address',
        'Reference Check',
      ],
    ),
    SitterListing(
      id: 103,
      name: 'Jessica Daniels',
      suburb: 'Claremont, Cape Town',
      rating: 4.8,
      totalReviews: 19,
      nightRate: 220.0,
      imageUrl: 'https://i.pravatar.cc/150?img=9',
      completedChecks: ['SA ID Verified'],
    ),
  ];

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

  Future<void> _loadData() async {
    try {
      final email = await _homeService.getUserEmail();
      if (!mounted) return;

      if (email == null || email.isEmpty) {
        setState(() => _email = '');
        return;
      }

      final result = await _homeService.fetchChecks(email: email);
      // when sitters API exists:
      // final sitters = SitterListing.listFromJson(
      //   (await _homeService.fetchSitters(...))['sitters'],
      // );
      if (!mounted) return;

      if (result['success'] == false) {
        setState(() => _email = email);
        _showSnack(result['message']?.toString() ?? 'Could not load checks');
        return;
      }

      setState(() {
        _email = email;
        _checks = OwnerChecks.fromJson(result);
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not load home data');
    }
  }

  void _closeDrawerIfOpen() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  void _open(Widget screen) {
    _closeDrawerIfOpen();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _comingSoon(String title) {
    _closeDrawerIfOpen();
    _showSnack('$title is coming soon');
  }

  Future<void> _signOut() async {
    await AuthService().clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _toggleFavorite(int sitterId) {
    setState(() {
      if (!_favoriteSitterIds.remove(sitterId)) {
        _favoriteSitterIds.add(sitterId);
      }
    });
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

  // ---------- Dialogs ----------

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

  // ---------- Build ----------

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
        savedSittersCount: _favoriteSitterIds.length,
        onProfileTap: () => _open(const OwnerProfileScreen()),
        onBookingsTap: () => _open(const BookingsDashboardScreen()),
        onSavedSittersTap: () => _open(const SavedSittersScreen()),
        onSettingsTap: () => _comingSoon('Settings'),
        onSignOut: _signOut,
      ),
      body: SingleChildScrollView(
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
                isSaved: _favoriteSitterIds.contains(sitter.id),
                onTap: () => _open(const SitterDetailScreen()),
                onMessage: () => _open(const DirectChatScreen()),
                onBook: () => _open(const BookingFlowScreen()),
                onToggleFavorite: () => _toggleFavorite(sitter.id),
              ),
          ],
        ),
      ),
      bottomNavigationBar: OwnerBottomNavBar(onTap: _handleBottomNavTap),
    );
  }
}
