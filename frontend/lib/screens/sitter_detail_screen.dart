import 'package:flutter/material.dart';
import '../models/saved_sitter_model.dart';
import '../models/sitter_details_model.dart';
import '../models/sitter_listing.dart';
import '../services/auth_services.dart';
import '../services/saved_sitter_service.dart';
import '../services/sitter_service.dart';
import '../theme/app_colors.dart';
import '../widgets/homeowner/homeowner_bottom_nav_bar.dart';
import '../widgets/homeowner/sitter_detail/sitter_about_card.dart';
import '../widgets/homeowner/sitter_detail/sitter_action_bar.dart';
import '../widgets/homeowner/sitter_detail/sitter_header_card.dart';
import '../widgets/homeowner/sitter_detail/sitter_pets_card.dart';
import '../widgets/homeowner/sitter_detail/sitter_services_card.dart';
import 'bookings_dashboard_screen.dart';
import 'direct_chat_screen.dart';
import 'messages_screen.dart';
import 'owner_home_screen.dart';
import 'owner_profile_screen.dart';

/// Pops with the sitter's saved state (`true` / `false`) once it is known, so the screen that
/// opened it can update its own bookmark icon; pops with null if it never loaded.
class SitterDetailScreen extends StatefulWidget {
  const SitterDetailScreen({super.key, required this.sitterId});

  final int sitterId;

  @override
  State<SitterDetailScreen> createState() => _SitterDetailScreenState();
}

class _SitterDetailScreenState extends State<SitterDetailScreen> {
  final SitterService _sitterService = SitterService();
  final SavedSitterService _savedSitterService = SavedSitterService();
  final AuthService _authService = AuthService();

  SitterDetails _details = const SitterDetails();
  bool? _isSaved;
  bool _savingFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSavedState();
  }

  Future<void> _loadData() async {
    try {
      final sitterDetails = await _sitterService.getSitterDetails(sitterId: widget.sitterId);
      if (!mounted) return;
      setState(() {
        _details = SitterDetails.fromJson(sitterDetails);
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not load sitter details');
    }
  }

  Future<void> _loadSavedState() async {
    final result = await _savedSitterService.fetchSavedSitters();
    if (!mounted || result['success'] != true) return;
    final saved = SavedSitterModel.listFromJson(result['sitters']);
    setState(() => _isSaved = saved.any((sitter) => sitter.id == widget.sitterId));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  void _onBottomNavTapped(OwnerNavTab tab) {
    final Widget targetScreen;
    switch (tab) {
      case OwnerNavTab.home:
        targetScreen = const OwnerHomeScreen();
        break;
      case OwnerNavTab.bookings:
        targetScreen = const BookingsDashboardScreen();
        break;
      case OwnerNavTab.messages:
        targetScreen = const MessagesScreen();
        break;
      case OwnerNavTab.profile:
        targetScreen = const OwnerProfileScreen();
        break;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
      (route) => false,
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.share, color: AppColors.darkText),
                title: const Text('Share Profile'),
                onTap: () {
                  Navigator.pop(context);
                  _shareProfile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined, color: Colors.red),
                title: const Text('Report Sitter', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted for review.')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing profile for ${_details.name}...')),
    );
  }

  Future<void> _toggleFavorite() async {
    final wasSaved = _isSaved;
    if (wasSaved == null || _savingFavorite) return;

    setState(() {
      _isSaved = !wasSaved;
      _savingFavorite = true;
    });

    var ok = false;
    try {
      final homeownerId = await _authService.getUserId();
      if (homeownerId != null) {
        final result = await _savedSitterService.toggleSavedSitter(
          homeownerId: homeownerId,
          sitterId: widget.sitterId,
          isCurrentlySaved: wasSaved,
        );
        ok = result['success'] == true;
      }
    } catch (e) {
      debugPrint('Error toggling saved sitter: $e');
    }
    if (!mounted) return;

    setState(() {
      _savingFavorite = false;
      if (!ok) _isSaved = wasSaved;
    });
    if (ok) {
      _showSnack(wasSaved ? 'Removed from saved sitters' : 'Added to saved sitters');
    } else {
      _showSnack(wasSaved ? 'Could not remove sitter. Please try again.' : 'Could not save sitter. Please try again.');
    }
  }

  void _messageSitter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(
          partnerId: widget.sitterId,
          partnerName: _details.name.isNotEmpty ? _details.name : 'Sitter',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _isSaved);
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Sitter Profile',
          style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.darkText),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SitterHeaderCard(details: _details, photoUrl: sitterPhotoUrl(widget.sitterId)),
          const SizedBox(height: 16),
          SitterAboutCard(experience: _details.experience),
          const SizedBox(height: 16),
          SitterPetsCard(petPreferences: _details.petPreferences),
          const SizedBox(height: 16),
          SitterServicesCard(services: _details.services),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SitterActionBar(
            isFavorite: _isSaved ?? false,
            onToggleFavorite: _toggleFavorite,
            onMessage: _messageSitter,
          ),
          OwnerBottomNavBar(
            selected: null,
            onTap: _onBottomNavTapped,
          ),
        ],
      ),
    );
  }
}