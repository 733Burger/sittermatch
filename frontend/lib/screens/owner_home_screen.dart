import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import '../services/auth_services.dart';
import '../theme/app_colors.dart';
import 'bookings_dashboard_screen.dart';
import 'saved_sitters_screen.dart';
import 'direct_chat_screen.dart';
import 'sitter_detail_screen.dart';
import 'booking_flow_screen.dart';
import 'messages_screen.dart';
import 'owner_profile_screen.dart';
 
class SitterListing {
  final int id;
  final String name;
  final String suburb;
  final double rating;
  final int totalReviews;
  final double nightRate;
  final String? imageUrl;
  final List<String> completedChecks;
 
  SitterListing({
    required this.id,
    required this.name,
    required this.suburb,
    required this.rating,
    required this.totalReviews,
    required this.nightRate,
    this.imageUrl,
    required this.completedChecks,
  });
}
 
class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});
 
  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}
 
class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isGuestBrowsing = false;
  bool _checksExpanded = false; // checks dropdown starts closed
  String _email = '';
 
  String _homeownerAddress = '12 Main Road, Rondebosch';
  String _emergencyContact = '+27 82 123 4567';
  String? _idPhotoPath;
 
  // 'completed', 'pending' or 'incomplete' statuses
  String _idCheckStatus = 'incomplete';
  String _addressCheckStatus = 'completed';
  String _emergencyCheckStatus = 'pending';
 
  int get _completedChecks => [
        _idCheckStatus,
        _addressCheckStatus,
        _emergencyCheckStatus,
      ].where((s) => s == 'completed').length;
 
  final Set<int> _favoriteSitterIds = {101};
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
 
  final List<String> _filterTags = [
    'All',
    'ID Verified',
    'Pet Type',
    'Date Available',
    'Medication Admin',
  ];
 
  final List<SitterListing> _sitters = [
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
      completedChecks: ['SA ID Verified', 'Proof of Address', 'Reference Check'],
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
    _loadEmail();
  }
 
  Future<void> _loadEmail() async {
    final email = await AuthService().getUserEmail();
    if (!mounted) return;
    setState(() => _email = email ?? '');
  }
 
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
 
  void _closeDrawerIfOpen() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) Navigator.pop(context);
  }
 
  void _open(Widget screen) {
    _closeDrawerIfOpen();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
 
  void _comingSoon(String title) {
    _closeDrawerIfOpen();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title is coming soon')),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
 
  // ---------- Footer navigation ----------
 
  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Already on Home
        break;
      case 1:
        _open(const BookingsDashboardScreen());
        break;
      case 2:
        _open(const MessagesScreen());
        break;
      case 3:
        _open(const OwnerProfileScreen());
        break;
    }
  }
 
  // ---------- Dialogs ----------
 
  void _openIdentityCheckDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Identity / SA ID Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Upload a clear photo of your South African ID Document or Card.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _idPhotoPath = 'uploads/id_card_user.png';
                  _idCheckStatus = 'pending';
                });
                Navigator.pop(ctx);
                _showSnack('ID Photo uploaded successfully! Status set to Pending.');
              },
              icon: const Icon(Icons.upload_file),
              label: Text(_idPhotoPath == null ? 'Upload ID Photo' : 'Replace ID Photo'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }
 
  void _openTextEntryDialog({
    required String title,
    required String prompt,
    required String label,
    required String initialValue,
    required String saveLabel,
    required String savedMessage,
    required void Function(String value) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prompt),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() => onSave(controller.text));
              Navigator.pop(ctx);
              _showSnack(savedMessage);
            },
            child: Text(saveLabel),
          ),
        ],
      ),
    );
  }
 
  void _openAddressCheckDialog() {
    _openTextEntryDialog(
      title: 'Home Address Verification',
      prompt: 'Confirm or enter your home physical address:',
      label: 'Home Address',
      initialValue: _homeownerAddress,
      saveLabel: 'Save & Confirm',
      savedMessage: 'Home address saved! Status set to Pending.',
      onSave: (v) {
        _homeownerAddress = v;
        _addressCheckStatus = 'pending';
      },
    );
  }
 
  void _openEmergencyContactDialog() {
    _openTextEntryDialog(
      title: 'Emergency Contact Details',
      prompt: 'Enter contact number for emergencies while away:',
      label: 'Phone Number',
      initialValue: _emergencyContact,
      saveLabel: 'Save Contact',
      savedMessage: 'Emergency contact saved! Status set to Pending.',
      keyboardType: TextInputType.phone,
      onSave: (v) {
        _emergencyContact = v;
        _emergencyCheckStatus = 'pending';
      },
    );
  }
 
  void _openSubmitDetailsModal() {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Verification Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add an optional message or note for the Admin review team:'),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., Please check my updated proof of residence...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _comingSoon('Admin Verification Review');
            },
            child: const Text('Submit to Admin'),
          ),
        ],
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
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
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
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primaryRust),
              accountName: const Text('Homeowner'),
              accountEmail: Text(_email),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppColors.primaryRust),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () => _open(const OwnerProfileScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('My Bookings'),
              onTap: () => _open(const BookingsDashboardScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border_outlined),
              title: const Text('Saved Sitters'),
              trailing: Badge(
                label: Text('${_favoriteSitterIds.length}'),
                backgroundColor: AppColors.primaryRust,
              ),
              onTap: () => _open(const SavedSittersScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => _comingSoon('Settings'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChecksCard(),
            const SizedBox(height: 24),
            _buildSearchField(),
            const SizedBox(height: 12),
            _buildFilters(),
            const SizedBox(height: 20),
            const Text(
              'Available Sitters Nearby',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._sitters.map(_buildSitterCard),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        currentIndex: 0,
        selectedItemColor: AppColors.primaryRust,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: _handleBottomNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'BOOKINGS'),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('3'),
              backgroundColor: AppColors.primaryRust,
              child: Icon(Icons.chat_bubble_outline),
            ),
            label: 'MESSAGES',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PROFILE'),
        ],
      ),
    );
  }
 
  Widget _buildChecksCard() {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _checksExpanded = !_checksExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.primaryRust, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete your profile',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_completedChecks of 3 checks complete',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _checksExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _checksExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        const Text(
                          'Complete your outstanding checks to start booking sitters.',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        _buildCheckTile(
                          title: 'Identity / SA ID Verification',
                          subtitle: _idPhotoPath == null ? 'No ID uploaded' : 'ID uploaded',
                          status: _idCheckStatus,
                          onTap: _openIdentityCheckDialog,
                        ),
                        _buildCheckTile(
                          title: 'Home Address / Proof of Residence',
                          subtitle: _homeownerAddress,
                          status: _addressCheckStatus,
                          onTap: _openAddressCheckDialog,
                        ),
                        _buildCheckTile(
                          title: 'Emergency Contact Details',
                          subtitle: _emergencyContact,
                          status: _emergencyCheckStatus,
                          onTap: _openEmergencyContactDialog,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: _openSubmitDetailsModal,
                                child: const Text(
                                  'Submit Documents / Details',
                                  style: TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.black87),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 10),
                              ),
                              onPressed: () {
                                setState(() => _isGuestBrowsing = true);
                                _showSnack(
                                    'Guest Browsing Active: Booking functions disabled until verified.');
                              },
                              child: const Text(
                                'Browse as Guest',
                                style: TextStyle(color: Colors.black87, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
 
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search suburb or location...',
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primaryRust),
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryRust, width: 1.5),
        ),
      ),
    );
  }
 
  Widget _buildFilters() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterTags.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tag = _filterTags[index];
          final isSelected = _selectedFilter == tag;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = tag),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black87 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
 
  Widget _avatarPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.person, color: Colors.grey, size: 36),
    );
  }
 
  Widget _buildSitterCard(SitterListing sitter) {
    final isSaved = _favoriteSitterIds.contains(sitter.id);
 
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _open(const SitterDetailScreen()),
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: sitter.imageUrl != null
                              ? Image.network(
                                  sitter.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _avatarPlaceholder(),
                                )
                              : _avatarPlaceholder(),
                        ),
                      ),
                      const Positioned(
                        bottom: -4,
                        right: -4,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primaryRust,
                          child: Icon(Icons.check, color: Colors.white, size: 12),
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
                            Flexible(
                              child: Text(
                                sitter.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'R${sitter.nightRate.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const TextSpan(
                                    text: ' / nt',
                                    style: TextStyle(color: Colors.black54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: AppColors.primaryRust, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                sitter.suburb,
                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.primaryRust, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${sitter.rating} (${sitter.totalReviews})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _open(const DirectChatScreen()),
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
                      label: const Text('Message',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isGuestBrowsing
                          ? () => _showSnack(
                              'Booking is disabled in Guest Mode. Complete verification to book!')
                          : () => _open(const BookingFlowScreen()),
                      icon: const Icon(Icons.calendar_month, color: Colors.white, size: 16),
                      label: const Text('Book',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRust,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isSaved ? Icons.favorite : Icons.favorite_border,
                        color: isSaved ? AppColors.primaryRust : Colors.black87,
                      ),
                      onPressed: () => _toggleFavorite(sitter.id),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _buildCheckTile({
    required String title,
    required String subtitle,
    required String status,
    required VoidCallback onTap,
  }) {
    Color statusColor;
    String statusText;
 
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Completed';
        break;
      case 'pending':
        statusColor = Colors.amber.shade800;
        statusText = 'Pending Review';
        break;
      case 'incomplete':
      default:
        statusColor = Colors.red;
        statusText = 'Incomplete';
        break;
    }
 
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              statusText,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}
 