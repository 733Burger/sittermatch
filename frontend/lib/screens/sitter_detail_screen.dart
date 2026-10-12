import 'package:flutter/material.dart';
import 'package:frontend/models/sitter_details_model.dart';
import '../theme/app_colors.dart';
import '../services/sitter_service.dart';
import 'direct_chat_screen.dart';
import 'messages_screen.dart';
import 'owner_profile_screen.dart';
import 'owner_home_screen.dart';
import 'bookings_dashboard_screen.dart';

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

  // Detail screen isn't a root tab page, so selected tab state starts unselected (-1)
  int currentNavIndex = -1;

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

  void _onBottomNavTapped(int index) {
    setState(() => currentNavIndex = index);

    Widget targetScreen;
    switch (index) {
      case 0:
        targetScreen = const OwnerHomeScreen();
        break;
      case 1:
        targetScreen = const BookingsDashboardScreen();
        break;
      case 2:
        targetScreen = const MessagesScreen();
        break;
      case 3:
        targetScreen = const OwnerProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
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
    setState(() {
      isFavorite = !isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? 'Added to saved sitters' : 'Removed from saved sitters',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
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

  IconData _serviceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'stay over night':
      case 'overnight sitting':
        return Icons.nights_stay_outlined;
      case 'walk dog':
      case 'dog walking':
        return Icons.directions_walk;
      case 'feed dog':
      case 'drop-in visit':
        return Icons.restaurant_outlined;
      default:
        return Icons.pets;
    }
  }

  String get _initial {
    final name = _details.name.trim();
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
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
          _buildHeaderCard(),
          const SizedBox(height: 16),
          _buildAboutCard(),
          const SizedBox(height: 16),
          _buildPetsCard(),
          const SizedBox(height: 16),
          _buildServicesCard(),
          const SizedBox(height: 16),
          _buildReviewsCard(),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _toggleFavorite,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppColors.primaryRust : AppColors.darkText,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await SitterService.initiateChat('lerato_123');
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DirectChatScreen(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRust,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                    label: const Text(
                      'Message Sitter',
                      style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            currentIndex: currentNavIndex == -1 ? 0 : currentNavIndex,
            onTap: _onBottomNavTapped,
            selectedItemColor: currentNavIndex == -1 ? Colors.grey : AppColors.primaryRust,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Bookings'),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
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
                backgroundColor: AppColors.lightRustBg,
                child: Text(
                  _initial,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRust,
                  ),
                ),
              ),
              if (_details.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRust,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _details.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          if (_details.email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _details.email,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
          if (_details.phoneNumber.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _details.phoneNumber,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.primaryRust, size: 18),
              const SizedBox(width: 4),
              Text(
                _details.rating.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                ' (${_details.totalReviews} reviews)',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('About & experience'),
          const SizedBox(height: 10),
          Text(
            _details.experience,
            style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Accepted pets'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _details.petPreferences.map((pet) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.expandButtonBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pets, color: AppColors.primaryRust, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      pet,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Services & rates'),
          const SizedBox(height: 2),
          const Text(
            'Prices are in rand (R).',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          ..._details.services.map(_buildServiceRow),
        ],
      ),
    );
  }

  Widget _buildServiceRow(SitterServiceItem service) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_serviceIcon(service.serviceType), color: AppColors.primaryRust, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              service.serviceType,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            'R${service.price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryRust,
              fontSize: 16,
            ),
          ),
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
          _sectionTitle('Rating & reviews'),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _details.rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stars(_details.rating, size: 18),
                  const SizedBox(height: 2),
                  Text(
                    '${_details.totalReviews} reviews',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}