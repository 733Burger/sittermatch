import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'sitter_detail_screen.dart';
import 'booking_flow_screen.dart';
import 'direct_chat_screen.dart';
import 'saved_sitters_screen.dart';

class BookingsDashboardScreen extends StatefulWidget {
  const BookingsDashboardScreen({super.key});

  @override
  State<BookingsDashboardScreen> createState() => _BookingsDashboardScreenState();
}

class _BookingsDashboardScreenState extends State<BookingsDashboardScreen> {
  late Future<List<BookingModel>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    // Start the backend stub the exact moment the screeN starts
    _bookingsFuture = BookingService.fetchDashboardBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const Icon(Icons.pets, color: AppColors.primaryRust),
        title: const Text('Bookings', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: AppColors.darkText), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF2C2C2C),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
     // Floating Action Button mapped to open Page 9
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookingFlowScreen()),
          );
        },
        backgroundColor: AppColors.primaryRust,
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text('New Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          //  Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryRust));
          }
          // Error State
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load dashboard data.', style: TextStyle(color: Colors.red)));
          }
          
          // Success State (Data mapped to UI)
          final bookings = snapshot.data!;
          
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              const SizedBox(height: 10),
              _buildSubheader(),
              const SizedBox(height: 16),
              _buildConciergeBanner(),
              const SizedBox(height: 20),
              _buildFilterPills(),
              const SizedBox(height: 20),
              // Dynamically render every card from the backend payload
              ...bookings.map((booking) => _buildDynamicCard(booking)),
              const SizedBox(height: 16),
              _buildArchivedFooter(),
              const SizedBox(height: 80), 
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        currentIndex: 1, 
        selectedItemColor: AppColors.primaryRust,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) {
          // ADDED ROUTING FOR PAGE 11 
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SavedSittersScreen()),
            );
          } else if (index == 2) { 
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DirectChatScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'BOOKINGS'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'MESSAGES'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PROFILE'),
        ],
      ),
    );
  }

  
  // COMPONENT BUILDERS
  
  
  Widget _buildSubheader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ESTATE & SANCTUARY MANAGEMENT', style: TextStyle(color: AppColors.primaryRust, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 4),
            Text('2 active pet stays • 1 live monitoring active', style: TextStyle(color: AppColors.darkText.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: const Row(
            children: [
              Icon(Icons.tune, size: 16, color: AppColors.darkText),
              SizedBox(width: 4),
              Text('FILTER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkText)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildConciergeBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryRust,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('SAPS VETTED NETWORK', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20,
                child: Icon(Icons.add, color: AppColors.primaryRust),
              )
            ],
          ),
          const SizedBox(height: 12),
          const Text('Need Concierge Care?', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Broadcast to elite verified sitters or re-book trusted caregivers.', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('+ Create New Booking  →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Instant Dispatch', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPill('IN PROGRESS (1)', true),
          const SizedBox(width: 8),
          _buildPill('ACCEPTED (1)', false),
          const SizedBox(width: 8),
          _buildPill('SEARCHING (1)', false),
        ],
      ),
    );
  }

  Widget _buildPill(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryRust : AppColors.expandButtonBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          if (isSelected) const Icon(Icons.circle, color: Colors.white, size: 10),
          if (isSelected) const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.darkText.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicCard(BookingModel booking) {
    //start by returning the new click detector
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SitterDetailScreen()),
        );
      },
      
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Tag Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      if (booking.type == BookingType.active) const Icon(Icons.circle, color: AppColors.primaryRust, size: 8),
                      if (booking.type == BookingType.completed) const Icon(Icons.check_circle_outline, color: AppColors.primaryRust, size: 12),
                      if (booking.type == BookingType.upcoming) const Icon(Icons.shield_outlined, color: AppColors.primaryRust, size: 12),
                      const SizedBox(width: 4),
                      Text(booking.badgeText, style: const TextStyle(color: AppColors.primaryRust, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Text(booking.rightBadgeText, style: TextStyle(color: booking.type == BookingType.upcoming ? AppColors.primaryRust : AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
 
          
          //Profile/Title Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (booking.avatarUrl != null) ...[
                
                const CircleAvatar(
                  radius: 24, 
                  backgroundColor: Colors.grey, 
                  child: Icon(Icons.person, color: Colors.white)
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                    const SizedBox(height: 4),
                    Text(booking.subtitle, style: TextStyle(fontSize: 12, color: AppColors.darkText.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
                    if (booking.sitterName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.primaryRust),
                          const SizedBox(width: 4),
                          Text('Sitter: ${booking.sitterName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ]
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic Internals per Type
          if (booking.type == BookingType.active) ...[
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   const Icon(Icons.pets, size: 14, color: AppColors.primaryRust),
                   const SizedBox(width: 6),
                   Text(booking.detailText1!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                 ],
               ),
             ),
             const SizedBox(height: 12),
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: AppColors.lightRustBg.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.lightRustBg)),
               child: Row(
                 children: [
                   const Icon(Icons.check_circle, color: AppColors.primaryRust, size: 20),
                   const SizedBox(width: 12),
                   Expanded(child: Text(booking.detailText2!, style: const TextStyle(fontSize: 12, height: 1.5))),
                   const Text('LIVE\nFEED', textAlign: TextAlign.center, style: TextStyle(color: AppColors.primaryRust, fontSize: 10, fontWeight: FontWeight.bold)),
                 ],
               ),
             ),
             const SizedBox(height: 16),
             SizedBox(
               width: double.infinity,
               child: ElevatedButton.icon(
                 onPressed: () {},
                 style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C2C2C), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                 icon: const Icon(Icons.radar, color: Colors.white, size: 18),
                 label: const Text('View In-Progress Booking & Daily Track', style: TextStyle(color: Colors.white, fontSize: 12)),
               ),
             ),
          ],

          if (booking.type == BookingType.upcoming) ...[
            Row(
              children: [
                Expanded(child: _buildInfoCard(Icons.key, booking.detailText1!)),
                const SizedBox(width: 8),
                Expanded(child: _buildInfoCard(Icons.medical_services, booking.detailText2!)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: AppColors.darkText.withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    icon: const Icon(Icons.chat_bubble_outline, color: AppColors.darkText, size: 16),
                    label: const Text('Message Sitter', style: TextStyle(color: AppColors.darkText, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRust, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    icon: const Icon(Icons.book, color: Colors.white, size: 16),
                    label: const Text('Stay Dossier', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                )
              ],
            )
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildInfoCard(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryRust, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildArchivedFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.expandButtonBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.history, color: AppColors.primaryRust),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Archived Records', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('5 older domestic care dockets on file', style: TextStyle(color: AppColors.darkText.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ),
          ),
          const Text('VIEW ALL STAYS  →', style: TextStyle(color: AppColors.primaryRust, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}