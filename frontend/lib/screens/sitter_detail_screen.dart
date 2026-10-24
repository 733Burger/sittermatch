import 'package:flutter/material.dart';
import '../models/sitter_details_model.dart';
import '../services/sitter_service.dart';
import '../theme/app_colors.dart';
import '../widgets/homeowner/homeowner_bottom_nav_bar.dart';
import '../widgets/homeowner/sitter_detail/sitter_about_card.dart';
import '../widgets/homeowner/sitter_detail/sitter_action_bar.dart';
import '../widgets/homeowner/sitter_detail/sitter_header_card.dart';
import '../widgets/homeowner/sitter_detail/sitter_pets_card.dart';
import '../widgets/homeowner/sitter_detail/sitter_reviews_card.dart';
import '../widgets/homeowner/sitter_detail/sitter_services_card.dart';
import 'bookings_dashboard_screen.dart';
import 'direct_chat_screen.dart';
import 'messages_screen.dart';
import 'owner_home_screen.dart';
import 'owner_profile_screen.dart';

class SitterDetailScreen extends StatefulWidget {
  const SitterDetailScreen({super.key, required this.sitterId});

  final int sitterId;

  @override
  State<SitterDetailScreen> createState() => _SitterDetailScreenState();
}

class _SitterDetailScreenState extends State<SitterDetailScreen> {
  final SitterService _sitterService = SitterService();

  SitterDetails _details = const SitterDetails();
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadData();
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  void _toggleFavorite() {
    setState(() => isFavorite = !isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? 'Added to saved sitters' : 'Removed from saved sitters',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
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
          SitterHeaderCard(details: _details),
          const SizedBox(height: 16),
          SitterAboutCard(experience: _details.experience),
          const SizedBox(height: 16),
          SitterPetsCard(petPreferences: _details.petPreferences),
          const SizedBox(height: 16),
          SitterServicesCard(services: _details.services),
          const SizedBox(height: 16),
          SitterReviewsCard(
            rating: _details.rating,
            reviewCount: _details.totalReviews,
          ),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SitterActionBar(
            isFavorite: isFavorite,
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