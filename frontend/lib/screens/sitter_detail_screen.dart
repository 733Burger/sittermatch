import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/sitter_service.dart';
import 'direct_chat_screen.dart';
import 'messages_screen.dart';
import 'owner_profile_screen.dart';
import 'owner_home_screen.dart';
import 'bookings_dashboard_screen.dart';

// DATA MODEL
class SitterProfile {
  final String name;
  final String location;
  final double rating;
  final int reviewCount;
  final String avatarUrl;
  final List<String> companions;
  final int yearsExperience;

  SitterProfile({
    required this.name,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.avatarUrl,
    required this.companions,
    required this.yearsExperience,
  });
}

/// One service the sitter offers, with their price.
class _ServiceRate {
  final IconData icon;
  final String title;
  final String? detail;
  final String price;
  final String unit;

  const _ServiceRate({
    required this.icon,
    required this.title,
    this.detail,
    required this.price,
    required this.unit,
  });
}

class _Review {
  final String author;
  final double rating;
  final String comment;
  final String date;

  const _Review({
    required this.author,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class SitterDetailScreen extends StatefulWidget {
  const SitterDetailScreen({super.key});

  @override
  State<SitterDetailScreen> createState() => _SitterDetailScreenState();
}

class _SitterDetailScreenState extends State<SitterDetailScreen> {
  bool isFavorite = false;

  // Detail screen isn't a root tab page, so selected tab state starts unselected (-1)
  int currentNavIndex = -1;

  final SitterProfile sitter = SitterProfile(
    name: 'Lerato Khumalo',
    location: 'Camps Bay, Cape Town',
    rating: 4.95,
    reviewCount: 38,
    avatarUrl: 'https://i.pravatar.cc/150?img=44',
    companions: ['Dogs (All Sizes)', 'Cats', 'Senior Dogs', 'Birds & Parrots'],
    yearsExperience: 8,
  );

  // Sample details. TODO: load these from the backend.
  static const String _about =
      'Canine first aid certified, with 8 years of experience looking after dogs and cats '
      'in Southern Suburbs homes. Comfortable with alarm systems and load shedding routines.';

  static const List<_ServiceRate> _services = [
    _ServiceRate(
      icon: Icons.nights_stay_outlined,
      title: 'Stay over night',
      price: 'R320',
      unit: '/ night',
    ),
    _ServiceRate(
      icon: Icons.directions_walk,
      title: 'Walk dog',
      detail: '45 minute walks',
      price: 'R120',
      unit: '/ walk',
    ),
    _ServiceRate(
      icon: Icons.restaurant_outlined,
      title: 'Feed dog',
      price: 'R160',
      unit: '/ visit',
    ),
  ];

  static const List<_Review> _reviews = [
    _Review(
      author: 'Michael S.',
      rating: 5.0,
      comment:
          'Lerato was exceptional with our two German Shepherds and managed the alarm system '
          'and solar backup flawlessly. Total peace of mind while overseas.',
      date: 'Sep 2026',
    ),
    _Review(
      author: 'Claire V.',
      rating: 4.9,
      comment: 'Punctual, caring and sent daily photo updates.',
      date: 'Aug 2026',
    ),
  ];

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

    // Clear detail screen stack and navigate directly to root destination view
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
      SnackBar(content: Text('Sharing profile for ${sitter.name}...')),
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

  // ---------- Helpers ----------

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

  // ---------- Build ----------

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
                backgroundColor: Colors.grey.shade300,
                backgroundImage: NetworkImage(sitter.avatarUrl),
              ),
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
            sitter.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primaryRust, size: 16),
              const SizedBox(width: 4),
              Text(
                sitter.location,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.primaryRust, size: 18),
              const SizedBox(width: 4),
              Text(
                sitter.rating.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                ' (${sitter.reviewCount} reviews)',
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
          const Text(
            _about,
            style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
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
            children: sitter.companions.map((c) {
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
                      c,
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
          ..._services.map(_buildServiceRow),
        ],
      ),
    );
  }

  Widget _buildServiceRow(_ServiceRate service) {
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
            child: Icon(service.icon, color: AppColors.primaryRust, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                    fontSize: 14,
                  ),
                ),
                if (service.detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    service.detail!,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                service.price,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryRust,
                  fontSize: 16,
                ),
              ),
              Text(
                service.unit,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
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
                sitter.rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stars(sitter.rating, size: 18),
                  const SizedBox(height: 2),
                  Text(
                    '${sitter.reviewCount} reviews',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          ..._reviews.map(_buildReviewTile),
        ],
      ),
    );
  }

  Widget _buildReviewTile(_Review review) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.lightRustBg,
            child: Text(
              review.author.isEmpty ? '?' : review.author[0].toUpperCase(),
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
                        review.author,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.primaryRust, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          review.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  review.comment,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  review.date,
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