import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';

import '../models/homeowner_checks_model.dart';
import '../services/auth_services.dart';
import '../services/sitter_verification_service.dart';
import '../theme/app_colors.dart';
import '../utils/profile_completion.dart';
import '../widgets/homeowner/dialogs/address_check_dialog.dart';
import '../widgets/homeowner/dialogs/emergency_contact_dialog.dart';
import '../widgets/homeowner/dialogs/identity_check_dialog.dart';
import '../widgets/homeowner/homepage/verification_checks_card.dart';
import 'bookings_dashboard_screen.dart';
import 'jobs_dashboard_screen.dart';
import 'messages_screen.dart';
import 'owner_home_screen.dart';
import 'owner_profile_screen.dart';
import 'sitter_profile_screen.dart';

class SitterHomeScreen extends StatefulWidget {
  const SitterHomeScreen({super.key});

  @override
  State<SitterHomeScreen> createState() => _SitterHomeScreenState();
}

class _SitterHomeScreenState extends State<SitterHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();

  String _email = '';
  String _userRole = 'SITTER';

  final SitterVerificationService _checkService = SitterVerificationService();
  OwnerChecks _checks = const OwnerChecks();

  // THE hard coded data
  // We can change these names, pets, and prices to whatever you want
  final List<Map<String, dynamic>> hardCodedBookings = const [
    {
      'ownerName': 'Kayla M.',
      'petDetails': 'Luna (Golden Retriever)',
      'location': 'Bedfordview, Gauteng',
      'dates': '28 Oct - 31 Oct',
      'pay': 'R450 / night',
    },
    {
      'ownerName': 'Jamie T.',
      'petDetails': 'Cleo (Domestic Shorthair)',
      'location': 'Oakdene, Johannesburg',
      'dates': '02 Nov - 05 Nov',
      'pay': 'R350 / night',
    },
    {
      'ownerName': 'Catia D.',
      'petDetails': 'Milo (French Bulldog)',
      'location': 'Germiston, Gauteng',
      'dates': '10 Nov - 12 Nov',
      'pay': 'R400 / night',
    },
  ];

  @override
  void initState() {
    super.initState();
    _requireCompleteProfile();
    _loadUserData();
  }

  // New sitters fill in their profile before they can use the rest of the app.
  Future<void> _requireCompleteProfile() async {
    final missing = await missingProfileItems();
    if (!mounted || missing.isEmpty) return;
    Navigator.of(context)
        .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SitterProfileScreen()), (route) => false);
  }

  Future<void> _loadUserData() async {
    final email = await _authService.getUserEmail();
    final role = await _authService.getUserRole();
    if (!mounted) return;
    setState(() {
      _email = email ?? '';
      _userRole = (role ?? 'SITTER').toUpperCase();
    });

    if (_email.isNotEmpty) _refreshChecks();
  }

  // Fetches only the verification checks, so saving a check updates just the checklist card.
  Future<void> _refreshChecks() async {
    final result = await _checkService.fetchChecks();
    if (!mounted) return;

    if (result['success'] != true) {
      _showSnack(result['message']?.toString() ?? 'Could not load checks');
      return;
    }
    setState(() => _checks = OwnerChecks.fromJson(result));
  }

  void _closeDrawerIfOpen() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) Navigator.pop(context);
  }

  void _open(Widget screen) {
    _closeDrawerIfOpen();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signOut() async {
    await _authService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  // Dialogs (the same ones the homeowner home page uses)

  void _showMessageIfMounted(String message) {
    if (mounted) _showSnack(message);
  }

  void _openIdentityCheckDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => IdentityCheckDialog(
        email: _email,
        checkService: _checkService,
        onUploaded: () {
          if (!mounted) return;
          _showSnack('ID Photo uploaded successfully! Status set to Pending.');
          _refreshChecks();
        },
        onMessage: _showMessageIfMounted,
      ),
    );
  }

  void _openAddressCheckDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddressCheckDialog(
        initialAddress: _checks.addressCheck.status == CheckStatus.incomplete ? '' : _checks.addressCheck.subtitle,
        email: _email,
        checkService: _checkService,
        onSaved: () {
          if (!mounted) return;
          _showSnack('Home address saved! Status set to Pending.');
          _refreshChecks();
        },
        onMessage: _showMessageIfMounted,
      ),
    );
  }

  void _openEmergencyContactDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmergencyContactDialog(
        initialName: _checks.emergencyContactName,
        initialPhone: _checks.emergencyContactNumber,
        email: _email,
        checkService: _checkService,
        onSaved: () {
          if (!mounted) return;
          _showSnack('Emergency contact saved! Status set to Pending.');
          _refreshChecks();
        },
        onMessage: _showMessageIfMounted,
      ),
    );
  }

  // Navigation Routing

  void _handleBottomNavTap(int index) {
    final isSitter = _userRole == 'SITTER';

    switch (index) {
      case 0:
        if (!isSitter) _open(const OwnerHomeScreen());
        break;
      case 1:
        _open(isSitter ? const JobsDashboardScreen() : const BookingsDashboardScreen());
        break;
      case 2:
        _open(const MessagesScreen());
        break;
      case 3:
        _open(isSitter ? const SitterProfileScreen() : const OwnerProfileScreen());
        break;
    }
  }

  // Build

  @override
  Widget build(BuildContext context) {
    final bool isSitter = _userRole == 'SITTER';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
      ),
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primaryRust),
              accountName: Text(isSitter ? 'Sitter' : 'Homeowner'),
              accountEmail: Text(_email),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppColors.primaryRust),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () => _open(isSitter ? const SitterProfileScreen() : const OwnerProfileScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      // Pull down to pick up a check an admin has just approved or rejected.
      body: RefreshIndicator(
        color: AppColors.primaryRust,
        onRefresh: _refreshChecks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VerificationChecksCard(
                checks: _checks,
                onIdentityTap: _openIdentityCheckDialog,
                onAddressTap: _openAddressCheckDialog,
                onEmergencyContactTap: _openEmergencyContactDialog,
                readySubtitle: 'You’re ready to take bookings',
              ),

              // THE OPEN BOOKINGS LIST
              const SizedBox(height: 32),
              const Text('Open Bookings Near You', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // This loop generates a beautiful card for each item in the hardCodedBookings list
              ...hardCodedBookings.map((booking) => _buildBookingCard(booking)),

              const SizedBox(height: 24),
            ],
          ),
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
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'HOME'),
          BottomNavigationBarItem(
            icon: Icon(isSitter ? Icons.work_outline : Icons.calendar_today),
            label: isSitter ? 'JOBS' : 'BOOKINGS',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'MESSAGES'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PROFILE'),
        ],
      ),
    );
  }

  // this will create the layout for the hard-coded Open Bookings cards
  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(booking['ownerName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRust.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking['pay'],
                    style: const TextStyle(color: AppColors.primaryRust, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.pets, booking['petDetails']),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_outlined, booking['location']),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today_outlined, booking['dates']),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: AppColors.primaryRust,
                      side: const BorderSide(color: AppColors.primaryRust),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRust,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Apply Now',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Creates the icon and text rows for the booking cards
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: Colors.grey[800], fontSize: 15)),
      ],
    );
  }
}
