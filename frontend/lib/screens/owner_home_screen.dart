import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import 'role_select_screen.dart';

class Sitter {
  final int id;
  final String name;
  final String suburb;
  final double rating;
  final int totalReviews;
  final double nightRate;
  final String? imageUrl;
  final List<String> completedChecks;

  Sitter({
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
  int _currentBottomNavIndex = 0;
  bool _isGuestBrowsing = false;

  String _homeownerAddress = '12 Main Road, Rondebosch';
  String _emergencyContact = '+27 82 123 4567';
  String? _idPhotoPath;

  String _idCheckStatus = 'incomplete';
  String _addressCheckStatus = 'completed';
  String _emergencyCheckStatus = 'pending';

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

  final List<Sitter> _sitters = [
    Sitter(
      id: 101,
      name: 'Sarah Jenkins',
      suburb: 'Sea Point, Cape Town',
      rating: 4.9,
      totalReviews: 28,
      nightRate: 250.0,
      imageUrl: 'https://i.pravatar.cc/150?img=5',
      completedChecks: ['SA ID Verified', 'SAPS Clearance'],
    ),
    Sitter(
      id: 102,
      name: 'Michael Tau',
      suburb: 'Sandton, Johannesburg',
      rating: 5.0,
      totalReviews: 14,
      nightRate: 300.0,
      imageUrl: 'https://i.pravatar.cc/150?img=12',
      completedChecks: ['SA ID Verified', 'Proof of Address', 'Reference Check'],
    ),
    Sitter(
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToPage(String title) {
    // Only close the drawer if it is actually open.
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to $title...')),
    );
  }

  Future<void> _signOut() async {
    await AuthService().clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
      (route) => false,
    );
  }

  void _toggleFavorite(int sitterId) {
    setState(() {
      if (_favoriteSitterIds.contains(sitterId)) {
        _favoriteSitterIds.remove(sitterId);
      } else {
        _favoriteSitterIds.add(sitterId);
      }
    });
  }

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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ID Photo uploaded successfully! Status set to Pending.')),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: Text(_idPhotoPath == null ? 'Upload ID Photo' : 'Replace ID Photo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _openAddressCheckDialog() {
    final TextEditingController addressController = TextEditingController(text: _homeownerAddress);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Home Address Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirm or enter your home physical address:'),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Home Address',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _homeownerAddress = addressController.text;
                _addressCheckStatus = 'pending';
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Home address saved! Status set to Pending.')),
              );
            },
            child: const Text('Save & Confirm'),
          ),
        ],
      ),
    );
  }

  void _openEmergencyContactDialog() {
    final TextEditingController contactController = TextEditingController(text: _emergencyContact);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency Contact Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter contact number for emergencies while away:'),
            const SizedBox(height: 12),
            TextField(
              controller: contactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _emergencyContact = contactController.text;
                _emergencyCheckStatus = 'pending';
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Emergency contact saved! Status set to Pending.')),
              );
            },
            child: const Text('Save Contact'),
          ),
        ],
      ),
    );
  }

  void _openSubmitDetailsModal() {
    final TextEditingController messageController = TextEditingController();
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToPage('Admin Verification Review');
            },
            child: const Text('Submit to Admin', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'SIT & STAY',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Colors.black),
            tooltip: 'Security & Trust',
            onPressed: () => _navigateToPage('Security & Trust Screen'),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              accountName: Text('Homeowner Dashboard'),
              accountEmail: Text('owner@sitstay.co.za'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.black),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () => _navigateToPage('Homeowner Profile'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('My Bookings'),
              onTap: () => _navigateToPage('My Bookings'),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border_outlined),
              title: const Text('Saved Sitters'),
              trailing: Badge(
                label: Text('${_favoriteSitterIds.length}'),
                backgroundColor: Colors.black,
              ),
              onTap: () => _navigateToPage('Saved Sitters'),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => _navigateToPage('Settings'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete Your Homeowner Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Complete your outstanding checks to start booking sitters.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

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
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _openSubmitDetailsModal,
                          child: const Text('Submit Documents / Details', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        ),
                        onPressed: () {
                          setState(() => _isGuestBrowsing = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Guest Browsing Active: Booking functions disabled until verified.')),
                          );
                        },
                        child: const Text('Browse as Guest', style: TextStyle(color: Colors.black, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search suburb or location...',
                hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.black),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filterTags.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tag = _filterTags[index];
                  final isSelected = _selectedFilter == tag;
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) => setState(() => _selectedFilter = tag),
                    selectedColor: Colors.grey.shade300,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? Colors.black : const Color(0xFFCBD5E1)),
                    ),
                    showCheckmark: false,
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Available Sitters Nearby',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sitters.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sitter = _sitters[index];
                final isFavorited = _favoriteSitterIds.contains(sitter.id);

                return InkWell(
                  onTap: () => _navigateToPage('Sitter Profile (${sitter.name})'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundImage: sitter.imageUrl != null ? NetworkImage(sitter.imageUrl!) : null,
                              child: sitter.imageUrl == null ? const Icon(Icons.person) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sitter.name,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    sitter.suburb,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                      Text(
                                        ' ${sitter.rating} ',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '(${sitter.totalReviews} reviews)',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: isFavorited
                                  ? const Icon(Icons.favorite, color: Colors.black)
                                  : const Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(Icons.favorite, color: Colors.black, size: 24),
                                        Icon(Icons.favorite, color: Colors.white, size: 20),
                                      ],
                                    ),
                              onPressed: () => _toggleFavorite(sitter.id),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: sitter.completedChecks.map((checkLabel) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, size: 12, color: Colors.black),
                                  const SizedBox(width: 4),
                                  Text(
                                    checkLabel,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'R${sitter.nightRate.toStringAsFixed(0)}/night',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black),
                            ),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.black),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  onPressed: () => _navigateToPage('Messages List'),
                                  icon: const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.black),
                                  label: const Text('Message', style: TextStyle(color: Colors.black, fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  onPressed: _isGuestBrowsing
                                      ? () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Booking is disabled in Guest Mode. Complete verification to book!')),
                                          );
                                        }
                                      : () => _navigateToPage('Bookings Dashboard'),
                                  icon: const Icon(Icons.calendar_month, size: 14, color: Colors.white),
                                  label: const Text('Book', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() => _currentBottomNavIndex = index);
          switch (index) {
            case 0:
              break; // already on Home
            case 1:
              _navigateToPage('Bookings Dashboard');
              break;
            case 2:
              _navigateToPage('Messages List');
              break;
            case 3:
              _navigateToPage('Homeowner Profile');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
          BottomNavigationBarItem(
            icon: Badge(label: Text('3'), backgroundColor: Colors.black, child: Icon(Icons.chat_bubble_outline)),
            label: 'Messages',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
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