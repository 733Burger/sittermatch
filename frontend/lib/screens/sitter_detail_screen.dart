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

// UI SCREEN
class SitterDetailScreen extends StatefulWidget {
  const SitterDetailScreen({super.key});

  @override
  State<SitterDetailScreen> createState() => _SitterDetailScreenState();
}

class _SitterDetailScreenState extends State<SitterDetailScreen> {
  bool isFavorite = false;
  bool isReviewsExpanded = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sitter Detail',
          style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.darkText),
            onPressed: _showMoreOptions,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OwnerProfileScreen()),
                );
              },
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF8B4513),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Header Tags
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.lightRustBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_outlined, color: AppColors.primaryRust, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'VERIFIED ESTATE CARETAKER',
                          style: TextStyle(
                            color: AppColors.primaryRust,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _shareProfile,
                        child: const CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 18,
                          child: Icon(Icons.share, color: AppColors.darkText, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _toggleFavorite,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 18,
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : AppColors.darkText,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),

              // Profile Info
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(sitter.avatarUrl),
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primaryRust,
                          child: Icon(Icons.security, color: Colors.white, size: 14),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sitter.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppColors.primaryRust, size: 16),
                            const SizedBox(width: 4),
                            Text(sitter.location, style: const TextStyle(color: AppColors.darkText, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.primaryRust, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${sitter.rating}  (${sitter.reviewCount} verified reviews)',
                              style: TextStyle(
                                color: AppColors.darkText.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Certifications
              Row(
                children: [
                  Expanded(child: _buildCertCard(Icons.verified_user_outlined, 'SAPS CERTIFIED', 'Police Clearance Valid')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCertCard(Icons.badge_outlined, 'DHA NATIONAL ID', 'Biometric Registered')),
                ],
              ),
              const SizedBox(height: 30),

              // Companions
              Text(
                'ACCEPTED COMPANIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText.withValues(alpha: 0.6),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sitter.companions.map((c) => _buildCompanionChip(c)).toList(),
              ),
              const SizedBox(height: 30),

              // Security & Mastery
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.primaryRust, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Security & High-Care Mastery',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText),
                              ),
                              Text(
                                'Cape Town Residential Protocols',
                                style: TextStyle(fontSize: 13, color: AppColors.darkText.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primaryRust, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            '${sitter.yearsExperience}+ YRS\nEXP',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Canine First Aid certified with extensive operational familiarity managing high-security & Southern Suburbs residences. Trained in active alarm systems and power redundancy routines.',
                      style: TextStyle(color: AppColors.darkText.withValues(alpha: 0.8), height: 1.5, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildSecurityGridItem(Icons.electrical_services, 'Load Shedding', 'Inverter & Gen Hand...')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSecurityGridItem(Icons.grid_4x4, 'Alarm Systems', 'Paradox, ADT, Electr...')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildSecurityGridItem(Icons.call, 'Armed Response', 'Direct dispatch links')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSecurityGridItem(Icons.medical_services_outlined, 'First Aid Vetted', 'Emergency med do...')),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Services
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Services & Standard\nRates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                  Text('ZAR (R)\nTRANSPARENT', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryRust)),
                ],
              ),
              const SizedBox(height: 16),
              _buildServiceRow(Icons.home_outlined, 'Overnight House & Pet Sitting', 'Continuous overnight care & perim...', 'R320', '/ night'),
              _buildServiceRow(Icons.access_time, 'Drop-In & Feeding Visits', 'Fresh water, medication, meal routines...', 'R160', '/ visit'),
              _buildServiceRow(Icons.directions_walk, 'Dog Walking (Beach & Mountain)', 'Camps Bay tidal runs & Pipe Track tr...', 'R120', '/ hour'),
              _buildServiceRow(Icons.local_florist_outlined, 'Plant Care & House Managem...', 'Mail, pool check, potted plants ...', 'Included', 'with sitting'),
              const SizedBox(height: 30),

              // Reviews
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Homeowner\nEndorsements', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(Icons.workspace_premium, color: AppColors.primaryRust, size: 16),
                      Text('100%\nCompletion', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryRust)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.lightRustBg,
                          child: Text('MS', style: TextStyle(color: AppColors.primaryRust, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Michael S.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText)),
                            Text('Constantia, Cape Town', style: TextStyle(fontSize: 12, color: AppColors.darkText.withValues(alpha: 0.6))),
                          ],
                        ),
                        const Spacer(),
                        Row(children: List.generate(5, (index) => const Icon(Icons.star, color: AppColors.primaryRust, size: 16))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '"Lerato was exceptional with our two German Shepherds and managed our alarm system and solar backup flawlessly during Stage 4 outages. Total peace of mind while overseas."',
                      style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.darkText.withValues(alpha: 0.8), height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, color: AppColors.darkText.withValues(alpha: 0.6), size: 14),
                          const SizedBox(width: 6),
                          Text('14-day booking • German Shepherds', style: TextStyle(fontSize: 11, color: AppColors.darkText.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.expandButtonBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() {
                      isReviewsExpanded = !isReviewsExpanded;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isReviewsExpanded ? 'Collapse Reviews' : 'Expand All 38 Reviews',
                        style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w600),
                      ),
                      Icon(
                        isReviewsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.darkText,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Heritage Bond Footer Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.heritageFooterBg, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified, color: AppColors.primaryRust, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('The Heritage Concierge\nBond', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            'Every reserved stay is backed by R10,000,000 public liability, 24/7 telephonic vet support via Cape Animal Medical Centre, and instant replacement emergency cover.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.5),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black12, width: 1)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _toggleFavorite,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : AppColors.darkText,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Message Sitter', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
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

  // Helper Widgets
  Widget _buildCertCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryRust, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: const TextStyle(color: AppColors.primaryRust, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: AppColors.darkText.withValues(alpha: 0.7), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildCompanionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.companionChipBg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pets, color: AppColors.primaryRust, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSecurityGridItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryRust, size: 20),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(color: AppColors.darkText.withValues(alpha: 0.6), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildServiceRow(IconData icon, String title, String subtitle, String price, String unit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.primaryRust, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: AppColors.darkText.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRust, fontSize: 16)),
              Text(unit, style: TextStyle(color: AppColors.darkText.withValues(alpha: 0.6), fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }
}