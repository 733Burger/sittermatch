import 'package:flutter/material.dart';
import 'package:frontend/services/auth_services.dart';
import '../theme/app_colors.dart';
import '../models/saved_sitter_model.dart';
import '../services/saved_sitter_service.dart';
import 'direct_chat_screen.dart';
import 'bookings_dashboard_screen.dart';

class SavedSittersScreen extends StatefulWidget {
  const SavedSittersScreen({super.key});

  @override
  State<SavedSittersScreen> createState() => _SavedSittersScreenState();
}

class _SavedSittersScreenState extends State<SavedSittersScreen> {
  late Future<List<SavedSitterModel>> _sittersFuture;

  @override
  void initState() {
    super.initState();
    _sittersFuture = SavedSitterService.getSavedSitters();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.pets, color: AppColors.primaryRust),
            SizedBox(width: 8),
            Text('Home', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(radius: 14, backgroundColor: Colors.black87, child: Icon(Icons.person, color: Colors.white, size: 16)),
          ),
        ],
      ),
      body: FutureBuilder<List<SavedSitterModel>>(
        future: _sittersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryRust));
          }
          if (snapshot.hasError) return const Center(child: Text('Failed to load sitters.'));

          final sitters = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildFilters(),
              const SizedBox(height: 16),
              ...sitters.map((sitter) => _buildSitterCard(sitter)),
              _buildSecurityFooter(),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Saved\nSitters', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.1)),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(20)),
              child: const Text('3\nSAVED', textAlign: TextAlign.center, style: TextStyle(color: AppColors.primaryRust, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 16, color: AppColors.primaryRust),
                    SizedBox(width: 4),
                    Expanded(child: Text('Cape Town Curated', style: TextStyle(fontSize: 12, color: Colors.black87))),
                  ],
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        const Text('Your trusted shortlist of verified residential stewards and bonded companion carers.', style: TextStyle(color: Colors.black54, fontSize: 13)),
      ],
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
          child: const Text('All Active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
          child: const Text('High Rating', style: TextStyle(color: Colors.black87)),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.tune, color: Colors.black54, size: 16),
          label: const Text('Filter', style: TextStyle(color: Colors.black87)),
        )
      ],
    );
  }

  Widget _buildSitterCard(SavedSitterModel sitter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, color: Colors.grey, size: 36),
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primaryRust,
                      child: Icon(
                        sitter.isVetNurse ? Icons.medical_services : Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(sitter.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: 'R${sitter.price}', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                              const TextSpan(text: ' / nt', style: TextStyle(color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppColors.primaryRust, size: 14),
                        const SizedBox(width: 4),
                        Text(sitter.location, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_outlined, color: AppColors.primaryRust, size: 12),
                          const SizedBox(width: 4),
                          Text(sitter.verificationBadge, style: const TextStyle(color: AppColors.primaryRust, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_border, color: AppColors.primaryRust, size: 14),
                        const SizedBox(width: 4),
                        Text('${sitter.rating} (${sitter.reviewCount})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Text(sitter.bioSnippet, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 13)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const DirectChatScreen()));
                  },
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                  label: const Text('Message Sitter', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    sitter.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: sitter.isSaved ? AppColors.primaryRust : Colors.grey,
                  ),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Processing request...'),
                        duration: Duration(milliseconds: 800),
                      ),
                    );

                    // Instantiating AuthService to retrieve the logged-in ID
                    final authService = AuthService();
                    final int? currentHomeownerId = await authService.getUserId();

                    if (currentHomeownerId == null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User session expired. Please log in again.')),
                      );
                      return;
                    }

                    // Sitter ID remains hardcoded for now as requested
                    const int targetSitterId = 10;
                    final bool wasSaved = sitter.isSaved;

                    debugPrint('Sending POST -> homeownerId: $currentHomeownerId, sitterId: $targetSitterId');

                    try {
                      final success = await SavedSitterService.toggleSaveSitter(
                        homeownerId: currentHomeownerId,
                        sitterId: targetSitterId,
                        isCurrentlySaved: wasSaved,
                      );

                      if (!mounted) return;

                      if (success) {
                        setState(() {
                          sitter.isSaved = !wasSaved;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              wasSaved
                                  ? 'Sitter removed from saved list.'
                                  : 'Sitter added to saved list!',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              wasSaved
                                  ? 'Failed to remove sitter from database.'
                                  : 'Failed to save sitter to database.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error toggling sitter: $e');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Network error: $e')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.primaryRust, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pre-Screened Security Standard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Text('All saved sitters undergo continuous bi-monthly South African Police Service criminal record validation and home conduct reference audits.', style: TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 0,
      currentIndex: 0, 
      selectedItemColor: AppColors.primaryRust,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (index) {
        if (index == 1) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BookingsDashboardScreen()));
        } else if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const DirectChatScreen()));
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'HOME'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'BOOKINGS'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'MESSAGES'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PROFILE'),
      ],
    );
  }
}